`timescale 1 ns/10 ps  // time-unit/precision

`define CLK_PER (1000/25)

module tb_soc ( );

  // Setup up test bench usb tx and rx tasks
  //
  localparam MAX_BITS   = 128;
  localparam MAX_BYTES  = 128;
  localparam MAX_STRING = 128;

  reg  dp_force = 1'bz; // used by tx routines to send
  reg  dn_force = 1'bz;

  wire dp_sense; // used by rx routines to receive
  wire dn_sense;

`ifdef CHOOSE_SPEED
  // LS signalling: 1.5 MHz, reverse polarity
  `define BIT_TIME (664)
  assign dp_sense = usb_n;
  assign dn_sense = usb_p;
  assign usb_p = dn_force;
  assign usb_n = dp_force;
  assign (pull1, weak0) usb_p = 1'b0;
  assign (pull1, weak0) usb_n = 1'b1; 
`else
  // FS signalling: 12 MHz, normal polarity
  `define BIT_TIME (84)
  assign dp_sense = usb_p;
  assign dn_sense = usb_n;
  assign usb_p = dp_force;
  assign usb_n = dn_force;
  assign (pull1, weak0) usb_p = 1'b1; 
  assign (pull1, weak0) usb_n = 1'b0; 
`endif

  integer errors, warnings;

  `include "usb_reports.v"
  `include "usb_rx_tasks.v"
  `include "usb_tx_tasks.v"

  usb_monitor mon(dp_sense, dn_sense);

  // Connect the SoC to the test bench
  //
  reg clk;

  initial begin
    clk = 0;
  end

  wire power_on = 1'b0;
  always @(clk or power_on) begin
      #(`CLK_PER/2) clk <= ~clk;
  end

  wire usb_p, usb_n;
  wire RX;

  top u_soc (.clk_25mhz(clk),
            .usb_fpga_dp(usb_p),
            .usb_fpga_bd_dp(usb_p),
            .usb_fpga_bd_dn(usb_n),
            .usb_fpga_pu_dp(),
            .usb_fpga_pu_dn(),
            .ftdi_rxd(RX),
            .ftdi_txd(1'b1)
           );

  // Simulate a device through enumertion
  //
  reg [8*MAX_STRING-1:0] test;
  reg [7:0] cnt;
   
   initial begin : u_host
      $timeformat(-6, 3, "us", 3);
      $dumpfile("tb.fst");
      $dumpvars;

      // set addr
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // setup
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data0
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, 0, 0, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      
      // get dev desc 18 bytes
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // setup
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data0
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
            //handshake_tx(PID_NAK, 8, `BIT_TIME); // test not ready
            //raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, {8'h18, 8'h01, 8'h00, 8'h02, 8'h00, 8'h00, 8'h00, 8'h08 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA0, {8'h4b, 8'h21, 8'h50, 8'h72, 8'h00, 8'h01, 8'h00, 8'h00 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, {8'h00, 8'h01 }, 2, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // out   -- status
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data1 -- status
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      
      // get conf desc 9 bytes
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // setup
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data0
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, {8'h09, 8'h02, 8'h19, 8'h00, 8'h01, 8'h00, 8'h01, 8'he0 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA0, {8'h32}, 1, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // out   -- status
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data1 -- status
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      
      // set config
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // setup
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data0
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, 0, 0, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      
      // get config full 25 bytes
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // setup
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data0
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, {8'h09, 8'h02, 8'h19, 8'h00, 8'h01, 8'h00, 8'h01, 8'he0 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA0, {8'h32, 8'h09, 8'h04, 8'h00, 8'h00, 8'h01, 8'h09, 8'h00 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, {8'h00, 8'h00, 8'h07, 8'h05, 8'h81, 8'h03, 8'h01, 8'h00 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA0, {8'hff}, 1, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // out   -- status
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data1 -- status
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      
      // get hub desc 9 bytes
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // setup
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data0
      handshake_tx(PID_ACK, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA1, {8'h09, 8'h29, 8'h04, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00 }, 8, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // in
      data_tx(PID_DATA0, {8'h00}, 1, 8, `BIT_TIME);
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // ack
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // out   -- status
      raw_packet_rx(test, cnt, `BIT_TIME, 1000000); // data1 -- status
      handshake_tx(PID_ACK, 8, `BIT_TIME);

      #2_000_000
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
