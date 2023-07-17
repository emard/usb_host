### Layer 2: Bits and packets

#### Introduction

This is a very brief summary of the second half of Chapter 7, "Electrical" of the USB 1.1 / USB 2.0 specification. For more detail please refer to that chapter.

#### Bit speed

USB1.1 operates at one of two signalling speeds: in low-speed ("LS") mode signalling happens at a bit rate of 1.5 Mbps; full-speed ("FS") mode is 8 times faster at 12 Mbps.

USB2.0 adds a third signalling speed: in high-speed ("HS") mode the bit rate is 480 Mbps. This is transmitted using a different transceiver interface. As USB2.0 is fully backwards compatible with USB1.1, we ignore HS signalling in this document.

#### NRZI encoding

USB uses NRZI encoding of the bit stream. This means that if the current data bit is a '0', the DP/DN lines change state (a J becomes a K, and vice-versa); if the data bit is a '1' the DP/DN lines keep the same state as they had for the previous bit.

This is illustrated in the below figure (from spec section 7.1.8):

![a](doc/img/nrzi.png)

#### Packets

All traffic on the bus is composed from **packets**. A packet consists of a SYNC pattern, a set of data bits and an EOP (End-Of-Packet) pattern.

![a](doc/img/packet.png)

The SYNC pattern is `KJKJKJKK`. This pattern has a lot of edges to synchronise the receiver PLL clock and the `KK` indicates the start of the data payload. The first edge of the SYNC pattern is considered to be the start of the packet ("SOP").

The data payload is transmitted least significant byte first and least significant bit first; the bitstream is NRZI encoded, with bit-stuffing after 6 sequential one bits. This is described further in the below sections. The data (before bit-stuffing) is always a multiple of 8 bits, i.e. an integral number of bytes. The maximum data size is 8 bytes for low-speed traffic and 64 bytes for full-speed traffic, i.e. a maximum packet duration of about 50 us in both cases.

The End-Of-Packet marker consists of two consecutive `SE0` bits, followed by a `J` bit and the bus going back to Idle.

Note that the SYNC pattern can be thought of as sending the data byte `0x80`: seven zeroes lead to KJKJKJK, followed by another K for the final one bit (remember that bytes are sent lsb first).

As USB is implicitly a shared bus, only one packet can be in transit in any one point in time. The protocol clearly defines who can send: in brief, the host initiates all traffic and a device must respond with a data packet or handshake packet within 18 bit times.

#### Bit stuffing

In order to keep the receive clock PLL sufficiently synchronised, the wire pattern must have sufficient transitions. This is achieved by inserting an additional '0' bit on the data stream after every six '1' bits (which have no transitions). The spec gives the following algorithm (section 7.1.9):

<p align="center">
![a](doc/img/bitstuff.png)

For receiving, "insert zero bit" obviously becomes "remove zero bit".

There are two important caveats in this algorithm to take into account:

1. The SYNC pattern is included in the bit stuffing algorithm, hence at the end of the SYNC pattern the bit stuff counter is at one, not zero.

2. If the data pattern ends with 6 sequential ones, the stuff bit is still inserted before the EOP is sent.


#### Mixed speed signaling

USB allows for 'hubs' to repeat the bus signal to multiple devices. A hub must be a full-speed device itself, i.e. its upstream connection is a FS connection. Both full-speed and low-speed devices may be connected to its downstream ports. A hub will repeat incoming host packets to all devices connected to it, and also repeats from device to host.

As an exception to the above rule, a hub will not forward full speed traffic form the host to low speed devices. The reason for this is two-fold (i) avoid the LS device getting confused by the FS signal, and (ii) avoid EMI radiating from the lower spec LS cabling. In the other direction these problems do not exist and host-bound traffic is repeated upstream as normal. The question then is how the host can send and receive low-speed traffic through a hub.


The solution to the above issue is a special packet identifier byte, `PRE` (= 0x3c) that alerts the hub to an outboud low-speed package that needs repeating to low-speed ports:

![a](doc/img/pre_mode.png)

When it wants to send a LS packet via a hub, the host first sends a full-speed sync pattern, followed by the PRE / 0x3c byte, also sent at full-speed. Then it pauses for 4 FS bit times to give the hub time to enable its low speed repeaters. Then it sends the low-speed packet. Once the hub sees the (LS) EOP pattern, it disables the low-speed repeater again. The PRE-preamble must be repeated before each and every outbound packet.

Inbound low-speed packets are always forwarded upstream. The host must be ready to receive a low-speed packet when it can expect one:

* after sending out a low-speed IN token (expect to receive DATAx or handshake packet)
* after sending out a low-speed DATAx packet (expect to receive a handshake packet)

A last oddity about talking to LS devices behind a hub is signal polarity: although the packet after the PRE header is sent at low speed, it is sent with the polarity of full-speed signalling (i.e. `J` has the D+ line high).

This is very counter-intuitive at first, but actually easy to understand when viewed in terms of wire swapping (see the [Signal Polarity](electrical.md) section):

![a](doc/img/pre_polarity.png)

The hub has already swapped the wires at its downstream port and hence the host sees the low-speed traffic with normal polarity.

