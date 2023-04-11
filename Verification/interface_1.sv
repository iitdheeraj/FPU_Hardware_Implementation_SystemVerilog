interface intf(input logic clk,rst);
  
  //declaring the signals
  logic [1:0]  operation;
  logic [31:0] a_fpn;
  logic [31:0] b_fpn;
  logic [31:0] out;
  
endinterface