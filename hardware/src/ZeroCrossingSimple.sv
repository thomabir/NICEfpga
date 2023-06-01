module ZeroCrossingSimple (
    input logic clk_i,
    input logic reset_i,
    input logic unsigned [31:0] current_time_i,
    input logic signed [15:0] data_i,  // input waveform

    output logic pulse_o,     // 1 during a positive-going zero crossing
    output logic unsigned [31:0] last_crossing_time_o
);

  typedef enum logic [2:0] {
    INIT,
    DETECT_CROSSING,
    CALCULATE,
    DIVIDE
  } state_e;



  typedef struct packed {
    state_e state;
    logic unsigned [31:0] crossing_high_t;
    logic signed [15:0] crossing_high_y;
    logic unsigned [31:0] crossing_low_t;
    logic signed [15:0] crossing_low_y;
    logic unsigned [31:0] crossing_zero_t;
  } state_t;




  state_t state_d;
  state_t state_q;


  logic done_div;
  logic signed [31:0] dtdy;
  logic signed [15:0] data_now;
  logic signed [15:0] data_prev;


  always_comb begin
    state_d = state_q;  // default
    case (state_q.state)
      INIT: begin
        state_d.state = DETECT_CROSSING;
        state_d.crossing_high_t = 32'd0;
        state_d.crossing_high_y = 16'sd0;
        state_d.crossing_low_t = 32'd0;
        state_d.crossing_low_y = 16'sd0;
        state_d.crossing_zero_t = 32'd0;
      end
      DETECT_CROSSING: begin
        if (data_prev < -16'sd1000 && data_now >= -16'sd1000) begin  // crossing lower threshold
          state_d.crossing_low_t = current_time_i;
          state_d.crossing_low_y = data_now;
        end
					 else if (data_prev < 16'sd1000 && data_now >= 16'sd1000) begin // crossing high threshold
          state_d.crossing_high_t = current_time_i;
          state_d.crossing_high_y = data_now;
          state_d.state = CALCULATE;
        end

      end
      CALCULATE: begin
        // division begins as soon as CALCULATE
        //					state_d.crossing_zero_t = state_q.crossing_low_t - (state_q.crossing_high_t-state_q.crossing_low_t)/(state_q.crossing_high_y - state_q.crossing_low_y) * state_q.crossing_low_y;
        //					state_d.crossing_zero_t = (state_q.crossing_low_t + state_q.crossing_high_t) / 2;
        state_d.state = DIVIDE;
      end
      DIVIDE: begin
        if (done_div) begin
          state_d.crossing_zero_t = state_q.crossing_low_t - dtdy * state_q.crossing_low_y;
          state_d.state = DETECT_CROSSING;
        end
      end
      default: state_d.state = INIT;
    endcase
  end  // always_comb

  assign last_crossing_time_o = state_q.crossing_zero_t;
  assign pulse_o = (state_q.state == DIVIDE) && done_div;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      state_q.state <= INIT;
    end else begin
      state_q   <= state_d;
      data_prev <= data_now;
      data_now  <= data_i;
    end
  end

  div_int #(32) divider (
      .clk(clk_i),
      .start(state_q.state == CALCULATE),
      .busy(),
      .valid(done_div),
      .dbz(),
      .x(state_q.crossing_high_t - state_q.crossing_low_t),
      .y(state_q.crossing_high_y - state_q.crossing_low_y),
      .q(dtdy),
      .r()
  );

endmodule
