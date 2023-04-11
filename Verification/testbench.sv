`include "interface_1.sv"
`include "random_test.sv"

module fifo_tb;
  bit clk;
  bit rst;  
  
  //creatinng instance of interface, inorder to connect DUT and testcase
  intf intf_1(clk,rst);
  test t1(intf_1);
  
  top_FPU uut( .clk(intf_1.clk), .rst(intf_1.rst), .operation(intf_1.operation), .a_fpn(intf_1.a_fpn), .b_fpn(intf_1.b_fpn), .out(intf_1.out));
  
  initial
    begin
      clk = 0;
      forever #10 clk = ~clk;
    end 
  // rst Generation
  initial begin
    rst = 1;
    #20 rst =0;
  end
  initial begin 
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule