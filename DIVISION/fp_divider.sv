`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 14:45:29
// Design Name: 
// Module Name: fp_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//////////////////////////////////////////////////////////////////////////////////

module fp_divider (
  input logic clk, rst,
  input logic  [31:0] a_fpn,    // numerator
  input logic  [31:0] b_fpn,    // denominator
  output logic [31:0] out);     // result
  
  logic [92:0] mant_a, mant_b, mant_out; // (4*23+1)
  logic  [7:0] exp_a, exp_b, exp_out;
  logic sign_a, sign_b, sign_out;
  logic is_zero_a, is_zero_b, is_inf_a, is_inf_b, is_nan_a, is_nan_b;
  
  logic [51:0] product;
  logic flag;
  logic [7:0]  diff;
  ////////////////////////////////
  logic [92:0] b1;             // copy of divisor
  logic [92:0] quo, quo_next;  // intermediate quotient
  logic [93:0] acc, acc_next;    // accumulator (1 bit wider)
  logic [$clog2(93):0] i;      // iteration counter
  ////////////////////////////////
  // Extracting components of inputs
  assign sign_a = a_fpn[31];
  assign sign_b = b_fpn[31];
  
  assign is_zero_a = (a_fpn[30:0]==0);
  assign is_zero_b = (b_fpn[30:0]==0);
  assign is_inf_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
  assign is_inf_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
  assign is_nan_a = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
  assign is_nan_b = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
  
  always@(posedge clk) begin
    if (rst) begin
      out = 'h00000000;
    end else if (is_nan_a || is_nan_b) begin // Any input is NaN, Output is NaN
      out = 'hffffffff;
    end else if (is_zero_a) begin   // numerator is zero
      if (is_zero_b) begin          // numerator and denominator are both zero, which is NaN
        out = 'hffffffff;
      end else begin                // denominator is infinity or finite, which is zero
        out = 'h00000000;
      end
    end else if (is_inf_a) begin    // numerator is infinity
      if (is_zero_b || is_inf_b) begin // denominator is zero or infinity, so the result is NaN
        out = 'hffffffff;
      end else begin                // denominator is finite, so the result is infinity with the sign determined by the signs of the inputs
        out = {sign_a, 8'd255, 23'd0};
      end
    // a is finite
    end else if (is_zero_b) begin   // numerator is finite, so the result is infinity with the sign determined by the signs of the inputs
      out = {sign_a, 8'd255, 23'd0};
    end else if (is_inf_b) begin    // numerator is finite, so the result is zero with the sign determined by the signs of the inputs
      sign_out = sign_a ^ sign_b;
      out = {sign_out, 31'd0};
    end else if (diff > 29) begin   // If one number is much bigger then the other
      out = 'h00000000;
    end else begin
      
      sign_out = sign_a ^ sign_b;
      exp_a = a_fpn[30:23];
      exp_b = b_fpn[30:23];
      mant_a = { |a_fpn[30:23] ? 1'b1 : 1'b0, a_fpn[22:0], 69'd0 };
      mant_b = { |b_fpn[30:23] ? 1'b1 : 1'b0, b_fpn[22:0], 69'd0 };
        
      diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a); // taking absolute difference
      mant_b = mant_b >> (3*diff); // shift denominator by diff
        
      // Both inputs are finite, so perform division
      flag = (a_fpn[22:0] < b_fpn[22:0]) ? 1 : 0;  // if deno > num
      exp_out = exp_a - exp_b + 127 - flag;
      //////////////////////////////////////////////////////////////////////
//       mant_out = mant_a / mant_b;
      b1 = mant_b;
      {acc, quo} = {{93{1'b0}}, mant_a, 1'b0};  // initialize calculation      
      for (i = 0; i < 93; i = i + 1) begin
        if (acc >= {1'b0, b1}) begin
          acc_next = acc - b1;
          {acc_next, quo_next} = {acc_next[92:0], quo, 1'b1};
        end else begin
          {acc_next, quo_next} = {acc, quo} << 1;
        end
        acc = acc_next;
        quo = quo_next;
      end
      mant_out = quo_next;
      //////////////////////////////////////////////////////////////////////
      diff = flag ? ((3*diff)-1) : (3*diff);       // if deno > num shift 1 less
      mant_out = mant_out << (92-diff);

      // Check for overflow and underflow
      if (exp_out >= 255) begin        // Result is too large to represent, so set to infinity with the sign determined by the signs of the inputs
        out = {sign_a, 8'd255, 23'd0};
      end else if (exp_out <= 0) begin // Result is too small to represent, so set to zero with the sign determined by the signs of the inputs
        out = {sign_a ^ sign_b, 31'd0};
      end else begin                   // Result is a normal number
        out = {sign_out, exp_out, mant_out[91:69]};
      end
    end
  end
endmodule