module QpdDemodulator #(
    parameter int NUM_BITS_IN = 24,
    parameter int NUM_BITS_OUT = 32
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS_IN-1:0] diff_x_i,
    input logic signed [NUM_BITS_IN-1:0] diff_y_i,
    input logic signed [NUM_BITS_IN-1:0] sum_i,
    input logic signed [NUM_BITS_IN-1:0] sin_i,
    input logic signed [NUM_BITS_IN-1:0] cos_i,
    output logic signed [NUM_BITS_OUT-1:0] x1_o,
    output logic signed [NUM_BITS_OUT-1:0] x2_o,
    output logic signed [NUM_BITS_OUT-1:0] y1_o,
    output logic signed [NUM_BITS_OUT-1:0] y2_o,
    output logic signed [NUM_BITS_OUT-1:0] i1_o,
    output logic signed [NUM_BITS_OUT-1:0] i2_o,
    output logic done_o
);

  // multipliers
  logic signed [NUM_BITS_IN*2-1:0] diff_x_sin;
  logic signed [NUM_BITS_IN*2-1:0] diff_x_cos;
  logic signed [NUM_BITS_IN*2-1:0] diff_y_sin;
  logic signed [NUM_BITS_IN*2-1:0] diff_y_cos;
  logic signed [NUM_BITS_IN*2-1:0] sum_sin;
  logic signed [NUM_BITS_IN*2-1:0] sum_cos;

  assign diff_x_sin = diff_x_i * sin_i;
  assign diff_x_cos = diff_x_i * cos_i;
  assign diff_y_sin = diff_y_i * sin_i;
  assign diff_y_cos = diff_y_i * cos_i;
  assign sum_sin = sum_i * sin_i;
  assign sum_cos = sum_i * cos_i;

  // low pass filters
  DemodLowPass lpf1 (
      .clk_i(clk_i),
      .signal_i(diff_x_sin[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
      .signal_o(x1_o),
      .tick_i(tick_i),
      .done_o(done_o)
  );

  DemodLowPass lpf2 (
      .clk_i(clk_i),
      .signal_i(diff_x_cos[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
      .signal_o(x2_o),
      .tick_i(tick_i),
      .done_o()
  );

  DemodLowPass lpf3 (
      .clk_i(clk_i),
      .signal_i(diff_y_sin[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
      .signal_o(y1_o),
      .tick_i(tick_i),
      .done_o()
  );

  DemodLowPass lpf4 (
      .clk_i(clk_i),
      .signal_i(diff_y_cos[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
      .signal_o(y2_o),
      .tick_i(tick_i),
      .done_o()
  );

  DemodLowPass lpf5 (
      .clk_i(clk_i),
      .signal_i(sum_sin[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
      .signal_o(i1_o),
      .tick_i(tick_i),
      .done_o()
  );

  DemodLowPass lpf6 (
      .clk_i(clk_i),
      .signal_i(sum_cos[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
      .signal_o(i2_o),
      .tick_i(tick_i),
      .done_o()
  );

endmodule


module DemodLowPass (
    input clk_i,
    input tick_i,
    input logic signed [31:0] signal_i,
    output logic signed [31:0] signal_o,
    output logic done_o
);

  parameter int NumOfStages = 41;
  logic signed [31:0] coeffs[NumOfStages] = '{
      32'd615349,
      32'd2187343,
      32'd4457282,
      32'd7519861,
      32'd11446272,
      32'd16276795,
      32'd22014827,
      32'd28622242,
      32'd36017079,
      32'd44073261,
      32'd52623098,
      32'd61461980,
      32'd70355702,
      32'd79049515,
      32'd87279044,
      32'd94781908,
      32'd101310001,
      32'd106641143,
      32'd110590008,
      32'd113017121,
      32'd113835953,
      32'd113017121,
      32'd110590008,
      32'd106641143,
      32'd101310001,
      32'd94781908,
      32'd87279044,
      32'd79049515,
      32'd70355702,
      32'd61461980,
      32'd52623098,
      32'd44073261,
      32'd36017079,
      32'd28622242,
      32'd22014827,
      32'd16276795,
      32'd11446272,
      32'd7519861,
      32'd4457282,
      32'd2187343,
      32'd615349
  };

  FIRFilter #(
      .COEFF_LENGTH(NumOfStages),
      .BITWIDTH(32)
  ) shift1 (
      .clk_i(clk_i),
      .tick_i(tick_i),
      .signal_i(signal_i),
      .signal_o(signal_o),
      .done_o(done_o),
      .coeff(coeffs)
  );
endmodule
