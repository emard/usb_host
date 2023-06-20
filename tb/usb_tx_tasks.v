
// This file is derived from the test bench of the "usb_cdc" project:
// https://github.com/ulixxe/usb_cdc/tree/main/examples/common/hdl
// License is MIT:
// https://github.com/ulixxe/usb_cdc/blob/main/LICENSE

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

