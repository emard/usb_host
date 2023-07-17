### Layer 6: Device discovery - Part 1, Overview

This is a very brief summary of of the second half of Chapter 9, "Device Framework" of the USB 1.1 / USB 2.0 specification. For more detail please refer to that chapter.

Managing the configuration of the bus has two different, but related aspects:

* Each device on the bus needs to be initialised, notably it needs to receive a unique bus address. This is **device configuration**.

* The host must build and maintain an overview of all devices on the bus, know their type and function and assign a software driver to each one. This is **device enumeration**.

This is a dynamic process, as the user can connect and disconnet devices at any time and without notice to the host software.

Although conceptually different, the above two aspects are typically intermingled in a practical implementation.

<a name="dev"></a>
#### Device reset and configuration

A connected USB device can be in one of 3 states:

* Default. A device enters this state after a reset. In this state it will respond to requests addressed to device number zero. Valid commands are reading the device descriptor and setting a specific address.

* Addressed. In this state the device responds to a wider set of commands and this state allows for device discovery and setting device parameters. The most important one is setting the active configuration.

* Configured. In this state the device is active and performing its design function.

In view of the above, the minimum to configure a device is (i) to issue a reset, (ii) to set the device address and (iii) to set the active device configuration to "1".

##### Reset

The definition of reset is 10 ms of SE0 signalling, but 7.1.7.3 says: "[The host] must ensure that resets issued to the root ports drive reset long enough to overwhelm any concurrent resume attempts by downstream devices. Resets from root ports should be nominally 50 ms. It is not required that this be 50 ms of continuous Reset signaling. However, if the reset is not continuous, the interval(s) between signaling reset must be less than 3ms." It seems that Windows uses such a split reset, with first issuing a 30 ms reset, followed by reading the device descriptor and concluding with a 20 ms reset.

The spec also says that the host should (i) read the line state for the device speed (i.e. LS versus FS) immediately after the reset signal concludes and that the device must be allowed a minimum of 10 ms of recevery time after the reset signal concludes (7.1.7.1).

##### Set Address

After receiving the set address command, the device has up to 2 ms to implement the change of address, i.e. the device should not be accessed in that interval.

##### Set Configuration

A device may support multiple configurations and the device descriptor will inform the host of how many exist for the device, numbered 1 ... N. All devices must support at least one configuration and in practice nearly all devices support just a single configuration.

##### Minimal algorithm

In summary, the minimum algortihm to configure a device is:

```C
set_reset(on);                   // issue 50 ms reset signal
wait_ms(50);
set_reset(off);
device->speed = read_speed();    // read device speed
wait_ms(100);                    // minimum is 10 ms
call(device, SET_ADDR, 1, 0, 0); // set address to 1
wait_ms(5);                      // minimum is 2 ms
call(device, SET_CONF, 1, 0, 0); // set active configuration to 1
```

Of course, with this mimimal algorithm, the host has no idea what type of device just connected.

<a name="enum"></a>
#### Device enumeration

There are two descriptors that enable device enumeration: the **device descriptor** and the **configuration descriptor**. The latter is acutally a compound descriptor, consisting of a hierarchy of descriptors (and its components cannot be retrieved individually).

Typically a host will in order request:

* the device descriptor
* the configuration descriptor header, which includes the size of the full configuration descriptor
* the full configuration descriptor

At minimum, the host can only request the device descriptor and decide on the appropriate driver from that information alone.

##### Device Classification

The USB spec defines a three level classification, consisting of a class, a sub-class and a protocol, together this classification can be written as (x,y,z). For example, the classification for a Hub is (9,0,0) and for a standard keyboard (3,1,1).

The class for 'vendor defined' is 255 and for example FTDI serial chips report with a classification of (255,255,255). In such cases the device class has to be determined through other means, such as using the vendor and product ID.

Common class codes are:

| Code | Class   | Description |
|:---- |:------- |:----------- |
| 0x00 | None    | No overall device class
| 0x01 | Audio   | Speakers, microphones, and sound cards
| 0x02 | CDC     | Modems, serial ports, and networking
| 0x03 | HID     | Keyboards, mice, game controllers, and touchscreens
| 0x06 | Image   | Image capture, such as webcams and scanners.
| 0x07 | Printer | Printers
| 0x08 | Storage | Hard drives, flash drives, and memory card readers
| 0x09 | Hub     | USB Hubs
| 0x0a | CDC     | Supplemental CDC data subclass

For more information on each class, please refer to the standards document for each class.

##### Device descriptor

The first level of information about the device is in the device descriptor (section 9.6.1):

```c
struct
{
  uint8_t  bLength;              // 18 bytes
  uint8_t  bDescriptorType;      // 0x01
  uint16_t bcdUSB;               // 0x0110 (USB 1.1) or 0x200 (USB 2.0)
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
  uint8_t  bNumConfigurations;  // usually 1
};
```

The key fields in this structure are:

* `bMaxPacketSize0 `: this field gives the FIFO size of the control endpoint (endpoint 0). At minimum this is 8. The other aspects of the control endpoint are dictated by the standard.
* `idVendor` and `idProduct`: these fields give the vendor ID ("VID") and the product ID ("PID"). These uniquely identify the device.
* The classification fields: these give the overall device classification; often, the classification here is (0,0,0) and the classification is included in the configuration data instead.
* `bNumConfigurations`: this field gives the number of configurations; nearly always this number is one (which is the minimum).

For a large host (e.g. the USB host software in a desktop OS) it is possible to keep tables linking VID/PID data to matching drivers and they do. Tiny hosts typically rely on the classification.

##### Configuration descriptor header

The second level of information about the device is in the configuration descriptor. This is a (potentially large) hierarchical set of descriptors that describe the device's function(s). It begins with a configuration header (section 9.6.2):

```c
struct
{
  uint8_t  bLength;              // 9 bytes
  uint8_t  bDescriptorType;      // 0x02
  uint16_t wTotalLength;
  uint8_t  bNumInterfaces;
  uint8_t  bConfigurationValue;  // usually 1
  uint8_t  iConfiguration;
  uint8_t  bmAttributes;
  uint8_t  bMaxPower;            // in 2 mA increments
};
```

The key fields in this structure are:

* `bConfigurationValue`: this field gives the configuration id; nearly always this is one. Used for the "set configuration" command.
* `wTotalLength`: this field gives the total size in bytes of the full configuration descriptor, including all sub-descriptors.
* `bNumInterfaces`: the number of "interfaces" in the configuration. Interfaces are the top level of the sub-descriptors.

The configuration descriptor header is followed by a numbered set of interface sub-descriptors that describe the device function(s). There is at minimum one interface descriptor. Interfaces are further described [on this page](interfaces.md).
