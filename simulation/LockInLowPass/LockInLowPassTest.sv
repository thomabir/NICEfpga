module LockInLowPassTest (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    LockInLowPass lowpass1 (
        .clk_i(clk_i),
        .tick_i(tick_i),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .done_o()
    );
endmodule
