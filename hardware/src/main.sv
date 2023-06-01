`timescale 1ns / 1ps

module main_sv (
    input clk,
    input [1:0] sw_i,
    input [3:0] btn_i,

    input  [7:0] pmodb_i,
    output [7:0] pmoda_o,

    output [ 3:0] led_o,
    output [31:0] oreg1
);

  logic reset;
  assign reset = btn_i[0];





  // ADC reader
  logic signed [23:0] adc1_o;
  logic signed [23:0] adc2_o;

  DoutReader reader1 (
      .clk_i(clk),
      .reset_i(reset),
      .drdy(pmodb_i[0]),
      .dclk(pmodb_i[1]),
      .din(pmodb_i[2]),
      .ch1_o(adc1_o),
      .ch2_o(adc2_o)
      //        .tick_o(tick1_o)
  );


  // input filters
  logic signed [23:0] ifilt1_o;
  //    logic signed [15:0] ifilt2_o;
  logic tick1_o;

  InputFilter ifilt1 (
      .clk_i(clk),
      .reset_i(reset),
      .adc_i(adc1_o),
      .filtered_o(ifilt1_o),
      .tick_o(tick1_o)
  );

  //    InputFilter ifilt2 (
  //        .clk_i(clk),
  //        .reset_i(reset),
  //        .adc_i(adc2_o),
  //        .filtered_o(ifilt2_o)
  //    );


  // Zero-crossing detection
  //    logic unsigned[31:0] timer;
  //    logic pulse1;
  //    logic pulse2;

  //    logic unsigned[31:0] time1;
  //    logic unsigned[31:0] time2;


  //    Timer timer1
  //    (
  //        .clk_i(clk),
  //        .reset_i(reset),
  //        .time_o(timer)
  //    );

  // TODO change to 24 bit

  //    ZeroCrossingSimple z1(
  //        .clk_i(clk),
  //        .reset_i(reset),
  //        .current_time_i(timer),
  //        .data_i(ifilt1_o), // input waveform
  //        .pulse_o(pulse1), // 1 during a positive-going zero crossing
  //        .last_crossing_time_o(time1)
  //    );


  //    ZeroCrossingSimple z2(
  //        .clk_i(clk),
  //        .reset_i(reset),
  //        .current_time_i(timer),
  //        .data_i(ifilt2_o), // input waveform
  //        .pulse_o(pulse2), // 1 during a positive-going zero crossing
  //        .last_crossing_time_o(time2)
  //    );


  // Frequency-Phase detection
  //    logic unsigned[31:0] freq1;
  //    logic unsigned[31:0] freq2;
  //    logic signed[31:0] phase;
  //    logic done_pulse;

  //    FreqPhaseDetector d1
  //    (
  //        .clk_i(clk),
  //        .reset_i(reset),
  //        .crossing_time_1_i(time1), // input waveform
  //        .crossing_time_2_i(time2), // input waveform
  //        .pulse_i(pulse2),
  //        .freq1_o(freq1),
  //        .freq2_o(freq2),
  //        .phase_o(phase),
  //        .done_pulse_o(done_pulse)
  //    );

  DacWriter dac1 (
      .clk_i(clk),
      .reset_i(reset),
      .start_i(tick1_o),
      .spi_sclk_o(pmoda_o[6]),
      .spi_mosi_o(pmoda_o[4]),
      .spi_cs_o(pmoda_o[5]),
      .data_i(ifilt1_o[23:8])
  );


  //    DacWriter2 dac12(
  //        .clk_i(clk),
  //        .reset_i(reset),
  //        .start_i(tick1_o),
  //        .spi_clk_o(pmoda_o[6]),
  //        .spi_mosi_o(pmoda_o[4]),
  //        .spi_cs_o(pmoda_o[5]),
  //        .data_i(adc1_o[23:8]) 
  //    );


  // assign the LSBs of oreg1 to interp1_out, the MSBs to 0
  assign oreg1 = adc1_o;



endmodule
