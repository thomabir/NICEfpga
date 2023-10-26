module CordicFSMTest (
    input logic clk_i,  // clock
    input logic reset_i,  // reset
    input logic start_i,  // start the computation
    input logic signed [23:0] sin_i,  // sine
    input logic signed [23:0] cos_i,  // cosine
    output logic signed [25:0] phi_o,  // phase
    output logic done_o  // computation is done, result is valid
);

    logic signed [24:0] angle_table[24] = '{
        6588396,
        3889357,
        2055029,
        1043165,
        523606,
        262058,
        131061,
        65534,
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
        0
    };

    CordicFSM #(
        .BIT_WIDTH_IN(24),
        .BIT_WIDTH_OUT(26)
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
