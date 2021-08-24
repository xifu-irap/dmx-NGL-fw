-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-ngl-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   slaurent@nanoxplore.com
--!   @file                   pkg_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Model constants and components
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

package pkg_model is

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser constants
   -- ------------------------------------------------------------------------------------------------------
constant c_DIR_ROOT           : string  := "../project/dmx-NGL-fw/"                                         ; --! Directory root
constant c_DIR_CMD_FILE       : string  := c_DIR_ROOT & "simu/utest/"                                       ; --! Directory unitary test file
constant c_DIR_RES_FILE       : string  := c_DIR_ROOT & "simu/result/"                                      ; --! Directory result file
constant c_CMD_FILE_ROOT      : string  := "DRE_DMX_UT_"                                                    ; --! Command file root
constant c_CMD_FILE_SFX       : string  := ""                                                               ; --! Command file suffix
constant c_RES_FILE_SFX       : string  := "_res"                                                           ; --! Result file suffix

constant c_CMD_FILE_CMD_S     : integer := 4                                                                ; --! Command file: command size
constant c_CMD_FILE_FLD_DATA_S: integer := 64                                                               ; --! Command file: field data size (multiple of 16)
constant c_RES_FILE_DIV_BAR   : string  := "--------------------------------------------------"             ; --! Result file divider bar
constant c_SIG_NAME_STR_MAX_S : integer := 20                                                               ; --! Signal name string maximal size
constant c_CMD_NAME_STR_MAX_S : integer := 30                                                               ; --! Command name string maximal size

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser discrete input index
   -- ------------------------------------------------------------------------------------------------------
constant c_DR_D_RST           : integer :=  0                                                               ; --! Discrete input index, signal: i_d_rst
constant c_DR_CLK_REF         : integer :=  1                                                               ; --! Discrete input index, signal: i_clk_ref
constant c_DR_D_CLK           : integer :=  2                                                               ; --! Discrete input index, signal: i_d_clk
constant c_DR_D_CLK_SQ1_ADC   : integer :=  3                                                               ; --! Discrete input index, signal: i_d_clk_sq1_adc_acq
constant c_DR_D_CLK_SQ1_PLS_SH: integer :=  4                                                               ; --! Discrete input index, signal: i_d_clk_sq1_pls_shap
constant c_DR_EP_CMD_BUSY_N   : integer :=  5                                                               ; --! Discrete input index, signal: i_ep_cmd_busy_n
constant c_DR_EP_DATA_RX_RDY  : integer :=  6                                                               ; --! Discrete input index, signal: i_ep_data_rx_rdy
constant c_DR_D_RST_SQ1_ADC   : integer :=  7                                                               ; --! Discrete input index, signal: i_d_rst_sq1_adc
constant c_DR_D_RST_SQ1_PLS_SH: integer :=  8                                                               ; --! Discrete input index, signal: i_d_rst_sq1_pls_shap

constant c_DR_S               : integer :=  9                                                               ; --! Discrete input size

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser discrete output index
   -- ------------------------------------------------------------------------------------------------------
constant c_DW_ARST_N          : integer :=  0                                                               ; --! Discrete output index, signal: o_arst_n
constant c_DW_BRD_MODEL_0     : integer :=  1                                                               ; --! Discrete output index, signal: o_brd_model(0)
constant c_DW_BRD_MODEL_1     : integer :=  2                                                               ; --! Discrete output index, signal: o_brd_model(1)

constant c_DW_S               : integer :=  3                                                               ; --! Discrete output size

   -- ------------------------------------------------------------------------------------------------------
   --!   Model generic default values
   -- ------------------------------------------------------------------------------------------------------
constant c_SIM_TIME_DEF       : time    := 0 us                                                             ; --! Simulation time
constant c_TST_NUM_DEF        : string  := "XXXX"                                                           ; --! Test number

   -- ------------------------------------------------------------------------------------------------------
   --  c_CLK_REF_PER_DEF condition to respect:
   --    - c_CLK_REF_PER_DEF is chosen in order main pll period is a simulation time resolution multiple
   -- ------------------------------------------------------------------------------------------------------
constant c_CLK_REF_PER_DEF    : time    := (16668 ps /c_PLL_MAIN_VCO_MULT) * c_PLL_MAIN_VCO_MULT            ; --! Reference Clock period default value
constant c_SYNC_PER_DEF       : time    := 34 * 12 * c_CLK_REF_PER_DEF                                      ; --! Pixel sequence synchronization period default value
constant c_SYNC_SHIFT_DEF     : time    :=       1 * c_CLK_REF_PER_DEF                                      ; --! Pixel sequence synchronization shift default value

constant c_EP_CLK_PER_DEF     : time    := 20000 ps                                                         ; --! EP - System clock period default value
constant c_EP_CLK_PER_SHFT_DEF: time    := 3 ns                                                             ; --! EP - Clock period shift
constant c_EP_SCLK_L_DEF      : integer := 3                                                                ; --! EP - Number of clock period for elaborating SPI Serial Clock low  level
constant c_EP_SCLK_H_DEF      : integer := 1                                                                ; --! EP - Number of clock period for elaborating SPI Serial Clock high level

   -- ------------------------------------------------------------------------------------------------------
   --!   Model constants
   -- ------------------------------------------------------------------------------------------------------
constant c_SYNC_HIGH          : time    :=      10 * c_CLK_REF_PER_DEF                                      ; --! Pixel sequence synchronization high level time

   -- ------------------------------------------------------------------------------------------------------
   --!   Model components
   -- ------------------------------------------------------------------------------------------------------
   component clock_model is generic
   (     g_CLK_REF_PER        : time    := c_CLK_REF_PER_DEF                                                ; --! Reference Clock period
         g_SYNC_PER           : time    := c_SYNC_PER_DEF                                                   ; --! Pixel sequence synchronization period
         g_SYNC_SHIFT         : time    := c_SYNC_SHIFT_DEF                                                   --! Pixel sequence synchronization shift
   ); port
   (     o_clk_ref            : out    std_logic                                                            ; --! Reference Clock
         o_sync               : out    std_logic                                                              --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   );
   end component;

   component ep_spi_model is generic
   (     g_EP_CLK_PER         : time    := c_EP_CLK_PER_DEF                                                 ; --! EP - System clock period (ps)
         g_EP_CLK_PER_SHIFT   : time    := c_EP_CLK_PER_SHFT_DEF                                            ; --! EP - Clock period shift
         g_EP_N_CLK_PER_SCLK_L: integer := c_EP_SCLK_L_DEF                                                  ; --! EP - Number of clock period for elaborating SPI Serial Clock low  level
         g_EP_N_CLK_PER_SCLK_H: integer := c_EP_SCLK_H_DEF                                                    --! EP - Number of clock period for elaborating SPI Serial Clock high level
   ); port
   (     i_ep_cmd_ser_wd_s    : in     std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)               ; --! EP - Serial word size
         i_ep_cmd_start       : in     std_logic                                                            ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd             : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Command to send
         o_ep_cmd_busy_n      : out    std_logic                                                            ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)

         o_ep_data_rx         : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Receipted data
         o_ep_data_rx_rdy     : out    std_logic                                                            ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)

         o_ep_spi_mosi        : out    std_logic                                                            ; --! EP - SPI Master Input Slave Output (MSB first)
         i_ep_spi_miso        : in     std_logic                                                            ; --! EP - SPI Master Output Slave Input (MSB first)
         o_ep_spi_sclk        : out    std_logic                                                            ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’), period = 2*g_EP_CLK_PER
         o_ep_spi_cs_n        : out    std_logic                                                              --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)
   );
   end component;

   component parser is generic
   (     g_SIM_TIME           : time    := c_SIM_TIME_DEF                                                   ; --! Simulation time
         g_TST_NUM            : string  := c_TST_NUM_DEF                                                      --! Test number
   ); port
   (     o_arst_n             : out    std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_c0_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 0 - Data
         i_c1_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 1 - Data
         i_c2_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 2 - Data
         i_c3_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 3 - Data

         i_c0_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_adc      : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_pls_shap : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              : in     std_logic                                                            ; --! Internal design: System Clock
         i_d_clk_sq1_adc_acq  : in     std_logic                                                            ; --! Internal design: SQUID1 ADC acquisition Clock
         i_d_clk_sq1_pls_shap : in     std_logic                                                            ; --! Internal design: SQUID1 pulse shaping Clock

         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Receipted data
         i_ep_data_rx_rdy     : in     std_logic                                                            ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Command to send
         o_ep_cmd_start       : out    std_logic                                                            ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      : in     std_logic                                                            ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)               ; --! EP - Serial word size

         o_brd_ref            : out    std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         o_brd_model          : out    std_logic_vector(c_BRD_MODEL_S-1 downto 0)                             --! Board model
   );
   end component;

end pkg_model;
