/*--------------------------------------------------------------------------------
LED driver STM STP16D05 simulation model
--------------------------------------------------------------------------------*/

//`timescale 1 ns / 1 ps

module LED_driver #(parameter C_N = 16)// разрядность 
( 
  input wire LED_Clk = 1'b0, 
  input wire LED_LE = 1'b0, 
  input wire LED_SDI = 1'b0, 
  input wire LED_OE = 1'b1, 
  output reg LED_SDO = 1'b0, 
  output reg [C_N-1:0] LED_PO = {C_N{1'b0}} 
); 
 
// Signal declaration 
reg [C_N-1:0] PO_signal = {C_N{1'b0}}; 
reg RST_signal = 1'b0; 
 
// Shift register 
always @ (posedge LED_Clk) 
  begin 
  if (RST_signal) 
  begin 
    PO_signal[0] <= 1'b0; 
  end else 
  begin 
    PO_signal[0] <= LED_SDI; 
  end 
end 
 
generate 
  for (integer i=1; i<C_N; i=i+1) 
  begin 
    always @ (posedge LED_Clk) 
	begin 
      if (RST_signal) 
	  begin 
        PO_signal[i] <= 1'b0; 
      end else 
	  begin 
        PO_signal[i] <= PO_signal[i-1]; 
      end 
    end 
  end 
endgenerate 
 
// Output 
always @ (LED_LE, LED_OE, PO_signal) 
  begin 
  if (LED_OE) 
  begin 
    LED_PO <= {C_N{1'b0}}; 
  end 
  else if (LED_LE) 
  begin 
    LED_PO <= PO_signal; 
  end 
end 
 
assign LED_SDO = PO_signal[C_N-1]; 
 
endmodule