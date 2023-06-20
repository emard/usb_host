
// Manage the root port using the SIE registers.
//

#include "root.h"

static uint32_t *usbh;
int sim;
uint32_t *uart;

void ctl_init(uint32_t base)
{
    usbh = (uint32_t *)base;
}

void line_reset(void)
{
    // UTMI+ reset is: opmode = 2, termselect = 0, xcvrselect = 0
    // and DP+DM pulldown = 1.
    //
    usbh[REG_CTRL] = CTL_OPMODE2|CTL_XCVRSEL0|CTL_DP_PULLD|CTL_DN_PULLD;
}

void line_enable(int speed, int enable_sof)
{
    uint32_t val;

    val  = (speed == 1) ? CTL_XCVRSEL1 : (speed == 3) ? CTL_XCVRSEL3 : CTL_XCVRSEL2;
    val |= CTL_OPMODE0|CTL_TERMSEL|CTL_DP_PULLD|CTL_DN_PULLD|CTL_TX_FLSH;
    if (enable_sof) val |= CTL_SOF_EN;

    usbh[REG_CTRL] = val;
}

EP  endpoints[20];
DEV connections[5];

int out_txn(EP *ep, int want_hs)
{
    uint32_t i, token, len;
    uint8_t *tx = ep->buf;

    // prepare transfer: set packet size, load fifo
    len = ep->size = (ep->len > ep->maxsz) ? ep->maxsz : ep->len;
    for (i=0; i < len; i++) {
        usbh[REG_DATA] = *tx++;
    }
    usbh[REG_TXLEN] = len;

    // set up SIE and schedule new transfer
    token = (ep->pid << 16) | ((ep->dev->dev_addr & 0x3ff) << 9) | ((ep->idx & 0xf) << 5);
    if (want_hs)    token |= TKN_HS;
    if (ep->toggle) token |= TKN_DATA1;
    usbh[REG_TOKEN] = (token | TKN_START);

    // wait for request acceptance (start bit auto-resets)
    while (usbh[REG_TOKEN] & TKN_START) ;

    // no handshake expected -> done
    if (!want_hs) return USB_RES_OK;

    // wait for transaction to finish (i.e. SIE returns to idle)
    while (!(usbh[REG_RXSTS] & SIE_IDLE)) ;

    // did handshake time out? -> error
    if (usbh[REG_RXSTS] & RX_TIMEOUT) {
        ep->resp = USB_RES_TIMEOUT;
        return USB_RES_ERR;
    }

    ep->resp = (usbh[REG_RXSTS] >> 16) & 0xff;
    return (ep->resp == PID_ACK) ? USB_RES_OK : USB_RES_ERR;
}

int in_txn(EP *ep, int want_hs)
{
    uint32_t i, token, len;
    uint8_t *rx = ep->buf;
    
    // No tx data
	usbh[REG_TXLEN] = 0;

    // set up SIE and request transfer
    token = (PID_IN << 16) | ((ep->dev->dev_addr & 0x3ff) << 9) | ((ep->idx & 0xf) << 5);
    if (want_hs)    token |= TKN_HS;
    if (ep->toggle) token |= TKN_DATA1;
    usbh[REG_TOKEN] = token | TKN_START | TKN_IN;

    // wait for request acceptance and for txn finish
    while (  usbh[REG_TOKEN] & TKN_START) ;
    while (!(usbh[REG_RXSTS] & SIE_IDLE)) ;

    // did response time out? -> report
    if (usbh[REG_RXSTS] & RX_TIMEOUT) {
       ep->resp = USB_RES_TIMEOUT;
       return USB_RES_ERR;
    }

    // check response type, and error on anything not PID_DATAx
    ep->resp = (usbh[REG_RXSTS] >> 16) & 0xff;
    if ((ep->resp & 0x3) != 0x3)
        return USB_RES_ERR;

    // bad CRC or bad toggle? -> treat as if nothing received at all
    if ((usbh[REG_RXSTS] & RX_CRCERR) || ((ep->resp == PID_DATA0) ^ (ep->toggle == 0))) {
       ep->resp = USB_RES_TIMEOUT;
       return USB_RES_ERR;
    }

    // fetch IN buf, check for buffer overflow
    ep->size = usbh[REG_RXSTS] & 0xffff;
    if (ep->size > ep->len)
        return USB_RES_ERR;
    for (i=0; i < ep->size; i++) {
        *rx++ = usbh[REG_DATA];
    }
    return USB_RES_OK;
}

int do_txn(EP *ep, int want_hs)
{
    uint32_t flags = ep->dev->prt_flags;
    int      speed;
    
    if (flags & ROOT_PORT)
        speed = (flags & PRT_LS) ? 2 : 1;
    else
        speed = (flags & PRT_LS) ? 3 : 1;
    line_enable(speed, usbh[REG_CTRL] & 0x1);

    if (ep->pid == PID_IN)
        return in_txn(ep, want_hs);
    else
        return out_txn(ep, want_hs);
}

int ep_next_state(EP *ep)
{
    int      dir = ep->dev->setup.bmReqTyp & SU_IN;
    uint16_t len = ep->dev->setup.wLength;

    switch (ep->state) {
    
    case ep_setup:
        ep->len = len;
        if (len) {
            ep->buf = ep->dev->setup.pData;
            ep->pid = dir ? PID_IN : PID_OUT;
            return ep_su_data;
        }
        /* fall through */

    case ep_su_data:
        ep->len    = 0;
        ep->pid    = dir ? PID_OUT : PID_IN;
        ep->toggle = 1;
        return ep_su_sts;
        
    default:
        return ep_idle;
    }
}

void process_ep(EP *ep)
{
    DEV *dev = ep->dev;

    //uart[2] = ep->state;
    if (ep->when > timer_now() || ep->retry == 0 || ep->state == ep_idle)
        return;

    switch(ep->state) {

    case ep_idle:
        return;

    case ep_in:    case ep_out:
    case ep_setup: case ep_su_data: case ep_su_sts:

        // fetch data in max packet size chunks, with handshake
        while (do_txn(ep, 1) == USB_RES_OK) {
            ep->retry = 5;
            ep->len -= (ep->len >= ep->size) ? ep->size : ep->len;
            ep->buf += ep->size;
            ep->toggle = 1 - ep->toggle;
            if (ep->len == 0)
                ep->state = ep_next_state(ep);
            return;
        }

        // immediate stop after a STALL is received
        if (ep->resp == PID_STALL) {
            ep->state = ep_idle;
        }

        // otherwise, give up after retries exhausted
        if (--ep->retry == 0) {
            ep->state = ep_idle;
            ep->resp = USB_RES_ERR;
            return;
        }
        
        // bad PID_DATAx sequence? -> try again
        if (ep->resp == PID_DATA0 || ep->resp == PID_DATA1)
            return;

        // NAK and TIMEOUT: try again in 2ms
        if (ep->resp == PID_NAK || ep->resp == USB_RES_TIMEOUT) {
            if (ep->resp == PID_NAK)         dev->nak++;
            if (ep->resp == USB_RES_TIMEOUT) dev->tout++;
            ep->when = timer_now() + 2;
        } else
            ep->state = ep_idle;
        return;

    default:
        printf("s=%x\n", ep->state);
    }    
}

void do_setup(DEV *dev, uint8_t typ, uint8_t req, uint16_t val, uint16_t idx, uint16_t len)
{
    EP *ep0 = dev->ep[0];

    dev->setup.bmReqTyp = typ;
    dev->setup.bReq     = req;
    dev->setup.wValue   = val;
    dev->setup.wIndex   = idx;
    dev->setup.wLength  = len;
    
    ep0->len    = 8;
    ep0->buf    = (uint8_t *)(&dev->setup);
    ep0->toggle = 0;
    ep0->retry  = 5;
    ep0->state  = ep_setup;
    ep0->pid    = PID_SETUP;
}

void do_data(DEV *dev, uint8_t ep, uint8_t dir, uint8_t *data, uint16_t len)
{
    EP *epp = dev->ep[ep];
    
    epp->len    = len;
    epp->buf    = data;
    epp->retry  = 1;
    epp->state  = (dir==IN) ? ep_in  : ep_out;
    epp->pid    = (dir==IN) ? PID_IN : PID_OUT;
}

static void yield(EP *ep)
{
    while (ep->state != ep_idle)
        process_ep(ep);
}

DEV *clr_port(int idx)
{
    DEV *dev = &connections[idx];
    EP  *ep  = &endpoints[idx];

    memset(dev, 0, sizeof(DEV));
    memset(ep,  0, sizeof(EP));
    dev->ep[0] = ep;
    dev->ep[0]->dev = dev;
    dev->ep[0]->maxsz = 8;
    dev->prt_idx = idx;
    return dev;
}

void process_dev(DEV *dev)
{
    uart[2] = dev->prt_flags;

    // still connected?
    if ((usbh[REG_STAT] & STAT_DETECT) == 0) {
        dev = clr_port(0);
        dev->prt_flags = ROOT_PORT|PRT_POWER;
    }

    // if enabled call driver; reset as needed
    if (dev->prt_flags & PRT_ENABLED) {
        if (dev->driver(dev, NULL) == 0) {
            dev->prt_flags &= ~(PRT_ENABLED|PRT_RESET);
            dev->prt_flags |= PRT_STALL;
        }
        return;
    }
    
    if (dev->prt_flags & PRT_STALL) return;
    
    // wait for connection, block
    if ((dev->prt_flags & (PRT_POWER|PRT_CONNECT)) == PRT_POWER) {
        while ((usbh[REG_STAT] & STAT_DETECT) == 0) ;
        dev->prt_flags |= (usbh[REG_STAT] & 1) ? PRT_FS : PRT_LS;
        dev->prt_flags |= PRT_CONNECT;
        printf("dev connect speed = %x\n", (dev->prt_flags & PRT_FS) ? 1 : 2);
        timer_sleep(20);
    }
    
    // reset port / device
    if ((dev->prt_flags & (PRT_CONNECT|PRT_RESET)) == PRT_CONNECT) {
        line_reset();
        timer_sleep(50);
        line_enable((dev->prt_flags & PRT_FS) ? 1 : 2, (sim ? 0 : 1));
        dev->prt_flags |= PRT_RESET;
    }

    // enable port / device
    if ((dev->prt_flags & (PRT_RESET|PRT_ENABLED)) == PRT_RESET) {
        timer_sleep(100);
        dev->driver = &enum_dev;
        dev->prt_flags |= PRT_ENABLED;
        dev->dev_state = 0; // = enum:set_address
    }
}

void main()
{
    DEV *root, *dev;
    int i, j;

    sim = is_sim();

    printf("start\n");
    ctl_init(0x21000000);
    
    root = clr_port(0);
    root->prt_flags = ROOT_PORT|PRT_POWER;

    // Naive scheduler
    //
    while(1) {
        for(i=0; i<5; i++) {
            dev = &connections[i];
            if (dev->prt_flags & ROOT_PORT)
                process_dev(dev);
            else if (dev->prt_flags & HUB_PORT)
                process_hub(dev);
            else break;
                
            for(j=0; j<6; j++) {
                if (dev->ep[j]) yield(dev->ep[j]);
            }
        }
    }
}
