module LockInAmplifierTest (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic [23:0] ch1_i,
    input logic [23:0] ch2_i,
    output logic [23:0] x_o,
    output logic [23:0] y_o
);

  LockInAmplifier #(
      .NUM_BITS(24)
  ) lock_in_amplifier (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .tick_i(tick_i),
      .ch1_i(ch1_i),
      .ch2_i(ch2_i),
      .x_o(x_o),
      .y_o(y_o),
      .done_o()
  );

endmodule
