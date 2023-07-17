### Tranceivers

This section does not correspond to a section in the USB 1.1 Specification, but describes the tradtional hardware layer of an implementation. It does correspond in part to the UTMI+ specification.

#### Introduction

The first 3 layers of the USB specification (bits, packets and transactions) describe things that happen at nanosecond to microsecond scales: the bit-time for full-speed signalling is 84 ns and the slowest low-speed transaction takes some 125 us. This is too fast for the small microcontrollers in keyboards or mice (or this was at least true when USB was designed). As a result, the first 3 layers were traditionally implemented in a separate transceiver chip or as a custom silicon IP block.

Today cheap CPUs are much faster, but with the addition of high-speed in USB 2 and superspeed in USB 3 the tradeoff has remained more or less the same.

This tiny implementation uses a FPGA-based transceiver block named **"USB11"**. It is implemented as about 800 sloc of plain Verilog.

#### UTMI+ and ULPI

The USB standard defines a set of standard signals for transceiver IP blocks, the so called **"USB Tranceiver Macrocell Interface"** or **UTMI**. UTMI comes in various levels, and the version that encompasses Host functions is [UTMI+ level 3](https://www.nxp.com/docs/en/brochure/UTMI-PLUS-SPECIFICATION.pdf). The USB11 Transceiver uses UTMI+ signals in its internal structure and some of the UTMI+ control signals are exposed through its register interface.

The UTMI+ interface has lots of wires, which is fine for custom silicon or FPGA's but not so handy for separate chips. There is a standard wrapper called the **UTMI Low-pin Interface** or [**ULPI**](https://www.sparkfun.com/datasheets/Components/SMD/ULPI_v1_1.pdf). This is what many transceiver chips use in their interface. It is not discussed further in these pages.

The key UTMI+ control signals are:

1. **OpMode**. This is a 2-bit signal with the following interpretation:
	* 0 - Normal operation; automatically adds SYNC and EOP to packets
	* 1 - Non-driving operation
	* 2 - HS chirp mode (also used for LS/FS reset)
	* 3 - Normal operation without automatic SYNC/EOP generation
2. **XcvrSel**. This is also a 2-bit signal. Its interpretation is:
	* 0 - High Speed
	* 1 - Full Speed
	* 2 - Low Speed
	* 3 - Low Speed over Full Speed connection ("PRE mode")
3. **TermSel**. This is a 1-bit signal that engages a termination resistor, depending on the selected speed.
4. **DpPullDown**. This is a 1-bit signal that engages the pulldown resistor on the DP line.
5. **DnPullDown**. This is a 1-bit signal that engages the pulldown resistor on the DN line.

The USB11 transceiver only implements OpMode 0 and just enough of OpMode 2 to cover generation of the reset signal. For XcvrSel it only supports the values 1, 2 and 3. Together this is sufficient for supporting the USB 1.1 requirements.

#### The "USB11" transceiver

The USB11 transceiver is constructed out of 5 modules: the physical interface or PHY, the Serial Interface Engine or SIE, two 64-byte FIFOs and a control module or CTRL.

The PHY module converts between bus signals and packets. The SIE module combines packets into complete transactions, consisting of a token packet, a data packet and optionally a handshake packet. The FIFOs are intermediate storage between the Host CPU and the bus. The CTRL unit manages USB frames and interaction with the Host CPU.

![a](doc/img/usb11.png)

It uses a classical synchronous CPU interface with select, read and write signals, for easy connection with simple systems. For use in larger designs some form of AXI wrapper may be useful.

#### Register interface

The USB11 tranceiver does not use the standard ULPI register set, but a custom set that is compatible with the "ultra-embedded" register set.

In short, the USB11 tranceiver is accessed through a set of nine 32-bit registers:

| Offset | Name       | R/W  | Description|
| ------:| ----       | ---- |:---------- |
| 0x00   | REG_CTRL   | [RW] | Main control register (UT+MI, sof, etc) |
| 0x04   | REG_STAT   | [R]  | Line state, wire error status and frame time |
| 0x08   | REG\_IRQ_A | [W]  | IRQ Acknowledge: clear interrupt(s) |
| 0x0c   | REG\_IRQ_S | [R]  | IRQ Status: pending interrupt flags |
| 0x10   | REG\_IRQ_E | [RW] | IRQ Enable: CPU interrupt mask |
| 0x14   | REG_TXLEN  | [RW] | OUT packet data length |
| 0x18   | REG_TOKEN  | [RW] | Transaction setting (token, handshake |
| 0x1c   | REG_RXSTS  | [R]  | Transaction result (data length, handshake, etc) |
| 0x20   | REG_DATA   | [RW] | Read/Write data IN/OUT FIFOs |

Detailed information about the registers is on the [register interface](registers.md) page.

#### A Unix driver for the USB11 tranceiver

The register interface of the USB11 transceiver has been kept compatible with the registers of the [ultra-embedded transceiver](https://github.com/ultraembedded/core_usb_host/tree/master). The reason for this is that it enables the use of the Linux driver that was created for that transceiver:

[https://github.com/ultraembedded/core_usb_host/blob/master/linux/ue11-hcd.c](https://github.com/ultraembedded/core_usb_host/blob/master/linux/ue11-hcd.c)

As of July 2023, this has not been tested yet.

#### A small SoC for testing

By itself the USB11 transceiver is not enough for interfacing a USB device with an FPGA project, as layers 4 to 6 of the USB protocol and the device drivers are managed by host software. For testing and as a tiny host for use in larger projects a small Host controller has been added.

The Host controller consists of a tiny Risc-V (RV32I) core combined with 16KB of block RAM memory. It executes a small C program that implements the higher layers of the protocol.

Together with an UART and a USB11 transceiver it has been combined into a small system-on-a-chip for testing and evaluation purposes:

![a](doc/img/soc.png)

The example software recognises hubs, keyboards and mice. The total number of ports in the system must be less than 15. Multiple levels of hub can be used, as long as this maximum is not exceeded.

A possible extension of this SoC is the addition of a GPIO block for interfacing with a larger design. Another useful extension would be an IO block to interface with the PS/2 keyboard and mouse interface of FPGA-based retro-computer recreations.




