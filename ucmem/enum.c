// Enumerate the (newly connected) device
//

#include "root.h"

struct UsbDeviceDescriptor dev_desc;
uint8_t buffer[256];
extern int sim;

void prn_dev_desc(uint8_t *data);
void prn_cf_full(uint8_t *data);

void prn_all(DEV *dev)
{
    prn_dev_desc((uint8_t*) &dev_desc);
    prn_cf_full((uint8_t*) buffer);
    printf("# of NAKs: %x\n", dev->nak);
    printf("# of TOs:  %x\n", dev->tout); 
}

void set_driver(DEV *dev, uint8_t *data);

int nxt_addr = 1;

enum enum_state {
  set_addr, get_dev_desc, get_cfg_desc, set_config, get_full_config, dev_enumerated, dev_stall = 255
};

int enum_dev(DEV *dev, uint8_t *data)
{
    struct UsbConfigurationDescriptor *desc_conf = (struct UsbConfigurationDescriptor*)buffer;

    if (dev->ep[0]->state != ep_idle) return 1;
    if (sim) dev->when = timer_now();
    if (dev->when > timer_now()) return 1;

    switch (dev->dev_state) {
    
    case set_addr:
        do_setup(dev, (SU_OUT|SU_STD|SU_DEV), REQ_SET_ADDRESS, nxt_addr, 0, 0);
        dev->when = timer_now() + 50;
        dev->dev_state = get_dev_desc;
        return 1;
        
    case get_dev_desc:
        if (dev->ep[0]->resp != PID_DATA1) break;
        dev->dev_addr = nxt_addr++;
        printf("SET ADDR ok\n");
        
        do_setup(dev, (SU_IN|SU_STD|SU_DEV), REQ_GET_DESCRIPTOR, DEV_DESC, 0, sizeof(dev_desc));
        dev->setup.pData = (uint8_t *) &dev_desc;
        dev->dev_state = get_cfg_desc;
        return 1;
    
    case get_cfg_desc:
        if (dev->ep[0]->resp != PID_ACK) break;
        printf("GET DEV DESC ok\n");
        
        do_setup(dev, (SU_IN|SU_STD|SU_DEV), REQ_GET_DESCRIPTOR, CONF_DESC, 0, sizeof(*desc_conf));
        dev->setup.pData = buffer;
        dev->dev_state = set_config;
        return 1;

    case set_config:
        if (dev->ep[0]->resp != PID_ACK) break;
        printf("GET CONF DESC ok, size = %x\n", ((struct UsbConfigurationDescriptor*)buffer)->wTotalLength);
        
        do_setup(dev, (SU_OUT|SU_STD|SU_DEV), REQ_SET_CONFIGURATION, desc_conf->bConfigurationValue, 0, 0);
        dev->when = timer_now() + 10;
        dev->dev_state = get_full_config;
        return 1;

    case get_full_config:
        if (dev->ep[0]->resp != PID_DATA1) break;
        printf("SET CONFIG ok\n");
        if (desc_conf->wTotalLength > sizeof(buffer)) {
            printf("configuration too large\n");
            dev->dev_state = dev_stall;
            return 0;
        }
        do_setup(dev, (SU_IN|SU_STD|SU_DEV), REQ_GET_DESCRIPTOR, CONF_DESC, 0, desc_conf->wTotalLength);
        dev->setup.pData = buffer;
        dev->dev_state = dev_enumerated;
        return 1;

    case dev_enumerated:
        if (dev->ep[0]->resp != PID_ACK) break;
        printf("GET CONF FULL ok\n");
        prn_all(dev);
        set_driver(dev, buffer);
        (*dev->driver)(dev, buffer);
        return 1;
    }
    printf("Enumeration step failed (%x)\n", dev->ep[0]->resp);
    dev->dev_state = dev_stall;
    return 0;
}

int drv_unkown(DEV *dev, uint8_t *data)
{
    //printf("Unkown device, port stalled\n");
    return 1;
}

void set_driver(DEV *dev, uint8_t *data)
{
    struct UsbConfigurationDescriptor *desc = (struct UsbConfigurationDescriptor *)data;
    uint8_t *end = data + desc->wTotalLength;
    struct UsbDescriptorHeader *hdr = (struct UsbDescriptorHeader *)data;
    struct UsbInterfaceDescriptor *iface;
    
    while (data < end && hdr->bDescriptorType != 4) {
        data += hdr->bLength;
        hdr = (struct UsbDescriptorHeader *)data;
    }
    iface = (struct UsbInterfaceDescriptor *)data;
    switch (iface->bInterfaceClass) {
    case 3:  dev->driver = drv_hid;     break;
    case 9:  dev->driver = drv_hub;     break;
    default: dev->driver = drv_unkown;
    }
    dev->dev_state = 0;
}


