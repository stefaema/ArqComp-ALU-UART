//----------------------------------------------------------------------------------
// MODULE: simple_alu
// DESCRIPTION:
//              Modulo Combinacional de la ALU con soporte para 8 operaciones.
//----------------------------------------------------------------------------------

module simple_alu #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] A,
    input  wire [DATA_WIDTH-1:0] B,
    input  wire [5:0] Op,
    output reg signed [DATA_WIDTH-1:0] Result, 
    output reg Overflow,
    output reg Zero
);

// Codigos de Operacion
localparam OP_ADD = 6'b100000;
localparam OP_SUB = 6'b100010;
localparam OP_AND = 6'b100100;
localparam OP_OR  = 6'b100101;
localparam OP_XOR = 6'b100110;
localparam OP_SRA = 6'b000011;
localparam OP_SRL = 6'b000010;
localparam OP_NOR = 6'b100111;

// Variables internas para el calculo
reg [DATA_WIDTH:0] sum_result;
wire a_sign, b_sign, res_sign;      

// Signos de los operandos y resultado
assign a_sign = A[DATA_WIDTH-1];
assign b_sign = B[DATA_WIDTH-1];
assign res_sign = Result[DATA_WIDTH-1];

// La logica comb. principal
always @(*) begin
    // Valores por defecto
    Result = {DATA_WIDTH{1'b0}};   
    Overflow = 1'b0;
    Zero = 1'b0;

    case (Op)
        OP_ADD: begin
            // Suma con un bit extra para capturar el carry out
            sum_result = {1'b0, A} + {1'b0, B};
            Result = sum_result[DATA_WIDTH-1:0];
            // Overflow: (A positivo, B positivo, R negativo) OR (A negativo, B negativo, R positivo)
            Overflow = (a_sign == 1'b0 && b_sign == 1'b0 && res_sign == 1'b1) || 
                       (a_sign == 1'b1 && b_sign == 1'b1 && res_sign == 1'b0);
        end

        OP_SUB: begin
            // Resta (A - B)
            sum_result = {1'b0, A} - {1'b0, B};
            Result = sum_result[DATA_WIDTH-1:0];
            // Overflow: (A positivo, ~B positivo, R negativo) OR (A negativo, ~B negativo, R positivo)
            Overflow = (a_sign == 1'b0 && b_sign == 1'b1 && res_sign == 1'b1) || 
                       (a_sign == 1'b1 && b_sign == 1'b0 && res_sign == 1'b0);
        end

        OP_AND: Result = A & B;
        OP_OR:  Result = A | B;
        OP_XOR: Result = A ^ B;
        OP_NOR: Result = ~(A | B);

        OP_SRL: Result = A >> 1; // Shift Right Logical (ingresa cero por la izquierda)
        
        OP_SRA: Result = $signed(A) >>> 1; // Shift Right Arithmetic (preserva el signo)

        default: Result = {DATA_WIDTH{1'b0}}; // Op. no valida
    endcase
    // Flag Zero
    if (Result == {DATA_WIDTH{1'b0}}) Zero = 1'b1;
    else Zero = 1'b0;
end

endmodule
