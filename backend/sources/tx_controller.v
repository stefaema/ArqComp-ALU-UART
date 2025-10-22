//-----------------------------------------------------------------------------
// MODULE:         tx_controller
// DESCRIPTION:
//                 Controlador de transmision (FSM) que, al recibir un
//                 comando, envia secuencialmente el resultado de la ALU y
//                 sus flags a traves del modulo uart_tx.
//-----------------------------------------------------------------------------

module tx_controller (
    // --- Entradas ---
    input  wire        clk,
    input  wire        reset,
    input  wire        display_cmd_pulse,   // Pulso que inicia la transmision
    input  wire [7:0]  alu_result,
    input  wire        alu_zero_flag,
    input  wire        alu_overflow_flag,
    input  wire        tx_busy,             // Flag de ocupado del uart_tx

    // --- Salidas ---
    output wire [7:0]  tx_data_out,       // Datos para el uart_tx
    output wire        tx_start_pulse       // Pulso de inicio para el uart_tx
);

    // 1. Estados de la FSM
    //----------------------------------------------------------------
    localparam [2:0] S_IDLE              = 3'd0; // Esperando comando de display
    localparam [2:0] S_SEND_RESULT       = 3'd1; // Enviar el byte de resultado
    localparam [2:0] S_WAIT_RESULT_SENT  = 3'd2; // Esperar a que TX termine el byte de resultado
    localparam [2:0] S_SEND_FLAGS        = 3'd3; // Enviar el byte de flags
    localparam [2:0] S_WAIT_FLAGS_SENT   = 3'd4; // Esperar a que TX termine el byte de flags

    // 2. Declaracion de Registros
    //----------------------------------------------------------------
    reg [2:0] state_reg, next_state;
    
    // Registros para capturar los datos de la ALU y mantenerlos estables
    // durante toda la secuencia de transmision.
    reg [7:0] result_reg;
    reg [7:0] flags_reg;

    // 3. Logica Secuencial (Actualizacion de Registros)
    //----------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg  <= S_IDLE;
            result_reg <= 8'd0;
            flags_reg  <= 8'd0;
        end else begin
            state_reg <= next_state;

            // Capturar los datos de la ALU solo al inicio de la secuencia
            if (state_reg == S_IDLE && next_state == S_SEND_RESULT) begin
                result_reg <= alu_result;
                flags_reg  <= {6'b0, alu_overflow_flag, alu_zero_flag};
            end
        end
    end

    // 4. Logica Combinacional (Calculo de Siguiente Estado y Salidas)
    //----------------------------------------------------------------
    always @(*) begin
        // Valores por defecto para evitar latches
        next_state = state_reg;

        case (state_reg)
            S_IDLE: begin
                if (display_cmd_pulse && !tx_busy) begin
                    next_state = S_SEND_RESULT;
                end
            end

            S_SEND_RESULT: begin
                next_state = S_WAIT_RESULT_SENT;
            end

            S_WAIT_RESULT_SENT: begin
                if (!tx_busy) begin
                    next_state = S_SEND_FLAGS;
                end
            end
            
            S_SEND_FLAGS: begin
                next_state = S_WAIT_FLAGS_SENT;
            end

            S_WAIT_FLAGS_SENT: begin
                if (!tx_busy) begin
                    next_state = S_IDLE;
                end
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
    
    // 5. Asignacion Final de Salidas
    //----------------------------------------------------------------

    // El pulso de inicio se genera en los estados de envio
    assign tx_start_pulse = (state_reg == S_SEND_RESULT) || (state_reg == S_SEND_FLAGS);
    
    // Seleccionar que dato enviar al transmisor segun el estado
    assign tx_data_out = (state_reg == S_SEND_RESULT) ? result_reg : flags_reg;

endmodule
