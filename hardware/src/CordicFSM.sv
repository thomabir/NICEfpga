module CordicFSM #(
    parameter int BIT_WIDTH = 24
) (
    input logic clk_i,  // clock
    input logic reset_i,  // reset
    input logic start_i,  // start the computation
    input logic signed [BIT_WIDTH-1:0] sin_i,  // sine
    input logic signed [BIT_WIDTH-1:0] cos_i,  // cosine
    input logic signed [BIT_WIDTH-1:0] angle_table[BIT_WIDTH],  // angle table
    output logic signed [BIT_WIDTH-1:0] phi_o,  // phase
    output logic done_o  // computation is done, result is valid
);

    parameter int ITERATOR_WIDTH = $clog2(BIT_WIDTH);  // 24 bit numbers -> 5 bit counter



    typedef enum logic [2:0] {
        IDLE,  // wait for start_i, all outputs are zero
        ITERATE,  // iterate the CORDIC algorithm for BIT_WIDTH iterations
        DONE  // phi_o is valid, done_o is high, go back to IDLE
    } state_e;

    typedef struct packed {
        state_e state;
        logic [ITERATOR_WIDTH-1:0] i;  // counts from 0 to BIT_WIDTH-1
        logic signed [BIT_WIDTH-1:0] x;  // x coordinate
        logic signed [BIT_WIDTH-1:0] y;  // y coordinate
        logic signed [BIT_WIDTH-1:0] phi;  // phase
        logic signed [BIT_WIDTH-1:0] phi_final;  // final phase, always valid
    } state_t;

    state_t state_d;
    state_t state_q;

    // start routine
    always_ff @(posedge clk_i) begin
        if (reset_i) state_q.state <= IDLE;
        else state_q <= state_d;
    end  // always_ff


    always_comb begin
        state_d = state_q;

        case (state_q.state)

            // take inputs, get ready for computation
            IDLE: begin
                state_d.i = 0;
                state_d.x = sin_i;
                state_d.y = cos_i;
                state_d.phi = 0;
                if (start_i) state_d.state = ITERATE;
            end

            ITERATE: begin
                if (state_q.i == ITERATOR_WIDTH'(BIT_WIDTH - 1)) begin
                    state_d.state = DONE;
                    state_d.phi_final = state_q.phi;
                end
                else begin
                    if (state_q.y >= 0) begin
                        state_d.x = state_q.x + (state_q.y >>> state_q.i);
                        state_d.y = state_q.y - (state_q.x >>> state_q.i);
                        state_d.phi = state_q.phi + angle_table[state_q.i];
                    end
                    else begin
                        state_d.x = state_q.x - (state_q.y >>> state_q.i);
                        state_d.y = state_q.y + (state_q.x >>> state_q.i);
                        state_d.phi = state_q.phi - angle_table[state_q.i];
                    end
                    state_d.i = state_q.i + 1;
                end

            end

            DONE: begin
                state_d.state = IDLE;
            end

            default: begin
                state_d.state = IDLE;
            end

        endcase

        // output signals
        phi_o = state_q.phi_final;
        done_o = (state_q.state == DONE);


    end  // always_comb

endmodule
