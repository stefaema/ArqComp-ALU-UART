//-----------------------------------------------------------------------------
// MODULE:         tb_tp2_top
// DESCRIPTION:
//                 Banco de pruebas para el modulo tp2_top.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_tp2_top;

    // 1. Parametros y Constantes de Temporizacion Sincronizada
    //----------------------------------------------------------------
    localparam CLK_PERIOD  = 10;
    localparam BAUD_RATE   = 9600;
    localparam CLK_FREQ    = 100_000_000;

    // REPLICAMOS LA LOGICA DEL HARDWARE PARA GARANTIZAR SINCRONIZACION PERFECTA
    // Esta es la cantidad de ciclos de reloj para un tick de 16x (truncado)
    localparam integer BAUD_DIVISOR_CLKS = (CLK_FREQ / (BAUD_RATE * 16));
    // Este es el periodo de bit EXACTO, en nanosegundos, que el hardware usa
    localparam integer BIT_PERIOD = BAUD_DIVISOR_CLKS * 16 * CLK_PERIOD;
    //----------------------------------------------------------------

    // Codigos de comando y operacion
    localparam CMD_CONFIG  = 8'hCD;
    localparam CMD_DISPLAY = 8'hD1;
    localparam OP_ADD      = 8'h20;
    localparam OP_SUB      = 8'h22;

    // 2. Senales
    reg  tb_clk;
    reg  tb_reset;
    reg  tb_rx_in;
    wire tb_tx_out;
    wire [7:0] tb_leds;
    integer test_count;
    integer fail_count;

    // 3. Instancia DUT
    tp2_top dut (.CLK100MHZ(tb_clk), .BTN_CENTER(tb_reset), .RX_IN(tb_rx_in), .TX_OUT(tb_tx_out), .LEDS(tb_leds));

    // 4. Reloj y Reset
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end
    initial begin
        tb_reset = 1'b1; tb_rx_in = 1'b1; test_count = 0; fail_count = 0;
        #(CLK_PERIOD * 10);
        tb_reset = 1'b0;
    end

    // 5. Tareas UART
    task send_byte(input [7:0] data_to_send);
        integer i;
        begin
            tb_rx_in = 1'b0; #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                tb_rx_in = data_to_send[i];
                #(BIT_PERIOD);
            end
            tb_rx_in = 1'b1; #(BIT_PERIOD);
        end
    endtask


    // 6. Secuenciador de Pruebas
    initial begin
        @(negedge tb_reset);
        #(CLK_PERIOD * 20);
        $display("\n==== INICIO DE LA SIMULACION DEL TP2 ====\n");

        $display("--- Test Case 1: Suma (5 + 10) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'h05); send_byte(8'h0A); send_byte(OP_ADD);
        #(BIT_PERIOD * 4);
        send_byte(CMD_DISPLAY);
        #(BIT_PERIOD * 4);


        $display("\n--- Test Case 2: Resta con Flag Zero (100 - 100) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'h64); send_byte(8'h64); send_byte(OP_SUB);
        #(BIT_PERIOD * 4);
        send_byte(CMD_DISPLAY);
        #(BIT_PERIOD * 4);


        $display("\n--- Test Case 3: Suma con Overflow (100 + 50) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'h64); send_byte(8'h32); send_byte(OP_ADD);
        #(BIT_PERIOD * 4);
        send_byte(CMD_DISPLAY);
        #(BIT_PERIOD * 20);

        
        $display("\n==== FIN DE LA SIMULACION ====");

        $display("");
        $finish;
    end

endmodule
