`timescale 1ns / 1ps
module test_float_sqrt;
    reg l_r_clk;
    reg l_r_rst;
    wire [15:0] result;
    reg [15:0] l_r_radicand;
        
//    sqrt #(.WIDTH(11)) l_m_sqrt(
//        .o_w_root(l_w_root),
//        .o_w_rdy(l_w_rdy),
//        .i_w_clk(l_r_clk),
//        .i_w_rst(l_r_rst),
//        .i_w_radicand(l_r_rad)
//        );
        
    float_sqrt l_m_float_sqrt(
        .o_w_result(result),
        .i_w_clk(l_r_clk),
        .i_w_rst(l_r_rst),
        .i_w_radicand(l_r_radicand)
        );

    always #2 l_r_clk = ~l_r_clk;
    
    //Simulation tests
    initial begin
        //wave files
        $dumpfile("test.vcd");
        // dumpp all variables
        $dumpvars;

        l_r_clk = 0;

        // input: 81
        // result: 9
        l_r_radicand = 16'b0101010100010000;
        l_r_rst = 1;
        #4
        l_r_rst = 0;
        #100
        
        // input: 0.03077
        // result: 0.1756
        l_r_radicand = 16'b0010011111100000;
        l_r_rst = 1;
        #4
        l_r_rst = 0;
        #100
        
        // input: 1.4991
        // result: 1.224
        l_r_radicand = 16'b0011110111111111;
        l_r_rst = 1;
        #4
        l_r_rst = 0;
        #100
        
        // input: 512
        // result:
        l_r_radicand = 16'b0110000000000000;
        l_r_rst = 1;
        #4
        l_r_rst = 0;
        #100
        
  
        //finish the simulation
        $finish;
    end
endmodule