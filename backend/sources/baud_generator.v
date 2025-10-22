//-----------------------------------------------------------------------------
// MODULE:         baud_rate_generator
// DESCRIPTION:    Genera un tick de temporizacion a 16 veces la frecuencia
//                 de un baud rate seleccionado dinamicamente. El modulo
//                 esta parametrizado para la frecuencia del reloj del sistema.
//
// PARAMETERS:
//   CLK_FREQ:     Frecuencia del reloj del sistema en Hz. Por defecto para
//                 la Basys3 es 100MHz.
//-----------------------------------------------------------------------------

module baud_rate_generator #(
    parameter CLK_FREQ = 100_000_000   // Frecuencia del reloj para Basys3
) (
    input  wire        clk,            // Reloj del sistema
    input  wire        reset,          // Reset asincrono, activo en alto
    input  wire [1:0]  baud_selector,  // Selector para la tasa de baudios

    output wire        tick_16x        // Pulso de 1 ciclo de clk a 16x Baud Rate
);
    // Se pre-calculan los valores del contador para cada baud rate. La formula es (Frecuencia del Reloj / (Baud Rate * 16)) - 1.
    localparam DIV_9600   = (CLK_FREQ / (9600   * 16)) - 1;
    localparam DIV_19200  = (CLK_FREQ / (19200  * 16)) - 1;
    localparam DIV_57600  = (CLK_FREQ / (57600  * 16)) - 1;
    localparam DIV_115200 = (CLK_FREQ / (115200 * 16)) - 1;

    // Contadores y registros internos
    reg [$clog2(DIV_9600)-1:0] counter_reg;   
    reg [$clog2(DIV_9600)-1:0] divisor_reg;   
    reg [1:0]                  baud_selector_d; 

    // Logica Combinacional para seleccionar el divisor basado en la entrada
    always @(*) begin
        case (baud_selector)
            2'b00:  divisor_reg = DIV_9600;
            2'b01:  divisor_reg = DIV_19200;
            2'b10:  divisor_reg = DIV_57600;
            2'b11:  divisor_reg = DIV_115200;
            default: divisor_reg = DIV_9600; // Valor seguro por defecto
        endcase
    end

    // Logica Secuencial para el contador y la generacion del tick
    always @(posedge clk or posedge reset) begin
        // Manejo del reset asincrono
        if (reset) begin
            counter_reg     <= 0;
            baud_selector_d <= 2'b0;
        // Si no hay reset, proceder con la logica normal
        end else begin
            // Si el baud rate cambia, reiniciar el contador
            if (baud_selector != baud_selector_d) begin
                baud_selector_d <= baud_selector;
                counter_reg     <= 0; 
            end
            // Logica principal del contador: incrementar o reiniciar
            else if (counter_reg == divisor_reg) begin
                counter_reg <= 0;
            end else begin
                counter_reg <= counter_reg + 1;
            end
        end
    end

    // El tick se genera si el contador alcanza el valor del divisor
    assign tick_16x = (counter_reg == divisor_reg);

endmodule

