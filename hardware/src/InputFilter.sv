module InputFilter #(
    parameter num_of_bits = 24,
    parameter num_of_bits_output = 24
) (
    input logic clk_i,
    input logic reset_i,
    input logic signed [num_of_bits-1:0] data_i,
    output logic signed [num_of_bits_output-1:0] data_o,
    output logic tick_o
);

  logic tick;
  logic tick_reduced;
  logic signed [num_of_bits-1:0] cic_in;
  logic signed [num_of_bits-1:0] dec_out;
  logic signed [num_of_bits-1:0] fir_out;
  logic signed [num_of_bits_output-1:0] interp_out;

  // create 1 MHz clock for signal processing
  TickGen #(100) tickGen (
      .clk_i  (clk_i),
      .reset_i(reset_i),
      .tick_o (tick)
  );

  assign cic_in = data_i;

  CicDecimator #(
      .num_of_stages(4),
      .decimation_factor(16),
      .num_bits_input(num_of_bits),
      .num_bits_output(num_of_bits)
  ) decimator1 (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .tick_i(tick),
      .signal_i(cic_in),
      .signal_o(dec_out),
      .tick_reduced_o(tick_reduced)
  );


  logic done_o;
  FirFSM fir1 (
      .clk_i(clk_i),
      // .reset_i(reset_i),
      .tick_i(tick_reduced),
      .signal_i(dec_out),
      .signal_o(fir_out),
      .done_o(done_o)
  );

  CicInterpolator #(
      .num_of_stages(4),
      .interpolation_factor(16),
      .num_bits_input(num_of_bits),
      .num_bits_output(num_of_bits_output)
  ) interpolator1 (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .tick_reduced_i(tick_reduced),
      .tick_i(tick),
      .signal_i(fir_out),
      .signal_o(interp_out)
  );

  assign data_o = interp_out;
  assign tick_o = tick;

endmodule
