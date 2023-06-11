#!/bin/sh

iverilog tb_soc.v pllsim.v usb_monitor.v \
         ../soc/microc.v ../soc/soc.v ../usb11/*.v

#vvp a.out -fst

