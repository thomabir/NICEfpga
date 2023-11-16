module CompensatedCICFilter #(
    parameter int NUM_BITS_IN = 24,
    parameter int NUM_BITS_OUT = 24,
    parameter int CIC_STAGES = 4,
    parameter int CIC_DECIMATION = 16,
    parameter int COEFF_LENGTH = 23  // number of coefficients
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS_IN-1:0] data_i,
    input logic signed [NUM_BITS_IN-1:0] coeff[COEFF_LENGTH],  // FIR coefficients for compensation
    output logic signed [NUM_BITS_OUT-1:0] data_o,
    output logic done_o
);

    // internal signals
    logic tick_reduced;
    logic signed [NUM_BITS_IN-1:0] dec_out;

    // decimator
    CICDecimator #(
        .NUM_STAGES(CIC_STAGES),
        .DECIMATION_FACTOR(CIC_DECIMATION),
        .NUM_BITS_INPUT(NUM_BITS_IN),
        .NUM_BITS_OUTPUT(NUM_BITS_IN)
    ) dec1 (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tick_i(tick_i),
        .signal_i(data_i),
        .signal_o(dec_out),
        .tick_reduced_o(tick_reduced)
    );

    // compensation filter
    FIRFilter #(
        .COEFF_LENGTH(COEFF_LENGTH),
        .BITWIDTH(NUM_BITS_IN)
    ) fir1 (
        .clk_i(clk_i),
        .tick_i(tick_reduced),
        .signal_i(dec_out),
        .signal_o(data_o),
        .coeff(coeff),
        .done_o(done_o)
    );

    // CICInterpolator #(
    //     .num_of_stages(CIC_STAGES),
    //     .interpolation_factor(CIC_DECIMATION),
    //     .num_bits_input(NUM_BITS_IN),
    //     .NUM_BITS_OUT(NUM_BITS_OUT)
    // ) interpolator1 (
    //     .clk_i(clk_i),
    //     .reset_i(reset_i),
    //     .tick_reduced_i(tick_reduced),
    //     .tick_i(tick_i),
    //     .signal_i(fir_out),
    //     .signal_o(interp_out)
    // );

endmodule
