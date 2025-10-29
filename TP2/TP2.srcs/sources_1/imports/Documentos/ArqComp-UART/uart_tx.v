//-----------------------------------------------------------------------------
// MODULE:         uart_tx
// DESCRIPTION:    Serializa un byte de datos en una trama UART.
//-----------------------------------------------------------------------------

module uart_tx (

    input  wire        clk,            // Reloj del sistema
    input  wire        reset,          // Reset asincrono, activo en alto
    input  wire        tick_16x,       // Tick del generador de baud rate (16x)

    input  wire [7:0]  data_in,        // Byte de datos a transmitir
    input  wire        start,          // Pulso de 1 ciclo para iniciar la transmision

    output reg         serial_out,     // Linea de transmision de datos (Tx)
    output wire        busy            // high mientras la transmision esta en curso
);

    // 1. Estados (FSM)
    //----------------------------------------------------------------
    localparam S_IDLE      = 2'd0; // Esperando la senial de 'start'
    localparam S_START_BIT = 2'd1; // Transmitiendo el bit de start
    localparam S_DATA_BITS = 2'd2; // Transmitiendo los 8 bits de datos
    localparam S_STOP_BIT  = 2'd3; // Transmitiendo el bit de stop

    reg [1:0] state_reg;

    // 2. Contadores y Registros de Datos
    //----------------------------------------------------------------
    reg [3:0] tick_counter_reg; 
    reg [2:0] bit_index_reg;    
    reg [7:0] data_buffer_reg;  

    // 3. Logica Secuencial de la FSM y Acciones
    //----------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg        <= S_IDLE;
            tick_counter_reg <= 4'd0;
            bit_index_reg    <= 3'd0;
            serial_out       <= 1'b1; // La linea Tx en reposo esta en alto
        end else begin
            case (state_reg)

                // Mantener la linea en alto hasta recibir 'start', luego enviar el start bit
                S_IDLE: begin 
                    serial_out <= 1'b1;
                    if (start) begin
                        data_buffer_reg  <= data_in; // Cargar el byte de datos
                        tick_counter_reg <= 4'd0;
                        serial_out       <= 1'b0;  // Transmitir el start bit
                        state_reg        <= S_START_BIT;
                    end
                end

                // Mantener 16 ticks del start bit, luego transmitir LSB
                S_START_BIT: begin
                    if (tick_16x) begin
                        if (tick_counter_reg == 15) begin // Mantener start bit por 16 ticks
                            tick_counter_reg <= 4'd0;
                            bit_index_reg    <= 3'd0;
                            serial_out       <= data_buffer_reg[0]; // LSB
                            state_reg        <= S_DATA_BITS;
                        end else begin
                            tick_counter_reg <= tick_counter_reg + 1;
                        end
                    end
                end

                // Mantener anterior por 16 ticks, luego cambiar salida. (Transmitir datos)
                S_DATA_BITS: begin
                    if (tick_16x) begin
                        if (tick_counter_reg == 15) begin // Cada 16 ticks
                            tick_counter_reg <= 4'd0;
                            
                            if (bit_index_reg == 7) begin // Si hemos enviado el ultimo bit, pasar al stop bit
                                serial_out <= 1'b1; 
                                state_reg  <= S_STOP_BIT;
                            end else begin // Sino, enviar el siguiente bit de datos
                                bit_index_reg <= bit_index_reg + 1;
                                serial_out    <= data_buffer_reg[bit_index_reg + 1];
                            end
                        end else begin
                            tick_counter_reg <= tick_counter_reg + 1;
                        end
                    end
                end

                // Transmitir el bit de stop y volver a IDLE
                S_STOP_BIT: begin
                    if (tick_16x) begin
                        if (tick_counter_reg == 15) begin
                            state_reg <= S_IDLE;
                        end else begin
                            tick_counter_reg <= tick_counter_reg + 1;
                        end
                    end
                end

                default: begin
                    state_reg <= S_IDLE;
                end
            endcase
        end
    end

    // 4. Asignacion de Salidas Combinacionales
    //----------------------------------------------------------------
    assign busy = (state_reg != S_IDLE); // Si no estamos en IDLE, estamos ocupados

endmodule

