`timescale 1ns / 1ps

module main_sv (
    input clk,
    input [1:0] sw_i,
    input [3:0] btn_i,

    input [7:0] pmodb_i,
    output [7:0] pmoda_o,

    output [3:0] led_o,
    output [31:0] oreg1
);

    logic reset;
    logic reader1_tick_o;
    assign reset = btn_i[0];





    // ADC reader
    logic signed [23:0] adc1_o;
    //   logic signed [23:0] adc2_o;

    DoutReader reader1 (
        .clk_i(clk),
        .reset_i(reset),
        .drdy(pmodb_i[0]),
        .dclk(pmodb_i[1]),
        .din(pmodb_i[2]),
        .ch1_o(adc1_o),
        .ch2_o(adc2_o),
        .tick_o(reader1_tick_o)
    );

    // A counter that increases by 1 every time reader1_tick_o is asserted
    logic unsigned [7:0] counter1;
    always_ff @(posedge clk) begin
        if (reset) begin
            counter1 <= 0;
        end
        else if (reader1_tick_o) begin
            counter1 <= counter1 + 1;
        end
    end


    // input filters
    logic signed [23:0] ifilt1_o;
    logic signed [23:0] ifilt2_o;
    logic tick_ifilt_o;

    InputFilter ifilt1 (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (reader1_tick_o),
        .data_i (adc1_o),
        .data_o (ifilt1_o),
        .tick_o (tick1_o)
    );

    InputFilter ifilt2 (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (reader1_tick_o),
        .data_i (adc2_o),
        .data_o (ifilt2_o),
        .tick_o ()
    );




    //   DacWriter dac1 (
    //       .clk_i(clk),
    //       .reset_i(reset),
    //       .start_i(tick1_o),
    //       .spi_sclk_o(pmoda_o[6]),
    //       .spi_mosi_o(pmoda_o[4]),
    //       .spi_cs_o(pmoda_o[5]),
    //       .data_i(ifilt1_o[23:8])
    //   );


    //    DacWriter2 dac12(
    //        .clk_i(clk),
    //        .reset_i(reset),
    //        .start_i(tick1_o),
    //        .spi_clk_o(pmoda_o[6]),
    //        .spi_mosi_o(pmoda_o[4]),
    //        .spi_cs_o(pmoda_o[5]),
    //        .data_i(adc1_o[23:8])
    //    );


    // the 8 MSBs of oreg are the counter, the 24 LSBs are the ADC value

    // depending on sw0, return either the counter or the ADC value
    assign oreg1 = {counter1, ifilt1_o};




endmodule
