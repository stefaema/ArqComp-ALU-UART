# ============================================================================
# UART_TOP Constraints - Digilent Basys3
# ============================================================================

# 1. Clock 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports CLK100MHZ]

# 2. Botones
set_property PACKAGE_PIN U18 [get_ports BTN_CENTER] ;# Reset (BTN_CENTER)
set_property PACKAGE_PIN T18 [get_ports BTN_UP]
set_property PACKAGE_PIN U17 [get_ports BTN_DOWN]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_CENTER BTN_UP BTN_DOWN}]

# 3. LEDs (solo 8 usados)
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]

# 4. Display de 7 segmentos
set_property PACKAGE_PIN W7 [get_ports {SEG[0]}]
set_property PACKAGE_PIN W6 [get_ports {SEG[1]}]
set_property PACKAGE_PIN U8 [get_ports {SEG[2]}]
set_property PACKAGE_PIN V8 [get_ports {SEG[3]}]
set_property PACKAGE_PIN U5 [get_ports {SEG[4]}]
set_property PACKAGE_PIN V5 [get_ports {SEG[5]}]
set_property PACKAGE_PIN U7 [get_ports {SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[*]}]

set_property PACKAGE_PIN U2 [get_ports {AN[0]}]
set_property PACKAGE_PIN U4 [get_ports {AN[1]}]
set_property PACKAGE_PIN V4 [get_ports {AN[2]}]
set_property PACKAGE_PIN W4 [get_ports {AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[*]}]

# 5. Interfaz UART (USB-Serial Bridge) -- [NUEVA SECCION AÑADIDA]
set_property PACKAGE_PIN B18 [get_ports TX_OUT]
set_property PACKAGE_PIN A18 [get_ports RX_IN]
set_property IOSTANDARD LVCMOS33 [get_ports {TX_OUT RX_IN}]
