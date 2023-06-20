#include "root.h"

void prn_dev_desc(uint8_t *data)
{
    struct UsbDeviceDescriptor *desc = (struct UsbDeviceDescriptor *)data;
    
    printf("Device VID=%x PID=%x:\n",   desc->idVendor, desc->idProduct);
    printf("  bcdUSB=%x\n",             desc->bcdUSB);
    printf("  bDeviceClass=%x\n",       desc->bDeviceClass);
    printf("  bDeviceSubClass=%x\n",    desc->bDeviceSubClass);
    printf("  bDeviceProtocol=%x\n",    desc->bDeviceProtocol);
    printf("  bMaxPacketSize0=%d\n",    desc->bMaxPacketSize0);
    printf("  bcdDevice=%x\n",          desc->bcdDevice);
    printf("  bNumConfigurations=%x\n", desc->bNumConfigurations);
}

void prn_cf_desc(uint8_t *data)
{
    struct UsbConfigurationDescriptor *desc = (struct UsbConfigurationDescriptor *)data;
    
    printf("CONFIGURATION:\n");
    //printf("  bLength=%x\n",             desc->bLength);
    //printf("  bDescriptorType=%x\n",     desc->bDescriptorType);
    printf("  wTotalLength=%x\n",        desc->wTotalLength);
    printf("  bNumInterfaces=%x\n",      desc->bNumInterfaces);
    printf("  bConfigurationValue=%x\n", desc->bConfigurationValue);
    //printf("  iConfiguration=%x\n",      desc->iConfiguration);
    printf("  bmAttributes=%x\n",        desc->bmAttributes);
    printf("  bMaxPower=%x\n",           desc->bMaxPower);
}

void prn_if_desc(uint8_t *data)
{
    struct UsbInterfaceDescriptor *desc = (struct UsbInterfaceDescriptor *)data;
    printf("INTERFACE:\n");
    //printf("  bLength=%x\n",             desc->bLength);
    //printf("  bDescriptorType=%x\n",     desc->bDescriptorType);
    printf("  bInterfaceNumber=%x\n",    desc->bInterfaceNumber);
    printf("  bAlternateSetting=%x\n",   desc->bAlternateSetting);
    printf("  bNumEndpoints=%x\n",       desc->bNumEndpoints);
    printf("  bInterfaceClass=%x\n",     desc->bInterfaceClass);
    printf("  bInterfaceSubClass=%x\n",  desc->bInterfaceSubClass);
    printf("  bInterfaceProtocol=%x\n",  desc->bInterfaceProtocol);
    //printf("  iInterface=%x\n",          desc->iInterface);
}

void prn_ep_desc(uint8_t *data)
{
    struct UsbEndpointDescriptor *desc = (struct UsbEndpointDescriptor *)data;

    printf("ENDPOINT:\n");
    //printf("  bLength=%x\n",             desc->bLength);
    //printf("  bDescriptorType=%x\n",     desc->bDescriptorType);
    printf("  bEndpointAddress=%x\n",    desc->bEndpointAddress);
    printf("  bmAttributes=%x\n",        desc->bmAttributes);
    printf("  wMaxPacketSize=%x\n",      desc->wMaxPacketSize);
    printf("  bInterval=%x\n",           desc->bInterval);
}

void prn_unknown_desc(uint8_t *data)
{
    struct UsbDescriptorHeader *desc = (struct UsbDescriptorHeader *)data;
    printf("UNKOWN DESCRIPTOR:\n");
    printf("  bLength=%x\n",             desc->bLength);
    printf("  bDescriptorType=%x\n",     desc->bDescriptorType);
}

void prn_cf_full(uint8_t *data)
{
    struct UsbConfigurationDescriptor *desc = (struct UsbConfigurationDescriptor *)data;
    struct UsbDescriptorHeader *hdr = (struct UsbDescriptorHeader *)data;
    uint8_t *end = data + desc->wTotalLength;
    
    do {
        switch (hdr->bDescriptorType) {
        
        case 2:  prn_cf_desc(data);     break;
        case 4:  prn_if_desc(data);     break;
        case 5:  prn_ep_desc(data);     break;
        default: prn_unknown_desc(data);
        }
        data += hdr->bLength;
        hdr = (struct UsbDescriptorHeader *)data;
    } while (data < end);
}
