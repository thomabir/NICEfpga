module IIRFilterTest (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic signed [23:0] signal_i,
    output logic signed [23:0] signal_o
);

    localparam int CoeffLength = 4;


    logic signed [17:0] numerator_coeffs[CoeffLength] = '{2212, 6636, 6636, 2212};
    logic signed [17:0] denominator_coeffs[CoeffLength] = '{-93087, 57638, -12390, 0};


    // 488,8061
    // 1951,-140877
    // 2926,129922
    // 1951,-56436
    // 488,9656

    // logic signed [23:0] numerator_coeffs[5] = '{1, 0, 0, 0, 0};
    // logic signed [17:0] denominator_coeffs[5] = '{
    //     0, 0, 0, 0, 0
    // };


    IIRFilter #(
        .COEFF_LENGTH(4),
        .SIGNAL_BITS(24),
        .COEFF_BITS(18),
        .COEFF_FRAC_BITS(16)
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


// parameter int SIGNAL_BITS = 24,  // number of bits of input and output signal
//     parameter int COEFF_LENGTH = 5,  // number of coefficients
//     parameter int COEFF_BITS = 24,  // number of bits per coefficient
//     parameter int COEFF_FRAC_BITS = 24
