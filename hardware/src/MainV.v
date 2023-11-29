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
    output [31:0] oreg5,
    output [31:0] oreg6,
    output [31:0] oreg7,
    output [31:0] oreg8,
    output [31:0] oreg_count_pos,
    output [31:0] oreg_count_opd
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
        .oreg5(oreg5),
        .oreg6(oreg6),
        .oreg7(oreg7),
        .oreg8(oreg8),
        .oreg_count_pos(oreg_count_pos),
        .oreg_count_opd(oreg_count_opd)
    );
endmodule
