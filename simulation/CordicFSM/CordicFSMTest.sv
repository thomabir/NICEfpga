module CordicFSMTest (
    input logic clk_i,  // clock
    input logic reset_i,  // reset
    input logic start_i,  // start the computation
    input logic signed [23:0] sin_i,  // sine
    input logic signed [23:0] cos_i,  // cosine
    output logic signed [23:0] phi_o,  // phase
    output logic done_o  // computation is done, result is valid
);

    logic signed [23:0] angle_table[24] = '{
        3294198,
        1944679,
        1027514,
        521582,
        261803,
        131029,
        65530,
        32767,
        16383,
        8191,
        4095,
        2047,
        1023,
        511,
        255,
        127,
        63,
        31,
        15,
        7,
        3,
        1,
        0,
        0
    };

    CordicFSM #(
        .BIT_WIDTH(24)
    ) dut (
        .clk_i(clk_i),
        .start_i(start_i),
        .reset_i(reset_i),
        .sin_i(sin_i),
        .cos_i(cos_i),
        .angle_table(angle_table),
        .phi_o(phi_o),
        .done_o(done_o)
    );
endmodule
