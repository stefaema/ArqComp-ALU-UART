//----------------------------------------------------------------------------------
// MODULE: register (Sincronous Flip-Flop with Enable)
// DESCRIPTION:
//              Registro secuencial (Flip-Flop) parametrizable (WIDTH) con reset asincrono
//              y habilitacion de carga sincrona (load_en).
//----------------------------------------------------------------------------------

module register #(
    parameter WIDTH = 8 // Ancho del registro
) (
    // CTRL: Reloj, Reset, Habilitacion de Carga
    input wire clk,
    input wire reset, 
    input wire load_en,
    // Datos
    input wire [WIDTH-1:0] data_in, 
    output reg [WIDTH-1:0] data_out 
);

always @(posedge clk or posedge reset) begin
    if (reset) data_out <= {WIDTH{1'b0}};      // Reset a cero
    else if (load_en)  data_out <= data_in;    // Cargar el dato de los switches
  
    // Si no hay reset ni carga, el valor se mantiene
end

endmodule
