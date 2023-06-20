#!/bin/sh

iverilog tb_soc.v pllsim.v usb_monitor.v \
         ../soc/rv32i.v ../soc/soc.v ../usb11/*.v

vvp a.out -fst

