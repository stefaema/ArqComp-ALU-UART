//-----------------------------------------------------------------------------
// MODULE:         uart_rx
// DESCRIPTION:    Deserializa un byte proveniente de un flujo de datos UART.
//-----------------------------------------------------------------------------

module uart_rx #(
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   serial_in,
    input  wire                   tick_16x,

    output reg                    done_tick,
    output wire                   error_frame,
    output wire [7:0]   data_out
);

    // 1. Sincronizacion de la Entrada Asincrona: evita metaestabilidad
    //----------------------------------------------------------------

    reg serial_in_r1, serial_in_r2;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            serial_in_r1 <= 1'b1;
            serial_in_r2 <= 1'b1;
        end else begin
            serial_in_r1 <= serial_in;
            serial_in_r2 <= serial_in_r1;
        end
    end

    // Deteccion de borde de bajada en la senial ya sincronizada
    wire falling_edge = ~serial_in_r1 & serial_in_r2;


    // 2. Estados (FSM)
    //----------------------------------------------------------------
    localparam [2:0] S_IDLE      = 3'd0; // Esperando un falling edge en la linea serial
    localparam [2:0] S_START_BIT = 3'd1; // Verificando el start bit
    localparam [2:0] S_DATA_BITS = 3'd2; // Recibiendo los bits de datos
    localparam [2:0] S_STOP_BIT  = 3'd3; // Verificando el stop bit
    localparam [2:0] S_DONE      = 3'd4; // Estado transitorio para generar done_tick

    // 3. Declaracion de Registros 
    //----------------------------------------------------------------
    reg [2:0]                   state_reg, next_state;
    reg [7:0]                   bit_index_reg, next_bit_index;
    reg [3:0]                   tick_count_reg, next_tick_count;
    reg [7:0]                   data_buffer_reg, next_data_buffer;
    reg [7:0]                   data_out_reg, next_data_out;
    reg                         error_frame_reg, next_error_frame;

    // 4. Bloque de actualizacion de registros
    //----------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg       <= S_IDLE;
            bit_index_reg   <= 0;
            tick_count_reg  <= 0;
            data_buffer_reg <= 0;
            data_out_reg    <= 0;
            error_frame_reg <= 1'b0;
        end else begin
            state_reg       <= next_state;
            bit_index_reg   <= next_bit_index;
            tick_count_reg  <= next_tick_count;
            data_buffer_reg <= next_data_buffer;
            data_out_reg    <= next_data_out;
            error_frame_reg <= next_error_frame;
        end
    end

    // 5. Calculo del siguiente estado y salidas
    //----------------------------------------------------------------
    always @(*) begin
        // Valores por defecto: mantener el estado actual
        next_state       = state_reg;
        next_bit_index   = bit_index_reg;
        next_tick_count  = tick_count_reg;
        next_data_buffer = data_buffer_reg;
        next_data_out    = data_out_reg;
        next_error_frame = error_frame_reg;
        done_tick        = 1'b0; // El pulso de salida es '0' por defecto

        case (state_reg)
            // Esperando un falling edge en la linea serial
            S_IDLE: begin
                if (falling_edge) begin
                    next_state       = S_START_BIT;
                    next_tick_count  = 0;
                    next_error_frame = 1'b0; // Limpiar error de la trama anterior si lo hay
                end
            end

            // Verificar que el start bit es valido
            S_START_BIT: begin
                if (tick_16x) begin
                   
                    if (tick_count_reg == 7) begin // Muestrar solo al medio del start bit
                            
                        next_tick_count = 0;
                            
                        if (serial_in_r2 == 1'b0) begin // Si es un start bit valido
                            next_state      = S_DATA_BITS;
                            next_tick_count = 0;
                            next_bit_index  = 0;
                        end else begin // Si no es un start bit valido, volver a esperar
                            next_state = S_IDLE;
                        end
                    end else begin
                        next_tick_count = tick_count_reg + 1;
                    end
                end
            end

            // Muestrear cada 16 ticks para cada bit de datos
            S_DATA_BITS: begin
                if (tick_16x) begin
    
                    if (tick_count_reg == 15) begin // Muestrear siempre al centro de cada bit
                        next_tick_count  = 0;
                        // Ensambla el byte, LSB primero
                        next_data_buffer = {serial_in_r2, data_buffer_reg[7:1]};

                        if (bit_index_reg == 7) begin // Verificar stop bit si ya se recibieron todos los bits
                            next_state = S_STOP_BIT;
                        end else begin
                            next_bit_index = bit_index_reg + 1;
                        end
                    end else begin
                        next_tick_count = tick_count_reg + 1;
                    end
                end
            end

            // Verificar el bit de stop
            S_STOP_BIT: begin
                if (tick_16x) begin
                    if (tick_count_reg == 15) begin // Muestrear al centro del stop bit

                        if (serial_in_r2 == 1'b1) begin // Si es un stop bit valido

                            next_data_out = data_buffer_reg; // Oficializar el byte recibido
                            next_error_frame = 1'b0;
                        end else begin
                            next_error_frame = 1'b1;        // Sino marcar error de trama y no se actualiza data_out
                        end
                        next_state = S_DONE; // Ir al estado final para el pulso
                    end else begin
                        next_tick_count = tick_count_reg + 1;
                    end
                end
            end

            S_DONE: begin
                // Estado transitorio de 1 ciclo
                done_tick  = 1'b1; // Activar el pulso de salida
                next_state = S_IDLE; // Volver a esperar la siguiente trama
            end

        endcase
    end

    // 6. Asignacion Final de Salidas
    //----------------------------------------------------------------
    assign data_out    = data_out_reg;
    assign error_frame = error_frame_reg;

endmodule


