module CompensatedCICFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

  logic signed [23:0] fir_coeffs[25] = {
    -111761,
    3923,
    333871,
    -67106,
    -354581,
    213822,
    -333103,
    -367217,
    1856848,
    374568,
    -3537164,
    -160702,
    4277397,
    -160702,
    -3537164,
    374568,
    1856848,
    -367217,
    -333103,
    213822,
    -354581,
    -67106,
    333871,
    3923,
    -111761
  };

  CompensatedCICFilter #(
      .NUM_BITS_IN(24),
      .NUM_BITS_OUT(24),
      .CIC_STAGES(5),
      .CIC_DECIMATION(16),
      .COEFF_LENGTH(25)
  ) dut (
      .clk_i  (clk_i),
      .reset_i(reset_i),
      .tick_i (start_i),
      .data_i (signal_i),
      .coeff  (fir_coeffs),
      .data_o (signal_o),
      .done_o ()
  );
endmodule
