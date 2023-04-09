`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2023 15:28:16
// Design Name: 
// Module Name: testbench
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


module testbench;
  logic   [31:0] a_fpn;
  logic   [31:0] b_fpn;
  logic  [31:0] out;
  logic clk, rst;
  
  fp_multiplier Instance(.clk(clk), .rst(rst), .a_fpn(a_fpn), .b_fpn(b_fpn), .out(out));
  
  
  initial
    begin
      clk = 1;
      forever #5 clk = ~clk;
    end 
  
  
  initial begin
//    $dumpfile("dump.vcd");
//    $dumpvars(1); 
    rst = 1;
    a_fpn = 32'b01000010110111010110001010110010; 
    b_fpn = 32'b01000011001001100111010110110110;
    #10 
    rst = 0;
    #10
    a_fpn = 32'b01000010101101000000000000000000;//90
    b_fpn = 32'b01000000000000000000000000000000;//2
    #10 
    a_fpn = 32'b01000000101000000000000000000000; //5
    b_fpn = 32'b00000000000000000000000000000000; //0
    #10 
    a_fpn = 32'b01000000101000000000000000000000;//5 
    b_fpn = 32'b01000000100000000000000000000000;//4 
    #10 
    a_fpn = 32'b01000001001000000000000000000000; //10
    b_fpn = 32'b01000001001000000000000000000000; //10
    #10
    a_fpn = 32'b01000000000000000000000000000000; //2
    b_fpn = 32'b01000000000000000000000000000000; //2
    #10
    $finish;
  end  
endmodule

/////////////////////////////////////////////////
// $display("- temp_b1 = %b", temp_b);

