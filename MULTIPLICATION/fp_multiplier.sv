`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2023 15:27:37
// Design Name: 
// Module Name: fp_multiplier
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

module fp_multiplier(clk, rst, a_fpn, b_fpn, out);
  input logic [31:0]  a_fpn, b_fpn;
  input logic clk, rst;
  output logic [31:0] out;
  
  logic           sign_out;
  logic [8:0]     exp_out;
  
  logic [25:0]    temp_a, temp_b;
  logic [7:0]     exp_a, exp_b;
  logic [51:0]    product;
  logic           normalised;
  logic [47:0]    out_normalised;
  logic [22:0]    out_mant;

  logic is_zero_a, is_zero_b, is_inf_a, is_inf_b, is_nan_a, is_nan_b, overflow, underflow, both_mant_zero;
    
  assign is_zero_a = (a_fpn[30:0]==0);
  assign is_zero_b = (b_fpn[30:0]==0);
  assign is_inf_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
  assign is_inf_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
  assign is_nan_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
  assign is_nan_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
  assign both_mant_zero = (!a_fpn[22:0] && !b_fpn[22:0]) ? 1 : 0;
  
  assign sign_out = (a_fpn[31] ^ b_fpn[31]);
  
  always_ff @(posedge clk ) begin
    if (rst) begin
      out = 'h00000000;
    end else if (is_nan_a || is_nan_b) begin // NaN
      out = 'hffffffff;
    end else if (is_zero_a || is_zero_b) begin // zero
      out = 'h00000000;
    end else if (is_inf_a || is_inf_b) begin   // infinite
      out = {sign_out, 8'd255, 23'd0};
    end else begin 
    
      exp_a = a_fpn[30:23];
      exp_b = b_fpn[30:23];
      
      temp_a = { 2'b0, |a_fpn[30:23] ? 1'b1 : 1'b0, a_fpn[22:0] };
      temp_b = { 2'b0, |b_fpn[30:23] ? 1'b1 : 1'b0, b_fpn[22:0] };
      
      product = temp_a * temp_b;
      normalised = product[47];
      out_normalised = normalised ? product : product << 1;
      out_mant = out_normalised[46:24];           // output mantissa
      exp_out = exp_a + exp_b + normalised - 127; // output exponent
      
      overflow  = (exp_out[8] & !exp_out[7]);   // overflow >255
      underflow = (exp_out[8] &  exp_out[7]);   // underflow <-126
      
      out = overflow ? {sign_out,8'hFF,23'd0} : underflow ? {sign_out,31'd0} : both_mant_zero ? {sign_out,exp_out[7:0],23'd0} : {sign_out,exp_out[7:0],out_mant};
    end
  end
endmodule





//module fp_multiplier(clk, rst, a_fpn, b_fpn, out);
//  input logic [31:0]  a_fpn, b_fpn;
//  input logic clk, rst;
//  output logic [31:0] out;
  
//  logic           sign_out;
//  logic [8:0]     exp_out;
  
//  logic [25:0]    temp_a, temp_b;
//  logic [7:0]     exp_a, exp_b;
//  logic [51:0]    product;
//  logic           normalised;
//  logic [47:0]    out_normalised;
//  logic [22:0]    out_mant;

//  logic is_zero_a, is_zero_b, is_inf_a, is_inf_b, is_nan_a, is_nan_b, both_mant_zero;
    
//  assign is_zero_a = (a_fpn[30:0]==0);
//  assign is_zero_b = (b_fpn[30:0]==0);
//  assign is_inf_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
//  assign is_inf_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
//  assign is_nan_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
//  assign is_nan_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
//  assign both_mant_zero = (!a_fpn[22:0] && !b_fpn[22:0]) ? 1 : 0;
  
//  assign sign_out = (a_fpn[31] ^ b_fpn[31]);
  
//  always_ff @(posedge clk ) begin
//    if (rst) begin
//      out = 'h00000000;
//    end else begin
////        both_mant_zero = 0;
        
//        exp_a = a_fpn[30:23];
//        exp_b = b_fpn[30:23];
        
//        if (is_nan_a || is_nan_b) begin // NaN
//          out = 'hffffffff;
//        end else if (is_zero_a || is_zero_b) begin // zero
//          out = 'h00000000;
//        end else if (is_inf_a || is_inf_b) begin   // infinite
//          out = {sign_out, 8'd255, 23'd0};
//        end else begin
//          ///////////////////////////////////////////////////////////////////////////////
//          temp_a = { 2'b0, |a_fpn[30:23] ? 1'b1 : 1'b0, a_fpn[22:0] };
//          temp_b = { 2'b0, |b_fpn[30:23] ? 1'b1 : 1'b0, b_fpn[22:0] };
          
//          product = temp_a * temp_b;
          
//          normalised = product[47]; 
          
//          out_normalised = normalised ? product : product << 1;
          
//          out_mant = out_normalised[46:24];           // output mantissa
          
//          exp_out = exp_a + exp_b + normalised - 127; // output exponent
          
//          out = both_mant_zero ? {sign_out,exp_out[7:0],23'd0} : {sign_out,exp_out[7:0],out_mant};
//        end
//    end
//  end
//endmodule