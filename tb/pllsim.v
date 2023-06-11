
`timescale 1ps/1ps

module PLL
(
    input  wire clkin,   // 25 MHz, 0 deg
    output wire pll96,   // 96 MHz, 0 deg
    output wire locked
);

    reg  clk1 = 0;
    always #5208 clk1 = !clk1;

    assign pll96  = clk1;
    
    reg [3:0] ctr = 0;
    assign locked = (ctr==4'hf);
    
    always @(posedge clk1) begin
      if (!locked) ctr <= ctr + 1;
    end

endmodule
