
`define max(a,b)((a) > (b) ? (a) : (b))
`define min(a,b)((a) < (b) ? (a) : (b))

`include "usb_rx_tasks.v"

localparam [7:0] REQ_GET_STATUS = 'd0,
                 REQ_CLEAR_FEATURE = 'd1,
                 REQ_RESERVED1 = 'd2,
                 REQ_SET_FEATURE = 'd3,
                 REQ_RESERVED2 = 'd4,
                 REQ_SET_ADDRESS = 'd5,
                 REQ_GET_DESCRIPTOR = 'd6,
                 REQ_SET_DESCRIPTOR = 'd7,
                 REQ_GET_CONFIGURATION = 'd8,
                 REQ_SET_CONFIGURATION = 'd9,
                 REQ_GET_INTERFACE = 'd10,
                 REQ_SET_INTERFACE = 'd11,
                 REQ_SYNCH_FRAME = 'd12,
                 REQ_SET_LINE_CODING = 'h20,
                 REQ_GET_LINE_CODING = 'h21,
                 REQ_SET_CONTROL_LINE_STATE = 'h22,
                 REQ_SEND_BREAK = 'h23;

localparam       CTRL_MAXPACKETSIZE = 'd8;
localparam [3:0] ENDP_CTRL = 'd0,
                 ENDP_BULK = 'd1,
                 ENDP_INT = 'd2;

localparam [8*'h12-1:0] DEV_DESCR = { // Standard Device Descriptor, USB2.0 9.6.1, page 261-263, Table 9-8
                                      8'h12, // bLength
                                      8'h01, // bDescriptorType (DEVICE)
                                      8'h00, // bcdUSB[0]
                                      8'h02, // bcdUSB[1] (2.00)
                                      8'h02, // bDeviceClass (Communications Device Class)
                                      8'h00, // bDeviceSubClass (specified at interface level)
                                      8'h00, // bDeviceProtocol (specified at interface level)
                                      CTRL_MAXPACKETSIZE[7:0], // bMaxPacketSize0
                                      VENDORID[7:0], // idVendor[0]
                                      VENDORID[15:8], // idVendor[1]
                                      PRODUCTID[7:0], // idProduct[0]
                                      PRODUCTID[15:8], // idProduct[1]
                                      8'h00, // bcdDevice[0]
                                      8'h01, // bcdDevice[1] (1.00)
                                      8'h00, // iManufacturer (no string)
                                      8'h00, // iProduct (no string)
                                      8'h00, // iSerialNumber (no string)
                                      8'h01}; // bNumConfigurations

localparam [8*'h43-1:0] CONF_DESCR = { // Standard Configuration Descriptor, USB2.0 9.6.3, page 264-266, Table 9-10
                                       8'h09, // bLength
                                       8'h02, // bDescriptorType (CONFIGURATION)
                                       8'h43, // wTotalLength[0]
                                       8'h00, // wTotalLength[1]
                                       8'h02, // bNumInterfaces
                                       8'h01, // bConfigurationValue
                                       8'h00, // iConfiguration (no string)
                                       8'h80, // bmAttributes (bus powered, no remote wakeup)
                                       8'h32, // bMaxPower (100mA)

                                       // Standard Interface Descriptor, USB2.0 9.6.5, page 267-269, Table 9-12
                                       8'h09, // bLength
                                       8'h04, // bDescriptorType (INTERFACE)
                                       8'h00, // bInterfaceNumber
                                       8'h00, // bAlternateSetting
                                       8'h01, // bNumEndpoints
                                       8'h02, // bInterfaceClass (Communications Device Class)
                                       8'h02, // bInterfaceSubClass (Abstract Control Model)
                                       8'h01, // bInterfaceProtocol (AT Commands in ITU V.25ter)
                                       8'h00, // iInterface (no string)

                                       // Header Functional Descriptor, CDC1.1 5.2.3.1, Table 26
                                       8'h05, // bFunctionLength
                                       8'h24, // bDescriptorType (CS_INTERFACE)
                                       8'h00, // bDescriptorSubtype (Header Functional)
                                       8'h10, // bcdCDC[0]
                                       8'h01, // bcdCDC[1] (1.1)

                                       // Call Management Functional Descriptor, CDC1.1 5.2.3.2, Table 27
                                       8'h05, // bFunctionLength
                                       8'h24, // bDescriptorType (CS_INTERFACE)
                                       8'h01, // bDescriptorSubtype (Call Management Functional)
                                       8'h00, // bmCapabilities (no call mgmnt)
                                       8'h01, // bDataInterface

                                       // Abstract Control Management Functional Descriptor, CDC1.1 5.2.3.3, Table 28
                                       8'h04, // bFunctionLength
                                       8'h24, // bDescriptorType (CS_INTERFACE)
                                       8'h02, // bDescriptorSubtype (Abstract Control Management Functional)
                                       8'h00, // bmCapabilities (none)

                                       // Union Functional Descriptor, CDC1.1 5.2.3.8, Table 33
                                       8'h05, // bFunctionLength
                                       8'h24, // bDescriptorType (CS_INTERFACE)
                                       8'h06, // bDescriptorSubtype (Union Functional)
                                       8'h00, // bMasterInterface
                                       8'h01, // bSlaveInterface0

                                       // Standard Endpoint Descriptor, USB2.0 9.6.6, page 269-271, Table 9-13
                                       8'h07, // bLength
                                       8'h05, // bDescriptorType (ENDPOINT)
                                       {4'h8, ENDP_INT}, // bEndpointAddress (2 IN)
                                       8'h03, // bmAttributes (interrupt)
                                       8'h08, // wMaxPacketSize[0]
                                       8'h00, // wMaxPacketSize[1]
                                       8'hFF, // bInterval (255 ms)

                                       // Standard Interface Descriptor, USB2.0 9.6.5, page 267-269, Table 9-12
                                       8'h09, // bLength
                                       8'h04, // bDescriptorType (INTERFACE)
                                       8'h01, // bInterfaceNumber
                                       8'h00, // bAlternateSetting
                                       8'h02, // bNumEndpoints
                                       8'h0A, // bInterfaceClass (data)
                                       8'h00, // bInterfaceSubClass
                                       8'h00, // bInterfaceProtocol
                                       8'h00, // iInterface (no string)

                                       // Standard Endpoint Descriptor, USB2.0 9.6.6, page 269-271, Table 9-13
                                       8'h07, // bLength
                                       8'h05, // bDescriptorType (ENDPOINT)
                                       {4'h0, ENDP_BULK}, // bEndpointAddress (1 OUT)
                                       8'h02, // bmAttributes (bulk)
                                       OUT_BULK_MAXPACKETSIZE[7:0], // wMaxPacketSize[0]
                                       8'h00, // wMaxPacketSize[1]
                                       8'h00, // bInterval

                                       // Standard Endpoint Descriptor, USB2.0 9.6.6, page 269-271, Table 9-13
                                       8'h07, // bLength
                                       8'h05, // bDescriptorType (ENDPOINT)
                                       {4'h8, ENDP_BULK}, // bEndpointAddress (1 IN)
                                       8'h02, // bmAttributes (bulk)
                                       IN_BULK_MAXPACKETSIZE[7:0], // wMaxPacketSize[0]
                                       8'h00, // wMaxPacketSize[1]
                                       8'h00}; // bInterval

`define rev(n) \
function automatic [n-1:0] rev``n;\
   input [n-1:0] data;\
   integer       i;\
   begin\
      for (i = 0; i <= n-1; i = i + 1) begin\
         rev``n[i] = data[n-1-i];\
               end\
   end\
endfunction

`rev(5)
`rev(8)
`rev(16)

task automatic raw_tx
  (
   input integer        length,
   input [MAX_BITS-1:0] dp_data,
   input [MAX_BITS-1:0] dn_data,
   input time           bit_time
   );
   integer              i;
   begin
      #bit_time;
      for (i = length-1; i >= 0; i = i-1) begin
         dp_force = dp_data[i];
         dn_force = dn_data[i];
         #bit_time;
      end
      dp_force = 1'bZ;
      dn_force = 1'bZ;
   end
endtask

task automatic nrzi_tx
  (
   input [8*MAX_BITS-1:0] nrzi_data,
   input time             bit_time
   );
   integer                i;
   begin
      #bit_time;
      for (i = MAX_BITS-1; i >= 0; i = i-1) begin
         if (nrzi_data[8*i +:8] == "J" || nrzi_data[8*i +:8] == "j") begin
            dp_force = 1'b1;
            dn_force = 1'b0;
            #bit_time;
         end else if (nrzi_data[8*i +:8] == "K" || nrzi_data[8*i +:8] == "k") begin
            dp_force = 1'b0;
            dn_force = 1'b1;
            #bit_time;
         end else if (nrzi_data[8*i +:8] == "0") begin
            dp_force = 1'b0;
            dn_force = 1'b0;
            #bit_time;
         end else if (nrzi_data[8*i +:8] == "1") begin
            dp_force = 1'b1;
            dn_force = 1'b1;
            #bit_time;
         end
      end
      dp_force = 1'bZ;
      dn_force = 1'bZ;
   end
endtask

task automatic usb_tx
  (
   input [8*MAX_BYTES-1:0] data,
   input integer           bytes,
   input integer           sync_length,
   input time              bit_time
   );
   reg                     nrzi_bit;
   integer                 bit_counter;
   integer                 i,j;
   begin
      #bit_time;
      if (!(dp_sense === 1 && dn_sense === 0)) begin
         `report_error("usb_tx(): Data lines must be Idle before Start Of Packet")
      end

      // Start Of Packet and sync pattern
      nrzi_bit = 1;
      for (i = 1; i < sync_length; i = i+1) begin
         nrzi_bit = ~nrzi_bit;
         dp_force = nrzi_bit;
         dn_force = ~nrzi_bit;
         #bit_time;
      end
      bit_counter = 1;
      #bit_time;

      // data transmission
      for (j = bytes-1; j >= 0; j = j-1) begin
         for (i = 0; i < 8; i = i+1) begin
            if (data[8*j+i] == 0) begin
               nrzi_bit = ~nrzi_bit;
               bit_counter = 0;
            end else
              bit_counter = bit_counter + 1;
            dp_force = nrzi_bit;
            dn_force = ~nrzi_bit;
            #bit_time;
            if (bit_counter == 6) begin
               nrzi_bit = ~nrzi_bit;
               bit_counter = 0;
               dp_force = nrzi_bit;
               dn_force = ~nrzi_bit;
               #bit_time;
            end
         end
      end

      // End Of Packet
      dp_force = 0;
      dn_force = 0;
      #(2*bit_time); // USB 2.0 Table 7-2
      dp_force = 1;
      dn_force = 0;
      #bit_time;
      dp_force = 1'bZ;
      dn_force = 1'bZ;
   end
endtask

task automatic handshake_tx
  (
   input [3:0]   pid,
   input integer sync_length,
   input time    bit_time
   );
   begin
      usb_tx ({~pid, pid}, 1, sync_length, bit_time);
   end
endtask

task automatic token_tx
  (
   input [3:0]   pid,
   input [6:0]   addr,
   input [3:0]   endp,
   input integer sync_length,
   input time    bit_time
   );
   reg [4:0]     crc;
   begin
      crc = ~rev5(crc5({endp, addr}, 11));
      usb_tx ({~pid, pid, endp[0], addr, crc, endp[3:1]}, 3, sync_length, bit_time);
   end
endtask

task automatic data_tx
  (
   input [3:0]             pid,
   input [8*MAX_BYTES-1:0] data,
   input integer           bytes,
   input integer           sync_length,
   input time              bit_time
   );
   reg [15:0]              crc;
   begin
      if (bytes > 0)
        crc = ~rev16(crc16(data, bytes));
      else
        crc = 16'h0000;
      if (bytes == MAX_BYTES)
        usb_tx ({~pid, pid, data, crc}, bytes+3, sync_length, bit_time);
      else begin
         data[8*bytes +:8] = {~pid, pid};
         usb_tx ({data, crc[7:0], crc[15:8]}, bytes+3, sync_length, bit_time);
      end
   end
endtask

