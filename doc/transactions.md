### Layer 3: Transactions

#### Introduction

This is a very brief summary of the first half of Chapter 8, "Protocol Layer" of the USB 1.1 / USB 2.0 specification.

In the USB architecture, individual packets combine into transactions. A transaction is a single interaction between the host and a device. There can only ever be a single active transaction on the bus on any one time, and hence its timing is capped. The spacing between the individual packets of a single transaction is a maximum of 16 bit times. After waiting 18 bit times both sides should abandon the transaction and revert to the idle state.

All higher layers of the USB architecture are much less time critical. Hence layers 1 through 3 are typically implemented in hardware and layer 4 and above in software.

#### Transaction types

The spec defines 4 different types of transactions, with somewhat confusing names:

* bulk IN/OUT transfers
* isosynchrous IN/OUT transfers
* interrupt IN/OUT transfers
* control read and control write transfers

I find it more clear to think about transactions as three types:

* IN/OUT datagram transactions (= isosynchrous in the spec)
* IN/OUT stream transactions (= bulk + interrupt in the spec)
* SETUP transactions (= first phase of control transfers)

These are discussed in more detail below.

Closely related to transactions are **requests** (or "IRPs" in the spec). Requests are sets of related transactions that together form one interaction. An example is the request to send 200 bytes on a stream connection: the request will be split into multiple OUT transactions of 64 bytes maximum, with re-transmissions as necessary. In this summary, [requests]( form the next layer.

#### Datagram ("isosynchrous") transactions

The simplest transactions are datagram transactions. They consist of two packets, a token packet and a data packet. The token packet defines the target device and endpoint, and the direction of the transfer. The token itself does not define the datagram nature of the transaction: this is an attribute of the endpoint.

There is no handshake in either direction: if a transaction is garbled in transmission, it is lost.

![a](doc/img/iso_txn.png)

Datagram transactions are typically used to transmit audio data. Transmitting a 64 byte datagram packet each frame results in an effective bitrate of 512kbps, easily enough for an MP3-encoded audio track.

Note that datagram transmissions are only allowed for full-speed devices.


#### Stream ("bulk" & "interrupt") transactions

Stream transactions are the building block for error controlled data transfers in the USB architecture. In the normal case, there are 3 packets in the transaction: a token packet, a data packet and a handshake packet.

The token itself does not define the stream nature of the transaction: it is the endpoint definition that sets the "bulk" or "interrupt" nature. A bulk endpoint is intended for 'at will' data communication. An interrupt endpoint is intended for regularly scheduled interactions, for instance a hub device that wants its status endpoint checked 4 times per second.

Stream transactions are more complex and best discussed for the IN and OUT directions seperately. First let's look at stream OUT transactions.

![a](doc/img/out_txn.png)

The host initiates the transaction by sending an OUT token, immediatley followed by a DATA packet. This can be a DATA0 or DATA1 packet, depending on the current transmission sequence number.

The device can then respond with a handshake or with a timeout. The choice is made as follows:

| response | when | host follow-up |
|:-------- |:---- |:----------- |
| timeout  | token or data garbled | repeat transaction |
| STALL    | endpoint blocked | notify device driver |
| NAK      | not ready | repeat transaction after wait |
| ACK      | received OK | retire data, move on |

Stream IN transactions are mostly similar, but look a bit more complex, as both sides can send a handshake:

![a](doc/img/in_txn.png)

The host initiates the transaction by sending an IN token. It then waits for the device response, which can be a DATA packet, a handshake or a timeout:

| response | when | host follow-up |
|:-------- |:---- |:----------- |
| timeout  | token garbled | repeat transaction |
| STALL    | endpoint blocked | notify device driver |
| NAK      | not ready | repeat transaction after wait |
| DATAx    | data ready | send ACK or timeout (see below) |

After the device has sent a DATA packet, the host has two options to finalise the transaction:

| response | when | device follow-up |
|:-------- |:---- |:----------- |
| timeout  | data garbled | keep data for retransmission |
| ACK      | received OK | retire data, move on |

Two things to note from the above are:

* The host will only ever send an ACK handshake; the other handshakes are for device use only.
* Correctly received DATA packets are always acknowledged, regardless of what the sequence number is.

This is further discussed in the section on requests.


#### SETUP transactions

SETUP transactions (maybe better named "command transactions") are the first transaction in a Control Read or Control Write request. The remainder of a Control request consists of one or more regular stream IN/OUT transactions.

SETUP transactions consist of three packets: a token packet, a data packet and a handshake packet:

![a](doc/img/setup_txn.png)

A setup transaction is very similar to a stream OUT transaction. The host starts by sending a SETUP token packet. The endpoint is always endpoint `0`, which is the obligatory control endpoint.

It then sends an 8-byte DATA0 packet with the command header. This is in a fixed format, see the request page for details.

The device will then respond with a handshake or a timeout:

| response | when | host follow-up |
|:-------- |:---- |:----------- |
| timeout  | token or command garbled | repeat transaction |
| STALL    | cmd not supported | notify device driver |
| ACK      | command accepted | enter next request phase |

Note that the device cannot reply with NAK to get more time to make the decision, i.e. if in doubt, accept. The later control request phases offer new opportunities to ask for delay and/or reject the command.


