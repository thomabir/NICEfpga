module IIRFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    parameter int NumOfStages = 5;
    parameter int NumBits = 24;

    logic signed [23:0] numerator_coeffs[NumOfStages] = '{372480, 0, -744704, 0, 372480};
    logic signed [23:0] denominator_coeffs[NumOfStages] = '{
        64487,
        -1643152,
        2107488,
        -1295016,
        327864
    };

    IIRFilter #(
        .COEFF_LENGTH(NumOfStages),
        .SIGNAL_BITS(NumBits),
        .COEFF_BITS(NumBits)
    ) filter1 (
        .clk_i(clk_i),
        .start_i(start_i),
        .signal_i(signal_i),
        .signal_o(signal_o),
        .numerator_coeffs(numerator_coeffs),
        .denominator_coeffs(denominator_coeffs),
        .done_o()
    );
endmodule
