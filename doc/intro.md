### Introduction

These pages contain a summary of the USB Specification for USB 1.1; this is more or less the same as the USB 2.0 Specification minus the High Speed part.

The summary is intended as the backdrop for a source code walk-through for a small FPGA-based implementation. It consists of the **"USB11"** transceiver and of a tiny USB Host Controller implemented around a 32-bit Risc-V microcontroller.

The code is quite small:

| Component   | Language  | Source size | Binary size |
|:----------- |:--------- |:----------- |:----------- |
| Transceiver | Verilog   |  ~800 lines | ~2K LUTs    |
| RV32I SoC   | Verilog   |  ~400 lines | ~2K LUTs    |
| Host S/W    | C         | ~1200 lines | 12KB BRAM   |

The main purpose of this project is to give FPGA-based projects access to USB devices with minimal supporting hardware. The base example is providing a PS/2 compatible keyboard and mouse to retro-computer projects.

### Example implementation

The code has been verified using the ULX3S FPGA board. This is a popular development board based around a Lattice ECP5 series FPGA.

![](https://radiona.org/ulx3s/assets/img/legend.png)

The USB2 port is connected directly (via a few resistors and diodes) to the FPGA. This circuit is easy to replicate on other boards using a [PMOD](https://www.crowdsupply.com/radiona/ulx3s/updates/introducing-the-ulx3s-pmod-set)

### Source code file overview

#### Transceiver

The source code for the USB11 transceiver is contained in 3 files of about 300 lines each:

| File        | Deals with          |
|:----------- |:------------------- |
| usb11/phy.v | Signal conditioning |
|             | Line clock & PLL, NRZI & bit-stuffing |
|             | Packet engine       |
| usb11/sie.v | CRC calculation     |
|             | Transaction engine  |
| usb11/ctl.v | Data FIFOs          |
|             | Frame engine        |
|             | Register interface to CPU |

#### Host controller

The source code for the Host controller is mainly contained in one file, which implements the CPU and the RAM. The SoC and PLL files are much shorter.

| File        | Deals with          |
|:----------- |:------------------- |
| soc/rv32i.v | Risc-V CPU & RAM    |
| soc/soc.v   | System & UART       |
| soc/pll.v   | 48MHz system clock  |

Of course this component can be replaced by any other softcore to match the surrounding project, if so desired.

#### Controller software

The core controller software is split over six files that implement the higher level aspects of the USB protocol. These higher levels are much less time critical than the aspects that the transceiver deals with (milliseconds not microseconds).

| File        | Deals with          |
|:----------- |:------------------- |
| mem/req.c   | Requests            |
| mem/task.c  | Tasks, root port    |
| mem/enum.c  | Enumeration         |
| mem/hub.c   | Hub driver          |
| mem/hid.c   | Kbd & mouse driver  |
| mem/lib.c   | printf & malloc     |

The compiler used in development is the [Plan9 RiscV compiler](https://gitlab.com/pnru/riscv-kencc) ("KenCC"). This is a straightforward lightweight cross-compiler that can itself be compiled with GCC or Clang on any Posix system in a few seconds.

The Host controller code is plain C and should also (cross-)compile using GCC, with a few minor tweaks (such as a different syntax for packing structs, or for the short assembler startup routine).



