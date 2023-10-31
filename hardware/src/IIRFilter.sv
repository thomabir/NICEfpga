module IIRFilter #(
    parameter int COEFF_LENGTH = 5,  // number of coefficients
    parameter int BITWIDTH = 24  // number of bits per sample
) (
    input clk_i,
    input start_i,
    output logic done_o,
    input logic signed [BITWIDTH-1:0] signal_i,
    output logic signed [BITWIDTH-1:0] signal_o,
    input logic signed [BITWIDTH-1:0] numerator_coeffs[COEFF_LENGTH],  // numerator coefficients
    input logic signed [BITWIDTH-1:0] denominator_coeffs[COEFF_LENGTH]  // denominator coefficients
);

    // deduce the number of bits needed to store each coefficient
    localparam int CoeffBitwidth = $clog2(COEFF_LENGTH);

    // COEFF_LENGTH - 1, but with CoeffBitwidth bits
    localparam logic [CoeffBitwidth-1:0] CoeffLengthReduced = CoeffBitwidth'(COEFF_LENGTH - 1);

    logic signed [BITWIDTH-1:0] data_i[COEFF_LENGTH];  // shift register to store past input data
    logic signed [BITWIDTH-1:0] data_o[COEFF_LENGTH];  // shift register to store past output data
    logic [CoeffBitwidth-1:0] count;  // counter for the state machine
    logic signed [2*BITWIDTH-1:0] acc;  // accumulator for the filter

    // State machine signals
    localparam logic IDLE = 0;
    localparam logic RUN = 1;

    logic state;

    always @(posedge clk_i) begin : capture
        integer i;
        if (start_i) begin
            for (i = 0; i < COEFF_LENGTH - 1; i = i + 1) begin
                data_i[i+1] <= data_i[i];
            end
            data_i[0] <= signal_i;
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
                    + data_o[count] * denominator_coeffs[count];
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
            if (acc >= 2 ** (2 * BITWIDTH - 2)) begin
                signal_o <= 2 ** (BITWIDTH - 1) - 1;
            end
            else if (acc < -(2 ** (2 * BITWIDTH - 2))) begin
                signal_o <= -(2 ** (BITWIDTH - 1));
            end
            else begin
                signal_o <= acc[2*BITWIDTH-2:BITWIDTH-1];
            end
        end
    end
endmodule
