module IIRFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    parameter int NumOfStages = 5;
    parameter int NumBits = 24;

    logic signed [23:0] numerator_coeffs[NumOfStages] = '{8852, 0, -17705, 0, 8852};
    logic signed [23:0] denominator_coeffs[NumOfStages] = '{
        1048575,
        -3460263,
        4674299,
        -3009671,
        794344
    };

    IIRFilter #(
        .COEFF_LENGTH(NumOfStages),
        .BITWIDTH(NumBits)
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
