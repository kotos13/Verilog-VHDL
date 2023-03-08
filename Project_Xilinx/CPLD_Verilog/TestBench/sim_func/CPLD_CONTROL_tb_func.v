/*--------------------------------------------------------------------------------
Module Name:    CPLD_CONTROL_tb_func
--------------------------------------------------------------------------------*/

`timescale	1 ps / 1 ps

module CPLD_CONTROL_tb_func #(
    parameter C_SIMULATION_TB = 1'b1,
    parameter C_LEDS_QUANTITY_TB = 24,
    parameter C_CRASH_TYPE_TB = 1,
    parameter C_TEMP_SENSOR_PO_WL_TB = 16,
    parameter C_TEMP_SENSOR_DATA_WL_TB = 13,
    parameter C_MAX_TEMP_TB = 40.0
);
endmodule

//Component declaration
module CPLD_CONTROL #(
    parameter C_SIMULATION = 1'b0,
    parameter C_LEDS_QUANTITY = 24,
    parameter C_TEMP_SENSOR_PO_WL = 16,
    parameter C_TEMPERATURE_DATA_WL = 13,
    parameter C_MAX_TEMP = 40.0
) (
    //Clock input
    input wire CLK_IN,
    //Power control inputs
    input wire [C_LEDS_QUANTITY+1-1:0] PGOOD_All_bus_IN,
    //User switch inputs
    input wire [3:0] KEY_CPLD_IN,
    //Temperature sensor data input
    input wire Temp_sensor_SO_IN,
    output wire EN_ANALOG_PWR_OUT,
    output wire EN_DIGITAL_3V3_OUT,
    output wire EN_5V0_POWER_OUT,
    output wire EN_VCC_2V5_OUT,
    output wire EN_VCC_1V0_INT_OUT,
    //Front LEDs outputs
    output wire LED_DRIVER_CLK_OUT,
    output wire LED_DRIVER_SDI_OUT = 1'b0,
    output wire LED_DRIVER_LE_OUT,
    //Temperature sensor control outputs
    output wire Temp_sensor_CS_OUT,
    output wire Temp_sensor_SCK_OUT,
    //PROG B output
    output wire FPGA_PROG_B_OUT
);
endmodule

module LED_driver #(
    parameter C_N = 16
)(
    input wire LED_Clk = 1'b0,
    input wire LED_LE = 1'b0,
    input wire LED_SDI = 1'b0,
    input wire LED_OE = 1'b1,
    output wire LED_SDO,
    output wire [C_N-1:0] LED_PO
);
endmodule

module Temp_sensor_model#(
    parameter C_TEMP_SENSOR_PO_WL = 16,
    parameter C_TEMP_SENSOR_DATA_WL = 13
)(
    input wire [C_TEMP_SENSOR_DATA_WL-1:0] Temp_sensor_Data_IN = {(C_TEMP_SENSOR_DATA_WL-1)(1'b0)},
    input wire Temp_sensor_SCK_IN = 1'b0,
    input wire Temp_sensor_CS_IN = 1'b1,
    input wire Temp_sensor_SO_OUT
);
endmodule

//Type declaration
//Constant declaration
`define CLK_PERIOD_TB_const = 25,

//Signal declaration
reg CLK_TB_signal = 1'b0;
reg [C_LEDS_QUANTITY_TB+1-1:0] Test_PGOOD_All_bus_TB_signal = {(C_LEDS_QUANTITY_TB+1){1'b0}};
reg [3:0]Test_KEY_CPLD_TB_signal;

reg EN_Power_TB_signal;

reg LED_Clk_TB_signal;
reg LED_LE_TB_signal;
reg LED_SDI_TB_signal;

reg Temp_sensor_SO_TB_signal;
reg Temp_sensor_CS_TB_signal;
reg Temp_sensor_SCK_TB_signal;
reg [C_TEMP_SENSOR_DATA_WL_TB-1:0] Temp_sensor_Data_TB_signal = {(C_TEMP_SENSOR_DATA_WL_TB-1)(1'b0)};

// Simulation procedures
module CPLD_CONTROL CPLD_CONTROL_inst (
	// Generic map
	.C_SIMULATION(C_SIMULATION_TB),
	.C_LEDS_QUANTITY(C_LEDS_QUANTITY_TB),
	.C_TEMP_SENSOR_PO_WL(C_TEMP_SENSOR_PO_WL_TB),
	.C_TEMPERATURE_DATA_WL(C_TEMP_SENSOR_DATA_WL_TB),
	.C_MAX_TEMP(C_MAX_TEMP_TB),

	// Clock input
	.CLK_IN(CLK_TB_signal),

	// Power control inputs
	.PGOOD_All_bus_IN(Test_PGOOD_All_bus_TB_signal),

	// User switch inputs
	.KEY_CPLD_IN(Test_KEY_CPLD_TB_signal),

	// LEDs control inputs
	// .LED_DRIVER_SDO_IN(LED_SDO_TB_signal),

	// Temperature sensor data input
	.Temp_sensor_SO_IN(Temp_sensor_SO_TB_signal),

	// Power enable outputs
	.EN_ANALOG_PWR_OUT(EN_Power_TB_signal),
	.EN_DIGITAL_3V3_OUT(),
	.EN_5V0_POWER_OUT(),
	.EN_VCC_2V5_OUT(),
	.EN_VCC_1V0_INT_OUT(),

	// Front LEDs outputs
	.LED_CPLD_0_RED_OUT(),
	.LED_CPLD_1_GREEN_OUT(),
	.LED_CPLD_2_RED_OUT(),
	.LED_CPLD_3_GREEN_OUT(),

	// LEDs control outputs
	.LED_DRIVER_CLK_OUT(LED_Clk_TB_signal),
	.LED_DRIVER_SDI_OUT(LED_SDI_TB_signal),
	.LED_DRIVER_LE_OUT(LED_LE_TB_signal),

	// Temperature sensor control outputs
	.Temp_sensor_CS_OUT(Temp_sensor_CS_TB_signal),
	.Temp_sensor_SCK_OUT(Temp_sensor_SCK_TB_signal),

	// PROG B output
	.FPGA_PROG_B_OUT()
);
endmodule

module LED_driver RTL_LED_driver (
    .C_N(C_LEDS_QUANTITY_TB),

    .LED_Clk(LED_Clk_TB_signal),
    .LED_LE(LED_LE_TB_signal),
    .LED_OE(1'b0),
    .LED_SDI(LED_SDI_TB_signal),
    .LED_SDO(),
    .LED_PO()
);
endmodule

module Temp_sensor_model Behavioral_Temp_sensor_model(
    .C_TEMP_SENSOR_PO_WL(C_TEMP_SENSOR_PO_WL_TB),
    .C_TEMP_SENSOR_DATA_WL(C_TEMP_SENSOR_DATA_WL_TB),

    .Temp_sensor_Data_IN(Temp_sensor_Data_TB_signal),
    .Temp_sensor_SCK_IN(Temp_sensor_SCK_TB_signal),
    .Temp_sensor_CS_IN(Temp_sensor_CS_TB_signal),

    .Temp_sensor_SO_OUT(Temp_sensor_SO_TB_signal)
);
endmodule

//Clock
always #CLK_PERIOD_TB_const/2 CLK_TB_signal = ~CLK_TB_signal;

// Test_PGOOD_All_bus_TB_signal
always @(posedge clk) begin
    if (C_CRASH_TYPE_TB == 0 || C_CRASH_TYPE_TB == 2) begin // Power crash or Power & Temperature crash
        Test_PGOOD_All_bus_TB_signal <= 32'h00000000; // '0' - fail
        #3; // Wait for 2.8 us
        Test_PGOOD_All_bus_TB_signal <= 32'hFFFFFFFF; // '1' - ok
        #7; // Wait for 7.2 us
        Test_PGOOD_All_bus_TB_signal <= 32'hBFFFFFFE; // Specific value
        @(posedge EN_Power_TB_signal); // Wait for EN_Power_TB_signal to change
        #5; // Wait for 50 ns
        Test_PGOOD_All_bus_TB_signal <= 32'h00000000; // '0' - fail
    end
end


//Temp_sensor_Data_TB_signal
always @(posedge clk) begin
    #5; // Wait for 5 us
    if (C_CRASH_TYPE_TB == 0) begin
        Temp_sensor_Data_TB_signal <= {C_TEMP_SENSOR_DATA_WL_TB{1'b0}} + ((C_MAX_TEMP_TB - 1.0) / 0.0625);
    end else begin
        Temp_sensor_Data_TB_signal <= {C_TEMP_SENSOR_DATA_WL_TB{1'b0}} + ((C_MAX_TEMP_TB + 1.0) / 0.0625);
    end
end


always @(posedge clk) begin
    if (C_CRASH_TYPE_TB == 1) begin // Temp crash
        Test_PGOOD_All_bus_TB_signal <= 32'h00000000; // '0' - fail
        #3; // Wait for 2.8 us
        Test_PGOOD_All_bus_TB_signal <= 32'hFFFFFFFF; // '1' - ok
        wait on EN_Power_TB_signal; // Wait for EN_Power_TB_signal to change
        #5; // Wait for 50 ns
        Test_PGOOD_All_bus_TB_signal <= 32'h00000000; // '0' - fail
    end
end


//Temp_sensor_Data_TB_signal
always @(posedge clk) begin
    if (C_CRASH_TYPE_TB == 1) begin // Temp crash
        #5; // Wait for 5 us
        Temp_sensor_Data_TB_signal <= $sformatf("%0d", (C_MAX_TEMP_TB-1.0) / 0.0625); // Set Temp_sensor_Data_TB_signal
        #25; // Wait for 25 us
        Temp_sensor_Data_TB_signal <= $sformatf("%0d", (C_MAX_TEMP_TB+1.0) / 0.0625); // Set Temp_sensor_Data_TB_signal
    end
end

// LED_TEST process
always @(posedge clk) begin
    Test_KEY_CPLD_TB_signal <= 4'b1111; // turn off all LEDs
    #4; // wait for 4 us
    Test_KEY_CPLD_TB_signal <= 4'b1110; // turn on LED_CPLD_0_RED_OUT
    #1; // wait for 1 us
    Test_KEY_CPLD_TB_signal <= 4'b1100; // turn on LED_CPLD_0_RED_OUT & LED_CPLD_1_GREEN_OUT
    #1; // wait for 1 us
    Test_KEY_CPLD_TB_signal <= 4'b1001; // turn on LED_CPLD_1_GREEN_OUT & LED_CPLD_2_RED_OUT
    #1; // wait for 1 us
    Test_KEY_CPLD_TB_signal <= 4'b0011; // turn on LED_CPLD_2_RED_OUT & LED_CPLD_3_GREEN_OUT
    #1; // wait for 1 us
    Test_KEY_CPLD_TB_signal <= 4'b0111; // turn on LED_CPLD_3_GREEN_OUT
    #1; // wait for 1 us
    Test_KEY_CPLD_TB_signal <= 4'b1111; // turn off all LEDs
end