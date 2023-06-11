#ifndef __USB_HW_H__
#define __USB_HW_H__

//#include <stdint.h>

typedef unsigned int   uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char  uint8_t;
typedef uint32_t       time_t;

//#define printf(...)
void printf(char *fmt, ...);
#define assert(...)
void timer_sleep(time_t);
time_t timer_now(void);
int is_sim(void);

//-----------------------------------------------------------------
// Prototypes:
//-----------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif

void usbhw_init(uint32_t base);
void usbhw_reset(void);
void usbhw_hub_reset(void);
int  usbhw_hub_device_detected(void);
int  usbhw_hub_full_speed_device(void);
void usbhw_hub_enable(int full_speed, int enable_sof);
int  usbhw_transfer_out(uint8_t pid, int device_addr, int endpoint, int handshake, uint8_t request, uint8_t *tx, int tx_length);
int  usbhw_transfer_in(uint8_t pid, int device_addr, int endpoint, uint8_t *response, uint8_t *rx, int rx_length);
void usbhw_timer_sleep(int ms);

typedef unsigned long t_time;
t_time        usbhw_timer_now(void);
static long   usbhw_timer_diff(t_time a, t_time b) { return (long)(a - b); }

#ifdef __cplusplus
}
#endif

#endif // __USB_HW_H__
