// Writes data to the AD5542 DAC

module DacWriter (
    input clk_i,  // FPGA clock
    input reset_i,  // reset
    input start_i,  // start the transaction
    output is_idle_o,  // 1 if in idle state

    // SPI signals
    output spi_sclk_o,  // SCLK = clk_i / (2 * CLOCK_DIVIDE)
    output spi_mosi_o,  // MOSI
    output spi_cs_o,  // /CS

    // FPGA data
    input signed [15:0] data_i  // data to send
);


    logic unsigned [15:0] data_calibrated;
    assign data_calibrated = 16'($unsigned(
            data_i
        ) + 16'h8000);  // convert from signed to unsigned with offset
    //    assign data_calibrated = 16'b1000000000000000;

    // Initialize the SPI controller
    SpiController #(
        .CLOCK_DIVIDE(2),
        .FRAME_WIDTH(16)
    ) spi_controller (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .start_i(start_i),
        .is_idle_o(is_idle_o),
        .spi_sclk_o(spi_sclk_o),
        .spi_mosi_o(spi_mosi_o),
        .spi_cs_o(spi_cs_o),
        .data_i(data_calibrated)
    );


endmodule
