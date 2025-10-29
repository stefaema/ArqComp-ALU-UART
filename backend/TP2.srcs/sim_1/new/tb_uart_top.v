//-----------------------------------------------------------------------------
// MODULE:         tb_uart_top
// DESCRIPTION:    Testbench para el modulo uart_top.
//                 - Verifica la transmision continua del byte 0x93.
//                 - Envia el byte 0x5A y verifica que se recibe en los LEDs.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_uart_top;

    //------------------------------------------------------------------
    // Parametros de la Simulacion
    //------------------------------------------------------------------
    localparam CLK_FREQ      = 100_000_000;
    localparam CLK_PERIOD_NS = 10; // 100 MHz clock period

    localparam BAUD_RATE     = 9600;
    localparam BIT_PERIOD_NS = 1_000_000_000 / BAUD_RATE;

    //------------------------------------------------------------------
    // Senales para conectar al DUT (Device Under Test)
    //------------------------------------------------------------------
    // Entradas al DUT
    reg clk_tb;
    reg btn_center_tb;
    reg btn_up_tb;
    reg btn_down_tb;
    reg rx_in_tb;

    // Salidas del DUT
    wire tx_out_tb;
    wire [7:0] led_tb;
    // No necesitamos verificar los segmentos en este testbench
    // wire [6:0] seg_tb;
    // wire [3:0] an_tb;

    //------------------------------------------------------------------
    // Instancia del DUT
    //------------------------------------------------------------------
    uart_top dut (
        .CLK100MHZ (clk_tb),
        .BTN_CENTER(btn_center_tb),
        .BTN_UP    (btn_up_tb),
        .BTN_DOWN  (btn_down_tb),
        .RX_IN     (rx_in_tb),
        .TX_OUT    (tx_out_tb),
        .LED       (led_tb)
        // .SEG    (seg_tb),
        // .AN     (an_tb)
    );

    //------------------------------------------------------------------
    // Generador de Reloj
    //------------------------------------------------------------------
    always begin
        clk_tb = 1'b0;
        #(CLK_PERIOD_NS / 2);
        clk_tb = 1'b1;
        #(CLK_PERIOD_NS / 2);
    end

    //------------------------------------------------------------------
    // Tarea para ENVIAR un byte al DUT
    //------------------------------------------------------------------
    task uart_send_byte(input [7:0] byte_to_send);
        integer i;
        begin
            $display("[%0t ns] Testbench: Enviando byte 0x%h...", $time, byte_to_send);

            // Start Bit
            rx_in_tb = 1'b0;
            #(BIT_PERIOD_NS);

            // 8 Data Bits (LSB primero)
            for (i = 0; i < 8; i = i + 1) begin
                rx_in_tb = byte_to_send[i];
                #(BIT_PERIOD_NS);
            end

            // Stop Bit
            rx_in_tb = 1'b1;
            #(BIT_PERIOD_NS);

            $display("[%0t ns] Testbench: Byte 0x%h enviado.", $time, byte_to_send);
        end
    endtask

    //------------------------------------------------------------------
    // Secuencia Principal de la Prueba
    //------------------------------------------------------------------
    initial begin: main_test_sequence
        reg[7:0] received_byte;
        integer i;
    
    
        // 1. Inicializacion
        $display("[%0t ns] ---- Inicio de la simulacion ----", $time);
        btn_center_tb = 1'b0;
        btn_up_tb     = 1'b0;
        btn_down_tb   = 1'b0;
        rx_in_tb      = 1'b1; // Linea UART en reposo (idle)

        // 2. Aplicar Reset
        $display("[%0t ns] Aplicando reset...", $time);
        btn_center_tb = 1'b1;
        #(CLK_PERIOD_NS * 10); // Mantener reset por 10 ciclos
        btn_center_tb = 1'b0;
        $display("[%0t ns] Reset liberado. El DUT deberia empezar a transmitir.", $time);

        // 3. Verificar la primera transmision del DUT
        // El DUT transmite continuamente. Solo verificaremos el primer byte.
        @(negedge tx_out_tb); // Esperar al start bit
        $display("[%0t ns] DUT: Start bit detectado en TX_OUT. Capturando byte...", $time);

        #(BIT_PERIOD_NS / 2); // Ir al centro del start bit

        // Muestrear los 8 bits

        for (i = 0; i < 8; i = i + 1) begin
            #(BIT_PERIOD_NS);
            received_byte[i] = tx_out_tb;
        end
        
        #(BIT_PERIOD_NS); // Esperar durante el stop bit para sincronizar
        $display("[%0t ns] DUT: Byte capturado de TX_OUT: 0x%h", $time, received_byte);
        
        if (received_byte === 8'h93) begin
            $display(">> EXITO: El byte transmitido por el DUT es el esperado (0x93).");
        end else begin
            $display(">> FALLO: El byte transmitido por el DUT (0x%h) no es el esperado (0x93).", received_byte);
        end

        #(BIT_PERIOD_NS * 5); // Esperar un poco

        // 4. Probar el receptor del DUT
        $display("\n[%0t ns] ---- Probando el receptor del DUT ----", $time);
        
        // Enviar un byte de prueba al DUT
        uart_send_byte(8'h5A);
        
        // Dar tiempo al DUT para procesar y mostrar en los LEDs
        #(BIT_PERIOD_NS);

        $display("[%0t ns] Verificando salida de LEDs...", $time);
        if (led_tb === 8'h5A) begin
            $display(">> EXITO: El DUT recibio 0x5A y lo mostro correctamente en los LEDs (0x%h).", led_tb);
        end else begin
            $display(">> FALLO: Se esperaba 0x5A en los LEDs, pero se leyo 0x%h.", led_tb);
        end

        // 5. Finalizar simulacion
        $display("\n[%0t ns] ---- Simulacion completada ----", $time);
        $finish;
    end

endmodule