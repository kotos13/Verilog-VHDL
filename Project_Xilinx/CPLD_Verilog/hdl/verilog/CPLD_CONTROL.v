/*--------------------------------------------------------------------------------
��������:				������ �������� ���������� � ����������� ��� �����
�������� ������:		������� �������������� ���� ���������� �������� (�������� ������� ������������ �������) � ����������� ����� ������� ������ �����������.
						� ���������� ������ ������ �������� �������������� ��������� ������� � FPGA_PROG_B, � ������ ����������� LED_CPLD ����� ��� ������
						����������. � ������ ������ ����������� �������������� ��������� ������� � FPGA_PROG_B, � ������ ����������� LED_CPLD ���������� ����
						�� ���� ������� ������, ��������������� ���� ������ (�� �������� ������������ ������� ��� ��-�� ���������� ����������� ���������� �����������),
						� �����, � ������ ������ �� �������� ������������ �������, ����������� �������� �������� ���������� ����, �������������� ���������� ������
						����������� �������.
						�������� ������� ���������� ������ �������� ��������� � ��������� ~1,68 � ����� ��� ���������.
--------------------------------------------------------------------------------*/

`timescale 1 ns / 1 ps


module CPLD_CONTROL #(
    parameter C_SIMULATION = 0,
    parameter C_LEDS_QUANTITY = 24,
    parameter C_TEMP_SENSOR_PO_WL = 16,
    parameter C_TEMPERATURE_DATA_WL = 13,
    parameter C_MAX_TEMP = 60.0
)
(
    // Clock input
    input wire CLK_IN,

    // Power control inputs
    input wire [C_LEDS_QUANTITY:0] PGOOD_All_bus_IN,

    // User switch inputs
    input wire [3:0] KEY_CPLD_IN,

    // LEDs control inputs
    // input wire LED_DRIVER_SDO_IN,

    // Temperature sensor data input
    input wire Temp_sensor_SO_IN,

    // Power enable outputs
    output wire EN_ANALOG_PWR_OUT,
    output wire EN_DIGITAL_3V3_OUT,
    output wire EN_5V0_POWER_OUT,
    output wire EN_VCC_2V5_OUT,
    output wire EN_VCC_1V0_INT_OUT,

    // Front LEDs outputs
    output wire LED_CPLD_0_RED_OUT,
    output wire LED_CPLD_1_GREEN_OUT,
    output wire LED_CPLD_2_RED_OUT,
    output wire LED_CPLD_3_GREEN_OUT,

    // LEDs control outputs
    output wire LED_DRIVER_CLK_OUT,
    output wire LED_DRIVER_SDI_OUT = 1'b0,
    output wire LED_DRIVER_LE_OUT,

    // Temperature sensor control outputs
    output wire Temp_sensor_CS_OUT,
    output wire Temp_sensor_SCK_OUT,

    // PROG B output
    output wire FPGA_PROG_B_OUT
);

//Constant declaration
`define C_TEMPERATURE_DATA_WL <width> // replace <width> with the desired width
`define C_MAX_TEMP <max_temp> // replace <max_temp> with the maximum temperature in degrees Celsius that can be represented
`define C_RESOLUTION 0.0625 // temperature resolution in degrees Celsius

parameter MAX_TEMP_CODE_CONST = $signed((`C_MAX_TEMP / `C_RESOLUTION) * 2 ** `C_TEMPERATURE_DATA_WL); // calculate the maximum temperature code

`define FILTER_LENGTH <length> // replace <length> with the desired length of the filter

parameter FILTER_LENGTH = `FILTER_LENGTH; // set the filter length as a parameter

//Type declaration
typedef enum logic [1:0] {
    Stop_state = 0,
    Start_state = 1,
    Run_state = 2,
    Finish_state = 3
} TX_RX_mode_value;

typedef enum logic [1:0] {
    Strobe_state1 = 0,
    Strobe_state2 = 1,
    Strobe_state3 = 2
} Strobe_value;


//Signal declaration
reg [1:0] TX_curr_mode = Start_state;
reg [1:0] RX_curr_mode = Stop_state;

reg GSR_signal;
reg CLK_signal;
reg [26:0] CLK_COUNTER_signal = 27'b0;
reg START_CONTROL_TIME_signal = 1'b0;
reg CLK_DIV_TX;
reg CLK_DIV_RX;
reg CLK_DIV_filter;

reg [C_LEDS_QUANTITY-1:0] PGOOD_All_bus_signal;
reg [FILTER_LENGTH-1:0] PGOOD_filtered_signal = {FILTER_LENGTH{1'b1}};
reg [C_LEDS_QUANTITY-1:0] SDI_Data_signal;

reg ENABLE_ALL_POWER_INV_signal = 1'b0;
reg ENABLE_ALL_POWER_signal;

reg CRASH_POWER_TRIG_signal = 1'b0;
reg CRASH_TEMP_TRIG_signal = 1'b0;
reg CRASH_signal;

reg LED_DRIVER_LE_signal = 1'b0;
reg TX_sinchro_signal = 1'b0;

reg Temp_sensor_CS_signal = 1'b1;
reg Temp_sensor_SCK_signal;
reg [C_TEMP_SENSOR_PO_WL-1:0] Temp_sensor_PO_signal = {C_TEMP_SENSOR_PO_WL{1'b0}};
`define C_TEMPERATURE_DATA_WL <width> // replace <width> with the desired width

reg signed [(`C_TEMPERATURE_DATA_WL-1):0] Temperature_data_signal = -2 ** (`C_TEMPERATURE_DATA_WL-1); // initialize Temperature_data_signal to the minimum value

reg RX_period_signal;
reg RX_period_strobe_signal;
reg RX_sinchro_signal = 1'b0;

reg [1:0] Strobe_curr_state = Strobe_state1;

assign CLK_signal = CLK_IN;

//Clock counter
always @(posedge CLK_signal or posedge GSR_signal) begin
    if (GSR_signal) begin
        CLK_COUNTER_signal <= 0;
    end else begin
        CLK_COUNTER_signal <= CLK_COUNTER_signal + 1;
    end
end

assign CLK_DIV_TX = CLK_COUNTER_signal[1];
assign CLK_DIV_RX = CLK_COUNTER_signal[3];
assign CLK_DIV_filter = CLK_COUNTER_signal[2];

always @(GSR_signal or CLK_COUNTER_signal)
begin
    if (GSR_signal == 1'b1)
        START_CONTROL_TIME_signal <= 1'b0;
    else if (posedge CLK_COUNTER_signal[7])
        START_CONTROL_TIME_signal <= 1'b1;
end

assign RX_period_signal = CLK_COUNTER_signal[8];

always @(GSR_signal or CLK_COUNTER_signal)
begin
    if (GSR_signal == 1'b1)
        START_CONTROL_TIME_signal <= 1'b0;
    else if (posedge CLK_COUNTER_signal[26])
        START_CONTROL_TIME_signal <= 1'b1;
end

assign RX_period_signal = CLK_COUNTER_signal[24];


assign PGOOD_All_bus_signal[(C_LEDS_QUANTITY-1):17] = PGOOD_All_bus_IN[(C_LEDS_QUANTITY-1):17];
assign PGOOD_All_bus_signal[16] = PGOOD_All_bus_IN[16] & PGOOD_All_bus_IN[C_LEDS_QUANTITY];
assign PGOOD_All_bus_signal[15:0] = PGOOD_All_bus_IN[15:0];

//PGOOD_filtered shift register
always @(GSR_signal or CLK_DIV_filter)
begin
    if (GSR_signal == 1'b1)
        PGOOD_filtered_signal[0] <= 1'b1;
    else if (posedge CLK_DIV_filter)
    begin
        if (PGOOD_All_bus_signal != ~{C_LEDS_QUANTITY{1'b1}})
            PGOOD_filtered_signal[0] <= 1'b0;
        else
            PGOOD_filtered_signal[0] <= 1'b1;
    end
end

genvar i;
generate
    for (i = 1; i < FILTER_LENGTH; i = i + 1)
    begin : PGOOD_SHIFT_REGISTER
        always @(GSR_signal or CLK_DIV_filter)
        begin
            if (GSR_signal == 1'b1)
                PGOOD_filtered_signal[i] <= 1'b1;
            else if (posedge CLK_DIV_filter)
                PGOOD_filtered_signal[i] <= PGOOD_filtered_signal[i-1];
        end
    end
endgenerate

always @(GSR_signal or CLK_signal or PGOOD_filtered_signal or START_CONTROL_TIME_signal or CRASH_TEMP_TRIG_signal)
begin
    if (GSR_signal == 1'b1)
        CRASH_POWER_TRIG_signal <= 1'b0;
    else if (posedge CLK_signal)
    begin
        if ((PGOOD_filtered_signal == {FILTER_LENGTH{1'b1}}) && (START_CONTROL_TIME_signal == 1'b1) && (CRASH_TEMP_TRIG_signal == 1'b0))
            CRASH_POWER_TRIG_signal <= 1'b1;
    end
end

assign CRASH_signal = CRASH_POWER_TRIG_signal | CRASH_TEMP_TRIG_signal;

//������������ ������� ������ �� ������������
always @(GSR_signal or CRASH_POWER_TRIG_signal or PGOOD_All_bus_signal)
begin
    if (GSR_signal == 1'b1)
        SDI_Data_signal <= {DATA_WIDTH{1'b0}};
    else if (posedge CRASH_POWER_TRIG_signal)
        SDI_Data_signal <= ~PGOOD_All_bus_signal;
end
//���������� ���������� �������
always @(GSR_signal or CRASH_signal or posedge CLK_signal)
begin
    if (GSR_signal == 1'b1)
        ENABLE_ALL_POWER_INV_signal <= 1'b0;
    else if (posedge CLK_signal)
        ENABLE_ALL_POWER_INV_signal <= CRASH_signal;
end

assign ENABLE_ALL_POWER_signal = ~ENABLE_ALL_POWER_INV_signal;

assign EN_ANALOG_PWR_OUT = ENABLE_ALL_POWER_signal;
assign EN_DIGITAL_3V3_OUT = ENABLE_ALL_POWER_signal;
assign EN_5V0_POWER_OUT = ENABLE_ALL_POWER_signal;
assign EN_VCC_2V5_OUT = ENABLE_ALL_POWER_signal;
assign EN_VCC_1V0_INT_OUT = ENABLE_ALL_POWER_signal;

assign FPGA_PROG_B_OUT = ~CRASH_signal;

assign LED_CPLD_0_RED_OUT = KEY_CPLD_IN[0] & ~CRASH_POWER_TRIG_signal;
assign LED_CPLD_1_GREEN_OUT = KEY_CPLD_IN[1] & CRASH_POWER_TRIG_signal;
assign LED_CPLD_2_RED_OUT = KEY_CPLD_IN[2] & ~CRASH_TEMP_TRIG_signal;
assign LED_CPLD_3_GREEN_OUT = KEY_CPLD_IN[3] & CRASH_TEMP_TRIG_signal;

//����������
//������ �����������. ����� ������ �� ����� LED_DRIVER_SDI_OUT
always @(GSR_signal or CLK_DIV_TX)
begin
    integer Data_serial_counter_TX;

    if (GSR_signal == 1'b1) begin
        LED_DRIVER_SDI_OUT <= 1'b0;
        LED_DRIVER_LE_signal <= 1'b0;
        TX_sinchro_signal <= 1'b0;
        Data_serial_counter_TX = C_LEDS_QUANTITY;
    end
    else if (falling_edge(CLK_DIV_TX)) begin
        if (TX_curr_mode == Run_state) begin
            if (Data_serial_counter_TX != 0) begin
                LED_DRIVER_SDI_OUT <= SDI_Data_signal[Data_serial_counter_TX-1];
                TX_sinchro_signal <= 1'b1;
                Data_serial_counter_TX = Data_serial_counter_TX - 1;
            end
            else begin
                LED_DRIVER_SDI_OUT <= 1'b0;
                LED_DRIVER_LE_signal <= 1'b1;
                TX_sinchro_signal <= 1'b0;
                Data_serial_counter_TX = C_LEDS_QUANTITY;
            end
        end
        else if (TX_curr_mode == Finish_state) begin
            LED_DRIVER_LE_signal <= 1'b0;
        end
    end
end


assign LED_DRIVER_CLK_OUT = CLK_DIV_TX & TX_sinchro_signal;
assign LED_DRIVER_LE_OUT = LED_DRIVER_LE_signal;

//�������� ������� ���������� ������������
always @(posedge CLK_DIV_TX or posedge GSR_signal)
begin
	if (GSR_signal) begin
		TX_curr_mode <= Start_state;
	end else begin
		case (TX_curr_mode)
			Stop_state:
				if (!CRASH_POWER_TRIG_signal) begin
					TX_curr_mode <= Stop_state;
				end else begin
					TX_curr_mode <= Start_state;
				end
			Start_state:
				TX_curr_mode <= Run_state;
			Run_state:
				if (LED_DRIVER_LE_signal) begin
					TX_curr_mode <= Finish_state;
				end else begin
					TX_curr_mode <= Run_state;
				end
			Finish_state:
				if (CRASH_POWER_TRIG_signal) begin
					TX_curr_mode <= Finish_state;
				end else begin
					TX_curr_mode <= Stop_state;
				end
			default:
				TX_curr_mode <= Stop_state;
		endcase
	end
end

//������� ������� �����������
always @(posedge CLK_signal or posedge GSR_signal)
begin
	if (GSR_signal) begin
		CRASH_TEMP_TRIG_signal <= 1'b0;
	end else if (signed(Temperature_data_signal) >= signed(MAX_TEMP_CODE_CONST) && CRASH_POWER_TRIG_signal == 1'b0) begin
		CRASH_TEMP_TRIG_signal <= 1'b1;
	end
end

//������ ��������. ���� ������ �� ���� Temp_sensor_SO_IN
integer Data_serial_counter_RX;

always @(GSR_signal or CLK_DIV_RX) begin
	if (GSR_signal == 1'b1) begin
		Temp_sensor_CS_signal <= 1'b1;
		RX_sinchro_signal <= 1'b0;
		Data_serial_counter_RX = 0;
		Temperature_data_signal <= -2 ** (C_TEMPERATURE_DATA_WL-1);
	end else if (negedge CLK_DIV_RX) begin
		if (RX_curr_mode == Run_state) begin
			if (Data_serial_counter_RX != C_TEMP_SENSOR_PO_WL) begin
				Temp_sensor_CS_signal <= 1'b0;
				RX_sinchro_signal <= 1'b1;
				Data_serial_counter_RX = Data_serial_counter_RX + 1;
			end else begin
				Temp_sensor_CS_signal <= 1'b1;
				RX_sinchro_signal <= 1'b0;
				Data_serial_counter_RX = 0;
				Temperature_data_signal <= Temp_sensor_PO_signal[(C_TEMP_SENSOR_PO_WL-1): (C_TEMP_SENSOR_PO_WL-C_TEMPERATURE_DATA_WL)];
			end
		end
	end
end

assign Temp_sensor_SCK_signal = CLK_DIV_RX & RX_sinchro_signal;

assign Temp_sensor_SCK_OUT = Temp_sensor_SCK_signal;

assign Temp_sensor_CS_OUT = Temp_sensor_CS_signal;

//Temp_sensor_PO shift register
always @(posedge Temp_sensor_SCK_signal or negedge GSR_signal)
begin
	if (GSR_signal == 1'b0) begin
		Temp_sensor_PO_signal[0] <= Temp_sensor_SO_IN;
	end else begin
		Temp_sensor_PO_signal[0] <= 1'b0;
	end
end

genvar i;

generate
	for (i = 1; i < C_TEMP_SENSOR_PO_WL; i = i + 1) begin
		always @(posedge Temp_sensor_SCK_signal or negedge GSR_signal) begin
			if (GSR_signal == 1'b0) begin
				Temp_sensor_PO_signal[i] <= Temp_sensor_PO_signal[i-1];
			end else begin
				Temp_sensor_PO_signal[i] <= 1'b0;
			end
		end
	end
endgenerate;

//�������� ������� ���������� ������� ������� ���������� ������ � ������� �����������
reg [1:0] Strobe_curr_state, Strobe_state1, Strobe_state2, Strobe_state3;

always @(posedge CLK_signal) begin
    if (GSR_signal == 1'b1) begin
        Strobe_curr_state <= Strobe_state1;
    end else begin
        case (Strobe_curr_state)
            Strobe_state1: begin
                if (RX_period_signal && !CRASH_signal && START_CONTROL_TIME_signal) begin
                    Strobe_curr_state <= Strobe_state2;
                end else begin
                    Strobe_curr_state <= Strobe_state1;
                end
            end
            Strobe_state2: begin
                if (RX_curr_mode == Start_state) begin
                    Strobe_curr_state <= Strobe_state3;
                end else begin
                    Strobe_curr_state <= Strobe_state2;
                end
            end
            Strobe_state3: begin
                if (RX_period_signal) begin
                    Strobe_curr_state <= Strobe_state3;
                end else begin
                    Strobe_curr_state <= Strobe_state1;
                end
            end
            default: begin
                Strobe_curr_state <= Strobe_state1;
            end
        endcase
    end
end

assign RX_period_strobe_signal = (Strobe_curr_state == Strobe_state2) ? 1'b1 : 1'b0;

//�������� ������� ���������� ���������
reg [1:0] RX_curr_mode, Stop_state = 2'b00, Start_state = 2'b01, Run_state = 2'b10, Finish_state = 2'b11;

always @(posedge CLK_DIV_RX) begin
    if (GSR_signal == 1'b1) begin
        RX_curr_mode <= Stop_state;
    end else begin
        case (RX_curr_mode)
            Stop_state: begin
                if (RX_period_strobe_signal) begin
                    RX_curr_mode <= Start_state;
                end else begin
                    RX_curr_mode <= Stop_state;
                end
            end
            Start_state: begin
                RX_curr_mode <= Run_state;
            end
            Run_state: begin
                if (Temp_sensor_CS_signal == 1'b0) begin
                    RX_curr_mode <= Run_state;
                end else begin
                    RX_curr_mode <= Finish_state;
                end
            end
            Finish_state: begin
                RX_curr_mode <= Stop_state;
            end
            default: begin
                RX_curr_mode <= Stop_state;
            end
        endcase
    end
end
endmodule