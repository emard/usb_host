`timescale 1 ns/10 ps  // time-unit/precision
`define BIT_TIME (1000/12)
`define CLK_PER (1000/25)

module tb_soc ( );


   localparam MAX_BITS = 128;
   localparam MAX_BYTES = 128;
   localparam MAX_STRING = 128;

   reg  dp_force = 1'bz;
   reg  dn_force = 1'bz;
   reg [8*MAX_STRING-1:0] test;

   wire dp_sense;
   wire dn_sense;

   integer errors;
   integer warnings;

   localparam IN_BULK_MAXPACKETSIZE = 'd8;
   localparam OUT_BULK_MAXPACKETSIZE = 'd8;
   localparam VENDORID = 16'h1D50;
   localparam PRODUCTID = 16'h6130;

   reg clk;

   initial begin
      clk = 0;
   end

   wire power_on = 1'b0;
   always @(clk or power_on) begin
        #(`CLK_PER/2) clk <= ~clk;
   end

   wire led;
   wire usb_p;
   wire usb_n;
   wire usb_pu, usb_nu;
   wire RX;

   top u_soc (.clk_25mhz(clk),
              .usb_fpga_dp(usb_p),
              .usb_fpga_bd_dp(usb_p),
              .usb_fpga_bd_dn(usb_n),
              .usb_fpga_pu_dp(usb_pu),
              .usb_fpga_pu_dn(usb_nu),
              .ftdi_rxd(RX),
              .ftdi_txd(1'b1)
             );

   assign usb_p = dp_force;
   assign usb_n = dn_force;

`include "usb_tasks.v"
   usb_monitor mon(dp_sense, dn_sense);

   assign (pull1, weak0) usb_p = 1'b1; //usb_pu; // 1.5kOhm pullup, 10kOhm pulldown
   assign (pull1, weak0) usb_n = 1'b0; //usb_nu; // 1.5kOhm pullup, 10kOhm pulldown

   //assign (highz1, weak0) usb_p = 1'b0; // to bypass verilator error on above pulldown
   //assign (highz1, weak0) usb_n = 1'b0; // to bypass verilator error on above pulldown

   assign dp_sense = usb_p;
   assign dn_sense = usb_n;

   reg [ 6:0] address;
   reg [15:0] datain_toggle;
   reg [15:0] dataout_toggle;

   initial begin : u_host
      $timeformat(-6, 3, "us", 3);
      $dumpfile("tb.fst");
      $dumpvars;
      
      // first get dev desc
      #00866600
      //#02030600
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      #00141300
      //#00375300
      data_tx(PID_DATA1, {8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h08 }, 8, 8, `BIT_TIME);
      /*#00029000
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      // set addr
      #00549000
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      #00084000
      //handshake_tx(PID_NAK, 8, `BIT_TIME);
      data_tx(PID_DATA1, 0, 0, 8, `BIT_TIME);
      // second get dev desc
      #00975500
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      #00081300
      data_tx(PID_DATA1, {8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h08 }, 8, 8, `BIT_TIME);
      #00029000
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      // third get dev desc
      #00787000
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      #00081300
      data_tx(PID_DATA1, {8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h08, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h28, 8'h27, 8'h28}, 18, 8, `BIT_TIME);
      #00029000
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      */
      #09014000;
      //data_tx(PID_DATA0, {8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h28 }, 8, 8, `BIT_TIME*8);
      #15000000;
      $finish;
   end
   
  // display bytes received on the serial line
  always @(posedge clk)
  begin : rcvr
    reg [7:0] byte;
    integer i;
    if (RX==0) begin
      #1302
      byte = 8'h00;
      for(i=0; i<8; i=i+1)
      begin
        byte[i] = RX;
        #868;
      end
      $write("%c", byte);
    end
  end

endmodule
