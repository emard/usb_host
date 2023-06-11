// Simple SoC to test the USB host system. Contains a RV32I microcontroller,
// the USB controller and a UART.

(* top *)
module top
(
   input wire clk_25mhz,        // 25MHz clock

   output wire [27:0] gp,       // test vector
   output wire [7:0] led,
   
   input  wire usb_fpga_dp,     // D differential in
   inout  wire usb_fpga_bd_dp,  // D+
   inout  wire usb_fpga_bd_dn,  // D-
   inout  wire usb_fpga_pu_dp,  // 1 = 1.5K up, 0 = 15K down, z = float
   inout  wire usb_fpga_pu_dn,  // 1 = 1.5K up, 0 = 15K down, z = float
   
   output wire ftdi_rxd,
   input  wire ftdi_txd
);
   
  assign gp[26] = usb_fpga_bd_dp;
  assign gp[27] = usb_fpga_bd_dn;
   
   // Clock generation
   //
   wire             clk_96mhz;
   wire             lock;
   
   PLL pll(
    .clkin(clk_25mhz),
    .pll96(clk_96mhz),
    .locked(lock)
   );

   reg clk_pll = 0;
   always @(posedge clk_96mhz) clk_pll <= ~clk_pll;

   reg [6:0]        rstn_sync = 0;
   wire             rstn = rstn_sync[0];

   always @(posedge clk_pll or negedge lock) begin
      if (~lock) begin
         rstn_sync <= 'd0;
      end else begin
         rstn_sync <= {1'b1, rstn_sync[6:1]};
      end
   end
  
  // Microcontroller
  //
  wire [31:0] cpu_ad, cpu_di, cpu_do;
  wire  [1:0] cpu_md;
  wire        cpu_wr = (cpu_md == 2'b01);
  wire        cpu_rd = (cpu_md == 2'b00);

  RV32I cpu (
    .CLK(clk_pll),
    .RST_X(rstn),
    
    .w_mic_addr(cpu_ad),
    .w_data(cpu_di),
    .w_mic_wdata(cpu_do),
    .w_mic_req(cpu_md),
    .w_mic_ctrl(),
    .w_stall(1'b0)
  );

  assign cpu_di = sie_sel  ? sie_di  :
                  uart_sel ? uart_di :
                  32'b0;
  wire sie_sel = (cpu_ad[31:8] == 24'h210000);
  
  // USB host PHY + SIE hardware
  //
  wire [31:0] sie_di;

  wire       utmi_txvalid,    utmi_txready,    utmi_rxvalid,    utmi_rxactive, utmi_rxerror;
  wire       utmi_termselect, utmi_dppulldown, utmi_dmpulldown;
  wire [1:0] utmi_linestate,  utmi_op_mode,    utmi_xcvrselect;
  wire [7:0] utmi_data_out,   utmi_data_in;

  PHY utmi_phy (
    .clk_i(clk_pll),
    .rst_i(~rstn),
//    .led_o(led),
    
    .utmi_data_out_i (utmi_data_out),
    .utmi_txvalid_i  (utmi_txvalid),
    .utmi_txready_o  (utmi_txready),
    
    .utmi_data_in_o  (utmi_data_in),
    .utmi_rxvalid_o  (utmi_rxvalid),
    .utmi_rxactive_o (utmi_rxactive),
    .utmi_rxerror_o  (utmi_rxerror),
    .utmi_linestate_o(utmi_linestate),

    .utmi_op_mode_i   (utmi_op_mode),
    .utmi_xcvrselect_i(utmi_xcvrselect),
    .utmi_termselect_i(utmi_termselect),
    .utmi_dppulldown_i(utmi_dppulldown),
    .utmi_dmpulldown_i(utmi_dmpulldown),
    
    .usb_fpga_dif(usb_fpga_dp),
    .usb_fpga_dp(usb_fpga_bd_dp),
    .usb_fpga_dn(usb_fpga_bd_dn),
    .usb_fpga_pu_dp(usb_fpga_pu_dp),
    .usb_fpga_pu_dn(usb_fpga_pu_dn)
  );

  REGS usb_regs (
    .clk_i(clk_pll),
    .rst_i(~rstn),
    .led_o(led),

    .m_sel(sie_sel),
    .m_addr(cpu_ad[5:2]),
    .m_data_i(cpu_do),
    .m_data_o(sie_di),
    .m_rd(cpu_rd),
    .m_wr(cpu_wr),
    .m_intr_o(),

    .utmi_data_in_i  (utmi_data_in),
    .utmi_rxvalid_i  (utmi_rxvalid),
    .utmi_rxactive_i (utmi_rxactive),
    .utmi_rxerror_i  (utmi_rxerror),
    .utmi_linestate_i(utmi_linestate),

    .utmi_data_out_o (utmi_data_out),
    .utmi_txvalid_o  (utmi_txvalid),
    .utmi_txready_i  (utmi_txready),

    .utmi_op_mode_o   (utmi_op_mode),
    .utmi_xcvrselect_o(utmi_xcvrselect),
    .utmi_termselect_o(utmi_termselect),
    .utmi_dppulldown_o(utmi_dppulldown),
    .utmi_dmpulldown_o(utmi_dmpulldown)
  );

  // UART + Timer
  //
  wire uart_sel = (cpu_ad[31:8] == 24'h200000);
  wire [31:0] uart_di;
  
  UART uart(
    .clk_i(clk_pll),
    .rstn(rstn),
    
    .m_sel(uart_sel),
    .m_addr(cpu_ad[5:2]),
    .m_data_i(cpu_do),
    .m_data_o(uart_di),
    .m_rd(cpu_rd),
    .m_wr(cpu_wr),

    .RXD(ftdi_txd),
    .TXD(ftdi_rxd)
  );

endmodule

// UART
//
`ifdef __ICARUS__
`define BAUDCNT 42    // 1.15 Mb/s
`else
`define BAUDCNT 48    // 1Mb/s
//`define BAUDCNT 416 // 115K2
`endif

module UART(
    input  wire    clk_i,
    input  wire    rstn,

    // CPU memory interface
    input  wire        m_sel,
    input  wire [3:0]  m_addr,
    input  wire [31:0] m_data_i,
    output wire [31:0] m_data_o,
    input  wire        m_rd,
    input  wire        m_wr,
    
    // Serial interface
    output reg         TXD,
    input  wire        RXD
  );
  
  // Create 3 registers: 0 = data, 1 = status and 2 = ms counter
  //
  wire uart_r0  = m_sel & (m_addr == 4'h0);
  wire uart_r1  = m_sel & (m_addr == 4'h1);
  wire uart_r2  = m_sel & (m_addr == 4'h2);
  wire uart_we  = (uart_r0 & m_wr);

`ifdef __ICARUS__
  wire is_sim = 1'b1;
`else
  wire is_sim = 1'b0;
`endif
   
  assign m_data_o = uart_r0 ? {24'b0,         rx_data}           :
                    uart_r1 ? {39'b0, is_sim, rx_full, tx_empty} :
                    uart_r2 ? ms_counter : 32'b0;

  // UART transmitter
  //
  reg  [ 8:0] tx_shift;
  reg  [31:0] tx_timer;
  reg  [ 3:0] tx_bitcnt;
  reg         tx_empty;

  always @(posedge clk_i) begin
    if(!rstn) begin
      TXD       <= 1'b1;
      tx_empty  <= 1'b1;
      tx_shift  <= 9'h1ff;
      tx_timer  <= 1'b0;
      tx_bitcnt <= 1'b0;
    end else if (tx_empty) begin
      TXD       <= 1'b1;
      tx_timer  <= 0;
      if (uart_we) begin
          tx_empty  <= 1'b0;
          tx_shift  <= { m_data_i[7:0], 1'b0 };
          tx_bitcnt <= 'd10;
      end
    end else if (tx_timer >= `BAUDCNT) begin
      TXD       <= tx_shift[0];
      tx_empty  <= (tx_bitcnt == 1);
      tx_shift  <= {1'b1, tx_shift[8:1]};
      tx_timer  <= 1'b1;
      tx_bitcnt <= tx_bitcnt - 'd1;
    end else begin
      tx_timer  <= tx_timer + 'd1;
    end
  end

  // UART receiver
  //
  reg     [7:0] rx_data;
  reg    [11:0] start_tmr;
  reg    [12:0] rx_timer;
  reg     [3:0] state;

  wire rx_full = (state == 'd8);

  always @(posedge clk_i) begin
      if (!rstn) start_tmr <= 0;
      else       start_tmr <= (RXD) ? 'd0 : start_tmr + 'd1;
  end

  localparam S_IDLE = 4'd0, S_START = 4'd1, S_STOP = 4'd9;
  
  always @(posedge clk_i) begin
    if(!rstn) begin
      rx_timer <= 'd1;
      state    <= S_IDLE;
    end else if (state == S_IDLE) begin
      rx_timer <= `BAUDCNT;
      state    <= (start_tmr == (`BAUDCNT >> 1)) ? S_START : state;
    end else begin
      if (rx_timer != `BAUDCNT) begin
        rx_timer <= rx_timer + 1;
      end else begin
        state    <= (state == S_STOP) ? S_IDLE : state + 1;
        rx_data  <= {RXD, rx_data[7:1]};
        rx_timer <= 'd1;
      end
    end
  end

  // milli-second resolution counter register
  //
  reg [31:0] ms_counter;
  reg [15:0] ms_timer;

  always @(posedge clk_i)
  if (~rstn) begin
      ms_counter <= 'd0;
      ms_timer <= 'd0;
  end else begin
      ms_timer <= ms_timer + 'd1;
      if (ms_timer == 16'd48000) begin
        ms_timer <= 'd0;
        ms_counter <= ms_counter + 'd1;
      end
  end

endmodule
