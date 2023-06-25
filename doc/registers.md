### Registers

The registers of the PHY/SIE controller have been chosen to be compatible with those of the: [ultra-embedded usb host controller](https://github.com/ultraembedded/core_usb_host)

The status register has one more bit defined: bit 3 has been added and is a debounced device connection bit. In future, it may make sense to combine the REG\_IRQ_A and REG\_IRQ_S registers into one RW regsiter.

Note that these registers are 32 bits wide and do not support partial (byte or halfword) access. Undefined bits read as zero and accept any value on write.

##### Register Map

| Offset | Name       | R/W  | Description|
| ------:| ----       | ---- |:---------- |
| 0x00   | REG_CTRL   | [RW] | Main control register (utmi, sof, etc) |
| 0x04   | REG_STAT   | [R]  | Line state, wire error status and frame time |
| 0x08   | REG\_IRQ_A | [W]  | Clear interrupt mask |
| 0x0c   | REG\_IRQ_S | [R]  | Pending interrupt mask |
| 0x10   | REG\_IRQ_E | [RW] | Enable interrupt mask |
| 0x14   | REG_TXLEN  | [RW] | OUT packet data length |
| 0x18   | REG_TOKEN  | [RW] | Transaction setting (token, handshake |
| 0x1c   | REG_RXSTS  | [R]  | Transcation result (data length, handshake, etc) |
| 0x20   | REG_DATA   | [RW] | Read/Write data IN/OUT FIFOs |

##### Register: REG_CTRL

This register sets the main control parameters of the PHY/SIE hardware. Bits [4:3] define the UTMI tranceiver mode. Mode 0 means high-speed (USB2) mode,
mode 1 means full-speed mode, mode 2 means low-speed mode and mode 3 is a special mode for low-speed signalling to a full-speed hub. The PHY/SIE hardware only supports modes 1, 2 and 3.

| Bits | Name | Description    |
| ----:| ---- |:-------------- |
| 0    | CTL_SOF_EN   | Enable SOF generation & guarding |
| 2:1  | CTL_OPMODE0  | UTMI PHY Output Mode |
| 4:3  | CTL_XCVRSEL  | UTMI PHY Transceiver Select |
| 5    | CTL_TERMSEL  | UTMI PHY Termination Select |
| 6    | CTL_DP_PULLD | UTMI PHY Pulldown Enable D+ |
| 7    | CTL_DN_PULLD | UTMI PHY Pulldown Enable D- |
| 8    | CTL_TX_FLSH  | Flush Tx FIFO (auto-reset) |

##### Register: REG_STAT

| Bits | Name         | Description    |
| ----:| ----         |:-------------- |
| 0     | STAT_DP     | Line state D+ |
| 1     | STAT_DN     | Line state D- |
| 2     | STAT_PHYERR | Wire protocol error; write to REG_CTRL to reset|
| 3     | STAT_DETECT | Device connected (debounced) |
| 31:16 | STAT_TIME   | Current frame time in us (0 - 48000) |

##### Register: REG\_IRQ_A, REG\_IRQ_S, REG\_IRQ_E

All 3 interrupt registers have the same 4 bits defined. Depending on the register, the report the current state of an interrupt (REG\_IRQ_S), clear a pending interrupt (REG\_IRQ_A) or enable passing the interrupt to the CPU (REG\_IRQ_E). All four interrupts share a single CPU interrupt line. The current control software does not enable any interrupt.

Note that FRAME interrupts only occur when the CTL_SOF_EN bit has been set.

| Bits | Name       | Description    |
| ----:| ----       |:-------------- |
| 0    | IRQ_FRAME  | A new frame started (= SOF transmitted |
| 1    | IRQ_DONE   | Transaction completed |
| 2    | IRQ_ERR    | Transaction had an error (CRC, timeout, etc.) |
| 3    | IRQ_DETECT | The STAT_DETECT bit changed state |

##### Register: REG_TXLEN

This register gives the length of the data in the OUT FIFO. This FIFO is 64 bytes long, so the maximum usable length is 64. A zero-length package is legal.

| Bits | Name   | Description    |
| ----:| ----   |:-------------- |
| 15:0 | TX_LEN | OUT transaction data length |

##### Register: REG_TOKEN

This register defines the transaction the SIE should undertake. A transaction consists of 2 or 3 packets. The host starts by sending a transaction token. This is followed by a data packet sent by either the host or the device. In most cases this is followed by a handshake packet in response.

A new transaction is started by the CPU by setting the TKN_START bit. A transaction might not start immediately, as the line may be in its SOF guard period or another transaction is already pending.

| Bits  | Name      | Description    |
| ----: | ----      |:-------------- |
| 31    | TXN_START | Transaction start request (auto-reset)|
| 30    | TXN_IN    | IN transaction (1) or OUT/SETUP transaction (0) |
| 29    | TXN_HS    | Send or wait for handshake packet |
| 28    | TXN_DATA1 | Send DATA1 (1) or DATA0 (0) |
| 23:16 | TXN_PID   | Token PID (SETUP=0x2d, OUT=0xE1 or IN=0x69) |
| 15:9  | TXN_ADDR  | Token device address |
| 8:5   | TXN_EP    | Token endpoint address |

##### Register: REG_RXSTS

This register reports the result of the transaction. After requesting a transaction, the CPU should first wait for the transaction to be queued and then wait for the tranasction to complete.

Once the transaction is complete, the RX_RESP field will report the PID that was received (a DATAx or a handshake PID). If there was a CRC or timeout error, the respective bits are set. The RX_LEN field reports the number of bytes that was received. A zero length is legal. The full speed protocol allows packets of up to 64 bytes long, so the practical range is 0-64.

| Bits  | Name       | Description    |
| ----: | ----       |:-------------- |
| 31    | TXN_QUEUED | Transaction start pending |
| 30    | RX_CRCERR  | CRC error detected |
| 29    | RX_TIMEOUT | Response timeout detected (no response) |
| 28    | SIE_IDLE   | SIE idle: transaction complete |
| 23:16 | RX_RESP    | Received response PID (DATAx or handshake) |
| 15:0  | RX_LEN     | IN transaction data length |

##### Register: REG_DATA

The IN and OUT FIFOs are accessed via single byte reads and writes. The IN FIFO is cleared automatically at the start of each transaction.

| Bits | Name | Description    |
| ----:| ---- |:-------------- |
| 7:0  | DATA | Date byte |


