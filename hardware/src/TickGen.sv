//
// TickGen generates a tick signal that is high for one clock cycle every DIVIDER clock cycles.
//
// Parameters:
//   - DIVIDER: the number of clock cycles between each tick
//
// Inputs:
//   - clk_i: the clock signal
//   - reset_i: the reset signal
//
// Outputs:
//   - tick_o: the tick signal
//
module TickGen #(
    parameter logic [23:0] DIVIDER = 100
) (
    input clk_i,
    input reset_i,
    output tick_o
);

    logic unsigned [23:0] counter;

    always_ff @(posedge clk_i) begin
        if (reset_i) counter <= 0;
        else if (counter < DIVIDER) counter <= counter + 24'd1;
        else counter <= 0;
    end  // ff

    assign tick_o = (counter == 0);
endmodule
