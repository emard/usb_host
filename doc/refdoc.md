### Reference documents and tools

#### Official Specifications

The specifications that are most relevant in this USB 1.1 host are the following three:

1. [USB 1.1 Spec](https://fabiensanglard.net/usbcheat/usb1.1.pdf)
2. [UTMI+ Spec](https://www.nxp.com/docs/en/brochure/UTMI-PLUS-SPECIFICATION.pdf)
3. [HID 1.1 Spec](https://www.usb.org/sites/default/files/hid1_11.pdf)

When adding support for other devices than Hubs and "HID" (keyboard, mouse, etc.) devices the relevant class specifications would become relevant as well (e.g. the storage class specification for memory sticks, etc.).

#### The USB 1.1 Spec

The core document is the USB 1.1 Spec. At 300+ pages it is not a short document, but only half the size of the 600+ pages of the USB 2.0 Spec. To the credit of the USB designers, a USB 1.1 compliant host can still drive most USB 2 (or even 3) devices and hubs! Hence the USB 1.1 Spec is a good place to start for educational use. **Note, however, that as an official specification USB 1.1 has been long withdrawn.**

| Chapter | Title | Description |
| ------- |:----- |:----------- |
| 1 - 3   | Intro | Introduction, Terms, Background
| 4       | Architectural Model | This chapter provides a basic overview of a USB system including topology, data rates, data flow types, basic electrical specs etc.
| 5	       | Data Flow Model | Overview of bus capacity managment and request types (iso, bulk, interrupt & control)
| 6       | Mechanical	| Connector types and requirements
| 7       | Electrical	| Low level electrical signalling including line impedance, rise/fall times, driver/receiver specifications and bit level NRZI encoding, bit stuffing etc.
| 8       | Protocol Layer | Describes packets at a bit level including the sync, pid, address, endpoint, CRC fields; also describes packet types
| 9       | Device Framework | Device enumeration and (standard) Control Requests
| 10      | Hosts | Frame generation, host controller requirements
| 11      | Hubs	| Hub responsibilities, hub controller requirements

The USB 2.0 Spec is very similar in structure, but less accessible because it adds a high-speed (480MHz) mode to USB 1.1. This new mode - although backward compatible - adds an entirely new electrical signalling approach over the same two wires and adds several new mechanisms / requirements to operate high-speed in combination with the earlier low- and full-speed modes. In particular, this makes hubs significantly more complex.

USB 3 adds new wires and signalling at 5GHz or even 10GHz.

#### Other good sources

The USB standard is almost 30 years old and many other summaries of the specifications exist. Below are two websites that also give good summaries of the lower levels of the USB Specification:

1. [USB Made Simple](https://www.usbmadesimple.co.uk)
2. [USB in a Nutshell](https://www-user.tu-chemnitz.de/~heha/hsn/chm/usb.chm/usb1.htm)

For the higher levels of speficification and designing new device drivers the following projects offer a view what is minimally needed to interact with a certain class of device:

1. [TinyUSB library](https://www.usbmadesimple.co.uk)
2. [CherryUSB library](https://github.com/cherry-embedded/CherryUSB)

#### Handy development tools

This RP2040-based USB sniffer is very handy to see the traffic going down the bus:

[https://github.com/ataradov/usb-sniffer-lite](https://github.com/ataradov/usb-sniffer-lite)

Combined with a male/female USB breakout board ([this for example](https://www.aliexpress.us/item/2251832838830634.html)) it makes for a 10 buck analyzer that arguably covers 90% of the issues that are normally encountered.

Also [sigrok](https://sigrok.org/wiki/Main_Page) is a very handy analysis tool, that works with many low-cost logic analyzers.




