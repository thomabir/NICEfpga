module DelayLineTest (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_delay_o,
    output logic signed [23:0] signal_hilbert_o
);

    // one copy of signal_i is delayed in the delay line
    DelayLine delay1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(signal_i),
        .signal_o(signal_delay_o),
        .done_o()
    );

    // the other copy of signal_i goes through the Hilbert transformer,
    // which is a phase shift by 90 degrees and a delay line
    HilbertTransformer hilbert1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(signal_i),
        .signal_o(signal_hilbert_o),
        .done_o()
    );

    // the result is then a phase shift of 90 degrees between signal_delay_o and signal_hilbert_o

endmodule
