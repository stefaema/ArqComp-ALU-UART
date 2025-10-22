//-----------------------------------------------------------------------------
// MODULE:         tb_tp2_top
// DESCRIPTION:
//                 Banco de pruebas para el modulo tp2_top.
//                 Simula un host que envia comandos a traves de UART
//                 y verifica las respuestas recibidas.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_tp2_top;

    // 1. Parametros y Constantes del Testbench
    //----------------------------------------------------------------
    localparam CLK_PERIOD  = 10; // Periodo del reloj (10 ns -> 100 MHz)
    localparam BAUD_RATE   = 115200;
    // Periodo de bit en ns (1 / 115200) * 1e9
    localparam integer BIT_PERIOD = 1_000_000_000 / BAUD_RATE;

    // Codigos de comando y operacion
    localparam CMD_CONFIG  = 8'hCD;
    localparam CMD_DISPLAY = 8'hD1;
    localparam OP_ADD      = 8'h20;
    localparam OP_SUB      = 8'h22;

    // 2. Senales del Testbench
    //----------------------------------------------------------------
    reg  tb_clk;
    reg  tb_reset;
    reg  tb_rx_in;
    wire tb_tx_out;

    integer test_count;
    integer fail_count;

    // 3. Instancia del Diseno Bajo Prueba (DUT)
    //----------------------------------------------------------------
    tp2_top dut (
        .CLK100MHZ(tb_clk),
        .BTN_CENTER(tb_reset),
        .RX_IN(tb_rx_in),
        .TX_OUT(tb_tx_out)
    );

    // 4. Generador de Reloj y Reset
    //----------------------------------------------------------------
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    initial begin
        tb_reset = 1'b1;
        tb_rx_in = 1'b1; // Linea UART en reposo (alta)
        test_count = 0;
        fail_count = 0;
        #(CLK_PERIOD * 10);
        tb_reset = 1'b0;
    end

    // 5. Tareas de Abstraccion UART
    //----------------------------------------------------------------

    // Tarea para enviar un byte por el puerto serie simulado
    task send_byte(input [7:0] data_to_send);
        integer i;
        begin
            // Start Bit (low)
            tb_rx_in = 1'b0;
            #(BIT_PERIOD);

            // 8 Data Bits (LSB primero)
            for (i = 0; i < 8; i = i + 1) begin
                tb_rx_in = data_to_send[i];
                #(BIT_PERIOD);
            end

            // Stop Bit (high)
            tb_rx_in = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    // Tarea para recibir y verificar un byte
    task check_received_byte(input [7:0] expected_data, input string test_name);
        reg [7:0] received_byte;
        integer i;
        begin
            test_count = test_count + 1;

            // Esperar el start bit (borde de bajada)
            @(negedge tb_tx_out);

            // Esperar la mitad del periodo del start bit para centrar el muestreo
            #(BIT_PERIOD / 2);

            // Verificar que la linea sigue en bajo (es un start bit valido)
            if (tb_tx_out !== 1'b0) begin
                $display("[%s] FAIL: Se esperaba un Start Bit valido.", test_name);
                fail_count = fail_count + 1;
            end else begin
                // Muestrear los 8 bits de datos
                for (i = 0; i < 8; i = i + 1) begin
                    #(BIT_PERIOD);
                    received_byte[i] = tb_tx_out;
                end

                // Esperar el stop bit
                #(BIT_PERIOD);
                if (tb_tx_out !== 1'b1) begin
                    $display("[%s] FAIL: Se esperaba un Stop Bit valido.", test_name);
                    fail_count = fail_count + 1;
                end else begin
                    // Comparar el byte recibido con el esperado
                    if (received_byte === expected_data) begin
                        $display("[%s] PASS: Se recibio el valor esperado 0x%h.", test_name, expected_data);
                    end else begin
                        $display("[%s] FAIL: Se esperaba 0x%h, pero se recibio 0x%h.", test_name, expected_data, received_byte);
                        fail_count = fail_count + 1;
                    end
                end
            end
            #(BIT_PERIOD); // Tiempo extra para asegurar que la linea se estabilice
        end
    endtask


    // 6. Secuenciador de Pruebas
    //----------------------------------------------------------------
    initial begin
        // Esperar a que el reset termine
        @(negedge tb_reset);
        #(CLK_PERIOD * 20);

        $display("\n==== INICIO DE LA SIMULACION DEL TP2 ====\n");

        // --- Test Case 1: Suma simple (5 + 10 = 15) ---
        $display("--- Test Case 1: Suma (5 + 10) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'h05); // A = 5
        send_byte(8'h0A); // B = 10
        send_byte(OP_ADD);
        #(BIT_PERIOD * 2); // Pequeña espera
        send_byte(CMD_DISPLAY);
        
        check_received_byte(8'h0F, "Test 1 - Resultado"); // Resultado = 15
        check_received_byte(8'h00, "Test 1 - Flags");    // Flags = 0


        // --- Test Case 2: Resta con resultado Cero (100 - 100 = 0) ---
        $display("\n--- Test Case 2: Resta con Flag Zero (100 - 100) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'h64); // A = 100
        send_byte(8'h64); // B = 100
        send_byte(OP_SUB);
        #(BIT_PERIOD * 2);
        send_byte(CMD_DISPLAY);

        check_received_byte(8'h00, "Test 2 - Resultado"); // Resultado = 0
        check_received_byte(8'h01, "Test 2 - Flags");    // Zero=1, Overflow=0


        // --- Test Case 3: Suma con Overflow (100 + 50 = -106) ---
        $display("\n--- Test Case 3: Suma con Flag Overflow (100 + 50) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'h64); // A = 100
        send_byte(8'h32); // B = 50
        send_byte(OP_ADD);
        #(BIT_PERIOD * 2);
        send_byte(CMD_DISPLAY);

        check_received_byte(8'h96, "Test 3 - Resultado"); // Resultado = -106
        check_received_byte(8'h02, "Test 3 - Flags");    // Zero=0, Overflow=1
        

        // --- Resumen Final ---
        $display("\n==== FIN DE LA SIMULACION ====");
        if (fail_count == 0) begin
            $display(">> RESULTADO: TODOS LOS %0d TESTS PASARON <<", test_count);
        end else begin
            $display(">> RESULTADO: FALLARON %0d DE %0d TESTS <<", fail_count, test_count);
        end
        $display("");
        
        $finish;
    end

endmodule
