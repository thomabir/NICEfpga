// `timescale 1ns / 1ns

module Filter (
    input logic clk_i,
    input logic reset_i,
    input logic [23:0] signal_i,
    output logic [23:0] signal_o
);
    logic tick;

    TickGen #(
        .DIVIDER(1000)
    ) tickgen (
        .clk_i  (clk_i),
        .reset_i(reset_i),
        .tick_o (tick)
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
        .tick_i(tick),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .done_o(),
        .coeff(coeffs)
    );
endmodule
