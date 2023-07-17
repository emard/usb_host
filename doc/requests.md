### Layer 4: Requests

#### Introduction

This is a very brief summary of parts of Chapter 5, "Data Flow Model" and of Chapter 8, "Protocol Layer" of the USB 1.1 / USB 2.0 specification.

Requests are sets of related transactions that together form one interaction. An example is the request to send 200 bytes on a stream connection: the request will be split into multiple OUT transactions of 64 bytes maximum, with re-transmissions as necessary.

In the spec, Requests are refered to as "I/O Request Packets", typically written as the abbreviation "IRP".

<a name="iso"></a>
#### Iso Requests

Iso Requests are basically the same as iso transactions: as they are never retried, there is no further work to be done at the Request level.

However, the USB spec guarantees that Iso Requests have access to up to 90% of the effective bus bandwith. An implementation could use the Request layer to manage line scheduling to give preferential treatment to the transmission of Iso Requests.

<a name="stream"></a>
#### Stream Requests

Stream Request differ from stream transactions in that Stream Requests offer error free transfers of arbitrary sized data.

_Arbitrary sized data_

A stream request breaks up the full transfer into chunks that are at most the maximum packet size for the endpoint (the protocol minimum is 8 bytes, the maximum is 64 bytes).

For an IN transaction, if the device is sending less data than requested by the host, it signals the end of data by ending with a transaction that is shorter than the maximum, using a zero-length package if necessary.

_Error correction_

Because USB is a bus architecture packets can never arrive out of order or in duplicate. This means that error correction can be achieved with a 1 bit sequence number per endpoint.

The receiver protects against garbled data through the use of parity bits and CRC-checksums. The PID field is protected through a parity check in its upper nibble, other data through a CRC-checksum. If there is a failure in these check bits, the packet is rejected.

Re-transmission is managed through the following algorithm:

For the **sender** (i.e. the host in an OUT request, or a device in an IN request):

| response | sequence | data    | next step        |
|:-------- |:-------- |:------- |:---------------- |
| ACK      | toggle	  | discard | send next data   |
| error    | keep     | keep    | retry            |
| NAK      | keep     | keep    | retry after wait |
| STALL    | -        | -       | report to driver |

And for the **receiver** (i.e the host in an IN request, or the device in an OUT request):

| DATAx    | sequence | data    | response   |
|:-------- |:-------- |:------- |:---------- |
| x == seq | toggle	  | accept  | send ACK   |
| x != seq | keep     | reject  | send ACK   |
| bad pkt  | keep     | reject  | timeout    |
| not rdy* | keep     | reject  | send NAK   |
| error*   | -        | -       | send STALL |

In the above table, 'x == seq' means the expected sequence number matches with the sequence received (i.e. expect sequence `0` and receive `DATA0`, or expect sequence `1` and receive `DATA1`). Likewise, 'x != seq' means such a match was not there.

The 'error' condition means that the device (belatedly, or based on the data received so far) cannot complete the Control Request.

*) Note that the host must always be ready and able to receive the data it requested, and cannot send NAK or STALL!

<a name="control"></a>
#### Control Requests

Control requests ("Control Read Transfers" and "Control Write Transfers" in the spec) are more complex than the other requests, because they consist of three distinct phases: a setup phase, an optional data phase and a final status phase:

<p align="center">
![](img/img/control.png)

_SETUP phase_

The first phase is the SETUP phase and in this phase the host transmits an 8 byte command block to the device. The command block has the following format:

| Field   | Size | Meaning |
|:-----   |:----:|:------- |
| type    | 1    | direction, group, context |
| request | 1    | main command |
| value   | 2    | 1st command argument |
| index   | 2    | 2nd command argument |
| length  | 2    | length of data phase |

For the Request layer only two fields are relevant: the direction bit in the type field and the data length field. The direction bit determines whether this is:

* a Control Write Request (where the data phase consists of a stream OUT request) followed by a status IN transaction.
* a Control Read Request (where the data phase consists of a stream IN request) followed by a status OUT transaction.

If a device receives a SETUP transaction, a device must stop any previous control request that it had pending.

If the setup transaction results in a STALL handshake, the Control Request is aborted and there are no further phases.

_DATA phase_

The length field in the command block determines the presense and length of the IN/OUT request that constitutes the data phase. If the length is zero, the data phase is skipped completely (i.e.: there is **not** a zero-length data packet in that case).

The stream IN/OUT request that forms this phase always starts with sequence number `1`. This is otherwise a normal stream request with the same mechanisms for error detection and retransmission.

If the data request results in a STALL handshake, the Control Request is aborted and there is no status phase.

_STATUS phase_

The third and final phase is the status phase. This phase consists of a single IN or OUT request with a zero-length data packet. The sequence number is again always `1`.

For Control Reads, the host sends a zero-length OUT transaction. The device response to this data packet indicates the current status. A NAK indicates that the device is still processing the command and that the host should retry the status stage. An ACK indicates that the device has completed the command and is ready to accept a new command. A STALL indicates that the device has an error that prevents it from completing the command.

For Control Writes, the host sends a zero-length IN transaction. The device responds with either a handshake or a zero-length data packet to indicate its current status. A NAK indicates that the device is still processing the command and that the host should retry the status stage; a STALL indicates that the device cannot complete the command; and return of a zero-length packet indicates normal completion of the command. The device expects the host to respond to this data packet with ACK. If the device does not receive ACK, it remains in the status stage of the command. Receipt of a new SETUP transaction clears this state.


