module HilbertTransformerTest (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    // delay ch1 by 90 degrees + delay line
    HilbertTransformer hilbert1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .done_o()
    );
endmodule
