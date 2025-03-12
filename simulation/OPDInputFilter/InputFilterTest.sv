module InputFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,  // high when new signal_i is available
    input logic [23:0] signal_i,
    output logic [23:0] signal_o
);

  InputFilter filt (
      .clk_i  (clk_i),
      .reset_i(reset_i),
      .tick_i (tick_i),
      .data_i (signal_i),
      .data_o (signal_o),
      .tick_o ()
  );

endmodule
