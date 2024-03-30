#!/bin/sh

ecpbram --verbose --generate random_mem.hex --seed 0 --width 32 --depth 4096

yosys -p "synth_ecp5 -json sys.json"  \
  ../usb11/phy.v ../usb11/sie.v ../usb11/regs.v \
  rv32i.v pll.v soc.v

nextpnr-ecp5 --12k --package CABGA381 --json sys.json --lpf ulx3s_v20.lpf --textcfg sys_empty.cfg

ecpbram --verbose --input sys_empty.cfg --from random_mem.hex --to ../ucmem/mem.hex --output sys.cfg

ecppack --compress sys.cfg sys.bit
