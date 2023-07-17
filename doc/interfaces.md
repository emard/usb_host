### Layer 6: Device discovery - Part 2, Interfaces

This is a very brief summary of interfaces. Interfaces are described in Chapters 9 and 10 and section 11.15 of the main specification and in the various class specifications (HID, CDC, etc.).

#### Introduction

Arguably, a **USB interface is best understood as an API** for a specific device function. In some cases there just a single API and hence a single interface. Hubs are an example of this.

A device may support multiple interfaces and all these interfaces are active at the same time. As an example, a keyboard with a builtin trackpad could report as having two interfaces, one for the keyboard and one for the trackpad. From the Host, this can be interpreted as the device supporting both the standard keyboard API and the standard mouse API.

The configuration header reports how many interfaces the device has and these are sequentially numbered in the range 0 to n-1.

#### Interface and device classification

From the above it is clear that there is close relationship between classification and interfaces. Each interface defines a classification for the device.

In a simple case a device may have a single interface with a classification that is the same as the overall device classification. Hubs are an example of this with the classification (9,0,0) for each. See Spec section 11.15.1 for details.

A more complex case occurs for a standard ("Hayes") modem. In this example the device has an overall classification of (2,0,0) placing the device in the [communication device class](https://cscott.net/usb_dev/data/devclass/usbcdc11.pdf) ("CDC"). It also presents two interfaces, the first with a classification of (2,2,1) which specifies a control channel supporting the AT command set, and the second with a classification of (10,0,0), which specifies a CDC data channel.

As seen from the Host, this configuration be understood as this device being a modem device supporting the "AT commands" API and the "data channel" API.

#### Interface descriptor structure

A full interface descriptor consists of an interface descriptor header, followed by zero or more class descriptors, followed by zero or more endpoint descriptors (in that order, i.e. endpoint descriptors come after class descriptors).

The interface descriptor header (Spec section 9.6.3) looks like this:

```C
struct
{
  uint8_t  bLength;              // 9 bytes
  uint8_t  bDescriptorType;      // 0x04
  uint8_t  bInterfaceNumber;
  uint8_t  bAlternateSetting;    // see "Alternates" below
  uint8_t  bNumEndpoints;
  uint8_t  bInterfaceClass;
  uint8_t  bInterfaceSubClass;
  uint8_t  bInterfaceProtocol;
  uint8_t  iInterface;
};
```

The structure gives the classification for the interface / API, and the number of endpoints included in this interface.

The class descriptors always have a descriptor type between 0x21 and 0x2f and come - if any - immediately after the interface header. In many cases (but not always), such class descriptors will have the following initial structure:

```C
struct
{
  uint8_t  bLength;
  uint8_t  bDescriptorType;      // between 0x21 and 0x2f
  uint8_t  bDescriptorSubtype;   // defined in class specification document
  ...
};
```

The endpoint descriptors - again, if any - have the following structure (section 9.6.4):

```C
struct
{
  uint8_t  bLength;              // 7 bytes
  uint8_t  bDescriptorType;      // 0x05
  uint8_t  bEndpointAddress;     // endpoint number or'ed with IN/OUT flag (0x80)
  uint8_t  bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t  bInterval;
};
```
There is never an endpoint descriptor for endpoint 0, only for other endpoints. This is both because its properties are well-known, but also because there is only one, shared endpoint 0 (i.e. control endpoint) for all interfaces.

For a bi-directional endpoint, there will be two entries: one output endpoint and one input endpoint, each with the same endpoint number, attributes, etc.

In general, a host driver will already know how many endpoints there are and what the attributes of each are, as this is set by the standards document for the class at hand. The assigned endpoint numbers and FIFO sizes must be read from the descriptors though.

#### Interface alternates

A device may offer several different alternatives for the same interface / API. The host can then select one of these. The default setting for an interface is always alternate setting zero. An alternate setting can only be selected by the Host after it has selected the active configuration.

One use for alternate interfaces is for isochronous endpoints, which must be specified in an alternate and not in a default interface (this requirement is part of the USB 2 spec). Such an endpoint is guaranteed the bandwith it has asked for in its descriptor when the device is active. If the bus does not currently have the necessary bandwith avaibable, the host would not be able to activate the device at all if such an endpoint was part of a default interface. 

A key aspect here is that all interfaces in a configuration are active at the same time, but when some interface has alternates then only one, host selected alternate is active.

#### A minimal device enumeration algorithm

Below is C pseudo-code to read the configuration descriptor from a device and itterate through the interfaces. This minimal code omits all error handling.

```C
CNF_DESC cnfhdr;
IFC_DESC *iface;
char *buffer, *end
int cnf_sz, i, j;

// fetch full configuration descriptor
//
call(device, GET_DESC, CNF_ID, 0, sizeof(CNF_DESC), &cnfhdr);
rpcwait();
cnf_sz = cnfhdr.wTotalSize;
buffer = malloc(cnfhdr.wTotalSize);
end    = buffer + cnfhdr.wTotalSize;
call(device, GET_DESC, CNF_ID, 0, cnf_sz, buffer);
rpcwait();

// itterate through interfaces, ignore alternates
//
for (int offset=0; offset < end; ) {
    // locate next interface descriptor, seeking from offset, update offset
    iface = get_iface(buffer, &offset);
    if (!iface || iface->bAlternateSetting != 0) continue;

    switch(iface->bInterfaceClass) {
    case 0x01: /* handle audio interface */
               break;
    ...
    case 0x03: /* handle HID interface */
               break;
    ...
    default: report("unsupported class");
    }
}
```

For a real, but still very basic implementation, refer to the code in `enum.c`.

