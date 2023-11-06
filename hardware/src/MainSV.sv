module MainSV (
    input clk,
    input logic [1:0] sw_i,
    input logic [3:0] btn_i,
    input logic [7:0] pmodb_i,
    output logic [7:0] pmoda_o,
    output logic [3:0] led_o,
    output logic signed [31:0] oreg1,
    output logic signed [31:0] oreg2,
    output logic unsigned [31:0] oreg3
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
        .ch1_o(adc1_o), // QPD1
        .ch2_o(adc2_o), // QPD2
        .ch3_o(adc3_o), // sin
        .ch4_o(adc4_o), // cos
        .ch5_o(adc5_o), // NC
        .ch6_o(adc6_o), // NC
        .ch7_o(adc7_o), // NC
        .ch8_o(adc8_o), // NC
        .tick_o(adc_tick_o)
    );


    // input filters
    logic signed [23:0] ifilt1_o; // QPD1
    logic signed [23:0] ifilt2_o; // QPD2
    logic signed [23:0] ifilt3_o; // sin
    logic signed [23:0] ifilt4_o; // cos
    logic tick_ifilt_o;

    InputFilter ifilt1 (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (adc_tick_o),
        .data_i (adc1_o),
        .data_o (ifilt1_o),
        .tick_o (tick_ifilt_o)
    );

    InputFilter ifilt2 (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (adc_tick_o),
        .data_i (adc2_o),
        .data_o (ifilt2_o),
        .tick_o ()
    );

    InputFilter ifilt3 (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (adc_tick_o),
        .data_i (adc3_o),
        .data_o (ifilt3_o),
        .tick_o ()
    );

    InputFilter ifilt4 (
        .clk_i  (clk),
        .reset_i(reset),
        .tick_i (adc_tick_o),
        .data_i (adc4_o),
        .data_o (ifilt4_o),
        .tick_o ()
    );

    // current to position
    logic signed [24:0] sum;
    logic signed [24:0] diff;

    assign sum  = - (ifilt1_o + ifilt2_o); // prefactor -1 to undo pi phase shift from inverting transimpedance amplifier
    assign diff = - (ifilt1_o - ifilt2_o); // prefactor -1


    // lock-in amplifier
    logic signed [23:0] x1;
    logic signed [23:0] x2;
    logic signed [23:0] i1;
    logic signed [23:0] i2;
    logic demod_done_o;

    QpdDemodulator demod (
        .clk_i(clk),
        .reset_i(reset),
        .tick_i(tick_ifilt_o),
        .diff_i(diff[24:1]),
        .sum_i(sum[24:1]),
        .sin_i(ifilt3_o),
        .cos_i(ifilt4_o),
        .x1_o(x1),
        .y2_o(x2),
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
        else if (demod_done_o) begin
            counter <= counter + 1;
        end
    end


    assign oreg1 = x1;
    assign oreg2 = x2;
    assign oreg3 = counter;
endmodule
