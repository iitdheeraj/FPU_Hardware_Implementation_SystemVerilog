`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2023 12:33:41
// Design Name: 
// Module Name: FPU_tb
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

module FPU_tb;
  logic   clk, rst;
  logic   [1:0]  operation;
  logic   [31:0] a_fpn;
  logic   [31:0] b_fpn;
  logic   [31:0] out;
  
  top_FPU Instance(.clk(clk), .rst(rst), .operation(operation), .a_fpn(a_fpn), .b_fpn(b_fpn), .out(out));
  
    initial
    begin
      clk = 0;
      forever #50 clk = ~clk;
    end 

    initial 
    begin
    $sdf_annotate("./gen_FPU_sdf.sdf",FPU_tb.Instance,,,"MAXIMUM","1:1:1","FROM_MTM");
    end 
  
  initial begin 
    rst = 1;
    operation = 2'b10;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000010110010000000000000000000;  //100
    #100 
    rst = 0;
    #100

    operation = 2'b10;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000000000000000000000000000;  //2
    #100 

    operation = 2'b01;
    a_fpn = 32'b01000001100100000000000000000000;  //18
    b_fpn = 32'b01000000010000000000000000000000;  //3
    #100 

    operation = 2'b11;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000100100000000000000000000;  //4.5
    #100 

    operation = 2'b00;
    a_fpn = 32'b11000001110010000000000000000000;  //-25
    b_fpn = 32'b01000001100010000000000000000000;  //17
    #100

    operation = 2'b00;
    a_fpn = 32'b11000001110010000000000000000000;  //-25
    b_fpn = 32'b11000001110010000000000000000000;  //-25
    #100 

    operation = 2'b11;
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000110000000000000000000000;  //6
    #100;
    
  end  
endmodule
