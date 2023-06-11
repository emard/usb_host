#!/bin/sh

yosys -p "synth_ecp5 -json sys.json"  \
  ../usb11/phy.v ../usb11/sie.v ../usb11/regs.v \
  rv32i.v pll.v soc.v

nextpnr-ecp5 --12k --package CABGA381 --json sys.json --lpf ulx3s_v20.lpf --textcfg sys.cfg

ecppack --compress sys.cfg sys.bit

