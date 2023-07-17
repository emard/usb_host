### Contents

#### USB Overview

1. [Introduction](intro.md)
2. [USB architecture](usbarch.md)
3. [Reference documents and tools](refdoc.md)

#### Operating the Universal Serial Bus

1. Layer 1: [Electrical interface](electrical.md)

2. Layer 2: [Bits and packets](bitspackets.md)

3. Layer 3: Transactions
 1. [Packet types](packets.md)
 2. [Transactions](transactions.md)
 3. [Frames](frames.md)

4. Transceivers
  1. [Intro and UTMI+](transceiver.md#intro)
  2. [The USB11 transceiver](transceiver.md#usb11)
  3. [Linux driver](transceiver.md#linux)
  4. [Exampe SoC](transceiver.md#soc)

5. Layer 4: Requests
 1. [Iso Requests](requests.md#iso)
 2. [Stream requests and retransmissions](requests.md#stream)
 2. [Control requests](requests.md#control)

6. Layer 5: Commands
 1. [Command structure](commands.md#cmd)
 2. [Requests are RPCs](commands.md#rpc)
 3. [Descriptors](commands.md#desc)

#### Operating USB devices and classes

1. Level 6: Device discovery
 1. [Device reset and configuration](discovery.md#dev)
 2. [Device enumeration](discovery.md#enum)
 2. [Interfaces](interfaces.md)

2. [HUB class](hubs.md)

3. HID class




