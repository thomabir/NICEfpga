module MainV(
    input clk,
    input [1:0] sw,
    input [3:0] btn,
    input [7:0] pmodb,
    output [7:0] pmoda,
    output [3:0] led,
    output [31:0] o1,
    output [31:0] o2,
    output [31:0] o3,
    output [31:0] o4,
    output [31:0] o5,
    output [31:0] o6,
    output [31:0] o7,
    output [31:0] o8,
    output [31:0] osync
);
    MainSV main_sv (
        .clk(clk),
        .sw_i(sw),
        .btn_i(btn),
        .pmodb_i(pmodb),
        .pmoda_i(pmoda),
        .led_o(led),
        .o1(o1),
        .o2(o2),
        .o3(o3),
        .o4(o4),
        .o5(o5),
        .o6(o6),
        .o7(o7),
        .o8(o8),
        .osync(osync)
    );
endmodule
