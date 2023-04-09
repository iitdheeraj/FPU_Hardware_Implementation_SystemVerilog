`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 16:04:18
// Design Name: 
// Module Name: add_sub
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////

module fp_add_sub(clk, rst, signal, a_fpn, b_fpn, out);
  input logic [31:0]  a_fpn, b_fpn;
  input logic clk, rst, signal; // signal 1 -> ADD, 0 -> SUB
  output logic [31:0] out;
    
  logic [31:0]    a, b;
  logic [24:0]    mant_a, mant_b, mant_out;
  logic [7:0]     exp_a, exp_b, exp_out;
  logic           sign_a, sign_b, sign_out;
  logic [7:0]     diff;
  logic is_inf_a, is_inf_b, is_nan_a, is_nan_b;
  
  assign is_inf_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
  assign is_inf_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
  assign is_nan_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
  assign is_nan_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
  
  integer position, shift, i;
  
  always_ff @(posedge clk ) begin
    if (rst) begin
      out = 'h00000000;
    end else if (is_nan_a || is_nan_b) begin // OUT -> NaN, if any input is NaN
      out = 'hffffffff;
    end else if (is_inf_a || is_inf_b) begin // OUT -> Inf, if any input is Inf
      sign_out = (a_fpn[30:0] > b_fpn[30:0]) ? a_fpn[31] : b_fpn[31];
      out = {sign_out, 8'd255, 23'd0};
    end else begin
    
      a = ( a_fpn[30:0] < b_fpn[30:0] ) ? b_fpn : a_fpn;
      b = ( a_fpn[30:0] < b_fpn[30:0] ) ? a_fpn : b_fpn;
      
      if (signal) begin //if signal = 1 => ADD
        sign_a = a[31];
        sign_b = b[31];
      end else begin    //if signal = 0 => SUBTRACT
        sign_a = ( a_fpn[30:23] < b_fpn[30:23] ) ? ~a[31] :  a[31];
        sign_b = ( a_fpn[30:23] < b_fpn[30:23] ) ?  b[31] : ~b[31];
      end
      
      exp_a = a[30:23];
      exp_b = b[30:23];
      
      mant_a = { 1'b0, exp_a ? 1'b1 : 1'b0, a[22:0] };
      mant_b = { 1'b0, exp_b ? 1'b1 : 1'b0, b[22:0] };
      
      diff = exp_a - exp_b;
      mant_b = mant_b >> diff;
      
      sign_out = ((a[30:0] == b[30:0]) && (sign_a != sign_b)) ? 0 : sign_a; // if same num signbit 0, as result is 0
      
      if ( sign_a || sign_b) begin  // if any input is negative
        if (sign_a && sign_b) begin // if both negative ADD
          mant_out = mant_a + mant_b;
        end else begin              // if any one is negative SUBTRACT
          mant_out = mant_a - mant_b;
        end
      end else begin                // if no negative ADD
        mant_out = mant_a + mant_b;
      end
      
      if ( mant_out[24] ) begin            // if value increases
        exp_out = exp_a + 1;
        mant_out = mant_out >> 1;
      end else if ( !mant_out[23] ) begin  // if value decreases
        position = 0;
        for (i = 23; i >= 0; i = i - 1 )   // Find the first non-zero value and shift
          if ( !position && mant_out[i] )
            position = i;
        shift = 23 - position;
          
        if ( (exp_a-127) < shift ) begin   // if number is much small
            exp_out = 0;
            mant_out = 0;
        end else begin                     // Shift the number in standard form
          exp_out = exp_a - shift;
          mant_out = mant_out << shift;
        end
          
      end else begin
        exp_out = exp_a;
        mant_out = mant_out;
      end
        
      out = {sign_out, exp_out, mant_out[22:0]}; // assign output
    end
  end
endmodule





//module fp_add_sub(clk, rst, signal, a_fpn, b_fpn, out);
//  input logic [31:0]  a_fpn, b_fpn;
//  input logic clk, rst, signal; // signal 1 -> ADD, 0 -> SUB
//  output logic [31:0] out;
    
//  logic [31:0]    a, b;
//  logic [24:0]    mant_a, mant_b, mant_out;
//  logic [7:0]     exp_a, exp_b, exp_out;
//  logic           sign_a, sign_b, sign_out;
//  logic [7:0]     diff;
//  logic is_inf_a, is_inf_b, is_nan_a, is_nan_b;
  
//  assign is_inf_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
//  assign is_inf_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
//  assign is_nan_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
//  assign is_nan_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
  
//  integer position, shift, i;
    
//  always_ff @(posedge clk ) begin
//    if (rst) begin
//      out = 'h00000000;
//    end else begin
//        a = ( a_fpn[30:0] < b_fpn[30:0] ) ? b_fpn : a_fpn;
//        b = ( a_fpn[30:0] < b_fpn[30:0] ) ? a_fpn : b_fpn;
        
//        if (signal) begin //if signal = 1 => ADD
//          sign_a = a[31];
//          sign_b = b[31];
//        end else begin    //if signal = 0 => SUBTRACT
//          sign_a = ( a_fpn[30:23] < b_fpn[30:23] ) ? ~a[31] :  a[31];
//          sign_b = ( a_fpn[30:23] < b_fpn[30:23] ) ?  b[31] : ~b[31];
//        end

//        exp_a = a[30:23];
//        exp_b = b[30:23];
        
//        mant_a = { 1'b0, exp_a ? 1'b1 : 1'b0, a[22:0] };
//        mant_b = { 1'b0, exp_b ? 1'b1 : 1'b0, b[22:0] };
        
//        diff = exp_a - exp_b;
//        mant_b = mant_b >> diff;
        
//        ////////////////////////////////////////////////////////
        
//        sign_out = ((a[30:0] == b[30:0]) && (sign_a != sign_b)) ? 0 : sign_a; // if same num signbit 0, as result is 0
                
//        if ( sign_a || sign_b) begin  // if any input is negative
//          if (sign_a && sign_b) begin // if both negative ADD
//            mant_out = mant_a + mant_b;
//          end else begin              // if any one is negative SUBTRACT
//            mant_out = mant_a - mant_b;
//          end
//        end else begin                // if no negative ADD
//          mant_out = mant_a + mant_b;
//        end
//        /////////////////////////////////////////////////////////////////
        
//        if ( mant_out[24] ) begin            // if value increases
//          exp_out = exp_a + 1;
//          mant_out = mant_out >> 1;
//        end else if ( !mant_out[23] ) begin  // if value decreases
//          position = 0;
//          for (i = 23; i >= 0; i = i - 1 )   // Find the first non-zero value and shift
//            if ( !position && mant_out[i] )
//              position = i;
//          shift = 23 - position;
          
//          if ( (exp_a-127) < shift ) begin   // if number is much small
//              exp_out = 0;
//              mant_out = 0;
//          end else begin                     // Shift the number in standard form
//            exp_out = exp_a - shift;
//            mant_out = mant_out << shift;
//          end
          
//        end else begin
//          exp_out = exp_a;
//          mant_out = mant_out;
//        end
        
//        out = (is_nan_b || is_nan_b) ? 'hffffffff : (is_inf_a || is_inf_b) ? {sign_a, 8'd255, 23'd0} : {sign_out, exp_out, mant_out[22:0]}; // assign output
//        // OUT -> NaN, if any input is NaN
//        // OUT -> Inf, if any input is Inf
//    end
//  end
//endmodule