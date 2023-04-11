class driver_1;
  
  //used to count the number of transactions
  int no_transactions;
  //creating virtual interface handle
  virtual intf vif;
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual intf vif,mailbox gen2driv);
    //getting the interface
    this.vif = vif;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
  endfunction

  //Reset task, Reset the Interface signals to default/initial values
  task rst;
    wait(vif.rst);
    $display("[ DRIVER ] ----- Reset Started -----");
    vif.operation <= 0;
    vif.a_fpn <= 0;
    vif.b_fpn <= 0;
    wait(!vif.rst);
    $display("[ DRIVER ] ----- Reset Ended   -----");
  endtask
  
  //drivers the transaction items to interface signals
  task main;
    forever begin
      transaction1 trans;
      gen2driv.get(trans);
      @(posedge vif.clk);
      vif.operation     <= trans.operation;
      vif.a_fpn     <= trans.a_fpn;
      vif.b_fpn     <= trans.b_fpn;
      @(posedge vif.clk);
      trans.out   = vif.out;
      @(posedge vif.clk);
      trans.display("[ Driver ]");
      no_transactions++;
    end
  endtask
  
endclass
