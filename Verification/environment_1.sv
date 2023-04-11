`include "transaction1.sv"
`include "generator_1.sv"
`include "driver_1.sv"

class environment_1;
  
  //generator and driver instance
  generator_1 gen;
  driver_1    driv;
  //mailbox handle's
  mailbox gen2driv;
  //virtual interface
  virtual intf vif;
  
  //constructor
  function new(virtual intf vif);
    //get the interface from test
    this.vif = vif;
    //creating the mailbox (Same handle will be shared across generator and driver)
    gen2driv = new();
    //creating generator and driver
    gen  = new(gen2driv);
    driv = new(vif,gen2driv);
  endfunction
  
  //
  task pre_test();
    driv.rst();
  endtask
  
  task test();
    fork 
    gen.main();
    driv.main();
    join_any
  endtask
  
  task post_test();
    wait(gen.ended.triggered);
    wait(gen.repeat_count == driv.no_transactions);
  endtask  
  
  //run task
  task run;
    pre_test();
    test();
    post_test();
    $finish;
  endtask
  
endclass