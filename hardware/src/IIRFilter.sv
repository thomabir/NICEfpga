module IIRFilter #(
    parameter int SIGNAL_BITS = 24,  // number of bits of input and output signal
    parameter int COEFF_LENGTH = 5,  // number of coefficients
    parameter int COEFF_BITS = 24,  // number of bits per coefficient
    parameter int COEFF_FRAC_BITS = 24  // number of bits reserved for the fractional part of each coefficient
) (
    input clk_i,
    input start_i,
    output logic done_o,
    input logic signed [SIGNAL_BITS-1:0] signal_i,
    output logic signed [SIGNAL_BITS-1:0] signal_o,
    input logic signed [COEFF_BITS-1:0] numerator_coeffs[COEFF_LENGTH],  // numerator coefficients
    input logic signed [COEFF_BITS-1:0] denominator_coeffs[COEFF_LENGTH]  // denominator coefficients
);

    // deduce the number of bits needed for counter
    localparam int CoeffLengthBits = $clog2(COEFF_LENGTH);

    // COEFF_LENGTH - 1, but with CoeffLengthBits bits
    localparam logic [CoeffLengthBits-1:0] CoeffLengthReduced = CoeffLengthBits'(COEFF_LENGTH - 1);

    localparam int GuardBits = 2 * CoeffLengthBits;

    localparam int AccumulatorBits = GuardBits + SIGNAL_BITS + COEFF_BITS;

    logic signed [SIGNAL_BITS-1:0] data_i[COEFF_LENGTH];  // shift register to store past input data
    logic signed [SIGNAL_BITS-1:0] data_o[COEFF_LENGTH];  // shift register to store past output data
    logic [CoeffLengthBits-1:0] count;  // counter for the state machine
    logic signed [AccumulatorBits-1:0] acc;  // accumulator for the filter

    // // State machine signals
    localparam logic IDLE = 0;
    localparam logic RUN = 1;

    logic state;


    always @(posedge clk_i) begin : capture
        integer i;
        if (start_i) begin
            data_i[0] <= signal_i;
            data_o[0] <= signal_o;
            for (i = 0; i < COEFF_LENGTH - 1; i = i + 1) begin
                data_i[i+1] <= data_i[i];
                data_o[i+1] <= data_o[i];
            end
        end
    end
    always @(posedge clk_i) begin
        case (state)
            IDLE: begin
                done_o <= 1'b0;
                if (start_i) begin
                    count <= CoeffLengthReduced;
                    acc <= 0;
                    state <= RUN;
                end
            end

            RUN: begin
                count <= count - 1'b1;
                acc <= acc + data_i[count] * numerator_coeffs[count]
                    - data_o[count] * denominator_coeffs[count];
                if (count == 0) begin
                    state <= IDLE;
                    done_o <= 1'b1;
                end
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
    always @(posedge clk_i) begin
        if (done_o) begin
            // Saturate if necessary
            if (acc >= 2 ** (SIGNAL_BITS+COEFF_FRAC_BITS-1) - 1) begin
                signal_o <= 2 ** (SIGNAL_BITS-1) - 1;
            end
            else if (acc < -(2 ** (SIGNAL_BITS+COEFF_FRAC_BITS-1))) begin
                signal_o <= -(2 ** (SIGNAL_BITS-1));
            end
            
            else begin
                signal_o <= acc[COEFF_FRAC_BITS+SIGNAL_BITS-1:COEFF_FRAC_BITS];
            end
        end
    end
endmodule
