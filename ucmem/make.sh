#!/bin/sh

ia entry.s
ic test.c
ic usb_hw.c
ic usb_core.c
ic os.c
il -H1 -l -T0x10000000 -c -t -a entry.i test.i os.i usb_hw.i usb_core.i >test.txt
il -H1 -l -T0x10000000 -c -t    entry.i test.i os.i usb_hw.i usb_core.i

#cp mem.hex old.hex
hexdump -e '1/4 "%08x\n"' -v i.out >mem.tmp
cat mem.tmp zero.hex | head -n 4096 >mem.hex

#ecpbram -i ../sys.cfg -o sys.cfg -f old.hex -t mem.hex
#ecppack sys.cfg ../sys.bit

