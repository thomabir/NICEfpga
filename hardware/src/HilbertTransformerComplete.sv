module HilbertTransformerComplete #(
    parameter int NUM_BITS = 24,
    parameter int COEFF_LENGTH = 13  // number of coefficients for Hilbert transformer
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS-1:0] signal_i,
    input logic signed [NUM_BITS-1:0] ha_coeffs[COEFF_LENGTH],  // FIR coeffs for Hilbert transfrmr
    input logic signed [NUM_BITS-1:0] delay_coeffs[COEFF_LENGTH],  // FIR coeffs for delay line
    output logic signed [NUM_BITS-1:0] sin_o,
    output logic signed [NUM_BITS-1:0] cos_o,
    output logic done_o
);

  // to generate the cos signal, the signal is delayed by 90 deg
  // because of causality, this will also introduce a delay in the sin signal
  FIRFilter #(
      .COEFF_LENGTH(COEFF_LENGTH),
      .BITWIDTH(NUM_BITS)
  ) cos_generator (
      .clk_i(clk_i),
      .tick_i(tick_i),
      .signal_i(signal_i),
      .signal_o(cos_o),
      .done_o(done_o),
      .coeff(ha_coeffs)
  );

  // to generate the sin signal, only use the delay line
  FIRFilter #(
      .COEFF_LENGTH(COEFF_LENGTH),
      .BITWIDTH(NUM_BITS)
  ) sin_generator (
      .clk_i(clk_i),
      .tick_i(tick_i),
      .signal_i(signal_i),
      .signal_o(sin_o),
      .done_o(),
      .coeff(delay_coeffs)
  );

endmodule
