# USB HOST for FPGA

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

Compile the cross compiler

    cd riscv-kencc
    ./CONFIG.sh
    ./BUILD.sh

Compile the firmware (edit make.sh)

    cd usb_host/ucmem
    ./make.sh

Compile the bitstream (edit build.sh)

    cd usb_host/soc
    ./build.sh

Upload to ULX3S board and print messages

    fujprog -tb1M usb_host/soc/sys.bit
