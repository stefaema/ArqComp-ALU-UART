//-----------------------------------------------------------------------------
// MODULE:         uart_top
// DESCRIPTION:    Modulo superior que integra transmision y recepcion UART
//                 junto al generador de baud rate y registro de visualizacion.
//                 Permite navegar entre baud rates con los botones 'up' y 'down',
//                 transmite continuamente el byte 0x93 (10010011) y muestra en
//                 los LEDs el ultimo byte recibido.
//
// HARDWARE:       Basys3 + interfaz FTDI externa (3.3V nivel logico)
//
//-----------------------------------------------------------------------------

module uart_top (
    input  wire        CLK100MHZ,     // Reloj del sistema 100 MHz
    input  wire        RST,    // Reset asincrono activo en alto
    input  wire        RX_IN,         // Entrada UART desde PC (FTDI TX)
    output wire        TX_OUT,        // Salida UART hacia PC (FTDI RX)
    output wire [7:0]  LED            // LEDs muestran el ultimo byte recibido
);

// Lo que entrara a la ALU antes del FF
wire [21:0] reg_alu_data_in;
wire        reg_alu_load_pulse;

// Salidas del FF (es solo el bus, las otras tres desprenden de el)
wire [21:0] alu_config_bus;
wire [7:0] alu_in_a;
wire [7:0] alu_in_b;
wire [5:0] alu_in_op;

// Salidas de la ALU
wire [7:0] alu_result_out;
wire       alu_zero_out;
wire       alu_overflow_out;

// DEBUG
wire [2:0] rx_current_state;
wire [2:0] tx_current_state;

// Lo que realmente va a la ALU es el BUS
assign alu_in_op = alu_config_bus[21:16];
assign alu_in_b  = alu_config_bus[15:8];
assign alu_in_a  = alu_config_bus[7:0];

//Instancia de Controlador UART. Permite enviar comandos basicos para ejecutar y mostrar.
uart_controller #(
    .BAUD_SELECTOR(2'b00)
)i_uart_ctrl 
(
    .clk(CLK100MHZ),
    .reset(RST),
    .serial_in(RX_IN),
    .serial_out(TX_OUT),
    .alu_result(alu_result_out),
    .alu_zero_flag(alu_zero_out),
    .alu_overflow_flag(alu_overflow_out),
    .alu_data_out(reg_alu_data_in),
    .reg_load_pulse(reg_alu_load_pulse),
    .rx_current_state(rx_current_state),
    .tx_current_state(tx_current_state)
    
);

// Instancia del registro intermedio para la ALU
register #(
    .WIDTH(22)
) i_alu_register (
    .clk(CLK100MHZ),
    .reset(RST),
    .load_en(reg_alu_load_pulse),
    .data_in(reg_alu_data_in),
    .data_out(alu_config_bus)
);

// Instancia de la Unidad Aritmetico-Logica
simple_alu #(
    .DATA_WIDTH(8)
) i_simple_alu (
    .A(alu_in_a),
    .B(alu_in_b),
    .Op(alu_in_op),
    .Result(alu_result_out),
    .Overflow(alu_overflow_out),
    .Zero(alu_zero_out)
);

assign LED[2:0] = rx_current_state;
assign LED[3]   = 1'b1;
assign LED[6:4] = tx_current_state;
assign LED[7]   = 1'b1;
endmodule
