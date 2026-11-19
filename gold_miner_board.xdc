# Nexys A7-100T | EE354 Gold Miner
# Board top uses the 100 MHz clock with internal clock enables.

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {clk}]
create_clock -name sys_clk -period 10.000 [get_ports {clk}]

# Center button starts or launches. Up button resets. Both are active high.
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {BtnC}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {BtnU}]

# VGA color outputs, 4 bits per channel.
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {vgaR[0]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {vgaR[1]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {vgaR[2]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {vgaR[3]}]
set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS33} [get_ports {vgaG[0]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {vgaG[1]}]
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports {vgaG[2]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS33} [get_ports {vgaG[3]}]
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS33} [get_ports {vgaB[0]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {vgaB[1]}]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {vgaB[2]}]
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {vgaB[3]}]

# VGA horizontal and vertical sync.
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {hSync}]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports {vSync}]
