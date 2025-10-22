//-----------------------------------------------------------------------------
// MODULE:         uart_controller
// DESCRIPTION:
//                 Modulo encapsulador que contiene todo el subsistema UART.
//                 Gestiona la recepcion, interpretacion de comandos y
//                 transmision de resultados.
//-----------------------------------------------------------------------------

module uart_controller (
    // --- Puertos Globales ---
    input  wire        clk,
    input  wire        reset,

    // --- Interfaz UART Fisica ---
    input  wire        serial_in,
    output wire        serial_out,

    // --- Interfaz con la ALU (Entradas para TX) ---
    input  wire [7:0]  alu_result,
    input  wire        alu_zero_flag,
    input  wire        alu_overflow_flag,
    
    // --- Interfaz con el Registro de la ALU (Salidas de RX) ---
    output wire [21:0] alu_data_out,
    output wire        reg_load_pulse
);

    // 1. Senales Internas de Interconexion
    //----------------------------------------------------------------
    
    // Senal compartida del generador de baud rate
    wire tick_16x;

    // Senales del camino de recepcion (uart_rx -> rx_controller)
    wire       rx_data_ready_pulse;
    wire [7:0] rx_data_out;
    wire       rx_error_frame;

    // Senales del camino de transmision (tx_controller -> uart_tx)
    wire       tx_start_pulse;
    wire [7:0] tx_data_out;
    wire       tx_busy;

    // Senal de conexion entre RX y TX (rx_controller -> tx_controller)
    wire display_cmd_pulse;


    // 2. Instanciacion de Sub-Modulos
    //----------------------------------------------------------------

    // Generador de Baud Rate (compartido)
    baud_rate_generator #(
        .CLK_FREQ(100_000_000)
    ) i_baud_gen (
        .clk(clk),
        .reset(reset),
        .baud_selector(2'b00), // 9600 baud
        .tick_16x(tick_16x)
    );

    // --- Instancias del Camino de Recepcion ---

    uart_rx i_uart_rx (
        .clk(clk),
        .reset(reset),
        .serial_in(serial_in),
        .tick_16x(tick_16x),
        .data_ready_pulse(rx_data_ready_pulse),
        .error_frame(rx_error_frame),
        .data_out(rx_data_out)
    );

    rx_controller i_rx_controller (
        .clk(clk),
        .reset(reset),
        .data_ready_pulse(rx_data_ready_pulse),
        .data_in(rx_data_out),
        .alu_data_out(alu_data_out),
        .reg_load_pulse(reg_load_pulse),
        .display_cmd_pulse(display_cmd_pulse)
    );

    // --- Instancias del Camino de Transmision ---

    tx_controller i_tx_controller (
        .clk(clk),
        .reset(reset),
        .display_cmd_pulse(display_cmd_pulse),
        .alu_result(alu_result),
        .alu_zero_flag(alu_zero_flag),
        .alu_overflow_flag(alu_overflow_flag),
        .tx_busy(tx_busy),
        .tx_data_out(tx_data_out),
        .tx_start_pulse(tx_start_pulse)
    );

    uart_tx i_uart_tx (
        .clk(clk),
        .reset(reset),
        .tick_16x(tick_16x),
        .data_in(tx_data_out),
        .start(tx_start_pulse),
        .serial_out(serial_out),
        .busy(tx_busy)
    );

endmodule
