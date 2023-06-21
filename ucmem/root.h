

// USBH register numbers
#define REG_CTRL        0x00
#define REG_STAT        0x01
#define REG_IRQ_A       0x02
#define REG_IRQ_S       0x03
#define REG_IRQ_E       0x04
#define REG_TXLEN       0x05
#define REG_TOKEN       0x06
#define REG_RXSTS       0x07
#define REG_DATA        0x08

// CTRL register bits
#define CTL_SOF_EN      0x0001
#define CTL_OPMODE0     0x0000
#define CTL_OPMODE1     0x0002
#define CTL_OPMODE2     0x0004
#define CTL_OPMODE3     0x0006
#define CTL_XCVRSEL0    0x0000
#define CTL_XCVRSEL1    0x0008
#define CTL_XCVRSEL2    0x0010
#define CTL_XCVRSEL3    0x0018
#define CTL_TERMSEL     0x0020
#define CTL_DP_PULLD    0x0040    
#define CTL_DN_PULLD    0x0080
#define CTL_TX_FLSH     0x0100

// STAT register bits
#define STAT_DP         0x0001
#define STAT_DN         0x0002
#define STAT_PHYERR     0x0004
#define STAT_DETECT     0x0008

// IRQ registers bits
#define IRQ_DETECT      0x0008
#define IRQ_ERR         0x0004
#define IRQ_DONE        0x0002
#define TKN_SOF         0x0001

// TOKEN register bits
#define TKN_START   0x80000000
#define TKN_IN      0x40000000
#define TKN_HS      0x20000000
#define TKN_DATA1   0x10000000

// RXSTS register bits
#define RX_QUEUED   0x80000000
#define RX_CRCERR   0x40000000
#define RX_TIMEOUT  0x20000000
#define SIE_IDLE    0x10000000

// Response values
#define USB_RES_OK           0x00
#define USB_RES_NAK          0x10
#define USB_RES_STALL        0x20
#define USB_RES_TIMEOUT      0x30
#define USB_RES_ERR          0x40

// PID values
#define PID_OUT           0xe1
#define PID_IN            0x69
#define PID_SOF           0xa5
#define PID_SETUP         0x2d
#define PID_DATA0         0xc3
#define PID_DATA1         0x4b
#define PID_ACK           0xd2
#define PID_NAK           0x5a
#define PID_STALL         0x1e

typedef unsigned int   uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char  uint8_t;
typedef char           int8_t;
typedef uint32_t       time_t;

#define NULL           ((void*)0)

struct usb_setup {
	uint8_t   bmReqTyp;
	uint8_t   bReq;
	uint16_t  wValue;
	uint16_t  wIndex;
	uint16_t  wLength;
  uint8_t  *pData;
};
typedef struct usb_setup SU;

// SETUP type values
#define SU_OUT          0x00
#define SU_IN           0x80
#define SU_STD          0x00
#define SU_CLS          0x20
#define SU_VDOR         0x40
#define SU_DEV          0x00
#define SU_IFACE        0x01
#define SU_EP           0x02
#define SU_OTHER        0x03

#define IN  1
#define OUT 2

struct ep {
    struct dev  *dev;
    int          idx;
    time_t       when;
    int          state;
    
    uint8_t     *buf;
    uint16_t     len;
    uint16_t     size;
    uint16_t     maxsz;

    uint8_t      pid;
    uint8_t      toggle;
    uint8_t      resp;
    int8_t       retry;
};
typedef struct ep EP;

typedef struct dev DEV;
enum ep_state {
  ep_idle,
  ep_setup, ep_su_data, ep_su_sts,
  ep_in, ep_out
};

typedef int (driver_t)(DEV *, uint8_t *);

struct dev {
    uint32_t     prt_flags;
    uint8_t      prt_idx;
    uint8_t      dummy;

    uint8_t      dev_addr;
    uint8_t      dev_state;
    time_t       when;
    uint16_t     nak;
    uint16_t     tout;
    
    driver_t    *driver;
    SU           setup;
    EP          *ep[6];
};

// flags
#define PORT_IDLE      0x000000000
#define ROOT_PORT      0x000000001
#define HUB_PORT       0x000000002
#define PRT_POWER      0x000000004
#define PRT_CONNECT    0x000000008
#define PRT_RESET      0x000000010
#define PRT_ENABLED    0x000000020
#define PRT_STALL      0x000000040
#define PRT_LS         0x000000080
#define PRT_FS         0x000000100

void timer_sleep(time_t);
time_t timer_now(void);
void printf(char *fmt, ...);
int is_sim(void);
void memset(void *dest, uint8_t val, uint32_t len);
void prn_all(DEV *dev);
void do_setup(DEV *dev, uint8_t typ, uint8_t req, uint16_t val, uint16_t idx, uint16_t len);
void do_data(DEV *dev, uint8_t ep, uint8_t dir, uint8_t *data, uint16_t len);
int enum_dev(DEV *dev, uint8_t *data);
int drv_hub(DEV *dev, uint8_t *data);
int drv_hid(DEV *dev, uint8_t *data);
void process_hub(DEV *dev);
DEV *clr_port(int idx);

#define REQ_GET_STATUS        0x00
#define REQ_SET_ADDRESS       0x05
#define REQ_GET_DESCRIPTOR    0x06
#define REQ_GET_CONFIGURATION 0x08
#define REQ_SET_CONFIGURATION 0x09

#define DEV_DESC              (1<<8)
#define CONF_DESC             (2<<8)

#pragma pack on

struct UsbDeviceDescriptor
{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint16_t bcdUSB;
  uint8_t  bDeviceClass;
  uint8_t  bDeviceSubClass;
  uint8_t  bDeviceProtocol;
  uint8_t  bMaxPacketSize0;
  uint16_t idVendor;
  uint16_t idProduct;
  uint16_t bcdDevice;
  uint8_t  iManufacturer;
  uint8_t  iProduct;
  uint8_t  iSerialNumber;
  uint8_t  bNumConfigurations;
};

struct UsbConfigurationDescriptor
{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint16_t wTotalLength;
  uint8_t  bNumInterfaces;
  uint8_t  bConfigurationValue;
  uint8_t  iConfiguration;
  uint8_t  bmAttributes;
  uint8_t  bMaxPower;
};

struct UsbInterfaceDescriptor
{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bInterfaceNumber;
  uint8_t  bAlternateSetting;
  uint8_t  bNumEndpoints;
  uint8_t  bInterfaceClass;
  uint8_t  bInterfaceSubClass;
  uint8_t  bInterfaceProtocol;
  uint8_t  iInterface;
};

struct UsbEndpointDescriptor
{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bEndpointAddress;
  uint8_t  bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t  bInterval;
};

struct UsbDescriptorHeader
{
  uint8_t bLength;
  uint8_t bDescriptorType;
};

#pragma pack off

