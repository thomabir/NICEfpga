module LockInAmplifier #(
    parameter num_bits = 24
) (
    input logic clk_i,
    input logic reset_i,
    input logic signed [num_bits-1:0] ch1_i,  // clean reference signal
    input logic signed [num_bits-1:0] ch2_i,  // noisy signal
    output logic signed [num_bits-1:0] x_o,
    output logic signed [num_bits-1:0] y_o
);

  // Internal signals

  // ch1, shifted by 90 degrees and delayed
  logic signed [num_bits-1:0] ch1_shifted;

  // ch1 and ch2, delayed
  logic signed [num_bits-1:0] ch1_delayed;
  logic signed [num_bits-1:0] ch2_delayed;


  // multipliers with correct number of bits
  logic signed [num_bits*2-1:0] ch1_delayed_mult_ch2;
  logic signed [num_bits*2-1:0] ch1_shifted_mult_ch2;

  // tick every 10 us
  logic tick;
  TickGen #(
      .DIVIDER(1000)
  ) tickgen (
      .clk_i  (clk_i),
      .reset_i(reset_i),
      .tick_o (tick)
  );

  // delay ch1 by 90 degrees + delay line
  HilbertTransformer shift1 (
      .clk_i(clk_i),
      .tick_i(tick),
      .signal_i(ch1_i),
      .signal_o(ch1_shifted),
      .done_o()
  );

  DelayLine delay1 (
      .clk_i(clk_i),
      .tick_i(tick),
      .signal_i(ch1_i),
      .signal_o(ch1_delayed),
      .done_o()
  );

  DelayLine delay2 (
      .clk_i(clk_i),
      .tick_i(tick),
      .signal_i(ch2_i),
      .signal_o(ch2_delayed),
      .done_o()
  );

  // Multipliers
  assign ch1_delayed_mult_ch2 = ch1_delayed * ch2_delayed;
  assign ch1_shifted_mult_ch2 = ch1_shifted * ch2_delayed;

  // low pass filters
  logic signed [num_bits-1:0] filtered_1;
  logic signed [num_bits-1:0] filtered_2;


  LockInLowPass lpf1 (
      .clk_i(clk_i),
      .signal_i(ch1_delayed_mult_ch2[2*num_bits-1:24]),
      .signal_o(filtered_1),
      .tick_i(tick),
      .done_o()
  );

  LockInLowPass lpf2 (
      .clk_i(clk_i),
      .signal_i(ch1_shifted_mult_ch2[2*num_bits-1:24]),
      .signal_o(filtered_2),
      .tick_i(tick),
      .done_o()
  );

  assign x_o = filtered_1;
  assign y_o = filtered_2;


endmodule

module HilbertTransformer (
    // Interface signals
    input clk_i,
    input tick_i,
    output reg done_o,
    // Data Signals
    input [23:0] signal_i,
    output reg [23:0] signal_o
);
  // Coefficient Storage
  reg signed [23:0] coeff[22:0];
  reg signed [23:0] data[22:0];
  // Counter for iterating through coefficients.
  reg [4:0] count;
  // Accumulator
  reg signed [47:0] acc;

  // State machine signals
  localparam IDLE = 0;
  localparam RUN = 1;

  reg state;

  initial begin
    coeff[0]  = 0;
    coeff[1]  = 0;
    coeff[2]  = -19348;
    coeff[3]  = 0;
    coeff[4]  = -121992;
    coeff[5]  = 0;
    coeff[6]  = -442606;
    coeff[7]  = 0;
    coeff[8]  = -1310247;
    coeff[9]  = 0;
    coeff[10] = -5164372;
    coeff[11] = 0;
    coeff[12] = 5164372;
    coeff[13] = 0;
    coeff[14] = 1310247;
    coeff[15] = 0;
    coeff[16] = 442606;
    coeff[17] = 0;
    coeff[18] = 121992;
    coeff[19] = 0;
    coeff[20] = 19348;
    coeff[21] = 0;
    coeff[22] = 0;
  end
  always @(posedge clk_i) begin : capture
    integer i;
    if (tick_i) begin
      for (i = 0; i < 22; i = i + 1) begin
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
          count <= 22;
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
    endcase
  end
  always @(posedge clk_i) begin
    if (done_o) begin
      // Saturate if necessary
      if (acc >= 2 ** 46) begin
        signal_o <= 8388607;
      end else if (acc < -(2 ** 46)) begin
        signal_o <= -8388608;
      end else begin
        signal_o <= acc[46:23];
      end
    end
  end
endmodule


module DelayLine (
    // Interface signals
    input clk_i,
    input tick_i,
    output reg done_o,
    // Data Signals
    input [23:0] signal_i,
    output reg [23:0] signal_o
);
  // Coefficient Storage
  reg signed [23:0] coeff[22:0];
  reg signed [23:0] data[22:0];
  // Counter for iterating through coefficients.
  reg [4:0] count;
  // Accumulator
  reg signed [45:0] acc;

  // State machine signals
  localparam IDLE = 0;
  localparam RUN = 1;

  reg state;

  initial begin
    coeff[0]  = 0;
    coeff[1]  = 0;
    coeff[2]  = 0;
    coeff[3]  = 0;
    coeff[4]  = 0;
    coeff[5]  = 0;
    coeff[6]  = 0;
    coeff[7]  = 0;
    coeff[8]  = 0;
    coeff[9]  = 0;
    coeff[10] = 0;
    coeff[11] = 4194304;
    coeff[12] = 0;
    coeff[13] = 0;
    coeff[14] = 0;
    coeff[15] = 0;
    coeff[16] = 0;
    coeff[17] = 0;
    coeff[18] = 0;
    coeff[19] = 0;
    coeff[20] = 0;
    coeff[21] = 0;
    coeff[22] = 0;
  end
  always @(posedge clk_i) begin : capture
    integer i;
    if (tick_i) begin
      for (i = 0; i < 22; i = i + 1) begin
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
          count <= 22;
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
    endcase
  end
  always @(posedge clk_i) begin
    if (done_o) begin
      signal_o <= acc[45:22];
    end
  end
endmodule


module LockInLowPass (
    // Interface signals
    input clk_i,
    input tick_i,
    output reg done_o,
    // Data Signals
    input [23:0] signal_i,
    output reg [23:0] signal_o
);
  // Coefficient Storage
  reg signed [23:0] coeff[40:0];
  reg signed [23:0] data[40:0];
  // Counter for iterating through coefficients.
  reg [5:0] count;
  // Accumulator
  reg signed [49:0] acc;

  // State machine signals
  localparam IDLE = 0;
  localparam RUN = 1;

  reg state;

  initial begin
    coeff[0]  = 833;
    coeff[1]  = 4093;
    coeff[2]  = 12013;
    coeff[3]  = 25975;
    coeff[4]  = 43978;
    coeff[5]  = 57966;
    coeff[6]  = 52934;
    coeff[7]  = 9997;
    coeff[8]  = -85448;
    coeff[9]  = -231735;
    coeff[10] = -399239;
    coeff[11] = -525150;
    coeff[12] = -520328;
    coeff[13] = -290355;
    coeff[14] = 232965;
    coeff[15] = 1059201;
    coeff[16] = 2118540;
    coeff[17] = 3263323;
    coeff[18] = 4295643;
    coeff[19] = 5015229;
    coeff[20] = 5273385;
    coeff[21] = 5015229;
    coeff[22] = 4295643;
    coeff[23] = 3263323;
    coeff[24] = 2118540;
    coeff[25] = 1059201;
    coeff[26] = 232965;
    coeff[27] = -290355;
    coeff[28] = -520328;
    coeff[29] = -525150;
    coeff[30] = -399239;
    coeff[31] = -231735;
    coeff[32] = -85448;
    coeff[33] = 9997;
    coeff[34] = 52934;
    coeff[35] = 57966;
    coeff[36] = 43978;
    coeff[37] = 25975;
    coeff[38] = 12013;
    coeff[39] = 4093;
    coeff[40] = 833;
  end
  always @(posedge clk_i) begin : capture
    integer i;
    if (tick_i) begin
      for (i = 0; i < 40; i = i + 1) begin
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
          count <= 40;
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
    endcase
  end
  always @(posedge clk_i) begin
    if (done_o) begin
      // Saturate if necessary
      if (acc >= 2 ** 48) begin
        signal_o <= 8388607;
      end else if (acc < -(2 ** 48)) begin
        signal_o <= -8388608;
      end else begin
        signal_o <= acc[48:25];
      end
    end
  end
endmodule
