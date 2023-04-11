`include "environment_1.sv"

program test(intf intf_1);
  
  //declaring environment instance
  environment_1 env;
  
  initial begin
    //creating environment
    env = new(intf_1);
    //setting the repeat count of generator as 20, means to generate 4 packets
    env.gen.repeat_count = 20;
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram