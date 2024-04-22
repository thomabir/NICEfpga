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
        -19348,
        0,
        -121992,
        0,
        -442606,
        0,
        -1310247,
        0,
        -5164372,
        0,
        5164372,
        0,
        1310247,
        0,
        442606,
        0,
        121992,
        0,
        19348,
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
    parameter int NumOfStages = 61;
    logic signed [23:0] coeffs[NumOfStages] = '{-22698, -88268, -230428, -492668, -924999, -1577743, -2492072, -3687950, -5150267, -6815015, -8557328, -10183971, -11432255, -11977505, -11449839, -9460528, -5636357, 340331, 8689895, 19496249, 32675385, 47955875, 64875246, 82794153, 100928924, 118400464, 134296020, 147738117, 157954380, 164341044, 166513891, 164341044, 157954380, 147738117, 134296020, 118400464, 100928924, 82794153, 64875246, 47955875, 32675385, 19496249, 8689895, 340331, -5636357, -9460528, -11449839, -11977505, -11432255, -10183971, -8557328, -6815015, -5150267, -3687950, -2492072, -1577743, -924999, -492668, -230428, -88268, -22698};

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
