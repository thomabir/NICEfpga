module FIRFilter #(
    parameter int COEFF_LENGTH = 23,  // number of coefficients
    parameter int BITWIDTH = 24  // number of bits per sample
) (
    input clk_i,
    input tick_i,
    output logic done_o,
    input logic signed [BITWIDTH-1:0] signal_i,
    output logic signed [BITWIDTH-1:0] signal_o,
    input logic signed [BITWIDTH-1:0] coeff[COEFF_LENGTH]
);

  // deduce the number of bits needed to store each coefficients
  localparam int CoeffBitwidth = $clog2(COEFF_LENGTH);

  // COEFF_LENGTH - 1, but with CoeffBitwidth bits
  localparam logic [CoeffBitwidth-1:0] CoeffLengthReduced = CoeffBitwidth'(COEFF_LENGTH - 1);

  logic signed [BITWIDTH-1:0] data[COEFF_LENGTH];
  logic [CoeffBitwidth-1:0] count;
  logic signed [2*BITWIDTH-1:0] acc;

  // State machine signals
  localparam logic IDLE = 0;
  localparam logic RUN = 1;

  logic state;

  always @(posedge clk_i) begin : capture
    integer i;
    if (tick_i) begin
      for (i = 0; i < COEFF_LENGTH - 1; i = i + 1) begin
        data[i+1] <= data[i];
      end
      data[0] <= signal_i;
    end
  end
  always @(posedge clk_i) begin
    case (state)
      IDLE: begin
        done_o <= 1'b0;
        if (tick_i) begin
          count <= CoeffLengthReduced;
          acc   <= 0;
          state <= RUN;
        end
      end

      RUN: begin
        count <= count - 1'b1;
        acc   <= acc + data[count] * coeff[count];
        if (count == 0) begin
          state  <= IDLE;
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
      end else if (acc < -(2 ** (2 * BITWIDTH - 2))) begin
        signal_o <= -(2 ** (BITWIDTH - 1));
      end else begin
        signal_o <= acc[2*BITWIDTH-2:BITWIDTH-1];
      end
    end
  end
endmodule
