module HilbertTransformerTest (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] sin_o,
    output logic signed [23:0] cos_o
);

  HilbertTransformerComplete #(
      .NUM_BITS(24),
      .COEFF_LENGTH(13)
  ) hilbert1 (
      .clk_i(clk_i),
      .tick_i(tick_i),
      .reset_i(reset_i),
      .signal_i(signal_i),
      .ha_coeffs({0, -28824, 0, -605240, 0, -4769003, 0, 4769003, 0, 605240, 0, 28824, 0}),
      .delay_coeffs({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0}),
      .sin_o(sin_o),
      .cos_o(cos_o),
      .done_o()
  );

endmodule
