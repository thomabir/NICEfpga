module LockInAmplifier #(
    parameter int NUM_BITS = 24
) (
    input logic clk_i,
    input logic reset_i,
    input logic signed [NUM_BITS-1:0] ch1_i,  // clean reference signal
    input logic signed [NUM_BITS-1:0] ch2_i,  // noisy signal
    output logic signed [NUM_BITS-1:0] x_o,
    output logic signed [NUM_BITS-1:0] y_o
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

    // tick every 10 us
    logic tick;
    TickGen #(
        .DIVIDER(1000)
    ) tickgen (
        .clk_i  (clk_i),
        .reset_i(reset_i),
        .tick_o (tick)
    );

    // delay ch1 by 90 degrees + delay line
    HilbertTransformer shift1 (
        .clk_i(clk_i),
        .tick_i(tick),
        .signal_i(ch1_i),
        .signal_o(ch1_shifted),
        .done_o()
    );

    DelayLine delay1 (
        .clk_i(clk_i),
        .tick_i(tick),
        .signal_i(ch1_i),
        .signal_o(ch1_delayed),
        .done_o()
    );

    DelayLine delay2 (
        .clk_i(clk_i),
        .tick_i(tick),
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
        .tick_i(tick),
        .done_o()
    );

    LockInLowPass lpf2 (
        .clk_i(clk_i),
        .signal_i(ch1_shifted_mult_ch2[2*NUM_BITS-1:24]),
        .signal_o(filtered_2),
        .tick_i(tick),
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
    parameter int NumOfStages = 21;
    logic signed [23:0] coeffs[NumOfStages] = '{
        15206,
        31627,
        -44293,
        -114889,
        85926,
        301009,
        -130868,
        -729553,
        165763,
        2612788,
        4015347,
        2612788,
        165763,
        -729553,
        -130868,
        301009,
        85926,
        -114889,
        -44293,
        31627,
        15206
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
