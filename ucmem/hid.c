// Handle HID functions
//
//

#include "root.h"

extern int sim;
extern EP  endpoints[];

#define IF_DESC      0x04
#define KBD          0x01
#define MSE          0x02

// Assume that the first Interface descriptor will contain a boot protocol
// mouse or keyboard device.
//
int find_protocol(uint8_t *data)
{
    struct UsbConfigurationDescriptor *desc = (struct UsbConfigurationDescriptor *)data;
    uint8_t *end = data + desc->wTotalLength;
    struct UsbDescriptorHeader *hdr = (struct UsbDescriptorHeader *)data;
    struct UsbInterfaceDescriptor *iface;
    
    while (data < end && hdr->bDescriptorType != IF_DESC) {
        data += hdr->bLength;
        hdr = (struct UsbDescriptorHeader *)data;
    }
    iface = (struct UsbInterfaceDescriptor *)data;
    if ((data == end) || (iface->bInterfaceSubClass != 1))
        return 0;
    return iface->bInterfaceProtocol;
}

enum hid_state {
    get_hid_desc, hid_mouse1, hid_mouse2, hid_keybd1, hid_keybd2, hid_idle, dev_stall = 255
};

uint8_t msepkt[4];
uint8_t kbdpkt[8];

// Driver for HID keyboard and mouse
//
int drv_hid(DEV *dev, uint8_t *data)
{
    int i, proto;
    EP  *ep;

    if (dev->ep[1] && (dev->ep[1]->state != ep_idle)) return; // note: EP 1 !
    if (sim) dev->when = timer_now();
    if (dev->when > timer_now()) return;
    
    switch (dev->dev_state) {
    
    // Read configuration data, first interface must be
    // a boot keyboard or boot mouse.
    //
    case get_hid_desc:
        printf("HID connected\n");
        proto = find_protocol(data);
        dev->ep[1] = ep = &endpoints[(proto == MSE) ? 5 : 6];
        ep->dev = dev;
        ep->maxsz = 8;
        ep->idx = 1;
        ep->toggle = 0;
        switch (proto) {
        case KBD:   printf("std keyboard detected\n");
                    dev->dev_state = hid_keybd1;
                    break;

        case MSE:   printf("std mouse detected\n");
                    dev->dev_state = hid_mouse1;
                    break;

        default:    printf("HID device not recognised\n");
        }
        return 1;
    
    case hid_mouse1:
        do_data(dev, 1, IN, msepkt, 4);
        dev->dev_state = hid_mouse2;
        return 1;
        
    case hid_mouse2:
        if (dev->ep[1]->resp == PID_STALL) {
            printf("stalled\n");
            dev->dev_state = hid_idle;
            return 1;
        }
        dev->dev_state = hid_mouse1;
        dev->when = timer_now() + 10;
        if (dev->ep[1]->resp != USB_RES_ERR) {
            printf("MOUSE: ");
            for(i=0; i<4; i++) printf("%x ", msepkt[i]);
            printf("\n");
        }
        return 1;
    
    case hid_keybd1:
        do_data(dev, 1, IN, kbdpkt, 8);
        dev->dev_state = hid_keybd2;
        return 1;
        
    case hid_keybd2:
        if (dev->ep[1]->resp == PID_STALL) {
            printf("stalled\n");
            dev->dev_state = hid_idle;
            return 1;
        }
        dev->dev_state = hid_keybd1;
        dev->when = timer_now() + 10;
        if (dev->ep[1]->resp != USB_RES_ERR) {
            printf("KEYBD: ");
            for(i=0; i<8; i++) printf("%x ", kbdpkt[i]);
            printf("\n");
        }
        return 1;

    case hid_idle:
        dev->when = timer_now() + 255;
        return 1;

    }
    printf("HID driver step failed (%x, %x)\n", dev->dev_state, dev->ep[0]->resp);
    dev->dev_state = dev_stall;
    return 0;
}


