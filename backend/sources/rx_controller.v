//-----------------------------------------------------------------------------
// MODULE:         rx_controller
// DESCRIPTION:    
//                 Controlador de recepcion (FSM) que interpreta un protocolo
//                 simple sobre el flujo de bytes recibido por la UART.
//-----------------------------------------------------------------------------

module rx_controller (
    // --- Entradas ---
    input  wire        clk,
    input  wire        reset,
    input  wire        data_ready_pulse, // Pulso de 'uart_rx' indicando nuevo byte
    input  wire [7:0]  data_in,          // Byte recibido de 'uart_rx'

    // --- Salidas ---
    output wire [21:0] alu_data_out,       // Salida para el registro de la ALU: {Op[5:0], B[7:0], A[7:0]}
    output wire        reg_load_pulse,     // Pulso para cargar el registro de la ALU
    output wire        display_cmd_pulse   // Pulso para iniciar la transmision del resultado
);

    // 1. Parametros y Estados de la FSM
    //----------------------------------------------------------------
    localparam CMD_CONFIG  = 8'hCD;
    localparam CMD_DISPLAY = 8'hD1;

    localparam [2:0] S_IDLE    = 3'd0;
    localparam [2:0] S_WAIT_A  = 3'd1;
    localparam [2:0] S_WAIT_B  = 3'd2;
    localparam [2:0] S_WAIT_OP = 3'd3;
    localparam [2:0] S_DONE    = 3'd4; 

    // 2. Declaracion de Registros
    //----------------------------------------------------------------
    reg [2:0] state_reg, next_state;
    reg [7:0] op_a_reg;
    reg [7:0] op_b_reg;
    reg [7:0] op_code_reg;
    reg [21:0] alu_data_out_reg;

    reg display_cmd_pulse_comb;

    // 3. Logica Secuencial (Actualizacion de Registros)
    //----------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg        <= S_IDLE;
            op_a_reg         <= 8'd0;
            op_b_reg         <= 8'd0;
            op_code_reg      <= 8'd0;
            alu_data_out_reg <= 22'd0;
        end else begin
            state_reg <= next_state;

            // La captura de datos ocurre durante las transiciones
            if (data_ready_pulse) begin
                case (state_reg)
                    S_WAIT_A:  op_a_reg    <= data_in;
                    S_WAIT_B:  op_b_reg    <= data_in;
                    S_WAIT_OP: op_code_reg <= data_in; 
                endcase
            end
            
            // La actualizacion del bus de datos de la ALU ocurre al transicionar a S_DONE
            if (next_state == S_DONE) begin
                 alu_data_out_reg <= {op_code_reg[5:0], op_b_reg, op_a_reg};
            end
        end
    end

    // 4. Logica Combinacional (Calculo de Siguiente Estado y Salidas)
    //----------------------------------------------------------------
    always @(*) begin
        next_state             = state_reg;
        display_cmd_pulse_comb = 1'b0;

        case (state_reg)
            S_IDLE: begin
                if (data_ready_pulse) begin
                    if (data_in == CMD_CONFIG) begin
                        next_state = S_WAIT_A;
                    end 
                    else if (data_in == CMD_DISPLAY) begin
                        display_cmd_pulse_comb = 1'b1;
                        next_state = S_IDLE; // Permanecer en IDLE
                    end
                end
            end
            
            S_WAIT_A: begin
                if (data_ready_pulse) next_state = S_WAIT_B;
            end

            S_WAIT_B: begin
                if (data_ready_pulse) next_state = S_WAIT_OP;
            end

            S_WAIT_OP: begin
                if (data_ready_pulse) next_state = S_DONE;
            end
            
            S_DONE: begin
                // En este estado, la salida de datos ya es estable.
                next_state = S_IDLE;
            end
            
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
    
    // 5. Asignacion Final de Salidas
    //----------------------------------------------------------------
    assign alu_data_out      = alu_data_out_reg;
    // El pulso de carga solo se activa cuando estamos en el estado S_DONE
    assign reg_load_pulse    = (state_reg == S_DONE);
    assign display_cmd_pulse = display_cmd_pulse_comb;

endmodule
