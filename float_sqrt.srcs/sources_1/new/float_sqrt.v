module sqrt #(
    parameter WIDTH=11
) (
    output wire [WIDTH-1:0] o_w_root,
    output wire o_w_rdy,
    input wire i_w_clk,
    input wire i_w_rst,
    input wire [WIDTH-1:0] i_w_radicand
);

    reg [WIDTH-1:0] l_r_rad, l_r_rad_next;
    reg [WIDTH-1:0] l_r_root, l_r_root_next;
    
    reg [WIDTH+1:0] l_r_acc, l_r_acc_next;
    reg [WIDTH+1:0] l_r_verif;
    
    reg l_r_rdy, l_r_working;
    
    // Will take the square root of significands.
    // ex:  For single precision float: 11 total width of which 10 fractional
    //      will require (11 + 10) / 2 iterations to complete.
    localparam ITER = (2*WIDTH+1)>>1;
    
    integer i;
    
    always @(posedge i_w_clk) begin
        if (i_w_rst) begin
            l_r_rdy <= 0;
            l_r_working <= 1;
            i <= 0;
            l_r_root <= 0;
            l_r_rad <= i_w_radicand;
            l_r_acc <= 0;
        end else begin
            if (l_r_working) begin
                if (i == ITER) begin
                    l_r_working <= 0;
                    l_r_rdy <= 1;
                end else begin
                    i <= i+1;
                end
                l_r_acc <= l_r_acc_next;
                l_r_rad <= l_r_rad_next;
                l_r_root <= l_r_root_next;
            end
        end
    end
    
    always @(*) begin
        // Only determine next values after the inputs have been sampled
        // and the registers set to their initial values.
        if (i_w_rst) begin
            l_r_acc_next = l_r_acc;
            l_r_root_next = l_r_root;
            l_r_rad_next = l_r_rad;
        end else begin
            // If the difference between the current "lowered pairs" of digits and
            // 01 appended to the partial result is positive, set the accumulator to
            // this new value and shift two bits of the radicand into it
            // otherwise skip
            l_r_verif = l_r_acc - {l_r_root, 2'b01};
            if (l_r_verif[WIDTH+1] == 0) begin
                l_r_acc_next = {l_r_verif[WIDTH-1:0], l_r_rad[WIDTH-1:WIDTH-2]};
                l_r_root_next = {l_r_root[WIDTH-2:0], 1'b1};
            end else begin
                l_r_acc_next = {l_r_acc[WIDTH-1:0], l_r_rad[WIDTH-1:WIDTH-2]};
                l_r_root_next = l_r_root << 1;
            end
            l_r_rad_next = l_r_rad << 2;
        end
    end

    assign o_w_rdy = l_r_rdy;
    assign o_w_root = (l_r_working) ? {WIDTH{1'bx}} : l_r_root;

endmodule


module float_sqrt #(
    parameter WIDTH=16,
    parameter EXP_WIDTH=5,
    parameter MAN_WIDTH=10,
    parameter BIAS=15
)(
    output wire [WIDTH-1:0] o_w_result,
    input wire i_w_clk,
    input wire i_w_rst,
    input wire [WIDTH-1:0] i_w_radicand 
);
    localparam STATE_INIT  = 2'b00;
    localparam STATE_SETUP = 2'b01;
    localparam STATE_SQRT = 2'b11;
    localparam STATE_DONE = 2'b10;
    
    reg [2:0] l_r_state, l_r_next_state;

    reg [EXP_WIDTH-1:0] l_r_e;
    reg [MAN_WIDTH:0] l_r_m;
    
    wire [MAN_WIDTH-1:0] l_r_sqrt;
    wire l_w_sqrt_rdy, l_w_sqrt_rst;
    
    sqrt #(.WIDTH(MAN_WIDTH+1)) l_m_sqrt (
        .o_w_root(l_r_sqrt),
        .o_w_rdy(l_w_sqrt_rdy),
        .i_w_clk(i_w_clk),
        .i_w_rst(l_w_sqrt_rst),
        .i_w_radicand(l_r_m)
    );
    
    assign l_w_sqrt_rst = (l_r_state == STATE_SETUP);
    
    always @(posedge i_w_clk) begin
        if (i_w_rst) begin
            l_r_state <= STATE_INIT;
        end else begin
            l_r_state <= l_r_next_state;
        end
    end
    
    always @(*) begin
        case (l_r_state)
            STATE_INIT: begin         
                l_r_e = 0;
                l_r_m = 0;
                l_r_next_state = STATE_SETUP;
            end
            STATE_SETUP: begin
                if (i_w_radicand[WIDTH-2:MAN_WIDTH] < BIAS) begin
                    l_r_e = BIAS - ((BIAS - i_w_radicand[WIDTH-2:MAN_WIDTH]) >> 1);
                end else begin
                    l_r_e = ((i_w_radicand[WIDTH-2:MAN_WIDTH] - BIAS) >> 1) + BIAS;
                end
                // Restore hidden bit and shift right to maintain divisibility by 2
                // for the pairs
                l_r_m = {2'b01, i_w_radicand[MAN_WIDTH-1:1]};
                l_r_next_state = STATE_SQRT;
            end
            STATE_SQRT: begin
                if (l_w_sqrt_rdy) begin
                    l_r_next_state = STATE_DONE;
                end else begin
                    l_r_next_state = STATE_SQRT;
                end
            end
            STATE_DONE: begin
                l_r_next_state = STATE_DONE;
            end
        endcase
    end

    assign o_w_result = (l_r_state == STATE_DONE) ?
        {i_w_radicand[WIDTH-1], l_r_e, l_r_sqrt[MAN_WIDTH-1:0]} :
        {WIDTH{1'bx}};

endmodule
