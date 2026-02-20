## nexys4_ddr_pinout.xdc
## Xilinx Artix-7 FPGA Constraints File
## Pin assignments for Nexys 4 DDR (xc7a100tcsg324-1)
## Gesture-based Robotic Arm Controller

## ============================================================================
## Clock signal (100 MHz) - Nexys 4 DDR uses E3
## ============================================================================
set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

## ============================================================================
## Reset button - Using BTNC (center button) on N17 (active-low)
## (CPU Reset BTNRES is on C12 but directly resets the FPGA itself)
## ============================================================================
set_property -dict { PACKAGE_PIN N17  IOSTANDARD LVCMOS33 } [get_ports rst_n]

## ============================================================================
## VGA Output Pins (Nexys 4 DDR on-board VGA connector)
## ============================================================================
set_property -dict { PACKAGE_PIN A3   IOSTANDARD LVCMOS33 } [get_ports {vga_r[0]}]
set_property -dict { PACKAGE_PIN B4   IOSTANDARD LVCMOS33 } [get_ports {vga_r[1]}]
set_property -dict { PACKAGE_PIN C5   IOSTANDARD LVCMOS33 } [get_ports {vga_r[2]}]
set_property -dict { PACKAGE_PIN A4   IOSTANDARD LVCMOS33 } [get_ports {vga_r[3]}]

set_property -dict { PACKAGE_PIN C6   IOSTANDARD LVCMOS33 } [get_ports {vga_g[0]}]
set_property -dict { PACKAGE_PIN A5   IOSTANDARD LVCMOS33 } [get_ports {vga_g[1]}]
set_property -dict { PACKAGE_PIN B6   IOSTANDARD LVCMOS33 } [get_ports {vga_g[2]}]
set_property -dict { PACKAGE_PIN A6   IOSTANDARD LVCMOS33 } [get_ports {vga_g[3]}]

set_property -dict { PACKAGE_PIN B7   IOSTANDARD LVCMOS33 } [get_ports {vga_b[0]}]
set_property -dict { PACKAGE_PIN C7   IOSTANDARD LVCMOS33 } [get_ports {vga_b[1]}]
set_property -dict { PACKAGE_PIN D7   IOSTANDARD LVCMOS33 } [get_ports {vga_b[2]}]
set_property -dict { PACKAGE_PIN D8   IOSTANDARD LVCMOS33 } [get_ports {vga_b[3]}]

set_property -dict { PACKAGE_PIN B11  IOSTANDARD LVCMOS33 } [get_ports vga_hsync]
set_property -dict { PACKAGE_PIN B12  IOSTANDARD LVCMOS33 } [get_ports vga_vsync]

## ============================================================================
## OV7670 Camera Interface (Pmod JA)
## Nexys 4 DDR Pmod JA pins:
##   Top row:    JA1=C17, JA2=D18, JA3=E18, JA4=G17
##   Bottom row: JA7=D17, JA8=E17, JA9=F18, JA10=G18
## ============================================================================
set_property -dict { PACKAGE_PIN C17  IOSTANDARD LVCMOS33 } [get_ports cam_xclk]
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33 } [get_ports cam_pclk]
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS33 } [get_ports cam_vsync]
set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports cam_href]

set_property -dict { PACKAGE_PIN D17  IOSTANDARD LVCMOS33 } [get_ports cam_sioc]
set_property -dict { PACKAGE_PIN E17  IOSTANDARD LVCMOS33 } [get_ports cam_siod]
set_property -dict { PACKAGE_PIN F18  IOSTANDARD LVCMOS33 } [get_ports cam_reset]
set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVCMOS33 } [get_ports cam_pwdn]

## ============================================================================
## Pmod JB - Camera Data[7:0]
## Nexys 4 DDR Pmod JB pins:
##   Top row:    JB1=D14, JB2=F16, JB3=G16, JB4=H14
##   Bottom row: JB7=E16, JB8=F13, JB9=G13, JB10=H16
## ============================================================================
set_property -dict { PACKAGE_PIN D14  IOSTANDARD LVCMOS33 } [get_ports {cam_data[0]}]
set_property -dict { PACKAGE_PIN F16  IOSTANDARD LVCMOS33 } [get_ports {cam_data[1]}]
set_property -dict { PACKAGE_PIN G16  IOSTANDARD LVCMOS33 } [get_ports {cam_data[2]}]
set_property -dict { PACKAGE_PIN H14  IOSTANDARD LVCMOS33 } [get_ports {cam_data[3]}]
set_property -dict { PACKAGE_PIN E16  IOSTANDARD LVCMOS33 } [get_ports {cam_data[4]}]
set_property -dict { PACKAGE_PIN F13  IOSTANDARD LVCMOS33 } [get_ports {cam_data[5]}]
set_property -dict { PACKAGE_PIN G13  IOSTANDARD LVCMOS33 } [get_ports {cam_data[6]}]
set_property -dict { PACKAGE_PIN H16  IOSTANDARD LVCMOS33 } [get_ports {cam_data[7]}]

## ============================================================================
## Servo PWM Outputs (Pmod JC) - ACTIVE ONLY WHEN ARM IS CONNECTED
## Nexys 4 DDR Pmod JC pins:
##   Top row: JC1=K1, JC2=F6, JC3=J2, JC4=G6
## Comment these out if no robotic arm is connected
## ============================================================================
#set_property -dict { PACKAGE_PIN K1   IOSTANDARD LVCMOS33 } [get_ports servo_pwm_base]
#set_property -dict { PACKAGE_PIN F6   IOSTANDARD LVCMOS33 } [get_ports servo_pwm_shoulder]
#set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports servo_pwm_elbow]
#set_property -dict { PACKAGE_PIN G6   IOSTANDARD LVCMOS33 } [get_ports servo_pwm_gripper]

## ============================================================================
## Debug LEDs (from your schematic: LD0=H17, LD1=K15, LD2=J13, LD3=N14)
## ============================================================================
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports {led_finger_count[0]}]
set_property -dict { PACKAGE_PIN K15  IOSTANDARD LVCMOS33 } [get_ports {led_finger_count[1]}]
set_property -dict { PACKAGE_PIN J13  IOSTANDARD LVCMOS33 } [get_ports {led_finger_count[2]}]
set_property -dict { PACKAGE_PIN N14  IOSTANDARD LVCMOS33 } [get_ports led_hand_detect]

## ============================================================================
## Configuration options
## ============================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Bitstream settings
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
