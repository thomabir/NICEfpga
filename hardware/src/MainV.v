module MainV(
    input clk,
    input [1:0] sw,
    input [3:0] btn,
    input [7:0] pmodb,
    output [7:0] pmoda,
    output [3:0] led,
    output [31:0] oreg1,
    output [31:0] oreg2,
    output [31:0] oreg3,
    output [31:0] oreg4,
    output [31:0] oreg_count
);
    MainSV main_sv (
        .clk(clk),
        .sw_i(sw),
        .btn_i(btn),
        .pmodb_i(pmodb),
        .pmoda_o(pmoda),
        .led_o(led),
        .oreg1(oreg1),
        .oreg2(oreg2),
        .oreg3(oreg3),
        .oreg4(oreg4),
        .oreg_count(oreg_count)
    );
endmodule
