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
    logic adc_tick_o;

    DoutReader reader (
        .clk_i(clk),
        .reset_i(reset),
        .drdy(pmodb_i[0]),
        .dclk(pmodb_i[1]),
        .din(pmodb_i[2]),
        .ch1_o(adc1_o),
        .ch2_o(adc2_o),
        .tick_o(adc_tick_o)
    );


    // input filters
    logic signed [23:0] ifilt1_o;
    logic signed [23:0] ifilt2_o;
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


    // lock-in amplifier
    logic signed [23:0] x;
    logic signed [23:0] y;
    logic lockin_done_o;

    LockInAmplifier lockin (
        .clk_i(clk),
        .reset_i(reset),
        .tick_i(tick_ifilt_o),
        .ch1_i(ifilt1_o),
        .ch2_i(ifilt2_o),
        .x_o(x),
        .y_o(y),
        .done_o(lockin_done_o)
    );


    // A counter that increases by 1 every time the lock-in amplifier is updated
    logic unsigned [7:0] counter1;
    always_ff @(posedge clk) begin
        if (reset) begin
            counter1 <= 0;
        end
        else if (lockin_done_o) begin
            counter1 <= counter1 + 1;
        end
    end


    assign oreg1 = x;
    assign oreg2 = y;
    assign oreg3 = counter;
endmodule
