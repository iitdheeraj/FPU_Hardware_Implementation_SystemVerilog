`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dheeraj Kumar
// 
// Create Date: 08.04.2023 12:33:14
// Design Name: 
// Module Name: top_FPU
// Project Name: 
//////////////////////////////////////////////////////////////////////////////////

module top_FPU ( clk, rst, operation, a_fpn, b_fpn, out );
  input  logic        clk;
  input  logic        rst;
  input  logic [1:0]  operation;
  input  logic [31:0] a_fpn;
  input  logic [31:0] b_fpn;
  output logic [31:0] out;
  
  parameter     A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;
  ////////////////////////////////////////////////////////////////////////////
  //Adder
  logic           signal;
  logic [31:0]    a, b;
  logic [24:0]    mant_a_as, mant_b_as, mant_out_as;
  logic [7:0]     exp_a, exp_b, exp_out;
  logic           sign_a, sign_b, sign_out;
  logic [7:0]     diff;
  integer         position, shift, i;
  ////////////////////////////////////////////////////////////////////////////
  // Multiplier
  logic [8:0]     exp_out_m;
  logic [25:0]    temp_a, temp_b;
  logic [51:0]    product;
  logic           normalised;
  logic [47:0]    out_normalised;
  logic [22:0]    out_mant;
  ////////////////////////////////////////////////////////////////////////////
  // Divider
  logic [92:0]    mant_a_d, mant_b_d, mant_out_d; // (4*23+1)
  logic           flag; // To check if denominator mantissa is greater (for dividor only)
  logic           is_zero_a, is_zero_b, is_inf_a, is_inf_b, is_nan_a, is_nan_b, overflow, underflow, both_mant_zero;
  
  logic [92:0] b1;             // copy of divisor
  logic [92:0] quo, quo_next;  // intermediate quotient
  logic [93:0] acc, acc_next;    // accumulator (1 bit wider)
  logic [$clog2(93):0] i_d;      // iteration counter
  ////////////////////////////////////////////////////////////////////////////
  assign is_zero_a = (a_fpn[30:0]==0);
  assign is_zero_b = (b_fpn[30:0]==0);
  assign is_inf_a  = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
  assign is_inf_b  = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
  assign is_nan_a  = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
  assign is_nan_b  = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
  assign both_mant_zero = (!a_fpn[22:0] && !b_fpn[22:0]) ? 1 : 0; // Used in Multiplier
  ////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clk ) begin
    if (rst) begin                           // OUT -> 0  , if rst = 1
      out = 'h00000000;
    end else if (is_nan_a || is_nan_b) begin // OUT -> NaN, if any input is NaN
      out = 'hffffffff;
    end else begin
      casez( operation )
          ////////////////////////////////////////////////////////////////////////
          A, B: begin // Addition Subtraction
            signal = (operation == 2'b00) ? 1'b1 : 1'b0; // Add or Sub
            if (is_inf_a || is_inf_b) begin // OUT -> Inf, if any input is Inf
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
              mant_a_as = { 1'b0, exp_a ? 1'b1 : 1'b0, a[22:0] };
              mant_b_as = { 1'b0, exp_b ? 1'b1 : 1'b0, b[22:0] };
              diff = exp_a - exp_b;
              mant_b_as = mant_b_as >> diff;
              sign_out = ((a[30:0] == b[30:0]) && (sign_a != sign_b)) ? 0 : sign_a; // if same num signbit 0, as result is 0
              
              if ( sign_a || sign_b) begin  // if any input is negative
                if (sign_a && sign_b) begin // if both negative ADD
                  mant_out_as = mant_a_as + mant_b_as;
                end else begin              // if any one is negative SUBTRACT
                  mant_out_as = mant_a_as - mant_b_as;
                end
              end else begin                // if no negative ADD
                mant_out_as = mant_a_as + mant_b_as;
              end
              
              if ( mant_out_as[24] ) begin            // if value increases
                exp_out = exp_a + 1;
                mant_out_as = mant_out_as >> 1;
              end else if ( !mant_out_as[23] ) begin  // if value decreases
                position = 0;
                for (i = 23; i >= 0; i = i - 1 )   // Find the first non-zero value and shift
                  if ( !position && mant_out_as[i] )
                    position = i;
                shift = 23 - position;
                  
                if ( (exp_a-127) < shift ) begin   // if number is much small
                    exp_out = 0;
                    mant_out_as = 0;
                end else begin                     // Shift the number in standard form
                  exp_out = exp_a - shift;
                  mant_out_as = mant_out_as << shift;
                end
                  
              end else begin
                exp_out = exp_a;
                mant_out_as = mant_out_as;
              end
              out = {sign_out, exp_out, mant_out_as[22:0]}; // assign output
            end
          end
          ////////////////////////////////////////////////////////////////////////
          C: begin // Multiplication
            sign_a = a_fpn[31];
            sign_b = b_fpn[31];
            sign_out = (sign_a ^ sign_b);
            if (is_zero_a || is_zero_b) begin // zero
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
              exp_out_m = exp_a + exp_b + normalised - 127; // output exponent
              overflow  = (exp_out_m[8] & !exp_out_m[7]);   // overflow >255
              underflow = (exp_out_m[8] &  exp_out_m[7]);   // underflow <-126
              out = overflow ? {sign_out,8'hFF,23'd0} : underflow ? {sign_out,31'd0} : both_mant_zero ? {sign_out,exp_out_m[7:0],23'd0} : {sign_out,exp_out_m[7:0],out_mant};
            end
          end
          ////////////////////////////////////////////////////////////////////////
          D: begin // Division
            sign_a = a_fpn[31];
            sign_b = b_fpn[31];
            if (is_zero_a) begin            // numerator is zero
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
              mant_a_d = { |a_fpn[30:23] ? 1'b1 : 1'b0, a_fpn[22:0], 69'd0 };
              mant_b_d = { |b_fpn[30:23] ? 1'b1 : 1'b0, b_fpn[22:0], 69'd0 };
              diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a); // taking absolute difference
              mant_b_d = mant_b_d >> (3*diff); // shift denominator by diff
              // Both inputs are finite, so perform division
              flag = (a_fpn[22:0] < b_fpn[22:0]) ? 1 : 0;  // if deno > num
              exp_out = exp_a - exp_b + 127 - flag;
              //////////////////////////////////////////////////////////////////////
              // Division Algorithm
              // mant_out_d = mant_a_d / mant_b_d;
              b1 = mant_b_d;
              {acc, quo} = {{93{1'b0}}, mant_a_d, 1'b0};  // initialize calculation      
              for (i_d = 0; i_d < 93; i_d = i_d + 1) begin
                if (acc >= {1'b0, b1}) begin
                  acc_next = acc - b1;
                  {acc_next, quo_next} = {acc_next[92:0], quo, 1'b1};
                end else begin
                  {acc_next, quo_next} = {acc, quo} << 1;
                end
                acc = acc_next;
                quo = quo_next;
              end
              mant_out_d = quo_next;
              //////////////////////////////////////////////////////////////////////   
              diff = flag ? ((3*diff)-1) : (3*diff);       // if deno > num shift 1 less
              mant_out_d = mant_out_d << (92-diff);
        
              // Check for overflow and underflow
              if (exp_out >= 255) begin        // Result is too large to represent, so set to infinity with the sign determined by the signs of the inputs
                out = {sign_a, 8'd255, 23'd0};
              end else if (exp_out <= 0) begin // Result is too small to represent, so set to zero with the sign determined by the signs of the inputs
                out = {sign_a ^ sign_b, 31'd0};
              end else begin                   // Result is a normal number
                out = {sign_out, exp_out, mant_out_d[91:69]};
              end
            end
          end
          default: begin
            out = 32'b0;
          end
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      endcase
    end
  end
endmodule





//module top_FPU ( clk, rst, operation, a_fpn, b_fpn, out );
//  input  logic        clk;
//  input  logic        rst;
//  input  logic [1:0]  operation;
//  input  logic [31:0] a_fpn;
//  input  logic [31:0] b_fpn;
//  output logic [31:0] out;
  
//  parameter     A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

//  ////////////////////////////////////////////////////////////////////////////
//  //Adder
//  logic           signal;
//  logic [31:0]    a, b;
//  logic [24:0]    mant_a_as, mant_b_as, mant_out_as;
//  logic [7:0]     exp_a, exp_b, exp_out;
//  logic           sign_a, sign_b, sign_out;
//  logic [7:0]     diff;  
//  integer         position, shift, i;
//  ////////////////////////////////////////////////////////////////////////////
//  // Multiplier
//  logic [8:0]     exp_out_m;
//  logic [25:0]    temp_a, temp_b;
//  logic [51:0]    product;
//  logic           normalised;
//  logic [47:0]    out_normalised;
//  logic [22:0]    out_mant;
//  ////////////////////////////////////////////////////////////////////////////
//  // Divider
//  logic [92:0]    mant_a_d, mant_b_d, mant_out_d; // (4*23+1)
//  logic [51:0]    product;
//  logic           flag; // To check if denominator mantissa is greater (for dividor only)
//  logic           is_zero_a, is_zero_b, is_inf_a, is_inf_b, is_nan_a, is_nan_b, overflow, underflow, both_mant_zero;
//  ////////////////////////////////////////////////////////////////////////////
//  assign is_zero_a = (a_fpn[30:0]==0);
//  assign is_zero_b = (b_fpn[30:0]==0);
//  assign is_inf_a  = (a_fpn[30:23] == 255) && (a_fpn[22:0] == 0); // All exp=1 and all mant=0
//  assign is_inf_b  = (b_fpn[30:23] == 255) && (b_fpn[22:0] == 0);
//  assign is_nan_a  = (a_fpn[30:23] == 255) && (a_fpn[22:0] != 0); // All exp=1 and atleast one mant !=0
//  assign is_nan_b  = (b_fpn[30:23] == 255) && (b_fpn[22:0] != 0);
//  assign both_mant_zero = (!a_fpn[22:0] && !b_fpn[22:0]) ? 1 : 0; // Used in Multiplier
//  ////////////////////////////////////////////////////////////////////////////


//  always_ff @(posedge clk ) begin
//    if (rst) begin
//      out = 'h00000000;
//    end else if (is_nan_a || is_nan_b) begin // OUT -> NaN, if any input is NaN
//      out = 'hffffffff;
//    end else begin
//      casez( operation )
//      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
//          A, B: begin // Addition Subtraction
//            signal = (operation == 2'b00) ? 1'b1 : 1'b0; // Add or Sub
//            if (is_inf_a || is_inf_b) begin // OUT -> Inf, if any input is Inf
//              sign_out = (a_fpn[30:0] > b_fpn[30:0]) ? a_fpn[31] : b_fpn[31];
//              out = {sign_out, 8'd255, 23'd0};
//            end else begin
//              a = ( a_fpn[30:0] < b_fpn[30:0] ) ? b_fpn : a_fpn;
//              b = ( a_fpn[30:0] < b_fpn[30:0] ) ? a_fpn : b_fpn;
//              if (signal) begin //if signal = 1 => ADD
//                sign_a = a[31];
//                sign_b = b[31];
//              end else begin    //if signal = 0 => SUBTRACT
//                sign_a = ( a_fpn[30:23] < b_fpn[30:23] ) ? ~a[31] :  a[31];
//                sign_b = ( a_fpn[30:23] < b_fpn[30:23] ) ?  b[31] : ~b[31];
//              end
              
//              exp_a = a[30:23];
//              exp_b = b[30:23];
              
//              mant_a_as = { 1'b0, exp_a ? 1'b1 : 1'b0, a[22:0] };
//              mant_b_as = { 1'b0, exp_b ? 1'b1 : 1'b0, b[22:0] };
              
//              diff = exp_a - exp_b;
//              mant_b_as = mant_b_as >> diff;
              
//              sign_out = ((a[30:0] == b[30:0]) && (sign_a != sign_b)) ? 0 : sign_a; // if same num signbit 0, as result is 0
              
//              if ( sign_a || sign_b) begin  // if any input is negative
//                if (sign_a && sign_b) begin // if both negative ADD
//                  mant_out_as = mant_a_as + mant_b_as;
//                end else begin              // if any one is negative SUBTRACT
//                  mant_out_as = mant_a_as - mant_b_as;
//                end
//              end else begin                // if no negative ADD
//                mant_out_as = mant_a_as + mant_b_as;
//              end
              
//              if ( mant_out_as[24] ) begin            // if value increases
//                exp_out = exp_a + 1;
//                mant_out_as = mant_out_as >> 1;
//              end else if ( !mant_out_as[23] ) begin  // if value decreases
//                position = 0;
//                for (i = 23; i >= 0; i = i - 1 )   // Find the first non-zero value and shift
//                  if ( !position && mant_out_as[i] )
//                    position = i;
//                shift = 23 - position;
                  
//                if ( (exp_a-127) < shift ) begin   // if number is much small
//                    exp_out = 0;
//                    mant_out_as = 0;
//                end else begin                     // Shift the number in standard form
//                  exp_out = exp_a - shift;
//                  mant_out_as = mant_out_as << shift;
//                end
                  
//              end else begin
//                exp_out = exp_a;
//                mant_out_as = mant_out_as;
//              end
                
//              out = {sign_out, exp_out, mant_out_as[22:0]}; // assign output
//            end
//          end
//          ///////////////////////////////////////////////////////////////////////////////////////////////////////////
//          C: begin // Multiplication
//            sign_a = a_fpn[31];
//            sign_b = b_fpn[31];
//            sign_out = (sign_a ^ sign_b);
//            if (is_zero_a || is_zero_b) begin // zero
//              out = 'h00000000;
//            end else if (is_inf_a || is_inf_b) begin   // infinite
//              out = {sign_out, 8'd255, 23'd0};
//            end else begin 
            
//              exp_a = a_fpn[30:23];
//              exp_b = b_fpn[30:23];
              
//              temp_a = { 2'b0, |a_fpn[30:23] ? 1'b1 : 1'b0, a_fpn[22:0] };
//              temp_b = { 2'b0, |b_fpn[30:23] ? 1'b1 : 1'b0, b_fpn[22:0] };
              
//              product = temp_a * temp_b;
//              normalised = product[47];
//              out_normalised = normalised ? product : product << 1;
//              out_mant = out_normalised[46:24];           // output mantissa
//              exp_out_m = exp_a + exp_b + normalised - 127; // output exponent
              
//              overflow  = (exp_out_m[8] & !exp_out_m[7]);   // overflow >255
//              underflow = (exp_out_m[8] &  exp_out_m[7]);   // underflow <-126
              
//              out = overflow ? {sign_out,8'hFF,23'd0} : underflow ? {sign_out,31'd0} : both_mant_zero ? {sign_out,exp_out_m[7:0],23'd0} : {sign_out,exp_out_m[7:0],out_mant};
//            end
//          end
//          ///////////////////////////////////////////////////////////////////////////////////////////////////////////
//          D: begin // Division
//            sign_a = a_fpn[31];
//            sign_b = b_fpn[31];
//            if (is_zero_a) begin            // numerator is zero
//              if (is_zero_b) begin          // numerator and denominator are both zero, which is NaN
//                out = 'hffffffff;
//              end else begin                // denominator is infinity or finite, which is zero
//                out = 'h00000000;
//              end
//            end else if (is_inf_a) begin    // numerator is infinity
//              if (is_zero_b || is_inf_b) begin // denominator is zero or infinity, so the result is NaN
//                out = 'hffffffff;
//              end else begin                // denominator is finite, so the result is infinity with the sign determined by the signs of the inputs
//                out = {sign_a, 8'd255, 23'd0};
//              end
//            // a is finite
//            end else if (is_zero_b) begin   // numerator is finite, so the result is infinity with the sign determined by the signs of the inputs
//              out = {sign_a, 8'd255, 23'd0};
//            end else if (is_inf_b) begin    // numerator is finite, so the result is zero with the sign determined by the signs of the inputs
//              sign_out = sign_a ^ sign_b;
//              out = {sign_out, 31'd0};
//            end else if (diff > 29) begin   // If one number is much bigger then the other
//              out = 'h00000000;
//            end else begin
              
//              sign_out = sign_a ^ sign_b;
//              exp_a = a_fpn[30:23];
//              exp_b = b_fpn[30:23];
//              mant_a_d = { |a_fpn[30:23] ? 1'b1 : 1'b0, a_fpn[22:0], 69'd0 };
//              mant_b_d = { |b_fpn[30:23] ? 1'b1 : 1'b0, b_fpn[22:0], 69'd0 };
                
//              diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a); // taking absolute difference
//              mant_b_d = mant_b_d >> (3*diff); // shift denominator by diff
                
//              // Both inputs are finite, so perform division
//              flag = (a_fpn[22:0] < b_fpn[22:0]) ? 1 : 0;  // if deno > num
//              exp_out = exp_a - exp_b + 127 - flag;
                  
//              mant_out_d = mant_a_d / mant_b_d;
                  
//              diff = flag ? ((3*diff)-1) : (3*diff);       // if deno > num shift 1 less
//              mant_out_d = mant_out_d << (92-diff);
        
//              // Check for overflow and underflow
//              if (exp_out >= 255) begin        // Result is too large to represent, so set to infinity with the sign determined by the signs of the inputs
//                out = {sign_a, 8'd255, 23'd0};
//              end else if (exp_out <= 0) begin // Result is too small to represent, so set to zero with the sign determined by the signs of the inputs
//                out = {sign_a ^ sign_b, 31'd0};
//              end else begin                   // Result is a normal number
//                out = {sign_out, exp_out, mant_out_d[91:69]};
//              end
//            end
//          end
//          default: begin
//            out = 32'b0;
//          end
//      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
//      endcase
//    end
//  end
//endmodule
