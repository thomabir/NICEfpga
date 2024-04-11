module MainSV (
    input clk,
    input logic [1:0] sw_i,
    input logic [3:0] btn_i,
    input logic [7:0] pmodb_i,
    input logic [7:0] pmoda_i,
    output logic [3:0] led_o,

    // ADC raw data
    output logic signed [31:0] adc_shear1,
    output logic signed [31:0] adc_shear2,
    output logic signed [31:0] adc_shear3,
    output logic signed [31:0] adc_shear4,
    output logic signed [31:0] adc_point1,
    output logic signed [31:0] adc_point2,
    output logic signed [31:0] adc_point3,
    output logic signed [31:0] adc_point4,
    output logic signed [31:0] adc_sine_ref,
    output logic signed [31:0] adc_opd_ref,

    // processed data
    output logic signed [31:0] opd_x,
    output logic signed [31:0] opd_y,

    // clock counters for synchronization
    output logic unsigned [32:0] osync
);
    // reset
    logic reset;
    assign reset = btn_i[0];

    // ADC1
    logic adc1_tick;
    DoutReader adc1 (
        .clk_i(clk),
        .reset_i(reset),
        .drdy(pmodb_i[0]),
        .dclk(pmodb_i[1]),
        .din0(pmodb_i[2]),
        .din1(pmodb_i[3]),
        .din2(pmodb_i[4]),
        .din3(pmodb_i[5]),
        .ch1_o(adc_shear1),
        .ch2_o(adc_shear2),
        .ch3_o(adc_shear3),
        .ch4_o(adc_shear4),
        .ch5_o(adc_point1),
        .ch6_o(adc_point2),
        .ch7_o(adc_point3),
        .ch8_o(adc_point4),
        .tick_o(adc1_tick)
    );

    // ADC2
    DoutReader adc2 (
        .clk_i(clk),
        .reset_i(reset),
        .drdy(pmoda_i[0]),
        .dclk(pmoda_i[1]),
        .din0(pmoda_i[2]),
        .din1(pmoda_i[3]),
        .din2(pmoda_i[4]),
        .din3(pmoda_i[5]),
        .ch1_o(adc_sine_ref),
        .ch2_o(adc_opd_ref),
        .ch3_o(), // NC
        .ch4_o(), // NC
        .ch5_o(), // NC
        .ch6_o(), // NC
        .ch7_o(), // NC
        .ch8_o(), // NC
        .tick_o()
    );

    // tick_o is high for one clock cycle, exactly 100 clock cycles after tick_i is high
    module Tick100 (
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

    // generate master_tick from adc1_tick, to avoid clock jitter problems
    logic adc_master_tick;
    Tick100 master_tick_generator (
        .clk_i(clk),
        .reset_i(reset),
        .tick_i(adc1_tick),
        .tick_o(adc_master_tick)
    );

    //
    // OPD signals
    //

    // add all photocurrents to get the equivalent of a single photodiode
    // logic signed [23:0] sum_opd;
    // assign sum_opd = shear1 + shear2;

    // input filters
    logic signed [23:0] ifilt_sum_opd_o;  // QPD1 + QPD2
    logic signed [23:0] ifilt_ref_opd_o;  // 10 kHz ref
    logic tick_ifilt_opd_o;

    module OpdInputFilter (
        input logic clk_i,
        input logic reset_i,
        input logic tick_i,
        input logic signed [23:0] data_i,
        output logic signed [23:0] data_o,
        output logic tick_o
    );

        FIRFilter #(
            .COEFF_LENGTH(41)
        ) input_fir (
            .clk_i(clk_i),
            .tick_i(tick_i),
            .signal_i(data_i),
            .signal_o(data_o),
            .done_o(tick_o),
            .coeff({
                3131,
                3088,
                -7302,
                -34808,
                -78326,
                -124386,
                -150791,
                -139637,
                -93913,
                -46108,
                -48658,
                -145320,
                -336117,
                -557017,
                -692472,
                -622718,
                -286880,
                270726,
                899702,
                1395544,
                1583627,
                1395544,
                899702,
                270726,
                -286880,
                -622718,
                -692472,
                -557017,
                -336117,
                -145320,
                -48658,
                -46108,
                -93913,
                -139637,
                -150791,
                -124386,
                -78326,
                -34808,
                -7302,
                3088,
                3131
            })
        );
    endmodule

    OpdInputFilter opdifilt_sum_opd (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (adc_master_tick),
        .data_i (adc_shear1),
        .data_o (ifilt_sum_opd_o),
        .tick_o ()
    );

    OpdInputFilter opdifilt_ref_opd (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (adc_master_tick),
        .data_i (adc_opd_ref),
        .data_o (ifilt_ref_opd_o),
        .tick_o (tick_ifilt_opd_o)
    );

    // lock-in amplifier
    logic opd_done_o;

    LockInAmplifier opd_lockin (
        .clk_i(clk),
        .reset_i(reset),
        .tick_i(tick_ifilt_opd_o),
        .ch1_i(ifilt_ref_opd_o),
        .ch2_i(ifilt_sum_opd_o),
        .x_o(opd_x),
        .y_o(opd_y),
        .done_o(opd_done_o)
    );


    //
    // Position signals
    //


    // module QPDInputFilter (
    //     input logic clk_i,
    //     input logic reset_i,
    //     input logic start_i,
    //     input logic signed [23:0] signal_i,
    //     output logic signed [23:0] signal_o,
    //     output logic done_o
    // );

    //     CompensatedCICFilter #(
    //         .NUM_BITS_IN(24),
    //         .NUM_BITS_OUT(24),
    //         .CIC_STAGES(5),
    //         .CIC_DECIMATION(16),
    //         .COEFF_LENGTH(25)
    //     ) dut (
    //         .clk_i(clk_i),
    //         .reset_i(reset_i),
    //         .tick_i(start_i),
    //         .data_i(signal_i),
    //         .coeff({
    //             -111761,
    //             3923,
    //             333871,
    //             -67106,
    //             -354581,
    //             213822,
    //             -333103,
    //             -367217,
    //             1856848,
    //             374568,
    //             -3537164,
    //             -160702,
    //             4277397,
    //             -160702,
    //             -3537164,
    //             374568,
    //             1856848,
    //             -367217,
    //             -333103,
    //             213822,
    //             -354581,
    //             -67106,
    //             333871,
    //             3923,
    //             -111761
    //         }),
    //         .data_o(signal_o),
    //         .done_o(done_o)
    //     );
    // endmodule


    // // input filters
    // logic signed [23:0] ifilt1_o;  // QPD1
    // logic signed [23:0] ifilt2_o;  // QPD2
    // logic signed [23:0] ifilt3_o;  // 500 Hz sin
    // logic tick_ifilt_o;

    // // pipe adc1 through ad3 through the QPD input filter
    // QPDInputFilter qpdifilt1 (
    //     .clk_i(clk),
    //     .reset_i(reset),
    //     .start_i(adc1_tick),
    //     .signal_i(shear1),
    //     .signal_o(ifilt1_o),
    //     .done_o(tick_ifilt_o)
    // );

    // QPDInputFilter qpdifilt2 (
    //     .clk_i(clk),
    //     .reset_i(reset),
    //     .start_i(adc1_tick),
    //     .signal_i(shear2),
    //     .signal_o(ifilt2_o),
    //     .done_o()
    // );

    // QPDInputFilter qpdifilt3 (
    //     .clk_i(clk),
    //     .reset_i(reset),
    //     .start_i(adc1_tick),
    //     .signal_i(shear3),
    //     .signal_o(ifilt3_o),
    //     .done_o()
    // );



    // // Hilbert transformer to phase shift 100 Hz sin to make it cos
    // logic signed [23:0] sin100;
    // logic signed [23:0] cos100;
    // logic hilbert_done;
    // HilbertTransformerComplete #(
    //     .NUM_BITS(24),
    //     .COEFF_LENGTH(13)
    // ) hilbert1 (
    //     .clk_i(clk),
    //     .tick_i(tick_ifilt_o),
    //     .reset_i(reset),
    //     .signal_i(ifilt3_o),
    //     .ha_coeffs({0, -28824, 0, -605240, 0, -4769003, 0, 4769003, 0, 605240, 0, 28824, 0}),
    //     .delay_coeffs({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0}),
    //     .sin_o(sin100),
    //     .cos_o(cos100),
    //     .done_o(hilbert_done)
    // );

    // // Then, Hilbert transformer's delay line to also shift the two QPD signals
    // logic signed [23:0] qpd1_delayed;
    // logic signed [23:0] qpd2_delayed;

    // FIRFilter #(
    //     .COEFF_LENGTH(13),
    //     .BITWIDTH(24)
    // ) qpd1_delay (
    //     .clk_i(clk),
    //     .tick_i(tick_ifilt_o),
    //     .signal_i(ifilt1_o),
    //     .signal_o(qpd1_delayed),
    //     .done_o(),
    //     .coeff({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0})
    // );

    // FIRFilter #(
    //     .COEFF_LENGTH(13),
    //     .BITWIDTH(24)
    // ) qpd2_delay (
    //     .clk_i(clk),
    //     .tick_i(tick_ifilt_o),
    //     .signal_i(ifilt2_o),
    //     .signal_o(qpd2_delayed),
    //     .done_o(),
    //     .coeff({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0})
    // );


    // // current to position
    // logic signed [24:0] sum;
    // logic signed [24:0] diff;

    // // prefactor -1 to undo pi phase shift from inverting transimpedance amplifier
    // assign sum = -(qpd1_delayed + qpd2_delayed);
    // assign diff = -(qpd1_delayed - qpd2_delayed);


    // // lock-in amplifier
    // logic signed [47:0] x1;
    // logic signed [47:0] x2;
    // logic signed [47:0] i1;
    // logic signed [47:0] i2;
    // logic demod_done_o;

    // QpdDemodulator demod (
    //     .clk_i(clk),
    //     .reset_i(reset),
    //     .tick_i(hilbert_done),
    //     .diff_i(diff[24:1]),
    //     .sum_i(sum[24:1]),
    //     .sin_i(sin100),
    //     .cos_i(cos100),
    //     .x1_o(x1),
    //     .x2_o(x2),
    //     .i1_o(i1),
    //     .i2_o(i2),
    //     .done_o(demod_done_o)
    // );


    // // A counter that increases by 1 every time the position signals are updated
    // logic unsigned [31:0] counter_pos;
    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         counter_pos <= 0;
    //     end
    //     else if (hilbert_done) begin
    //         counter_pos <= counter_pos + 1;
    //     end
    // end

    // A counter that increases every time the ADC is read
    logic unsigned [32:0] counter_opd;
    always_ff @(posedge clk) begin
        if (reset) begin
            counter_opd <= 0;
        end
        else if (adc1_tick) begin
            counter_opd <= counter_opd + 1;
        end
    end


    // send only the 32 MSBs, as that is the max width of the AXI GPIO interface
    // assign oreg1 = x1[47:16];
    // assign oreg2 = i1[47:16];
    // assign oreg3 = x2[47:16];
    // assign oreg4 = i2[47:16];
    assign osync = counter_opd;
endmodule
