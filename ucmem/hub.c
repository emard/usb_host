// Handle hub functions
// A. Manage the hub itself
//    1. When a hub connects, create new ports / devices
//    2. Monitor hub interupt endpoint for status changes (notably port disconnect events)
// B. Provide a connection action routine for each new port
//

#include "root.h"

extern int sim;
extern DEV connections[];
extern EP  endpoints[];
extern uint8_t buffer[];

#pragma pack on
struct UsbHubDescriptor {
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bNbrPorts;
  uint8_t  wHubCharacteristicsL;
  uint8_t  wHubCharacteristicsH;
  uint8_t  bPwrOn2PwrGood;
  uint8_t  bHubContrCurrent;
  uint8_t  DeviceRemovable;
  uint8_t  PortPwrCtrlMask;
};
#pragma pack off

#define HUB_DESC   0x2900
#define GET_STAT     0x00
#define SET_FEAT     0x03
#define CLR_FEAT     0x01
#define POWER        0x08
#define RESET        0x04

// Port status word bits
#define HAS_POWER   0x00000100
#define CONNECTED   0x00000001
#define ENABLED     0x00000002
#define HAS_RESET   0x00100000
#define IS_LS_DEV   0x00000200

enum hub_state {
    get_desc, build_ports, get_status, act_status, do_next, cmd_wait, hub_wait, dev_stall = 255
};

// Driver for the hub itself
//
int drv_hub(DEV *dev, uint8_t *data)
{
    struct UsbHubDescriptor *hub_desc;
    DEV *port;
    static DEV *lock = NULL;
    int i;
    static uint32_t status, idx;

    if (dev->ep[0]->state != ep_idle) return;
    if (sim) dev->when = timer_now();
    if (dev->when > timer_now()) return;
    
    switch (dev->dev_state) {
    
    // To-do: review configuration data before jumping in
    // Re-use config buffer for hub descriptor
    case get_desc:
        printf("hub connected\n");
        do_setup(dev, (SU_IN|SU_CLS|SU_DEV), REQ_GET_DESCRIPTOR, HUB_DESC, 0, sizeof(*hub_desc));
        dev->setup.pData = data;
        dev->dev_state = build_ports;
        return 1;
        
    case build_ports:
        if (dev->ep[0]->resp != PID_ACK) break;
        printf("GET HUB DESC ok\n");

        hub_desc = (struct UsbHubDescriptor *)dev->setup.pData;
        for(i=1; i<=hub_desc->bNbrPorts; i++) {
            printf("creating hub port %x\n", i);
            port = clr_port(i);
            port->prt_flags = HUB_PORT;
        }
        dev->prt_idx   = hub_desc->bNbrPorts;
        dev->dev_state = get_status;
        idx = 1;
        return 1;
    
    case get_status:
        do_setup(dev, (SU_IN|SU_CLS|SU_OTHER), REQ_GET_STATUS, 0, idx, 4);
        dev->setup.pData = (uint8_t *)&status;
        dev->dev_state = act_status;
        return 1;
        
    case act_status:
        if (dev->ep[0]->resp != PID_ACK) break;
        //printf("GET PORT STATUS ok\n");
        
        // release reset lock if possible (has address or stalled)
        if (lock) {
            if ((lock->dev_addr != 0) || (lock->prt_flags & PRT_STALL))
                lock = NULL;
        }
        
        // check that port is still connected to the device
        //
        port = &connections[idx];
        if (((status & ENABLED) == 0) && (port->prt_flags & PRT_ENABLED)) {
            printf("port %x disconnected\n", idx);
            port = clr_port(idx);
            port->prt_flags = HUB_PORT;
            do_setup(dev, (SU_OUT|SU_CLS|SU_OTHER), CLR_FEAT, POWER, idx, 0);
            dev->dev_state = cmd_wait;
            return 1;
        }
        
        // power up port, wait for device insertion and reset device
        //
        if ((status & HAS_POWER) == 0) {
            do_setup(dev, (SU_OUT|SU_CLS|SU_OTHER), SET_FEAT, POWER, idx, 0);
            dev->dev_state = cmd_wait;
        }
        else if ((status & CONNECTED) == 0) {
            port->prt_flags |= PRT_POWER;
            dev->dev_state = do_next;
        }
        else if ((status & HAS_RESET) == 0) {
            port->prt_flags |= PRT_CONNECT;
            // only can reset if no other reset is pending, otherwise wait
            if (lock == NULL) {
                lock = port;
                do_setup(dev, (SU_OUT|SU_CLS|SU_OTHER), SET_FEAT, RESET, idx, 0);
                dev->dev_state = cmd_wait;
            }
            else
                dev->dev_state = hub_wait;
        }
        else if (status & ENABLED) {
            if ((port->prt_flags & PRT_ENABLED) == 0) {
                printf("port %x connected, status = %x, ep = %x\n", idx, status, port->ep[0]);
                /* to-do: set port speed & start port enum */
                port->prt_flags |= (PRT_RESET|PRT_ENABLED) | ((status & IS_LS_DEV) ? PRT_LS : PRT_FS);
                port->driver     = &enum_dev;
                port->dev_state  = 0; // = enum:set_address
            }
            dev->dev_state = do_next;
        }
        else
            dev->dev_state = do_next;
        return 1;
    
    case do_next:
        if (++idx > dev->prt_idx) idx = 1;
        dev->dev_state = hub_wait;
        return 1;
        
    case cmd_wait:
        if (dev->ep[0]->resp != PID_DATA1) break;
        printf("SET/CLR FEAT ok\n");
        /* fall through */

    case hub_wait:
        dev->when = timer_now() + 255;
        dev->dev_state = get_status;
        return 1;

    }
    printf("Hub driver step failed (%x, %x)\n", dev->dev_state, dev->ep[0]->resp);
    dev->dev_state = dev_stall;
    return 0;
}

extern uint32_t *uart;

enum port_state {
    device_enum
};

// Connection management for hub ports
//
void process_hub(DEV *dev)
{
    uart[2] = dev->prt_flags;
    
    // if enabled call driver; reset as needed
    if (dev->prt_flags & PRT_ENABLED) {
    //printf("idx=%x addr=%x, state=%x, ep_st=%x\n", dev->prt_idx, dev->dev_addr, dev->dev_state, dev->ep[0]->state);
        if (dev->driver(dev, NULL) == 0) {
            dev->prt_flags &= ~(PRT_ENABLED|PRT_RESET);
            dev->prt_flags |= PRT_STALL;
        }
    }
}

