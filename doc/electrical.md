### Layer 1: Electrical

#### Introduction

This is a very brief summary of the first half Chapter 7, Electrical of the USB 1.1 / USB 2.0 specification. For more detail please refer to that chapter.

At the electrical level, USB is a two-wire semi-differential bus. The signal wires are named `D+` and `D-` respectively. A further two wires carry power and ground, and these four wires are combined into a shielded cable.

It is "semi-differential" because although data signalling is differential, the bus also uses single ended signaling in its wire protocol. The signals are named SE0, J, K and SE1 ('SE' meaning 'single ended').

These states are used together with the following cable setup (figure 7.10 in the spec):

![a](doc/img/usb_electrical.png)

Note that the transceivers must have an output/input impedance that matches that of the cable, in order to minimise reflections and optimise signal integrity. The spec also states:

*A differential input receiver must be used to accept the USB data signal. The receiver must feature an input sensitivity (Vdi) of at least 200mV when both differential data inputs are in the differential common mode range (Vcm) of 0.8V to 2.5V.*

*In addition to the differential receiver, there must be a single-ended receiver for each of the two data lines. The receivers must have a switching threshold between 0.8V (Vil) and 2.0V (Vih). It is recommended that the single-ended receivers incorporate hysteresis to reduce their sensitivity to noise.*

#### Signaling

As mentioned, the four signals are SE0, J, K and SE1:

| DP  | DN  | Name    | Usage |
| --- | --- | ---     |:--- |
|  0  |  0  | SE0     | Unconnected, Reset, End-Of-Packet |
|  0  |  1  | J, Idle | Logical 1, Connected Idle |
|  1  |  0  | K       | Logical 0 |
|  1  |  1  | SE1     | Illegal |

As long as no device is connected, both D+ and D- are pulled down at the host (or 'upstream' port) and the controller recognises this as the unconnected state.

Once a device (or 'downstream' port) is connected the D+ line is pulled high and the controller recognizes this as the connected idle state. In terms of signal levels this is the same as the J state, with the differnce that for a J state the bus is actively driven by the host or the device and the idle state is driven by the pull-up and pull-down resistors.

A reset condition is a brief (> 2.5 us and < 50 ms) driven SE0 state. There can be no confusion between disconnected and reset, because the reset state is always driven by the host, and never the device.

An End-Of-Packet ("EOP") condition consists of two bit-times of SE0 followed by one bit-time of J. For low-speed connections, one bit-time is 667 ns, for full-speed connections one bit-time is 84 ns.

The SE1 state is illegal under the USB wire protocol and should normally never be seen, other than as a cross-over transient. Encountering a non-transient SE1 condition during data transmission is a bus error.

#### Signal polarity

In a USB 1.1 context two types of device can connect to the bus, Low-Speed ("LS") and Full-Speed ("FS"). A low-speed device indicates that it is low speed by pulling up its `D-` wire instead of its `D+` wire. In order to keep the Idle state identical to the J state, J and K switch places for a low-speed device. The spec has a complicated way of explaining this.

The easier (for me at least) way to deal with this is to say that a low-speed device swaps its internal DP/DN wires on the bus: DP is connected to `D-` and DN is connected to `D+`. One might call this 'reverse polarity'. A full-speed device has DP connected to `D+` and DN to `D-`, i.e. 'normal polarity'.

![a](doc/img/swapping.png)

In the above view, the pull-up resistor is always on DP and hence DP==1, DN==0 always means J and DP==0, DN==1 always means K. This greatly simplifies the design of the host PHY module.

In order for the host to read the type of device, the host software can still read the actual `D+` and `D-` line states, bypassing any internal swapping.

#### ULX3S electrical interface

The ULX3S board has a clever electrical interface to generate the required signals. As recommended by the spec, it combines single ended receivers (for SE0 and SE1) with a differential receiver (for J-K data). For transmission single ended transmitters are used (in a pseudo-differential mode for J-K data).

Two further IOs are used to drive the pull-up / pull-down resistors. If the IO is driven high ('1') it pulls the associated line high with a 1K2 resistor (equivalent to 1K5 in view of the extra diode). If the IO is driven low ('0') it pulls the associated line low with a 15K resistor (should be 12K in view of the diode, but 15K works in practice).

![a](doc/img/ulx3s_u2_schematics.png)

The data lines have 27 ohm series resistors to match impedances and to limit currents in case of over-voltage. Two 3V6 zener diodes protect the FPGA inputs from ESD and other mishap.

The ULX3S does not offer programmable facilities for managing the USB Vbus power line. The board offers the possibility to include a diode in the Vbus power line, in order to limit power flow either to the out direction (a host powering the bus), or to the in direction (a device taking power form the bus). Other alternatives are to place a fuse or a wire bridge. There is no mechanism for the FPGA to sense whether or not (external) power is present on the Vbus line.


 
