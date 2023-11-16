module FIRFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    logic signed [23:0] coeffs[25] = '{2212, 6636, 6636, 2212};

    FIRFilter #(
        .COEFF_LENGTH(4),
        .SIGNAL_BITS(24),
        .COEFF_BITS(18),
        .COEFF_FRAC_BITS(16)
    ) filter1 (
        .clk_i(clk_i),
        .start_i(start_i),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .coeff(coeffs),
        .done_o()
    );
endmodule
