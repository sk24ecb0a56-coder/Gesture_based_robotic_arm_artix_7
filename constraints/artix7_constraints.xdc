## Constraints file for Gesture-Based Robotic Arm on Artix-7 FPGA
## Target Board: Nexys A7-100T (or similar Artix-7 board)
## Clock and timing constraints

## System Clock (100 MHz)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk_100mhz }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk_100mhz }];

## Reset button (active low)
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { rst_n }];

##############################################################################
## Camera Interface Signals (OV7670 or similar on Pmod connectors)
##############################################################################

## Camera Pixel Clock
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { cam_pclk }];

## Camera Master Clock
set_property -dict { PACKAGE_PIN D3    IOSTANDARD LVCMOS33 } [get_ports { cam_xclk }];

## Camera Control Signals
set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33 } [get_ports { cam_href }];
set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33 } [get_ports { cam_vsync }];
set_property -dict { PACKAGE_PIN E2    IOSTANDARD LVCMOS33 } [get_ports { cam_reset }];
set_property -dict { PACKAGE_PIN D2    IOSTANDARD LVCMOS33 } [get_ports { cam_pwdn }];

## Camera Data Bus [7:0]
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports { cam_data[0] }];
set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { cam_data[1] }];
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { cam_data[2] }];
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { cam_data[3] }];
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { cam_data[4] }];
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports { cam_data[5] }];
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { cam_data[6] }];
set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { cam_data[7] }];

##############################################################################
## VGA Display Interface
##############################################################################

## VGA Horizontal and Vertical Sync
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { vga_hsync }];
set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33 } [get_ports { vga_vsync }];

## VGA Red [3:0]
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }];
set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }];
set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }];
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { vga_r[3] }];

## VGA Green [3:0]
set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }];
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }];
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }];
set_property -dict { PACKAGE_PIN A6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[3] }];

## VGA Blue [3:0]
set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }];
set_property -dict { PACKAGE_PIN C7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }];
set_property -dict { PACKAGE_PIN D7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }];
set_property -dict { PACKAGE_PIN D8    IOSTANDARD LVCMOS33 } [get_ports { vga_b[3] }];

##############################################################################
## Servo Control Outputs (4-axis robotic arm)
##############################################################################

## Servo PWM Signals
set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS33 } [get_ports { servo0_pwm }];
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { servo1_pwm }];
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { servo2_pwm }];
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { servo3_pwm }];

##############################################################################
## Status LEDs
##############################################################################

## Finger Count LEDs [3:0]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { led_finger_count[0] }];
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { led_finger_count[1] }];
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { led_finger_count[2] }];
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { led_finger_count[3] }];

## Frame Ready LED
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { led_frame_ready }];

##############################################################################
## Timing Constraints
##############################################################################

## Camera pixel clock (assume 24 MHz)
create_clock -period 41.667 -name cam_pclk [get_ports cam_pclk]

## VGA pixel clock (25 MHz)
create_generated_clock -name clk_25mhz -source [get_ports clk_100mhz] -divide_by 4 [get_pins {clk_div_reg[1]/Q}]

## Set false paths between clock domains
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks cam_pclk]
set_clock_groups -asynchronous -group [get_clocks clk_25mhz] -group [get_clocks cam_pclk]

##############################################################################
## Configuration
##############################################################################

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
