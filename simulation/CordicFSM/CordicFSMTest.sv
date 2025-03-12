module CordicFSMTest (
    input logic clk_i,  // clock
    input logic reset_i,  // reset
    input logic start_i,  // start the computation
    input logic signed [23:0] sin_i,  // sine
    input logic signed [23:0] cos_i,  // cosine
    output logic signed [26:0] phi_o,  // phase
    output logic signed [24:0] r_o,  // radius
    output logic done_o  // computation is done, result is valid
);

  logic signed [23:0] angle_table[24] = '{
      2097151,
      1238020,
      654136,
      332049,
      166669,
      83415,
      41718,
      20860,
      10430,
      5215,
      2607,
      1303,
      651,
      325,
      162,
      81,
      40,
      20,
      10,
      5,
      2,
      1,
      0,
      0
  };

  CordicFSM #(
      .BIT_WIDTH_IN(24),
      .BIT_WIDTH_OUT(27),
      .PI(8388607)
  ) dut (
      .clk_i(clk_i),
      .start_i(start_i),
      .reset_i(reset_i),
      .sin_i(sin_i),
      .cos_i(cos_i),
      .angle_table(angle_table),
      .phi_o(phi_o),
      .r_o(r_o),
      .done_o(done_o)
  );
endmodule
