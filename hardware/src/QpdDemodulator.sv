module QpdDemodulator #(
    parameter int NUM_BITS = 24
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS-1:0] diff_i,
    input logic signed [NUM_BITS-1:0] sum_i,
    input logic signed [NUM_BITS-1:0] sin_i,
    input logic signed [NUM_BITS-1:0] cos_i,
    output logic signed [NUM_BITS-1:0] x1_o,
    output logic signed [NUM_BITS-1:0] x2_o,
    output logic signed [NUM_BITS-1:0] i1_o,
    output logic signed [NUM_BITS-1:0] i2_o,
    output logic done_o
);

    // multipliers
    logic signed [NUM_BITS*2-1:0] diff_sin;
    logic signed [NUM_BITS*2-1:0] diff_cos;
    logic signed [NUM_BITS*2-1:0] sum_sin;
    logic signed [NUM_BITS*2-1:0] sum_cos;

    assign diff_sin = diff_i * sin_i;
    assign diff_cos = diff_i * cos_i;
    assign sum_sin = sum_i * sin_i;
    assign sum_cos = sum_i * cos_i;

    // low pass filters
    DemodLowPass lpf1 (
        .clk_i(clk_i),
        .signal_i(diff_sin[2*NUM_BITS-1:24]),
        .signal_o(x1_o),
        .tick_i(tick_i),
        .done_o(done_o)
    );

    DemodLowPass lpf2 (
        .clk_i(clk_i),
        .signal_i(diff_cos[2*NUM_BITS-1:24]),
        .signal_o(x2_o),
        .tick_i(tick_i),
        .done_o()
    );

    DemodLowPass lpf3 (
        .clk_i(clk_i),
        .signal_i(sum_sin[2*NUM_BITS-1:24]),
        .signal_o(i1_o),
        .tick_i(tick_i),
        .done_o()
    );

    DemodLowPass lpf4 (
        .clk_i(clk_i),
        .signal_i(sum_cos[2*NUM_BITS-1:24]),
        .signal_o(i2_o),
        .tick_i(tick_i),
        .done_o()
    );


endmodule


module DemodLowPass (
    input clk_i,
    input tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o,
    output logic done_o
);
    parameter int NumOfStages = 41;
    logic signed [23:0] coeffs[NumOfStages] = '{
        -1160,
        -4252,
        -5987,
        -249,
        14455,
        26725,
        16225,
        -25132,
        -71262,
        -68926,
        15144,
        140039,
        190488,
        61713,
        -219237,
        -444611,
        -327982,
        283633,
        1242185,
        2127762,
        2487678,
        2127762,
        1242185,
        283633,
        -327982,
        -444611,
        -219237,
        61713,
        190488,
        140039,
        15144,
        -68926,
        -71262,
        -25132,
        16225,
        26725,
        14455,
        -249,
        -5987,
        -4252,
        -1160
    };

    FIRFilter #(
        .COEFF_LENGTH(NumOfStages)
    ) shift1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .done_o(done_o),
        .coeff(coeffs)
    );
endmodule
