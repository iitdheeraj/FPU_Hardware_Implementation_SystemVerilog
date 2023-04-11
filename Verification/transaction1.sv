class transaction1;

  //declaring the transaction items
  rand bit [1:0]  operation;
  rand bit [31:0] a_fpn;
  rand bit [31:0] b_fpn;
       bit [31:0] out;
  function void display(string name);
    $display("-------------------------");
    $display("- %s ",name);
    $display("-------------------------");
    $display("- operation = %0d",operation);
    $display("- a_fpn = %0d, b_fpn = %0d",a_fpn, b_fpn);
    $display("-------------------------");
  endfunction
endclass