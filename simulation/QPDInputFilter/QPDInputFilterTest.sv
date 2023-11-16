module CompensatedCICFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    logic signed [23:0] fir_coeffs[25] = {
        -12515,
        48061,
        103347,
        -4735,
        125381,
        304529,
        -272697,
        -405181,
        229239,
        -1126971,
        -2391966,
        1185892,
        4438326,
        1185892,
        -2391966,
        -1126971,
        229239,
        -405181,
        -272697,
        304529,
        125381,
        -4735,
        103347,
        48061,
        -12515
    };

    CompensatedCICFilter #(
        .NUM_BITS_IN(24),
        .NUM_BITS_OUT(24),
        .CIC_STAGES(2),
        .CIC_DECIMATION(128),
        .COEFF_LENGTH(25)
    ) dut (
        .clk_i  (clk_i),
        .reset_i(reset_i),
        .tick_i (start_i),
        .data_i (signal_i),
        .coeff  (fir_coeffs),
        .data_o (signal_o),
        .done_o ()
    );
endmodule
