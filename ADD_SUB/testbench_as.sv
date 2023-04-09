`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 16:05:27
// Design Name: 
// Module Name: testbench_as
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module testbench_as;
  logic clk, rst, signal;
  logic   [31:0] a_fpn;
  logic   [31:0] b_fpn;
  logic  [31:0] out;
  
  
  fp_add_sub Instance(.clk(clk), .rst(rst), .signal(signal), .a_fpn(a_fpn), .b_fpn(b_fpn), .out(out));
  
  initial
    begin
      clk = 1;
      forever #10 clk = ~clk;
    end 
  
  initial begin
//    $dumpfile("dump.vcd");
//    $dumpvars(1); 
    rst = 1;
    signal = 1;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000010110010000000000000000000;  //100
    #20 
    rst = 0;
    #20
    $display("-------------------------");
    signal = 1;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000000000000000000000000000;  //2
    #20 
    $display("-------------------------");
    signal = 1;
    a_fpn = 32'b01000001100100000000000000000000;  //18
    b_fpn = 32'b01000000010000000000000000000000;  //3
    #20 
    $display("-------------------------");
    signal = 0;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000100100000000000000000000;  //4.5
//    b_fpn = 32'b01000000110000000000000000000000;  //6
//     b_fpn = 32'b01000000101000000000000000000000;  //5
    #20 
    $display("-------------------------");
    signal = 1;
    a_fpn = 32'b11000001110010000000000000000000;  //-25
    b_fpn = 32'b01000001100010000000000000000000;  //17
    #20
    $display("-------------------------");
    signal = 0;
    a_fpn = 32'b11000001110010000000000000000000;  //-25
    b_fpn = 32'b11000001110010000000000000000000;  //-25
    #20 
    
    $finish;
  end  
endmodule

/////////////////////////////////////////////////

