# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
#
#                            dmx-ngl-fw is free software: you can redistribute it and/or modify
#                            it under the terms of the GNU General Public License as published by
#                            the Free Software Foundation, either version 3 of the License, or
#                            (at your option) any later version.
#
#                            This program is distributed in the hope that it will be useful,
#                            but WITHOUT ANY WARRANTY; without even the implied warranty of
#                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                            GNU General Public License for more details.
#
#                            You should have received a copy of the GNU General Public License
#                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    email                   slaurent@nanoxplore.com
#    @file                   no_regression.do
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Modelsim script for no regression:
#                                * proc run_utest: run all the unitary tests
#                                * proc run_utest [CONF_FILE]: run the unitary test selected by the configuration file [CONF_FILE] and display chronograms
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#### Parameters ####
quietly set VARIANT "NG-LARGE"
quietly set NXMAP3_MODEL_PATH "../modelsim"
quietly set PR_DIR "../project/dmx-NGL-fw"

#### Directories ####
quietly set IP_DIR "${PR_DIR}/ip/nx/${VARIANT}"
quietly set SRC_DIR "${PR_DIR}/src"
quietly set TB_DIR "${PR_DIR}/simu/tb"
quietly set CFG_DIR "${PR_DIR}/simu/conf"

# Compile library linked to the FPGA technology
vlib nx
if {${VARIANT} == "NG-MEDIUM" || ${VARIANT} == "NG-MEDIUM-EMBEDDED"} {
    vcom -work nx -2008 "${NXMAP3_MODEL_PATH}/nxLibrary-Medium.vhdp"
} elseif { $VARIANT == "NG-LARGE" || ${VARIANT} == "NG-LARGE-EMBEDDED"} {
    vcom -work nx -2008 "${NXMAP3_MODEL_PATH}/nxLibrary-Large.vhdp"
} elseif { $VARIANT == "NG-ULTRA" || ${VARIANT} == "NG-ULTRA-EMBEDDED"} {
    vcom -work nx -2008 "${NXMAP3_MODEL_PATH}/nxLibrary-Ultra.vhdp"
} else {
    puts "Unrecognized Variant"}

#### Run unitary test(s)
proc run_utest {args} {
   global IP_DIR
   global SRC_DIR
   global TB_DIR
   global CFG_DIR

   # Compile all packages
   vlib work
   vcom -work work -just pb -93 "${IP_DIR}/*.vhd"
   vcom -work work -just pb -93 "${SRC_DIR}/pkg_func_math.vhd"
   vcom -work work -just pb -93 "${SRC_DIR}/pkg_project.vhd"
   vcom -work work -just pb -93 "${SRC_DIR}/*.vhd"

   # Compile all entities/architectures
   vcom -work work -just ea -93 "${IP_DIR}/*.vhd"
   vcom -work work -just ea -93 "${SRC_DIR}/spi_slave.vhd"
   vcom -work work -just ea -93 "${SRC_DIR}/sts_err_add_mgt.vhd"
   vcom -work work -just ea -93 "${SRC_DIR}/sts_err_wrt_mgt.vhd"
   vcom -work work -just ea -93 "${SRC_DIR}/*.vhd"

   # Compile all testbenches/models
   vcom -work work -just pb -2008 "${TB_DIR}/*.vhd"
   vcom -work work -just ea -2008 "${TB_DIR}/*.vhd"

   # Test the argument number
   if {[llength $args] == 0} {

      # In the case of no argument, compile all configuration files
      vcom -work work -2008 "${CFG_DIR}/*.vhd"

      foreach file [lsort -dictionary [glob -directory ${CFG_DIR} *.vhd]] {

         # Extract the simulation time from the selected configuration file
         set file_sel [open $file]
         while {[gets $file_sel line] != -1} {
            if {[regexp {g_SIM_TIME\s+=>\s+(\d*?\d*.\d*\s+(sec|ms|us|ns|ps))} $line l sim_time]} {
               break
            }
         }

         close $file_sel

         # Run simulation
         vsim -t ps -lib work work.[file rootname [file tail $file]]
         run $sim_time
         quit -sim
      }

   } else {

      # In the case of arguments, compile the mentioned configuration files
      foreach cfg_file $args {

         vcom -work work -2008 "${CFG_DIR}/${cfg_file}.vhd"

         # Extract the simulation time from the selected configuration file
         set file_sel [open "${CFG_DIR}/${cfg_file}.vhd"]
         while {[gets $file_sel line] != -1} {
            if {[regexp {g_SIM_TIME\s+=>\s+(\d*?\d*.\d*\s+(sec|ms|us|ns|ps))} $line l sim_time]} {
               break
            }
         }

         close $file_sel

         vsim -t ps -lib work work.${cfg_file}

         # Display signals
         add wave -noupdate -divider "Reset & general clocks"
         add wave -format Logic                    -group "Inputs"                              sim:/top_dmx_tb/I_top_dmx/i_arst_n
         add wave -format Logic                    -group "Inputs"                              sim:/top_dmx_tb/I_top_dmx/i_clk_ref
         add wave -format Logic                                                                 sim:/top_dmx_tb/I_top_dmx/rst
         add wave -format Logic                                                                 sim:/top_dmx_tb/I_top_dmx/clk
         add wave -format Logic                                                                 sim:/top_dmx_tb/I_top_dmx/clk_sq1_adc
         add wave -format Logic                                                                 sim:/top_dmx_tb/I_top_dmx/clk_sq1_pls_shape
         add wave -format Logic                                                                 sim:/top_dmx_tb/I_top_dmx/i_sync

         add wave -noupdate -divider "Squid1 Channel 0"
         add wave -format Logic                    -group "ADC - Channel 0"                     sim:/top_dmx_tb/I_top_dmx/o_c0_clk_sq1_adc
         add wave -format Logic -Radix unsigned    -group "ADC - Channel 0"                     sim:/top_dmx_tb/I_top_dmx/i_c0_sq1_adc_data
         add wave -format Logic                    -group "ADC - Channel 0"                     sim:/top_dmx_tb/I_top_dmx/i_c0_sq1_adc_oor

         add wave -format Logic                    -group "ADC - Channel 0" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/b_c0_sq1_adc_spi_sdio
         add wave -format Logic                    -group "ADC - Channel 0" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c0_sq1_adc_spi_sclk
         add wave -format Logic                    -group "ADC - Channel 0" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c0_sq1_adc_spi_cs_n

         add wave -format Logic                    -group "DAC - Channel 0"                     sim:/top_dmx_tb/I_top_dmx/o_c0_clk_sq1_dac
         add wave -format Logic -Radix unsigned    -group "DAC - Channel 0"                     sim:/top_dmx_tb/I_top_dmx/o_c0_sq1_dac_data
         add wave -format Logic                    -group "DAC - Channel 0"                     sim:/top_dmx_tb/I_top_dmx/o_c0_sq1_dac_sleep

         add wave -noupdate -divider "Squid1 Channel 1"
         add wave -format Logic                    -group "ADC - Channel 1"                     sim:/top_dmx_tb/I_top_dmx/o_c1_clk_sq1_adc
         add wave -format Logic -Radix unsigned    -group "ADC - Channel 1"                     sim:/top_dmx_tb/I_top_dmx/i_c1_sq1_adc_data
         add wave -format Logic                    -group "ADC - Channel 1"                     sim:/top_dmx_tb/I_top_dmx/i_c1_sq1_adc_oor

         add wave -format Logic                    -group "ADC - Channel 1" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/b_c1_sq1_adc_spi_sdio
         add wave -format Logic                    -group "ADC - Channel 1" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c1_sq1_adc_spi_sclk
         add wave -format Logic                    -group "ADC - Channel 1" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c1_sq1_adc_spi_cs_n

         add wave -format Logic                    -group "DAC - Channel 1"                     sim:/top_dmx_tb/I_top_dmx/o_c1_clk_sq1_dac
         add wave -format Logic -Radix unsigned    -group "DAC - Channel 1"                     sim:/top_dmx_tb/I_top_dmx/o_c1_sq1_dac_data
         add wave -format Logic                    -group "DAC - Channel 1"                     sim:/top_dmx_tb/I_top_dmx/o_c1_sq1_dac_sleep

         add wave -noupdate -divider "Squid1 Channel 2"
         add wave -format Logic                    -group "ADC - Channel 2"                     sim:/top_dmx_tb/I_top_dmx/o_c2_clk_sq1_adc
         add wave -format Logic -Radix unsigned    -group "ADC - Channel 2"                     sim:/top_dmx_tb/I_top_dmx/i_c2_sq1_adc_data
         add wave -format Logic                    -group "ADC - Channel 2"                     sim:/top_dmx_tb/I_top_dmx/i_c2_sq1_adc_oor

         add wave -format Logic                    -group "ADC - Channel 2" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/b_c2_sq1_adc_spi_sdio
         add wave -format Logic                    -group "ADC - Channel 2" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c2_sq1_adc_spi_sclk
         add wave -format Logic                    -group "ADC - Channel 2" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c2_sq1_adc_spi_cs_n

         add wave -format Logic                    -group "DAC - Channel 2"                     sim:/top_dmx_tb/I_top_dmx/o_c2_clk_sq1_dac
         add wave -format Logic -Radix unsigned    -group "DAC - Channel 2"                     sim:/top_dmx_tb/I_top_dmx/o_c2_sq1_dac_data
         add wave -format Logic                    -group "DAC - Channel 2"                     sim:/top_dmx_tb/I_top_dmx/o_c2_sq1_dac_sleep

         add wave -noupdate -divider "Squid1 Channel 3"
         add wave -format Logic                    -group "ADC - Channel 3"                     sim:/top_dmx_tb/I_top_dmx/o_c3_clk_sq1_adc
         add wave -format Logic -Radix unsigned    -group "ADC - Channel 3"                     sim:/top_dmx_tb/I_top_dmx/i_c3_sq1_adc_data
         add wave -format Logic                    -group "ADC - Channel 3"                     sim:/top_dmx_tb/I_top_dmx/i_c3_sq1_adc_oor

         add wave -format Logic                    -group "ADC - Channel 3" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/b_c3_sq1_adc_spi_sdio
         add wave -format Logic                    -group "ADC - Channel 3" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c3_sq1_adc_spi_sclk
         add wave -format Logic                    -group "ADC - Channel 3" -group "SPI"        sim:/top_dmx_tb/I_top_dmx/o_c3_sq1_adc_spi_cs_n

         add wave -format Logic                    -group "DAC - Channel 3"                     sim:/top_dmx_tb/I_top_dmx/o_c3_clk_sq1_dac
         add wave -format Logic -Radix unsigned    -group "DAC - Channel 3"                     sim:/top_dmx_tb/I_top_dmx/o_c3_sq1_dac_data
         add wave -format Logic                    -group "DAC - Channel 3"                     sim:/top_dmx_tb/I_top_dmx/o_c3_sq1_dac_sleep

         add wave -noupdate -divider
         add wave -format Logic                    -group "Science"                             sim:/top_dmx_tb/I_top_dmx/o_clk_science
         add wave -format Logic                    -group "Science"                             sim:/top_dmx_tb/I_top_dmx/o_science_ctrl
         add wave -format Logic                    -group "Science"                             sim:/top_dmx_tb/I_top_dmx/o_c0_science_data
         add wave -format Logic                    -group "Science"                             sim:/top_dmx_tb/I_top_dmx/o_c1_science_data
         add wave -format Logic                    -group "Science"                             sim:/top_dmx_tb/I_top_dmx/o_c2_science_data
         add wave -format Logic                    -group "Science"                             sim:/top_dmx_tb/I_top_dmx/o_c3_science_data

         add wave -format Logic -Radix unsigned    -group "Command"                             sim:/top_dmx_tb/ep_cmd_ser_wd_s
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim:/top_dmx_tb/ep_cmd
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/ep_cmd_start
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/ep_cmd_busy_n
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim:/top_dmx_tb/ep_data_rx
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/ep_data_rx_rdy
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/I_top_dmx/i_ep_spi_mosi
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/I_top_dmx/o_ep_spi_miso
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/I_top_dmx/i_ep_spi_sclk
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/I_top_dmx/i_ep_spi_cs_n
#TODO
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim:/top_dmx_tb/I_top_dmx/ep_cmd_sts_rg

         add wave -format Logic -Radix hexadecimal -group "Command"                             sim:/top_dmx_tb/I_top_dmx/ep_cmd_rx_wd_add
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim:/top_dmx_tb/I_top_dmx/ep_cmd_rx_wd_data
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/I_top_dmx/ep_cmd_rx_rw
         add wave -format Logic                    -group "Command"                             sim:/top_dmx_tb/I_top_dmx/ep_cmd_rx_noerr_rdy

         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/i_hk1_spi_miso
         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/o_hk1_spi_mosi
         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/o_hk1_spi_sclk
         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/o_hk1_spi_cs_n

         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/i_hk2_spi_miso
         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/o_hk2_spi_mosi
         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/o_hk2_spi_sclk
         add wave -format Logic                    -group "HouseKeeping"                        sim:/top_dmx_tb/I_top_dmx/o_hk2_spi_cs_n

         # Display adjustment
         configure wave -namecolwidth 220
         configure wave -valuecolwidth 30
         configure wave -justifyvalue left
         configure wave -signalnamewidth 1
         configure wave -snapdistance 10
         configure wave -datasetprefix 0
         configure wave -rowmargin 4
         configure wave -childrowmargin 2
         configure wave -gridoffset 0
         configure wave -gridperiod 1000
         configure wave -griddelta 40
         configure wave -timeline 0
         configure wave -timelineunits ns
         update

         # Run simulation
         run $sim_time
      }
   }
}