module MainV(
    input clk,
    input [1:0] sw,
    input [3:0] btn,
    input [7:0] pmodb,
    output [7:0] pmoda,
    output [3:0] led,
    output [31:0] x,
    output [31:0] y
);
    mainSV main_sv (
        .clk(clk),
        .sw_i(sw),
        .btn_i(btn),
        .pmodb_i(pmodb),
        .pmoda_o(pmoda),
        .led_o(led),
        .oreg1(x),
        .oreg2(y)
    );
endmodule
