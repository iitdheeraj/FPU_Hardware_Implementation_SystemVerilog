`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 14:46:18
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
  logic clk, rst;
  logic   [31:0] a_fpn;
  logic   [31:0] b_fpn;
  logic  [31:0] out;  
  
  fp_divider Instance(.clk(clk), .rst(rst), .a_fpn(a_fpn), .b_fpn(b_fpn), .out(out));
  
  initial
    begin
      clk = 1;
      forever #10 clk = ~clk;
    end 
  
  initial begin
//    $dumpfile("dump.vcd");
//    $dumpvars(1); 
    
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000010110010000000000000000000;  //100
    rst = 1;
    #20
    rst = 0;
    #20 
    $display("-------------------------");
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000000000000000000000000000;  //2
    #20 
    $display("-------------------------");
    a_fpn = 32'b01000001100100000000000000000000;  //18
    b_fpn = 32'b01000000010000000000000000000000;  //3
    #20 
    $display("-------------------------");
    a_fpn = 32'b01000001101000000000000000000000;  //20
    b_fpn = 32'b01000000110000000000000000000000;  //6
//     b_fpn = 32'b01000000101000000000000000000000;  //5
    #20 
    $display("-------------------------");
    
    $finish;
  end  
endmodule

/////////////////////////////////////////////////

