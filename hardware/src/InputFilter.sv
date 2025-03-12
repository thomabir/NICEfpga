module InputFilter (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [23:0] data_i,
    output logic signed [23:0] data_o,
    output logic tick_o
);

  parameter int NumOfStages = 21;
  logic signed [23:0] coeffs[NumOfStages] = '{
      18177,
      -1996,
      -156523,
      -297170,
      -165831,
      -87593,
      -691506,
      -1397353,
      -567521,
      1783518,
      3127631,
      1783518,
      -567521,
      -1397353,
      -691506,
      -87593,
      -165831,
      -297170,
      -156523,
      -1996,
      18177
  };

  FIRFilter #(
      .COEFF_LENGTH(NumOfStages)
  ) input_fir (
      .clk_i(clk_i),
      .tick_i(tick_i),
      .signal_i(data_i),
      .signal_o(data_o),
      .done_o(tick_o),
      .coeff(coeffs)
  );

endmodule
