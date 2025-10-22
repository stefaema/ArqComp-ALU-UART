//-----------------------------------------------------------------------------
// MODULE:         tp2_top
// DESCRIPTION:
//                 Modulo superior del sistema. Instancia y conecta el
//                 controlador UART, el registro de la ALU y la propia ALU.
//                 Conecta la logica interna a los pines de la FPGA.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tp2_top (
    // --- Puertos Fisicos ---
    input  wire CLK100MHZ,
    input  wire BTN_CENTER, // Usado como reset global
    input  wire RX_IN,
    output wire TX_OUT
);

    // 1. Senales Internas de Interconexion
    //----------------------------------------------------------------

    // Salidas del uart_controller hacia el registro de la ALU
    wire [21:0] reg_alu_data_in;
    wire        reg_alu_load_pulse;

    // Salida del registro hacia la ALU
    wire [21:0] alu_config_bus;

    // Senales desagregadas del bus de configuracion para la ALU
    wire [7:0] alu_in_a;
    wire [7:0] alu_in_b;
    wire [5:0] alu_in_op;

    // Salidas de la ALU hacia el uart_controller
    wire [7:0] alu_result_out;
    wire       alu_zero_out;
    wire       alu_overflow_out;

    // El boton es activo en alto, coincide con la logica de reset
    wire reset = BTN_CENTER;


    // 2. Desagregacion del Bus de Configuracion de la ALU
    //----------------------------------------------------------------
    // El bus que sale del registro se descompone para alimentar la ALU
    // Formato: {Op[5:0], B[7:0], A[7:0]}
    assign alu_in_op = alu_config_bus[21:16];
    assign alu_in_b  = alu_config_bus[15:8];
    assign alu_in_a  = alu_config_bus[7:0];


    // 3. Instanciacion de Modulos Principales
    //----------------------------------------------------------------

    // Instancia del subsistema UART completo
    uart_controller i_uart_controller (
        .clk(CLK100MHZ),
        .reset(reset),
        .serial_in(RX_IN),
        .serial_out(TX_OUT),
        .alu_result(alu_result_out),
        .alu_zero_flag(alu_zero_out),
        .alu_overflow_flag(alu_overflow_out),
        .alu_data_out(reg_alu_data_in),
        .reg_load_pulse(reg_alu_load_pulse)
    );

    // Instancia del registro intermedio para la ALU
    register #(
        .WIDTH(22)
    ) i_alu_register (
        .clk(CLK100MHZ),
        .reset(reset),
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

endmodule
