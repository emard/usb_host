TEXT entry(SB),0,$-4
	MOV	$0x10004000,R2   // 0x10002000
	MOV	$setSB(SB),R3

	MOV	$edata(SB),R8	// clear bss area
	MOV	$end(SB),R5
	MOV	R0,0(R8)
	ADD	$4,R8,R8
	BLT	R5,R8,-2(PC)

	JAL	R1,main(SB)
	JMP	0(PC)

TEXT    put_ep0+0(SB),0,$-4
        MOVW    len+4(FP),R14
        MOVW    usb+0(SB),R12

        MOVW    0(R12),R9
        AND     $2,R9
        BNE     R0,R9,-2(PC)
        MOVBU   0(R8),R10
        MOVW    R10,16(R12)
        ADD     $1,R8,R8
        ADD     $-1,R14,R14
	BNE     R0,R14,-7(PC)
        JMP     0(R1)

TEXT    get_ep0+0(SB),0,$-4
        MOVW    len+4(FP),R14
        MOVW    usb+0(SB),R12

        MOVW    0(R12),R9
        AND     $2,R9
        BNE     R0,R9,-2(PC)
        MOVBU   16(R12),R10
        MOVW    R10,0(R8)
        ADD     $1,R8,R8
        ADD     $-1,R14,R14
        BNE     R0,R14,-7(PC)
        JMP     0(R1)

	END
