module LockInAmplifier #(
    parameter int NUM_BITS = 24
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS-1:0] ch1_i,  // clean reference signal
    input logic signed [NUM_BITS-1:0] ch2_i,  // noisy signal
    output logic signed [NUM_BITS-1:0] x_o,
    output logic signed [NUM_BITS-1:0] y_o,
    output done_o
);

    // Internal signals

    // ch1, shifted by 90 degrees and delayed
    logic signed [NUM_BITS-1:0] ch1_shifted;

    // ch1 and ch2, delayed
    logic signed [NUM_BITS-1:0] ch1_delayed;
    logic signed [NUM_BITS-1:0] ch2_delayed;


    // multipliers with correct number of bits
    logic signed [NUM_BITS*2-1:0] ch1_delayed_mult_ch2;
    logic signed [NUM_BITS*2-1:0] ch1_shifted_mult_ch2;

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
    logic signed [NUM_BITS-1:0] filtered_1;
    logic signed [NUM_BITS-1:0] filtered_2;


    LockInLowPass lpf1 (
        .clk_i(clk_i),
        .signal_i(ch1_delayed_mult_ch2[2*NUM_BITS-1:24]),
        .signal_o(filtered_1),
        .tick_i(tick_i),
        .done_o(done_o)
    );

    LockInLowPass lpf2 (
        .clk_i(clk_i),
        .signal_i(ch1_shifted_mult_ch2[2*NUM_BITS-1:24]),
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
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o,
    output logic done_o
);
    parameter int NumOfStages = 81;
    logic signed [23:0] coeffs[NumOfStages] = '{
        26,
        94,
        237,
        498,
        923,
        1557,
        2431,
        3550,
        4875,
        6307,
        7679,
        8744,
        9187,
        8638,
        6708,
        3034,
        -2654,
        -10472,
        -20307,
        -31757,
        -44086,
        -56208,
        -66708,
        -73895,
        -75910,
        -70858,
        -56985,
        -32852,
        2477,
        49275,
        107033,
        174397,
        249171,
        328407,
        408555,
        485691,
        555780,
        614979,
        659926,
        688004,
        697553,
        688004,
        659926,
        614979,
        555780,
        485691,
        408555,
        328407,
        249171,
        174397,
        107033,
        49275,
        2477,
        -32852,
        -56985,
        -70858,
        -75910,
        -73895,
        -66708,
        -56208,
        -44086,
        -31757,
        -20307,
        -10472,
        -2654,
        3034,
        6708,
        8638,
        9187,
        8744,
        7679,
        6307,
        4875,
        3550,
        2431,
        1557,
        923,
        498,
        237,
        94,
        26
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
