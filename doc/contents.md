### Contents

#### USB Overview

1. [Introduction](intro.md)
1. [USB architecture](usbarch.md)
1. [Reference documents and tools](refdoc.md)

#### Operating the Universal Serial Bus

1. **Layer 1**: [Electrical interface](electrical.md)

1. **Layer 2**: [Bits and packets](bitspackets.md)

1. **Layer 3**: Transactions
   1. [Packet types](packets.md)
   1. [Transactions](transactions.md)
   1. [Frames](frames.md)

1. Transceivers
   1. [Intro and UTMI+](transceiver.md#intro)
   1. [The USB11 transceiver](transceiver.md#usb11)
   1. [Linux driver](transceiver.md#linux)
   1. [Exampe SoC](transceiver.md#soc)

1. **Layer 4**: Requests
   1. [Iso Requests](requests.md#iso)
   1. [Stream requests and retransmissions](requests.md#stream)
   1. [Control requests](requests.md#control)

1. **Layer 5**: Commands
   1. [Command structure](commands.md#cmd)
   1. [Requests are RPCs](commands.md#rpc)
   1. [Descriptors](commands.md#desc)

#### Operating USB devices and classes

1. **Layer 6**: Device discovery
   1. [Device reset and configuration](discovery.md#dev)
   1. [Device enumeration](discovery.md#enum)
   1. [Interfaces](interfaces.md)

1. [HUB class](hubs.md)

1. HID class
