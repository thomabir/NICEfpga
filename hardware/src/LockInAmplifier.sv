module LockInAmplifier #(
    parameter int NUM_BITS_IN = 24,
    parameter int NUM_BITS_OUT = 32
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS_IN-1:0] ch1_i,  // clean reference signal
    input logic signed [NUM_BITS_IN-1:0] ch2_i,  // noisy signal
    output logic signed [NUM_BITS_OUT-1:0] x_o,
    output logic signed [NUM_BITS_OUT-1:0] y_o,
    output done_o
);

    // Internal signals

    // ch1, shifted by 90 degrees and delayed
    logic signed [NUM_BITS_IN-1:0] ch1_shifted;

    // ch1 and ch2, delayed
    logic signed [NUM_BITS_IN-1:0] ch1_delayed;
    logic signed [NUM_BITS_IN-1:0] ch2_delayed;


    // multipliers with correct number of bits
    logic signed [NUM_BITS_IN*2-1:0] ch1_delayed_mult_ch2;
    logic signed [NUM_BITS_IN*2-1:0] ch1_shifted_mult_ch2;

    // delay ch1 by 90 degrees + delay line
    HilbertTransformer shift1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(ch1_i),
        .signal_o(ch1_shifted),
        .done_o()
    );

    DelayLine delay1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(ch1_i),
        .signal_o(ch1_delayed),
        .done_o()
    );

    DelayLine delay2 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(ch2_i),
        .signal_o(ch2_delayed),
        .done_o()
    );

    // Multipliers
    assign ch1_delayed_mult_ch2 = ch1_delayed * ch2_delayed;
    assign ch1_shifted_mult_ch2 = ch1_shifted * ch2_delayed;

    // low pass filters
    logic signed [NUM_BITS_OUT-1:0] filtered_1;
    logic signed [NUM_BITS_OUT-1:0] filtered_2;


    LockInLowPass lpf1 (
        .clk_i(clk_i),
        .signal_i(ch1_delayed_mult_ch2[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
        .signal_o(filtered_1),
        .tick_i(tick_i),
        .done_o(done_o)
    );

    LockInLowPass lpf2 (
        .clk_i(clk_i),
        .signal_i(ch1_shifted_mult_ch2[2*NUM_BITS_IN-1:2*NUM_BITS_IN-NUM_BITS_OUT]),
        .signal_o(filtered_2),
        .tick_i(tick_i),
        .done_o()
    );

    assign x_o = filtered_1;
    assign y_o = filtered_2;


endmodule

module HilbertTransformer (
    input clk_i,
    input tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o,
    output logic done_o
);
    parameter int NumOfStages = 23;
    logic signed [23:0] coeffs[NumOfStages] = '{
        0,
        0,
        -19347,
        0,
        -121991,
        0,
        -442606,
        0,
        -1310247,
        0,
        -5164371,
        0,
        5164371,
        0,
        1310247,
        0,
        442606,
        0,
        121991,
        0,
        19347,
        0,
        0
    };

    // delay ch1 by 90 degrees + delay line
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

module DelayLine (
    input clk_i,
    input tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o,
    output logic done_o
);
    parameter int NumOfStages = 23;
    logic signed [23:0] coeffs[NumOfStages] = '{
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8388607,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    };

    // delay ch1 by 90 degrees + delay line
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

module LockInLowPass (
    input clk_i,
    input tick_i,
    input logic signed [31:0] signal_i,
    output logic signed [31:0] signal_o,
    output logic done_o
);
    parameter int NumOfStages = 81;
    logic signed [31:0] coeffs[NumOfStages] = '{6866, 24284, 61044, 127821, 236608, 398863, 622665, 909110, 1248207, 1614918, 1966023, 2238781, 2352180, 2211627, 1717410, 777048, -679179, -2680597, -5198327, -8129429, -11285642, -14389069, -17076969, -18916902, -19432600, -18139519, -14587908, -8409799, 634388, 12614696, 27400773, 44645769, 63788056, 84072456, 104590451, 124337064, 142279954, 157434984, 168941338, 176129259, 178573772, 176129259, 168941338, 157434984, 142279954, 124337064, 104590451, 84072456, 63788056, 44645769, 27400773, 12614696, 634388, -8409799, -14587908, -18139519, -19432600, -18916902, -17076969, -14389069, -11285642, -8129429, -5198327, -2680597, -679179, 777048, 1717410, 2211627, 2352180, 2238781, 1966023, 1614918, 1248207, 909110, 622665, 398863, 236608, 127821, 61044, 24284, 6866};


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
