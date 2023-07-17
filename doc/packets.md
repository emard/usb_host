### Layer 3: Packet types and PIDs

#### Introduction

USB packets come in various types. The data segment of a packet always start with a single Packet Identification byte, or **PID**. A PID is a 4 bit number, that is transmitted with its inverse in the upper nibble as an error check. For example the PID code 0x5 will be transmitted as the byte 0xA5. A packet with a PID byte where the higher nibble is not the inverse of the lower nibble should be rejected.

Each packet type has a specific structure for the remaining bytes in the packet's data segment.

Most packet types do not appear in isolation on the bus, but as part of a multi-packet transaction. Transactions are further discussed in the "Level 3: Transactions" page.

#### PIDs in USB1.1 and USB2.0

Packet identifiers come in four different categories: Token, Data, Handshake and Special. Each category is discussed below.

##### Token packets

The first group of packets are token packets. Token packages introduce a transaction. An OUT token initiates an outbound (from host to device) data transfer. Likewise, An IN token initiates an inbound (from device to host) data transfer. A SETUP token is very similar to an OUT token, but initiates a special transfer sequence with the device's control software. A SOF token is a one packet transaction that starts a new frame.

| Group | Name  | Value | Spec | Packet purpose  |
|:----- | ----  | -----:| ----:|:------- |
| Token | OUT   | 0xe1  |  1.1 | Start OUT transaction |
|       | SETUP | 0x2d  |  1.1 | Start SETUP transaction |
|       | IN    | 0x69  |  1.1 | Start IN transaction  |
|       | SOF   | 0xa5  |  1.1 | Start new frame  |

Note that the lowest two bits of token PIDs are always 2'b01.

Token packets are a bit unusual in their intrnal structure, in the sense that their internal fields are not byte-aligned. The total packet has a round number of bytes i.e. three data segment bytes.

The OUT/IN/SETUP token packets all share the same layout:
<font size="2" color="darkblue">

| Field | Bits | Purpose |
| ----- |:----:|:------- |
| SYNC  |  8   | Start new packet |
| PID   |  8   | Packet ID |
| ADDR  |  7   | Device address |
| EP    |  4   | Endpoint number |
| CRC5  |  5   | CRC over ADDR and EP |
| EOP   |  3   | End of packet |
</font>

Note that the total length of the ADDR, EP and CRC5 fields is 16 bits, i.e. two full bytes. See the page on transactions for further discussion of the token packet fields.

The layout of a SOF token packet is a variant on the above:
<font size="2" color="darkblue">

| Field | Bits | Purpose |
| ----- |:----:|:------- |
| SYNC  |  8   | Start new packet |
| PID   |  8   | Packet ID |
| FRAME | 11   | Sequence number of new frame |
| CRC5  |  5   | CRC over FRAME |
| EOP   |  3   | End of packet |
</font>

Note that the total length of the FRAME and CRC5 fields is 16 bits, i.e. two full bytes. See the page on USB frames for further discussion of frame packets fields.

The CRC5 polynominal is `G(X)=X^5+X^2+1`, see section 8.3.5 of the spec for details.

##### Data packets

The second group are data packets. As the name suggests, these packets carry payload data. USB1.1 uses a simple 1 bit sequence number, using the PIDs `DATA0` and `DATA1` only. USB2.0 extends this for high-speed communication only with two additional packet types.

| Group | Name  | Value | Spec | Packet purpose |
|:----- | ----  | -----:| ----:|:------- |
| Data  | DATA0 | 0xc3  |  1.1 | data with sequence no. = 0 |
|       | DATA1 | 0x4b  |  1.1 | data with sequence no. = 1 |
|       | DATA2 | 0x87  |  2.0 | data with sequence no. = 2 |
|       | MDATA | 0x0f  |  2.0 | data [?] |

Note that the lowest two bits data PIDs are always 2'b11.

Data packets are variable length according to the following format (note that size here is given in _bytes_ not _bits_):
<font size="2" color="darkblue">

| Field | Bytes | Purpose |
| ----- |:-----:|:------- |
| SYNC  |  1    | Start new packet |
| PID   |  1    | Packet ID |
| DATA  | 0-64*  | Data payload |
| CRC16 |  2    | CRC over DATA |
| EOP   |       | End of packet |
</font>

The data payload may vary from zero to 8 bytes on a low-speed link and from zero to 64 bytes on a full-speed link. When communicating to an isosynchrous endpoint, the maximum payload size is 1,023 on full-speed links. Isosynchrous traffic is not allowed on a low speed link.

The CRC16 polynominal is `G(X) = X^16+X^15+X^2+1`, see section 8.3.5 of the spec for details. The low order byte of this CRC is sent first.

##### Handshake packets

The third group are handshake packets, which normally finalise a bus transaction (isosynchrous transactions are the exception).

| Group     | Name  | Value | Spec | Packet purpose |
|:-----     | ----  | -----:| ----:|:------- |
| Handshake | ACK   | 0xd2  |  1.1 | Data packet received & accepted |
|           | NAK   | 0x5a  |  1.1 | Can not send or store data |
|           | STALL | 0xe1  |  1.1 | Endpoint disabled / Function not supported |
|           | NYET  | 0x96  |  2.0 | Transaction translation not ready |

Note that the lowest two bits of handshake PIDs are always 2'b10.

Handshake packets have a very simple structure and have a data segment of only one byte: the PID itself:
<font size="2" color="darkblue">

| Field | Bits | Purpose |
| ----- |:----:|:------- |
| SYNC  |  8   | Start new packet |
| PID   |  8   | Packet ID |
| EOP   |  3   | End of packet |
</font>


##### Special packets

The last group are the special packets. As the name suggests, these packets deal with special situations. In USB1.1 only the PRE PID is defined, which is used to route low-speed traffic to a low-speed device that is connected via a hub (full speed by definition).


| Group | Name     | Value | Spec | Packet purpose |
|:----- | ----     | -----:| ----:|:------- |
| Data  | PRE      | 0x3c  |  1.1 | start mixed-speed signalling |
|       | ERR      | 0x3c  |  2.0 | transaction error |
|       | SPLIT    | 0x78  |  2.0 | split transaction |
|       | PING     | 0xb4  |  2.0 | ping device |
|       | Reserved | 0xf0  |  2.0 | - |

Note that the lowest two bits of special PIDs are always 2'b00. Also note that PRE and ERR packets share the same value. As the PRE PID is only used in the context of low-speed and full-speed communication, and the ERR PID only in the context of high-speed communication there can be no confusion between the two.

The use of the PRE packet header is discussed in more detail in [the page on bit-level signalling](bitspackets.md#mixed).


