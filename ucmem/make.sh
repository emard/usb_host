#!/bin/sh

ia entry.s
ic root.c
ic enum.c
ic hub.c
ic hid.c
ic prn.c
ic os.c
il -H1 -l -T0x10000000 -c -t -a *.i >test.txt
il -H1 -l -T0x10000000 -c -t    *.i
rm *.i

#cp mem.hex old.hex
hexdump -e '1/4 "%08x\n"' -v i.out >mem.tmp
cat mem.tmp zero.hex | head -n 4096 >mem.hex
rm mem.tmp

#ecpbram -i ../sys.cfg -o sys.cfg -f old.hex -t mem.hex
#ecppack sys.cfg ../sys.bit

