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
        .done_o(done_o)
    );

    DemodLowPass lpf3 (
        .clk_i(clk_i),
        .signal_i(sum_sin[2*NUM_BITS-1:24]),
        .signal_o(i1_o),
        .tick_i(tick_i),
        .done_o(done_o)
    );

    DemodLowPass lpf4 (
        .clk_i(clk_i),
        .signal_i(sum_cos[2*NUM_BITS-1:24]),
        .signal_o(i2_o),
        .tick_i(tick_i),
        .done_o(done_o)
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
        144,
        797,
        2561,
        6017,
        11095,
        16239,
        17830,
        10563,
        -10688,
        -47567,
        -94469,
        -136116,
        -148413,
        -103711,
        20196,
        229968,
        509453,
        818924,
        1102458,
        1302031,
        1373963,
        1302031,
        1102458,
        818924,
        509453,
        229968,
        20196,
        -103711,
        -148413,
        -136116,
        -94469,
        -47567,
        -10688,
        10563,
        17830,
        16239,
        11095,
        6017,
        2561,
        797,
        144
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
