module MainSV (
    input clk,
    input logic [1:0] sw_i,
    input logic [3:0] btn_i,
    input logic [7:0] pmodb_i,
    output logic [7:0] pmoda_o,
    output logic [3:0] led_o,
    output logic signed [31:0] oreg1,
    output logic signed [31:0] oreg2,
    output logic signed [31:0] oreg3,
    output logic signed [31:0] oreg4,
    output logic signed [31:0] oreg5,
    output logic signed [31:0] oreg6,
    output logic signed [31:0] oreg7,
    output logic signed [31:0] oreg8,
    output logic unsigned [31:0] oreg_count
);
    // reset
    logic reset;
    assign reset = btn_i[0];


    // ADC reader
    logic signed [23:0] adc1_o;
    logic signed [23:0] adc2_o;
    logic signed [23:0] adc3_o;
    logic signed [23:0] adc4_o;
    logic signed [23:0] adc5_o;
    logic signed [23:0] adc6_o;
    logic signed [23:0] adc7_o;
    logic signed [23:0] adc8_o;


    logic adc_tick_o;

    DoutReader reader (
        .clk_i(clk),
        .reset_i(reset),
        .drdy(pmodb_i[0]),
        .dclk(pmodb_i[1]),
        .din0(pmodb_i[2]),
        .din1(pmodb_i[3]),
        .din2(pmodb_i[4]),
        .din3(pmodb_i[5]),
        .ch1_o(adc1_o),  // QPD1
        .ch2_o(adc2_o),  // QPD2
        .ch3_o(adc3_o),  // sin 100 Hz (CH1)
        .ch4_o(adc4_o),  // cos 100 Hz (CH2)
        .ch5_o(adc5_o),  // NC
        .ch6_o(adc6_o),  // NC
        .ch7_o(adc7_o),  // NC
        .ch8_o(adc8_o),  // NC
        .tick_o(adc_tick_o)
    );






    module QPDInputFilter (
        input logic clk_i,
        input logic reset_i,
        input logic start_i,
        input logic signed [23:0] signal_i,
        output logic signed [23:0] signal_o,
        output logic done_o
    );

        logic signed [23:0] fir_coeffs[25] = {
            -12515,
            48061,
            103347,
            -4735,
            125381,
            304529,
            -272697,
            -405181,
            229239,
            -1126971,
            -2391966,
            1185892,
            4438326,
            1185892,
            -2391966,
            -1126971,
            229239,
            -405181,
            -272697,
            304529,
            125381,
            -4735,
            103347,
            48061,
            -12515
        };

        CompensatedCICFilter #(
            .NUM_BITS_IN(24),
            .NUM_BITS_OUT(24),
            .CIC_STAGES(2),
            .CIC_DECIMATION(128),
            .COEFF_LENGTH(25)
        ) dut (
            .clk_i  (clk_i),
            .reset_i(reset_i),
            .tick_i (start_i),
            .data_i (signal_i),
            .coeff  (fir_coeffs),
            .data_o (signal_o),
            .done_o (done_o)
        );
    endmodule


    // input filters
    logic signed [23:0] ifilt1_o;  // QPD1
    logic signed [23:0] ifilt2_o;  // QPD2
    logic signed [23:0] ifilt3_o;  // 100 Hz sin
    logic signed [23:0] ifilt4_o;  // 10 kHz ref
    logic tick_ifilt_o;

    // pipe adc1 through ad3 through the QPD input filter
    QPDInputFilter qpdifilt1 (
        .clk_i(clk),
        .reset_i(reset),
        .start_i(adc_tick_o),
        .signal_i(adc1_o),
        .signal_o(ifilt1_o),
        .done_o(tick_ifilt_o)
    );

    QPDInputFilter qpdifilt2 (
        .clk_i(clk),
        .reset_i(reset),
        .start_i(adc_tick_o),
        .signal_i(adc2_o),
        .signal_o(ifilt2_o),
        .done_o()
    );

    QPDInputFilter qpdifilt3 (
        .clk_i(clk),
        .reset_i(reset),
        .start_i(adc_tick_o),
        .signal_i(adc3_o),
        .signal_o(ifilt3_o),
        .done_o()
    );

    QPDInputFilter qpdifilt4 (
        .clk_i(clk),
        .reset_i(reset),
        .start_i(adc_tick_o),
        .signal_i(adc4_o),
        .signal_o(ifilt4_o),
        .done_o()
    );

    // Hilbert transformer to phase shift 100 Hz sin to make it cos
    logic signed [23:0] sin100;
    logic signed [23:0] cos100;
    logic hilbert_done;
    HilbertTransformerComplete #(
        .NUM_BITS(24),
        .COEFF_LENGTH(13)
    ) hilbert1 (
        .clk_i(clk),
        .tick_i(tick_ifilt_o),
        .reset_i(reset),
        .signal_i(ifilt3_o),
        .ha_coeffs({0, -28824, 0, -605240, 0, -4769003, 0, 4769003, 0, 605240, 0, 28824, 0}),
        .delay_coeffs({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0}),
        .sin_o(sin100),
        .cos_o(cos100),
        .done_o(hilbert_done)
    );

    // Then, Hilbert transformer's delay line to also shift the two QPD signals
    logic signed [23:0] qpd1_delayed;
    logic signed [23:0] qpd2_delayed;

    FIRFilter #(
        .COEFF_LENGTH(13),
        .BITWIDTH(24)
    ) qpd1_delay (
        .clk_i(clk),
        .tick_i(tick_ifilt_o),
        .signal_i(ifilt1_o),
        .signal_o(qpd1_delayed),
        .done_o(),
        .coeff({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0})
    );

    FIRFilter #(
        .COEFF_LENGTH(13),
        .BITWIDTH(24)
    ) qpd2_delay (
        .clk_i(clk),
        .tick_i(tick_ifilt_o),
        .signal_i(ifilt2_o),
        .signal_o(qpd2_delayed),
        .done_o(),
        .coeff({0, 0, 0, 0, 0, 0, 8388607, 0, 0, 0, 0, 0, 0})
    );


    // current to position
    logic signed [24:0] sum;
    logic signed [24:0] diff;

    // prefactor -1 to undo pi phase shift from inverting transimpedance amplifier
    assign sum = -(qpd1_delayed + qpd2_delayed);
    assign diff = -(qpd1_delayed - qpd2_delayed);


    // lock-in amplifier
    logic signed [23:0] x1;
    logic signed [23:0] x2;
    logic signed [23:0] i1;
    logic signed [23:0] i2;
    logic demod_done_o;

    QpdDemodulator demod (
        .clk_i(clk),
        .reset_i(reset),
        .tick_i(hilbert_done),
        .diff_i(diff[24:1]),
        .sum_i(sum[24:1]),
        .sin_i(sin100),
        .cos_i(cos100),
        .x1_o(x1),
        .x2_o(x2),
        .i1_o(i1),
        .i2_o(i2),
        .done_o(demod_done_o)
    );


    // A counter that increases by 1 every time the demodulator is updated
    logic unsigned [31:0] counter;
    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
        end
        else if (hilbert_done) begin
            counter <= counter + 1;
        end
    end


    assign oreg1 = qpd1_delayed;
    assign oreg2 = ifilt1_o;
    assign oreg3 = cos100;
    assign oreg4 = sin100;

    // assign oreg1 = ifilt1_o;
    // assign oreg2 = ifilt2_o;
    // assign oreg3 = ifilt3_o;
    // assign oreg4 = 1;

    // assign oreg1 = 1; // adc1_o;
    // assign oreg2 = adc2_o;
    // assign oreg3 = adc3_o;
    // assign oreg4 = adc4_o;

    assign oreg_count = counter;
endmodule
