module FreqPhaseDetector (
    input  logic                 clk_i,
    input  logic                 reset_i,
    input  logic unsigned [31:0] crossing_time_1_i,
    input  logic unsigned [31:0] crossing_time_2_i,
    input  logic                 pulse_i,            // indicates when crossing_time_2 is updated
    output logic unsigned [31:0] freq1_o,
    output logic unsigned [31:0] freq2_o,
    output logic signed   [31:0] phase_o,
    output logic                 done_pulse_o
);

  typedef enum logic [1:0] {
    RESET,
    CALCULATE,
    DIVIDE
  } state_e;



  typedef struct packed {
    state_e state;
    logic unsigned [31:0] time_ch1_now;
    logic unsigned [31:0] time_ch1_prev;
    logic unsigned [31:0] time_ch2_now;
    logic unsigned [31:0] time_ch2_prev;
    logic unsigned [31:0] frequency_ch1;
    logic unsigned [31:0] frequency_ch2;
    logic signed [31:0] phase;
  } state_t;

  state_t state_d;
  state_t state_q;
  logic   done_freq1_div;

  always_comb begin

    state_d = state_q;  // default

    case (state_q.state)
      RESET: begin
        state_d.time_ch1_prev = 32'd0;
        state_d.time_ch1_now = 32'd0;
        state_d.time_ch2_prev = 32'd0;
        state_d.time_ch2_now = 32'd0;
        state_d.phase = 32'sd0;
        state_d.state = CALCULATE;
      end
      CALCULATE: begin
        if (pulse_i) begin
          // frequency calculation starts in the divider below
          state_d.time_ch2_now = crossing_time_2_i;
          state_d.time_ch1_now = crossing_time_1_i;
          state_d.time_ch1_prev = state_q.time_ch1_now;
          state_d.time_ch2_prev = state_q.time_ch2_now;

          state_d.phase = crossing_time_2_i - crossing_time_1_i;
        end
      end
      //			DIVIDE: begin // calculate frequencies
      //				if (done_freq1_div) begin
      //					state_d.phase = (crossing_time_2_i - crossing_time_1_i) * ;
      //				end
      //			end
      default: state_d = RESET;
    endcase
  end  // always_comb


  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      state_q.state <= RESET;
    end else begin
      state_q <= state_d;
    end
  end

  assign phase_o      = state_d.phase;
  assign freq1_o      = state_d;
  assign freq2_o      = 32'd0;
  assign done_pulse_o = (state_q.state == CALCULATE);

  //	div_int #(32) freq1_divider (
  //		.clk(clk_i),
  //		.start(state_q.state == CALCULATE),
  //		.busy(),
  //		.valid(done_freq1_div),
  //		.dbz(),
  //		.x(1000000000), // 1 s / (1 ns)  (where 1 ns is the timer resolution)
  //		.y(state_q.time_ch1_now - crossing_time_1_i), // doesn't look great
  //		.q(state_d.frequency_ch1), // in Hz
  //		.r()
  //	);


endmodule





// not working
// module PhaseUnwrapper
// 	(
// 	input logic clk_i,
// 	input logic reset_i,
// 	input logic signed[31:0] phase_i,
// 	output logic signed[31:0] phase_unwrapped_o
//     );

// 	typedef enum logic [1:0] {
// 		RESET,
// 		CALCULATE
//    } state_e;

// 	typedef struct packed {
// 		state_e state;
//  		logic signed [31:0] phase_unwrapped;
// 	} state_t;

// 	state_t state_q, state_d;

// 	logic signed[31:0] minphase = 32'sd0;
// 	logic signed[31:0] maxphase = 32'sd100000;
// 	logic signed[31:0] delta_phase;
// 	logic signed[31:0] phase_now;
// 	logic signed[31:0] phase_prev;
// 	logic signed[31:0] delta_phase_unwrapped;

// 	always_comb begin
// 		state_d = state_q;
// 		delta_phase = phase_now - phase_prev;

// 		case(state_q.state)
// 			RESET: begin
// 				state_d.phase_unwrapped = 32'sd0;
// 				state_d.state = CALCULATE;
// 			end
// 			CALCULATE: begin
// 				if (delta_phase < -32'sd50000) begin // the phase jumped low, but should instead go up
// 					delta_phase_unwrapped = phase_prev + (maxphase - phase_prev) + (phase_i - minphase);
// 				end
// 				else if (delta_phase > 32'sd50000) begin // the phase jumped high, but should instead go down
// 					delta_phase_unwrapped = phase_prev - (phase_prev - minphase) - (maxphase - phase_now);
// 				end
// 				else begin
// 					delta_phase_unwrapped = delta_phase;
// 				end

// 				state_d.phase_unwrapped = state_q.phase_unwrapped + delta_phase_unwrapped;
// 			end
// 		endcase
// 	end

// 	always_ff @(posedge clk_i) begin
// 		if(reset_i) begin
// 			state_q.state <= RESET;
// 		end else begin
// 			state_q <= state_d;
// 			phase_prev <= phase_now;
// 			phase_now <= phase_i;
// 		end
// 	end

// 	assign phase_unwrapped_o = state_q.phase_unwrapped;


// endmodule
