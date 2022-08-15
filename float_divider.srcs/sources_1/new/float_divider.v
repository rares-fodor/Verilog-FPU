module divider #(
    parameter WIDTH=11
) (
    output wire [WIDTH-1:0] o_w_quot,
    output wire o_w_rdy,
    input wire i_w_clk,
    input wire i_w_rst,
    input wire [WIDTH-1:0] i_w_num,
    input wire [WIDTH-1:0] i_w_den
);
    // Double width for shifting (when "lowering zeroes")
    reg [(2*WIDTH)-1:0] l_r_num;
    reg [(2*WIDTH)-1:0] l_r_num_next;

    reg l_r_rdy, l_r_working;
    integer i;

    reg [WIDTH-1:0] quot;
    
    always @(posedge i_w_clk) begin
        if (i_w_rst) begin
            l_r_rdy <= 0;
            l_r_working <= 1;
            quot <= 0;
            i <= WIDTH-1;
            l_r_num <= i_w_num;
        end else if (l_r_working) begin
            if (i == 0) begin
                l_r_working <= 0;
                l_r_rdy <= 1;
            end else begin
                i <= i - 1;
                l_r_num <= l_r_num_next;
            end
        end
    end

    always @(*) begin
        if (l_r_num >= i_w_den) begin
            l_r_num_next = (l_r_num - i_w_den) << 1;
            quot[i] = 1;
        end else begin
            l_r_num_next = l_r_num << 1;
        end
    end

    assign o_w_rdy = l_r_rdy;
    assign o_w_quot = quot;

endmodule

module float_divider #(
    // Default values for half precision floating point
    parameter WIDTH=16,
    parameter EXP_WIDTH=5,
    parameter MAN_WIDTH=10,
    parameter BIAS=15
) (
    output wire [WIDTH-1:0] o_w_q,
    input wire i_w_clk,
    input wire i_w_rst,
    input wire [WIDTH-1:0] i_w_a,
    input wire [WIDTH-1:0] i_w_b
);

    localparam STATE_INIT = 2'b00;
    localparam STATE_SETUP = 2'd01;
    localparam STATE_DIVIDING = 2'b11;
    localparam STATE_DONE = 2'b10;
    
    reg [2:0] l_r_state;
    reg [2:0] l_r_next_state;
    
    reg l_r_s;
    
    reg [EXP_WIDTH-1:0] l_r_ea;
    reg [EXP_WIDTH-1:0] l_r_eb; 

    reg [MAN_WIDTH:0] l_r_ma;
    reg [MAN_WIDTH:0] l_r_mb;

    reg [EXP_WIDTH-1:0] l_r_e;
    reg [MAN_WIDTH:0] l_r_m;
    
    wire l_w_div_rdy, l_w_div_rst;
    wire [MAN_WIDTH:0] l_w_div_quot;
    
    // Initialize parameter width with mantissa length + 1 (for the hidden bit)
    
    divider #(.WIDTH(MAN_WIDTH+1)) l_m_divider (
       .o_w_quot(l_w_div_quot),
       .o_w_rdy(l_w_div_rdy),
       .i_w_clk(i_w_clk),
       .i_w_rst(l_w_div_rst),
       .i_w_num(l_r_ma),
       .i_w_den(l_r_mb)
    );
    
    assign l_w_div_rst = (l_r_state == STATE_SETUP);
    
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
                l_r_next_state = STATE_SETUP;
            end
            STATE_SETUP: begin
                // Set sign
                l_r_s = i_w_a[WIDTH-1] ^ i_w_b[WIDTH-1];
            
                // Extract exponents
                l_r_ea = i_w_a[WIDTH-2:MAN_WIDTH];
                l_r_eb = i_w_b[WIDTH-2:MAN_WIDTH];
            
                // Extract significands
                l_r_ma = {1'b1, i_w_a[MAN_WIDTH-1:0]};
                l_r_mb = {1'b1, i_w_b[MAN_WIDTH-1:0]};
                
                // Subtract exponents and adjust with bias
                if (l_r_ea <= l_r_eb) begin
                  l_r_e = BIAS - (l_r_eb - l_r_ea);
                end else if (l_r_ea > l_r_eb) begin
                  l_r_e = BIAS + l_r_ea - l_r_eb;
                end
                
                l_r_next_state = STATE_DIVIDING;
            end
            STATE_DIVIDING: begin
                if (l_w_div_rdy) begin
                    l_r_next_state = STATE_DONE;
                end else begin
                    l_r_next_state = STATE_DIVIDING;
                end
            end
            STATE_DONE: begin
                if (l_w_div_quot[MAN_WIDTH] == 1'b0) begin
                    l_r_m = (l_w_div_quot << 1);    // Normalize significand if there is a leading 0
                    l_r_e = l_r_e - 1;              // Adjust exponent
                end else begin
                    l_r_m = l_w_div_quot;
                end
                l_r_next_state = STATE_DONE;
            end
        endcase
        
    end
    
    assign o_w_q = (l_r_state == STATE_DONE) ?
        {l_r_s, l_r_e, l_r_m[MAN_WIDTH-1:0]} :
        0;
        
endmodule
