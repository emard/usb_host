

#include "usb_hw.h"
#include "usb_defs.h"
#include "usb_core.h"

int *usb  = (int *)0x21000000;

uint8_t data[] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9
};

uint8_t datai[] = {
    8, 7, 6, 5, 4, 3, 2, 1
};

int enum_IF(struct usb_device *dev, struct usb_interface *intp) {return 1;}

int enum_class(struct usb_device *dev, struct usb_interface *intp, void *desc) {return 1;}
           
struct usb_device dev, dev2;

void main()
{
    uint32_t stat, i, res, cnt;
    uint8_t  hs, sts;

    printf("Mode = %s\n", is_sim() ? "SIM" : "FPGA");

    /*
    usbhw_init((uint32_t)usb);
    usbhw_reset();
    //usbhw_transfer_out(PID_SETUP, 23, 0, 1, PID_DATA0, data, sizeof(data));
    usbhw_transfer_in(PID_IN, 23, 0, &hs, datai, sizeof(datai));
    for(i=0; i<8; i++) printf("%x ", usb[8]);
    //*/
    
    //*
    usbhw_init((uint32_t)usb);
    //usbhw_reset();
    usb_init();
    //usb_reset_device(&dev);
again:
    // Wait for insertion
    while (1) {
        while(!usbhw_hub_device_detected());
        if (!is_sim())
            usbhw_timer_sleep(20);
        if(usbhw_hub_device_detected())
            break;
    }
    
    if (!is_sim())
        usbhw_timer_sleep(500);

    usbhw_reset();

    cnt = 4;
    do {
       res = usb_configure_device(&dev, 3);
       cnt++;
    }
    while (res==0 && cnt<5);
    if (res==0 && cnt==5) goto err;
    
    cnt = 4;
    do {
       res = usb_enumerate(&dev, enum_IF, enum_class);
       cnt++;
    }
    while (res==0 && cnt<5);
    if (res==0 && cnt==5) goto err;

    //*
    if(dev.interfaces[0].if_class == 9) {
    int port = 1;
    
        usb_send_control_write(&dev, 0x23, 0x03, 0x0008, port, 0, data); // power
        usbhw_timer_sleep(200);
        //usb_send_control_write(&dev, 0x23, 0x03, 0x0001, 0x0001, 0, data); // enable
        //usbhw_timer_sleep(100);
        usb_send_control_read (&dev, 0xa3, 0x00, 0x0000, port, 4, data, 4); // get port status
        if(data[1]&1) printf("Powered, ");
        if(data[0]&2) printf("Enabled, ");
        if(data[0]&1) printf("Connected, ");
        if(data[1]&2) printf("Low speed, ");
        if(data[2]&16) printf("Reset completed\n");
        printf("\n");
        for(i=0; i<4; i++)
            printf("byte[%x]=%x\n", i, data[i]);

hub_again:
        usb_send_control_write(&dev, 0x23, 0x03, 0x0004, port, 0, data); // reset
        usbhw_timer_sleep(200);
        
        usb_send_control_read (&dev, 0xa3, 0x00, 0x0000, port, 4, data, 4); // get port status
        if(data[1]&1) printf("Powered, ");
        if(data[0]&2) printf("Enabled, ");
        if(data[0]&1) printf("Connected, ");
        if(data[1]&2) printf("Low speed, ");
        if(data[2]&16) printf("Reset completed\n");
        printf("\n");
        for(i=0; i<4; i++)
            printf("byte[%x]=%x\n", i, data[i]);

        if((data[2]&16)==0) goto err;

        if(data[1]&2) {
            usbhw_hub_enable(3, 1);
            usbhw_timer_sleep(50);
        }

        cnt = 0;
        do {
           usbhw_timer_sleep(50);
           res = usb_configure_device(&dev2, 4);
           cnt++;
        }
        while(res==0 && cnt<1);
        //if(res==0) goto err;

        cnt = 0;
        do {
           usbhw_timer_sleep(50);
           res = usb_enumerate(&dev2, enum_IF, enum_class);
           cnt++;
        }
        while(res==0 && cnt<1);
        //if(res==0) goto err;
    }

    /*
    usbhw_transfer_in(PID_IN, 3, 1, &hs, &sts, 1);
    printf("hs=%x, data=\n", hs, sts);
    usbhw_transfer_in(PID_IN, 3, 1, &hs, &sts, 1);
    printf("hs=%x, data=\n", hs, sts);
    */
    
    //*/
    printf("USB host\n");

    // Wait for ejection
    while (1) {
        while(usbhw_hub_device_detected());
        if(usbhw_hub_device_detected()) continue;
        if(usbhw_hub_device_detected()) continue;
        if(usbhw_hub_device_detected()) continue;
        goto again;
    }
    return;
    
err:
    printf("USB error\n");
    goto again;
}

