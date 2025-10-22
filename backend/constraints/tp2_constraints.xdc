# ============================================================================
# UART_TOP Constraints - Digilent Basys3
# ============================================================================

# 1. Clock 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports CLK100MHZ]

# 2. Botones
set_property PACKAGE_PIN U18 [get_ports BTN_CENTER] ;# Reset (BTN_CENTER)
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_CENTER}]

# 5. Interfaz UART (USB-Serial Bridge)
set_property PACKAGE_PIN B18 [get_ports TX_OUT]
set_property PACKAGE_PIN A18 [get_ports RX_IN]
set_property IOSTANDARD LVCMOS33 [get_ports {TX_OUT RX_IN}]
