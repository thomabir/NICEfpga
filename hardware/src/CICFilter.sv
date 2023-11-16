module CICDecimator #(
    parameter int NUM_STAGES = 4,  // number of stages
    parameter int DECIMATION_FACTOR = 8,  // reduction factor of the sampling rate
    parameter int NUM_BITS_INPUT = 16,
    parameter int NUM_BITS_OUTPUT = 16
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,  // input sampling rate
    input logic signed [NUM_BITS_INPUT-1:0] signal_i,
    output logic signed [NUM_BITS_OUTPUT-1:0] signal_o,
    output logic tick_reduced_o  // output samping rate
);
    // calculate the number of internal bits required
    parameter int num_bits_internal = $clog2(DECIMATION_FACTOR ** NUM_STAGES) + NUM_BITS_INPUT;

    // internal signals
    logic signed [num_bits_internal-1:0] signal_integrated;
    logic signed [num_bits_internal-1:0] comb_in;
    logic signed [num_bits_internal-1:0] result;

    // integrator
    Integrators #(
        .NUM_STAGES(NUM_STAGES),
        .NUM_BITS(num_bits_internal)
    ) integrators (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tick_i(tick_i),
        .signal_i(num_bits_internal'(signal_i)),
        .signal_o(signal_integrated)
    );


    // decimator tick_i generator
    parameter int size_decimator_counter = $clog2(DECIMATION_FACTOR);
    logic unsigned [size_decimator_counter-1:0] decimator_counter, next_decimator_counter;
    logic decimated_tick;
    always_ff @(posedge clk_i) begin
        if (reset_i == 1) decimator_counter <= 0;
        else if (tick_i == 1) begin
            decimator_counter <= next_decimator_counter;
        end
    end  // always_ff
    // the decimated tick_i output assignment: Careful: The decimated tick_i must only be one clock cycle long.
    // For this reason we use an and with the tick_i.
    assign decimated_tick = (decimator_counter == size_decimator_counter'(DECIMATION_FACTOR-1)) & tick_i;

    // combinational part
    assign next_decimator_counter = decimated_tick ? 0 : (decimator_counter + 1);

    // sample rate reduction
    always_ff @(posedge clk_i) begin
        if (reset_i == 1) comb_in <= 0;
        else if (decimated_tick == 1) begin
            comb_in <= signal_integrated;
        end
    end  // always_ff

    // comb filters
    Combs #(
        .NUM_STAGES(NUM_STAGES),
        .NUM_BITS(num_bits_internal)
    ) combs (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tick_i(decimated_tick),
        .signal_i(comb_in),
        .signal_o(result)
    );

    // use MSBs for the output
    assign signal_o = result[num_bits_internal-1:num_bits_internal-NUM_BITS_OUTPUT];
    assign tick_reduced_o = decimated_tick;

endmodule


/*
  Interpolator using an input running at the reduced sampling rate and interpolating
  it to the full rate.
*/
module CICInterpolator #(
    parameter int NUM_STAGES = 4,  // number of stages
    parameter int NUM_BITS_INPUT = 16,
    parameter int NUM_BITS_OUTPUT = 16,
    parameter int INTERPOLATION_FACTOR =  8 // only used to calculate the number of bits needed internally
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_reduced_i,  // tick_i for the input sampling rate
    input logic tick_i,  // tick_i for the output sampling rate
    input logic signed [NUM_BITS_INPUT-1:0] signal_i,
    output logic signed [NUM_BITS_OUTPUT-1:0] signal_o
);
    // calculate the number of internal bits
    parameter num_bits_internal = $clog2(INTERPOLATION_FACTOR ** NUM_STAGES) + NUM_BITS_INPUT;

    // output of the comb stages
    logic signed [num_bits_internal-1:0] comb_out;

    // re-sampled comb output
    logic signed [num_bits_internal-1:0] comb_out_resampled;

    logic signed [num_bits_internal-1:0] result;

    // comb filters
    Combs #(
        .NUM_STAGES(NUM_STAGES),
        .NUM_BITS(num_bits_internal)
    ) combs (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tick_i(tick_reduced_i),
        .signal_i(num_bits_internal'(signal_i)),
        .signal_o(comb_out)
    );

    // add a flipflop to reduce the length of the combinational chain
    always_ff @(posedge clk_i) begin
        if (reset_i == 1) comb_out_resampled <= 0;
        else if (tick_reduced_i == 1) comb_out_resampled <= comb_out;
    end

    // integrators (running at the higher sampling rate)
    Integrators #(
        .NUM_STAGES(NUM_STAGES),
        .NUM_BITS(num_bits_internal)
    ) integrators (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tick_i(tick_i),
        .signal_i(comb_out_resampled),
        .signal_o(result)
    );

    assign signal_o = result[num_bits_internal-1:num_bits_internal-NUM_BITS_OUTPUT];

endmodule


module Integrators #(
    parameter int NUM_STAGES,
    parameter int NUM_BITS
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS-1:0] signal_i,
    output logic signed [NUM_BITS-1:0] signal_o
);
    logic signed [NUM_BITS-1:0] inte[NUM_STAGES:0];
    logic signed [NUM_BITS-1:0] inte_delayed[NUM_STAGES:1];

    assign inte[0] = signal_i;
    genvar k;
    generate
        for (k = 0; k < NUM_STAGES; k++) begin : gen_int
            // adders
            assign inte[k+1] = inte[k] + inte_delayed[k+1];

            // flip-flops
            always_ff @(posedge clk_i) begin
                if (reset_i == 1) inte_delayed[k+1] <= 0;
                else if (tick_i == 1) inte_delayed[k+1] <= inte[k+1];
            end  // always_ff
        end  // gen_int
    endgenerate
    assign signal_o = inte_delayed[NUM_STAGES];
endmodule


module Combs #(
    parameter int NUM_STAGES,
    parameter int NUM_BITS = 24  // number of bits per sample
) (
    input logic clk_i,
    input logic reset_i,
    input logic tick_i,
    input logic signed [NUM_BITS-1:0] signal_i,
    output logic signed [NUM_BITS-1:0] signal_o
);
    logic signed [NUM_BITS-1:0] comb[NUM_STAGES:0];
    logic signed [NUM_BITS-1:0] comb_delayed[NUM_STAGES-1:0];

    // comb filter stages
    assign comb[0] = signal_i;
    genvar k;
    generate
        for (k = 0; k < NUM_STAGES; k++) begin : gen_comb
            // subtractors
            assign comb[k+1] = comb[k] - comb_delayed[k];

            // flip-flops
            always_ff @(posedge clk_i) begin
                if (reset_i == 1) comb_delayed[k] <= 0;
                else if (tick_i == 1) begin
                    comb_delayed[k] <= comb[k];
                end
            end  // always_ff
        end  // gen_int
    endgenerate
    assign signal_o = comb[NUM_STAGES];

endmodule
