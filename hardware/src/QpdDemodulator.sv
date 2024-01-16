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
    output logic signed [2*NUM_BITS-1:0] x1_o,
    output logic signed [2*NUM_BITS-1:0] x2_o,
    output logic signed [2*NUM_BITS-1:0] i1_o,
    output logic signed [2*NUM_BITS-1:0] i2_o,
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
        .signal_i(diff_sin),
        .signal_o(x1_o),
        .tick_i(tick_i),
        .done_o(done_o)
    );

    DemodLowPass lpf2 (
        .clk_i(clk_i),
        .signal_i(diff_cos),
        .signal_o(x2_o),
        .tick_i(tick_i),
        .done_o()
    );

    DemodLowPass lpf3 (
        .clk_i(clk_i),
        .signal_i(sum_sin),
        .signal_o(i1_o),
        .tick_i(tick_i),
        .done_o()
    );

    DemodLowPass lpf4 (
        .clk_i(clk_i),
        .signal_i(sum_cos),
        .signal_o(i2_o),
        .tick_i(tick_i),
        .done_o()
    );


endmodule


module DemodLowPass (
    input clk_i,
    input tick_i,
    input logic signed [47:0] signal_i,
    output logic signed [47:0] signal_o,
    output logic done_o
);
    parameter int NumOfStages = 41;
    logic signed [47:0] coeffs[NumOfStages] = '{
        48'd40327485159,
        48'd143349741121,
        48'd292112447966,
        48'd492821621172,
        48'd750142870924,
        48'd1066716039478,
        48'd1442763705017,
        48'd1875787269984,
        48'd2360415279047,
        48'd2888385238668,
        48'd3448707337426,
        48'd4027972309465,
        48'd4610831267402,
        48'd5180589035501,
        48'd5719919401805,
        48'd6211627113366,
        48'd6639452253744,
        48'd6988833954356,
        48'd7247626753542,
        48'd7406690040162,
        48'd7460353040306,
        48'd7406690040162,
        48'd7247626753542,
        48'd6988833954356,
        48'd6639452253744,
        48'd6211627113366,
        48'd5719919401805,
        48'd5180589035501,
        48'd4610831267402,
        48'd4027972309465,
        48'd3448707337426,
        48'd2888385238668,
        48'd2360415279047,
        48'd1875787269984,
        48'd1442763705017,
        48'd1066716039478,
        48'd750142870924,
        48'd492821621172,
        48'd292112447966,
        48'd143349741121,
        48'd40327485159
    };

    FIRFilter #(
        .COEFF_LENGTH(NumOfStages),
        .BITWIDTH(48)
    ) shift1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .done_o(done_o),
        .coeff(coeffs)
    );
endmodule
