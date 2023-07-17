module FirFSM (
    // Interface signals
    input clk_i,
    input tick_i,
    output reg done_o,
    // Data Signals
    input [23:0] signal_i,
    output reg [23:0] signal_o
);
    // Coefficient Storage
    reg signed [23:0] coeff[40:0];
    reg signed [23:0] data[40:0];
    // Counter for iterating through coefficients.
    reg [5:0] count;
    // Accumulator
    reg signed [48:0] acc;

    // State machine signals
    localparam IDLE = 0;
    localparam RUN = 1;

    reg state;

    initial begin
        coeff[0] = 2366;
        coeff[1] = -11888;
        coeff[2] = 7427;
        coeff[3] = 28174;
        coeff[4] = -48980;
        coeff[5] = -18087;
        coeff[6] = 121306;
        coeff[7] = -70863;
        coeff[8] = -168958;
        coeff[9] = 268147;
        coeff[10] = 78244;
        coeff[11] = -517069;
        coeff[12] = 271034;
        coeff[13] = 641954;
        coeff[14] = -922789;
        coeff[15] = -379093;
        coeff[16] = 1819401;
        coeff[17] = -579383;
        coeff[18] = -3070759;
        coeff[19] = 2733702;
        coeff[20] = 8019381;
        coeff[21] = 2733702;
        coeff[22] = -3070759;
        coeff[23] = -579383;
        coeff[24] = 1819401;
        coeff[25] = -379093;
        coeff[26] = -922789;
        coeff[27] = 641954;
        coeff[28] = 271034;
        coeff[29] = -517069;
        coeff[30] = 78244;
        coeff[31] = 268147;
        coeff[32] = -168958;
        coeff[33] = -70863;
        coeff[34] = 121306;
        coeff[35] = -18087;
        coeff[36] = -48980;
        coeff[37] = 28174;
        coeff[38] = 7427;
        coeff[39] = -11888;
        coeff[40] = 2366;
    end
    always @(posedge clk_i) begin : capture
        integer i;
        if (tick_i) begin
            for (i = 0; i < 40; i = i + 1) begin
                data[i+1] <= data[i];
            end
            data[0] <= signal_i;
        end
    end
    always @(posedge clk_i) begin
        case (state)
            IDLE: begin
                done_o <= 1'b0;
                if (tick_i) begin
                    count <= 40;
                    acc <= 0;
                    state <= RUN;
                end
            end

            RUN: begin
                count <= count - 1'b1;
                acc <= acc + data[count] * coeff[count];
                if (count == 0) begin
                    state <= IDLE;
                    done_o <= 1'b1;
                end
            end
        endcase
    end
    always @(posedge clk_i) begin
        if (done_o) begin
            // Saturate if necessary
            if (acc >= 2 ** 46) begin
                signal_o <= 8388607;
            end
            else if (acc < -(2 ** 46)) begin
                signal_o <= -8388608;
            end
            else begin
                signal_o <= acc[46:23];
            end
        end
    end
endmodule
