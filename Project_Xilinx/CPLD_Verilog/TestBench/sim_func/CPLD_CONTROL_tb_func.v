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
reg [C_TEMP_SENSOR_DATA_WL_TB-1:0] Temp_sensor_Data_TB_signal = {(C_TEMP_SENSOR_DATA_WL_TB-1)(1'b0)}