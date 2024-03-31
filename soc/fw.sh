#!/bin/sh -e

# for fast firmware development
# this script
# compiles firmware
# embeds it into the existing bistream without synthesizing again
# uploads new bitstream to ulx3s board
# 

cd ../ucmem
./make.sh
cd ../soc

ecpbram --verbose --generate random_mem.hex --seed 0 --width 32 --depth 4096
ecpbram --verbose --input sys_empty.cfg --from random_mem.hex --to ../ucmem/mem.hex --output sys.cfg
ecppack --compress sys.cfg sys.bit

echo fujprog -tb1M sys.bit
