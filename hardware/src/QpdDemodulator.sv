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
        2403,
        8543,
        17410,
        29373,
        44711,
        63580,
        85994,
        111805,
        140691,
        172160,
        205558,
        240085,
        274826,
        308786,
        340933,
        370241,
        395741,
        416566,
        431991,
        441472,
        444671,
        441472,
        431991,
        416566,
        395741,
        370241,
        340933,
        308786,
        274826,
        240085,
        205558,
        172160,
        140691,
        111805,
        85994,
        63580,
        44711,
        29373,
        17410,
        8543,
        2403
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
