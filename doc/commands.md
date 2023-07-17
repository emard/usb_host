### Layer 5: Commands (Control Requests)

This is a very brief summary of of the first half of Chapter 9, "Device Framework" of the USB 1.1 / USB 2.0 specification. For more detail please refer to that chapter.

As discussed for Layer 4, Control Requests are commands that are issued by the host to the device on its endpoint zero. In some cases the command is asking the device to send back data, usually in the form of a "descriptor" or one or more status words.

<a name="cmd"></a>
#### Command structure

Commands consist of a command block and an optional data exchange. The command block specifies the size and direction of that optional exchange.

The command block has the following 8 byte structure:

| Field   | Size | Meaning |
|:------- |:----:|:------- |
| type    | 1    | direction, group, context |
| request | 1    | command code |
| value   | 2    | 1st command argument |
| index   | 2    | 2nd command argument |
| length  | 2    | length of data |

The first byte ("type") classifies the command. It is not fully orthogonal with the command code in the second byte ("request"), but probably exist to allow devices to make quicker decisions on how to respond. The "type" byte has three bit fields:

| "type"    | Bit | #defined values |
|:--------- |:---:|:------ |
| direction |   7 | SU_IN, SU_OUT |
| group     | 6:5 | SU_STD, SU_CLS, SU_VENDOR |
| context   | 0:4 | SU_DEV, SU_IFACE, SU_EP, SU_OTHER |

The "direction" bitfield indicates whether the data phase will be inbound or outbound. If there is no data phase, the direction bit is set for outbound.

The "group" bitfield indicates whether the command is *standard* (i.e. defined in the main specification) or is *class* related (i.e. defined in a class specification; the oddball exception is the Hub class which is part of the main spec document). A third *vendor* group allows for a vendor specific command set.

The third and last bitfield, "context", specifies the context for the command, whether it relates to the device as a whole, to an interface, to an endpoint or something else. An example of the latter are commands relating to a hub port.

The "request" field is the command code. Some of the more frequently used command codes from the main specification (used both for the standard commands and for hub class commands) are:

| Command     | Hex  | Data? | Std | Hub | Typical meaning |
|:----------- |:---- |:-----:|:---:|:---:|:------ |
| GET_STAT    | 0x00 |  Yes  |  v  |  v  | Get status word(s) |
| CLR_FEAT    | 0x01 |  No   |  v  |  v  | Clear bit in settings or status |
| SET_FEAT    | 0x03 |  No   |  v  |  v  | Set bit in settings |
| SET_ADDR    | 0x05 |  No   |  v  |     | Set device address |
| GET_DESC    | 0x06 |  Yes  |  v  |  v  | Fetch descriptor structure |
| SET_CONF    | 0x09 |  No   |  v  |     | Set active configuration |

The remaining fields in the command block are 16 bit words.

The first two, "value" and "index" are the command parameters. Their meaning varies by command, but as their names suggest, the first is typically a value and the second an index. A notable exception is the GET_DESC command and associated GET_STRING command, where the "index" field is used to specify the language of the response (typically zero) and the "value" field has both a descriptor number in its high byte and an index in its low byte.

The last field ("length") specifies the length of the data to be returned (or less commonly: to be sent). A value of zero means that there is no data to be transferred, and hence no data stage in the Command Request.

<a name="rpc"></a>
#### Control Requests are RPCs

Commands (Control Requests) appear complicated, but they are probably best understood as Remote Procedure Calls, or RPCs: when making a Control Request, the Host is calling a service routine in the device's firmware. All the complexity of Control Requests can be reduced to nothing more than a detailed description of the RPC transport mechanism.

For example, if the code to initiate a Control Request is encapsulated in a procedure with the name `call`, and a companion procedure named `wait` blocks until the Control Request has completed, then the command to set a device's address can be written as:

```
call(device, (SU_OUT|SU_STD|SU_DEV), SET_ADDR, addr, 0, 0);
resp = wait();
if (resp != OK ) {
	* handle error *
}
```

The point here is that the intricacies of command blocks an Control Requests belong at Layer 4; they should be viewed as high level commands at Layer 5 and up.

<a name="desc"></a>
#### Descriptors

USB devices report their attributes using descriptors. A descriptor is a data structure with a defined format. Each descriptor begins with a byte-wide field that contains the total number of bytes in the descriptor followed by a byte-wide field that identifies the descriptor type:

```
struct
{
  uint8_t bLength;
  uint8_t bDescriptorType;
  ...
};
```

All descriptors defined by the main USB standard and by class standards start with this structure. It allows for traversal of reponses that concatenate multiple descriptors into a single data response.

Individual descriptors are typically a dozen bytes or so in size. The full configuration desscriptor, including all its sub-descriptors, can be several hundred bytes long.

One complexity is that class-specific descriptors can be returned in one of two ways:

1. As part of the full configuration descriptor, typically immediately after the  interface descriptor for that class. This is the normal case.

2. Through a class GET_DESC command. This is used when the descriptor is not in the normal format or is unrelated to the configuration. For some unclear reason (probably "historical reasons"...), the Hub descriptor is in this group.

For more information on descriptors, see the pages on [device discovery](discovery.md) and on [interfaces](interfaces.md).

#### Status words

Status is usually returned in one or more words with bitfields. The format of status words is highly class specific.



