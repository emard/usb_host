# USB HOST for FPGA

This is a fork of PNRU's great source
[usb_host](https://gitlab.com/pnru/usb_host).
emard wrote this readme and added soc/fw.sh script that
quickly replaces firmware in already compiled bitstream.

Supports hotplugging of the USB hub, keyboard and mouse.

Contains small RISC-V softcore using 16K BRAM.

Verilog source compiles with yosys/nextpnr for ECP5 ULX3S.
Firmware compiles with plan9 riscv-kencc C cross-compiler,
small and fast.

# Quick start

Bitstream with demo for ULX3S 12F:

    fujprog -tb1M soc/sys.bit

Prints reports at USB serial port.
Hotplug USB hub, keyboard and mouse.

# Compiling

Compile the cross compiler [riscv-kencc](https://gitlab.com/pnru/riscv-kencc)

    cd riscv-kencc
    ./CONFIG.sh
    ./BUILD.sh

Compile the bitstream (edit build.sh)

    cd usb_host/soc
    ./build.sh

Compile the firmware (edit make.sh) and replace it in the bitstream

    cd usb_host/soc
    ./fw.sh

Upload to ULX3S board and print messages

    fujprog -tb1M usb_host/soc/sys.bit
