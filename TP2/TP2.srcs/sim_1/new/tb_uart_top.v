//-----------------------------------------------------------------------------
// MODULE:         tb_uart_top
// DESCRIPTION:
//                 Banco de pruebas auto-verificable para el modulo uart_top.
//                 Este testbench envia comandos a la ALU y luego recibe
//                 y comprueba los resultados y flags transmitidos de vuelta.
//                 **Compatible con el estandar Verilog-2001.**
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_uart_top;

    // 1. Parametros y Constantes de Temporizacion
    //----------------------------------------------------------------
    localparam CLK_PERIOD  = 10; // 100 MHz
    localparam BAUD_RATE   = 9600;
    localparam CLK_FREQ    = 100_000_000;

    // Se replica la logica del hardware para garantizar una temporizacion UART perfecta.
    localparam integer BAUD_DIVISOR_CLKS = (CLK_FREQ / (BAUD_RATE * 16));
    localparam integer BIT_PERIOD        = BAUD_DIVISOR_CLKS * 16 * CLK_PERIOD;
    localparam integer PADDED_BIT_PERIOD = BAUD_DIVISOR_CLKS * 17 * CLK_PERIOD;
    //----------------------------------------------------------------

    // Codigos de comando y operacion
    localparam CMD_CONFIG  = 8'hCD;
    localparam CMD_DISPLAY = 8'hD1;
    localparam OP_ADD      = 8'h20;
    localparam OP_SUB      = 8'h22;

    // 2. Senales del Testbench
    //----------------------------------------------------------------
    reg  tb_clk;
    reg  tb_reset;
    reg  tb_rx_in;      // Senal que nosotros controlamos para enviar datos al DUT
    wire tb_tx_out;     // Senal que el DUT controla y nosotros escuchamos
    wire [7:0] tb_leds;

    // Contadores para el reporte final
    integer test_count;
    integer fail_count;

    // 3. Instancia del Diseno Bajo Prueba (DUT)
    //----------------------------------------------------------------
    uart_top dut (
        .CLK100MHZ(tb_clk),
        .RST(tb_reset),
        .RX_IN(tb_rx_in),
        .TX_OUT(tb_tx_out),
        .LED(tb_leds)
    );

    // 4. Generacion de Reloj y Reset
    //----------------------------------------------------------------
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    initial begin
        // Inicializar contadores y senales
        tb_reset   = 1'b1;
        tb_rx_in   = 1'b1; // Linea UART en reposo
        test_count = 0;
        fail_count = 0;
        #(CLK_PERIOD * 10);
        tb_reset = 1'b0; // Liberar el reset
    end

    // 5. Tareas UART (Envio y Recepcion)
    //----------------------------------------------------------------
    task send_byte;
        input [7:0] data_to_send;
        integer i;
        begin
            // Start Bit
            tb_rx_in = 1'b0;
            #(PADDED_BIT_PERIOD);
            // Data Bits (LSB-first)
            for (i = 0; i < 8; i = i + 1) begin
                tb_rx_in = data_to_send[i];
                #(PADDED_BIT_PERIOD);
            end
            // Stop Bit
            tb_rx_in = 1'b1;
            #(PADDED_BIT_PERIOD);
        end
    endtask

    task receive_byte;
        output reg [7:0] received_data;
        reg    [7:0] data_buffer;
        integer i;
        begin
            // Esperar el flanco de bajada del start bit
            @(negedge tb_tx_out);
            // Sincronizar al centro del primer bit de datos
            #(BIT_PERIOD + BIT_PERIOD / 2);
            // Muestrear los 8 bits de datos (LSB-first)
            for (i = 0; i < 8; i = i + 1) begin
                data_buffer[i] = tb_tx_out;
                #(BIT_PERIOD);
            end
            received_data = data_buffer;
        end
    endtask

    // 6. Tarea de Verificacion (Verilog-2001 compliant)
    //----------------------------------------------------------------
    task check;
        input [7:0] received;
        input [7:0] expected;
        begin
            test_count = test_count + 1;
            if (received === expected) begin
                $display("     [PASS] Recibido: 0x%h, Esperado: 0x%h", received, expected);
            end else begin
                $display("     [FAIL] Recibido: 0x%h, Esperado: 0x%h", received, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // 7. Secuenciador de Pruebas
    //----------------------------------------------------------------
    initial begin: test
        reg [7:0] rx_result;
        reg [7:0] rx_flags;

        // Esperar a que el DUT salga del reset
        @(negedge tb_reset);
        #(CLK_PERIOD * 20);
        $display("\n==== INICIO DE LA SIMULACION AUTO-VERIFICABLE ====\n");

        // --- Test Case 1: Suma simple (5 + 10 = 15) ---
        $display("--- Test Case 1: Suma (5 + 10) ---");
        send_byte(CMD_CONFIG);
        #(BIT_PERIOD * 1);      // Pequena espera
        send_byte(8'd5);        // Operando A
        #(BIT_PERIOD * 1);      // Pequena espera
        send_byte(8'd10);       // Operando B
        #(BIT_PERIOD * 1);      // Pequena espera
        send_byte(OP_ADD);      // Codigo de Operacion
        #(BIT_PERIOD * 1);      // Pequena espera
        $display("Comando de operacion mandado. Manndando comando de muestra");
        send_byte(CMD_DISPLAY); // Solicitar resultado
        receive_byte(rx_result);
        
        $display("   Verificando resultado...");
        check(rx_result, 8'd15);
        receive_byte(rx_flags);
        $display("   Verificando flags...");
        check(rx_flags, 8'b00); // Esperado: Z=0, O=0
        #(BIT_PERIOD * 4);

        // --- Test Case 2: Resta con Flag Zero (100 - 100 = 0) ---
        $display("\n--- Test Case 2: Resta con Flag Zero (100 - 100) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'd100);      // Operando A
        send_byte(8'd100);      // Operando B
        send_byte(OP_SUB);      // Codigo de Operacion
        #(BIT_PERIOD * 2);
        send_byte(CMD_DISPLAY);
        
        receive_byte(rx_result);
        $display("   Verificando resultado...");
        check(rx_result, 8'd0);
        receive_byte(rx_flags);
        $display("   Verificando flags...");
        check(rx_flags, 8'b01); // Esperado: Z=1, O=0
        #(BIT_PERIOD * 4);

        // --- Test Case 3: Suma con Overflow (200 + 100 = 300 -> 44) ---
        $display("\n--- Test Case 3: Suma con Overflow (200 + 100) ---");
        send_byte(CMD_CONFIG);
        send_byte(8'd200);      // Operando A
        send_byte(8'd100);      // Operando B
        send_byte(OP_ADD);      // Codigo de Operacion
        #(BIT_PERIOD * 2);
        send_byte(CMD_DISPLAY);
        
        receive_byte(rx_result);
        $display("   Verificando resultado...");
        check(rx_result, 8'd44); // 300 mod 256 = 44
        receive_byte(rx_flags);
        $display("   Verificando flags...");
        check(rx_flags, 8'b10); // Esperado: Z=0, O=1
        #(BIT_PERIOD * 20);

        // --- Reporte Final ---
        $display("\n==== FIN DE LA SIMULACION ====");
        if (fail_count == 0) begin
            $display(">>>>> TODOS LOS %0d TESTS PASARON <<<<<", test_count);
        end else begin
            $display(">>>>> %0d de %0d TESTS FALLARON <<<<<", fail_count, test_count);
        end
        $display("");
        $finish;
    end

endmodule