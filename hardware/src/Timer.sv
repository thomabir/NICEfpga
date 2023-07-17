module Timer (
    input logic clk_i,
    input logic reset_i,
    output logic unsigned [31:0] time_o
);

    typedef enum logic [1:0] {
        IDLE,  // wait for the stopwatch to start or continue
        COUNT  // do the counting
    } state_e;

    typedef struct packed {
        state_e state;
        logic unsigned [31:0] counter;
    } state_t;

    state_t state_q, state_d;

    ///////////////////////////////////////
    // Implement your state machine here //
    ///////////////////////////////////////

    always_comb begin
        // defaults

        case (state_q.state)
            IDLE: begin
                state_d.state = COUNT;
            end

            COUNT: begin
                //state_d.counter = state_q.counter + 32'd20; // resolution: 1 ns assuming 50 MHz clock
                state_d.counter = state_q.counter + 32'd10;  // resolution: 20 ns
                state_d.state = COUNT;
            end

            default: state_d.state = IDLE;

        endcase
    end  // always_comb

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            state_q.counter <= 32'd0;
            state_q.state <= COUNT;
        end
        else begin
            state_q <= state_d;
        end
    end

    // the output
    assign time_o = state_q.counter;

endmodule
