`timescale 1ns / 1ps
module test_float_divider;
    //Inputs
    reg [15:0] l_r_a;
    reg [15:0] l_r_b;
    reg l_r_clk;
    reg l_r_rst;

    //Outputs
    wire [15:0] l_w_quot;
    
    //Module initialization
    float_divider l_m_divider(
        .o_w_q(l_w_quot),
        .i_w_clk(l_r_clk),
        .i_w_rst(l_r_rst),
        .i_w_a(l_r_a),
        .i_w_b(l_r_b)
        );

    always #2 l_r_clk = ~l_r_clk;
    
    //Simulation tests
    initial begin
        //wave files
        $dumpfile("test.vcd");
        // dumpp all variables
        $dumpvars;

        l_r_clk = 0;
        l_r_rst = 1;
        #10
        
        l_r_rst = 0;
        
        // -3 / 15.5 = -0.1935
        // rezultat: -0.1934
        l_r_a = 16'b1100001000000000;
        l_r_b = 16'b0100101111000000;
        #100;
        
        l_r_rst = 1;
        #10
        
        
        l_r_rst = 0;
        // 0.5 / 0.25 = 2
        // rezultat: 2
        l_r_a = 16'b0011100000000000;
        l_r_b = 16'b0011010000000000;
        #100;
        
        l_r_rst = 1;
        #10
        
        l_r_rst = 0;
        // 32768 / 1.001 = 32735.26
        // rezultat: 32736
        l_r_a = 16'b0111100000000000;
        l_r_b = 16'b0011110000000001;
        #100;
        
        l_r_rst = 1;
        #10
        
  
        //finish the simulation
        $finish;
    end
endmodule