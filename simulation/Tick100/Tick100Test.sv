// tick_o is high for one clock cycle, exactly 100 clock cycles after tick_i is high
module Tick100Test (
    input clk_i,
    input reset_i,
    input tick_i,
    output tick_o
);

    logic unsigned [8:0] counter;
    logic counting;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            counter <= 0;
            counting <= 0;
        end else if (tick_i) begin
            counter <= 0;
            counting <= 1;
        end else if (counting) begin
            if (counter < 99) counter <= counter + 1;
            else begin
                counting <= 0;
                counter <= 0;
            end
        end
    end  // ff

    assign tick_o = (counter == 99);
endmodule
