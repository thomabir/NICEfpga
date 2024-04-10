module MainV(
    input clk,
    input [1:0] sw,
    input [3:0] btn,
    input [7:0] pmodb,
    input [7:0] pmoda,
    output [3:0] led,

    output [31:0] adc_shear1,
    output [31:0] adc_shear2,
    output [31:0] adc_shear3,
    output [31:0] adc_shear4,
    output [31:0] adc_point1,
    output [31:0] adc_point2,
    output [31:0] adc_point3,
    output [31:0] adc_point4,
    output [31:0] adc_sine_ref,
    output [31:0] adc_opd_ref,

    output [31:0] opd_x,
    output [31:0] opd_y,

    output [31:0] osync
);
    MainSV main_sv (
        .clk(clk),
        .sw_i(sw),
        .btn_i(btn),
        .pmodb_i(pmodb),
        .pmoda_i(pmoda),
        .led_o(led),
        .adc_shear1(adc_shear1),
        .adc_shear2(adc_shear2),
        .adc_shear3(adc_shear3),
        .adc_shear4(adc_shear4),
        .adc_point1(adc_point1),
        .adc_point2(adc_point2),
        .adc_point3(adc_point3),
        .adc_point4(adc_point4),
        .adc_sine_ref(adc_sine_ref),
        .adc_opd_ref(adc_opd_ref),
        .opd_x(opd_x),
        .opd_y(opd_y),
        .osync(osync)
    );
endmodule
