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
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

library std;
use std.textio.all;

package pkg_model is

   -- ------------------------------------------------------------------------------------------------------
   --    Model types
   -- ------------------------------------------------------------------------------------------------------
type     t_real_arr             is array (natural range <>) of real                                         ; --! Real array type
type     t_time_arr             is array (natural range <>) of time                                         ; --! Time array type
type     t_time_arr_tab         is array (natural range <>) of t_time_arr                                   ; --! Time array table type
type     t_line_arr             is array (natural range <>) of line                                         ; --! Line array type

type     t_clk_chk_prm is record
         clk_name             : string                                                                      ; --! Clock signal name
         clk_per_l            : time                                                                        ; --! Low  level clock period expected time
         clk_per_h            : time                                                                        ; --! High level clock period expected time
         clk_st_ena           : std_logic                                                                   ; --! Clock state value when enable goes to active
         clk_st_dis           : std_logic                                                                   ; --! Clock state value when enable goes to inactive
         chk_osc_en           : std_logic                                                                   ; --! Check oscillation on clock when enable inactive ('0' = No, '1' = Yes)
end record t_clk_chk_prm                                                                                    ; --! Clock check parameters type

type     t_clk_chk_prm_arr      is array (natural range <>) of t_clk_chk_prm                                ; --! Clock check parameters array type

type     t_spi_chk_prm is record
         spi_name             : string                                                                      ; --! SPI bus name
         spi_cpol             : std_logic                                                                   ; --! SPI CPOL
         spi_time             : t_time_arr                                                                  ; --! SPI time parameter
end record t_spi_chk_prm                                                                                    ; --! SPI check parameters type

type     t_spi_chk_prm_arr      is array (natural range <>) of t_spi_chk_prm                                ; --! SPI check parameters array type

constant c_SPI_ERR_POS_TL     : integer := 0                                                                ; --! SPI error number position: minimum SCLK low time
constant c_SPI_ERR_POS_TH     : integer := 1                                                                ; --! SPI error number position: minimum SCLK high time
constant c_SPI_ERR_POS_TSCMIN : integer := 2                                                                ; --! SPI error number position: minimum SCLK period
constant c_SPI_ERR_POS_TSCMAX : integer := 3                                                                ; --! SPI error number position: maximum SCLK period
constant c_SPI_ERR_POS_TCSH   : integer := 4                                                                ; --! SPI error number position: minimum CS high time
constant c_SPI_ERR_POS_TS2CSR : integer := 5                                                                ; --! SPI error number position: minimum not(SCLK) to CS rising edge time
constant c_SPI_ERR_POS_TD2S   : integer := 6                                                                ; --! SPI error number position: minimum Data Event to not(SCLK) time
constant c_SPI_ERR_POS_TS2D   : integer := 7                                                                ; --! SPI error number position: minimum not(SCLK) to Data Event time
constant c_SPI_ERR_POS_STSCA  : integer := 8                                                                ; --! SPI error number position: SCLK state error when CS goes to active
constant c_SPI_ERR_POS_STSCI  : integer := 9                                                                ; --! SPI error number position: SCLK state error when CS goes to inactive

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser constants
   -- ------------------------------------------------------------------------------------------------------
constant c_DIR_ROOT           : string  := "../project/dmx-NGL-fw/"                                         ; --! Directory root
constant c_DIR_CMD_FILE       : string  := c_DIR_ROOT & "simu/utest/"                                       ; --! Directory unitary test file
constant c_DIR_RES_FILE       : string  := c_DIR_ROOT & "simu/result/"                                      ; --! Directory result file
constant c_CMD_FILE_ROOT      : string  := "DRE_DMX_UT_"                                                    ; --! Command file root
constant c_CMD_FILE_SFX       : string  := ""                                                               ; --! Command file suffix
constant c_RES_FILE_SFX       : string  := "_res"                                                           ; --! Result file suffix
constant c_SCD_FILE_SFX       : string  := "_scd"                                                           ; --! Science data result file suffix

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
constant c_DR_D_RST_SQ1_ADC_0 : integer :=  7                                                               ; --! Discrete input index, signal: i_d_rst_sq1_adc(0)
constant c_DR_D_RST_SQ1_ADC_1 : integer :=  8                                                               ; --! Discrete input index, signal: i_d_rst_sq1_adc(1)
constant c_DR_D_RST_SQ1_ADC_2 : integer :=  9                                                               ; --! Discrete input index, signal: i_d_rst_sq1_adc(2)
constant c_DR_D_RST_SQ1_ADC_3 : integer :=  10                                                              ; --! Discrete input index, signal: i_d_rst_sq1_adc(3)
constant c_DR_D_RST_SQ1_DAC_0 : integer :=  11                                                              ; --! Discrete input index, signal: i_d_rst_sq1_dac(0)
constant c_DR_D_RST_SQ1_DAC_1 : integer :=  12                                                              ; --! Discrete input index, signal: i_d_rst_sq1_dac(1)
constant c_DR_D_RST_SQ1_DAC_2 : integer :=  13                                                              ; --! Discrete input index, signal: i_d_rst_sq1_dac(2)
constant c_DR_D_RST_SQ1_DAC_3 : integer :=  14                                                              ; --! Discrete input index, signal: i_d_rst_sq1_dac(3)
constant c_DR_D_RST_SQ2_MUX_0 : integer :=  15                                                              ; --! Discrete input index, signal: i_d_rst_sq2_mux(0)
constant c_DR_D_RST_SQ2_MUX_1 : integer :=  16                                                              ; --! Discrete input index, signal: i_d_rst_sq2_mux(1)
constant c_DR_D_RST_SQ2_MUX_2 : integer :=  17                                                              ; --! Discrete input index, signal: i_d_rst_sq2_mux(2)
constant c_DR_D_RST_SQ2_MUX_3 : integer :=  18                                                              ; --! Discrete input index, signal: i_d_rst_sq2_mux(3)
constant c_DR_SYNC            : integer :=  19                                                              ; --! Discrete input index, signal: i_sync
constant c_DR_SQ1_ADC_PWDN_0  : integer :=  20                                                              ; --! Discrete input index, signal: i_c0_sq1_adc_pwdn
constant c_DR_SQ1_ADC_PWDN_1  : integer :=  21                                                              ; --! Discrete input index, signal: i_c1_sq1_adc_pwdn
constant c_DR_SQ1_ADC_PWDN_2  : integer :=  22                                                              ; --! Discrete input index, signal: i_c2_sq1_adc_pwdn
constant c_DR_SQ1_ADC_PWDN_3  : integer :=  23                                                              ; --! Discrete input index, signal: i_c3_sq1_adc_pwdn
constant c_DR_SQ1_DAC_SLEEP_0 : integer :=  24                                                              ; --! Discrete input index, signal: i_c0_sq1_dac_sleep
constant c_DR_SQ1_DAC_SLEEP_1 : integer :=  25                                                              ; --! Discrete input index, signal: i_c1_sq1_dac_sleep
constant c_DR_SQ1_DAC_SLEEP_2 : integer :=  26                                                              ; --! Discrete input index, signal: i_c2_sq1_dac_sleep
constant c_DR_SQ1_DAC_SLEEP_3 : integer :=  27                                                              ; --! Discrete input index, signal: i_c3_sq1_dac_sleep
constant c_DR_CLK_SQ1_ADC_0   : integer :=  28                                                              ; --! Discrete input index, signal: i_c0_clk_sq1_adc
constant c_DR_CLK_SQ1_ADC_1   : integer :=  29                                                              ; --! Discrete input index, signal: i_c1_clk_sq1_adc
constant c_DR_CLK_SQ1_ADC_2   : integer :=  30                                                              ; --! Discrete input index, signal: i_c2_clk_sq1_adc
constant c_DR_CLK_SQ1_ADC_3   : integer :=  31                                                              ; --! Discrete input index, signal: i_c3_clk_sq1_adc
constant c_DR_CLK_SQ1_DAC_0   : integer :=  32                                                              ; --! Discrete input index, signal: i_c0_clk_sq1_dac
constant c_DR_CLK_SQ1_DAC_1   : integer :=  33                                                              ; --! Discrete input index, signal: i_c1_clk_sq1_dac
constant c_DR_CLK_SQ1_DAC_2   : integer :=  34                                                              ; --! Discrete input index, signal: i_c2_clk_sq1_dac
constant c_DR_CLK_SQ1_DAC_3   : integer :=  35                                                              ; --! Discrete input index, signal: i_c3_clk_sq1_dac

constant c_DR_S               : integer :=  36                                                              ; --! Discrete input size

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser discrete output index
   -- ------------------------------------------------------------------------------------------------------
constant c_DW_ARST_N          : integer :=  0                                                               ; --! Discrete output index, signal: o_arst_n
constant c_DW_BRD_MODEL_0     : integer :=  1                                                               ; --! Discrete output index, signal: o_brd_model(0)
constant c_DW_BRD_MODEL_1     : integer :=  2                                                               ; --! Discrete output index, signal: o_brd_model(1)
constant c_DW_SW_ADC_VIN_0    : integer :=  3                                                               ; --! Discrete output index, signal: o_sw_adc_vin(0)
constant c_DW_SW_ADC_VIN_1    : integer :=  4                                                               ; --! Discrete output index, signal: o_sw_adc_vin(1)

constant c_DW_S               : integer :=  5                                                               ; --! Discrete output size

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser check clock parameters enable
   -- ------------------------------------------------------------------------------------------------------
constant c_CHK_ENA_CLK_NB     : integer :=  13                                                              ; --! Clock check enable number

constant c_CE_CLK             : integer :=  0                                                               ; --! Clock enable report index, signal: i_err_chk_clk        (d_clk report)
constant c_CE_CK1_ADC         : integer :=  1                                                               ; --! Clock enable report index, signal: i_err_chk_ck1_adc    (d_clk_sq1_adc_acq report)
constant c_CE_CK1_PLS         : integer :=  2                                                               ; --! Clock enable report index, signal: i_err_chk_ck1_pls    (d_clk_sq1_pls_shap report)
constant c_CE_C0_CK1_ADC      : integer :=  3                                                               ; --! Clock enable report index, signal: i_err_chk_c0_ck1_adc (c0_clk_sq1_adc report)
constant c_CE_C1_CK1_ADC      : integer :=  4                                                               ; --! Clock enable report index, signal: i_err_chk_c1_ck1_adc (c1_clk_sq1_adc report)
constant c_CE_C2_CK1_ADC      : integer :=  5                                                               ; --! Clock enable report index, signal: i_err_chk_c2_ck1_adc (c2_clk_sq1_adc report)
constant c_CE_C3_CK1_ADC      : integer :=  6                                                               ; --! Clock enable report index, signal: i_err_chk_c3_ck1_adc (c3_clk_sq1_adc report)
constant c_CE_C0_CK1_DAC      : integer :=  7                                                               ; --! Clock enable report index, signal: i_err_chk_c0_ck1_dac (c0_clk_sq1_dac report)
constant c_CE_C1_CK1_DAC      : integer :=  8                                                               ; --! Clock enable report index, signal: i_err_chk_c1_ck1_dac (c1_clk_sq1_dac report)
constant c_CE_C2_CK1_DAC      : integer :=  9                                                               ; --! Clock enable report index, signal: i_err_chk_c2_ck1_dac (c2_clk_sq1_dac report)
constant c_CE_C3_CK1_DAC      : integer :=  10                                                              ; --! Clock enable report index, signal: i_err_chk_c3_ck1_dac (c3_clk_sq1_dac report)
constant c_CE_CLK_SC_01       : integer :=  11                                                              ; --! Clock enable report index, signal: i_err_chk_clk_sc_01  (clk_science_01 report)
constant c_CE_CLK_SC_23       : integer :=  12                                                              ; --! Clock enable report index, signal: i_err_chk_clk_sc_23  (clk_science_23 report)

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser check SPI parameters enable
   -- ------------------------------------------------------------------------------------------------------
constant c_CHK_ENA_SPI_NB     : integer :=   9                                                              ; --! SPI bus check enable number

constant c_SPIE_HK            : integer :=  13                                                              ; --! SPI enable report index, ADC HK
constant c_SPIE_C0_SQ2_LSB    : integer :=  14                                                              ; --! SPI enable report index, SQUID2 DAC LSB column 0
constant c_SPIE_C1_SQ2_LSB    : integer :=  15                                                              ; --! SPI enable report index, SQUID2 DAC LSB column 1
constant c_SPIE_C2_SQ2_LSB    : integer :=  16                                                              ; --! SPI enable report index, SQUID2 DAC LSB column 2
constant c_SPIE_C3_SQ2_LSB    : integer :=  17                                                              ; --! SPI enable report index, SQUID2 DAC LSB column 3
constant c_SPIE_C0_SQ2_OFF    : integer :=  18                                                              ; --! SPI enable report index, SQUID2 DAC Offset column 0
constant c_SPIE_C1_SQ2_OFF    : integer :=  19                                                              ; --! SPI enable report index, SQUID2 DAC Offset column 1
constant c_SPIE_C2_SQ2_OFF    : integer :=  20                                                              ; --! SPI enable report index, SQUID2 DAC Offset column 2
constant c_SPIE_C3_SQ2_OFF    : integer :=  21                                                              ; --! SPI enable report index, SQUID2 DAC Offset column 3

constant c_E_PLS_SHP          : integer :=  22                                                              ; --! Enable report index, pulse shaping error number

constant c_CE_S               : integer :=  23                                                              ; --! Enable report size

   -- ------------------------------------------------------------------------------------------------------
   --!   Model generic default values
   -- ------------------------------------------------------------------------------------------------------
constant c_SIM_TIME_DEF       : time    := 0 us                                                             ; --! Simulation time
constant c_TST_NUM_DEF        : string  := "XXXX"                                                           ; --! Test number

   -- ------------------------------------------------------------------------------------------------------
   --  c_CLK_REF_PER_DEF condition to respect:
   --    - c_CLK_REF_PER_DEF is chosen in order main pll period is a simulation time resolution multiple
   -- ------------------------------------------------------------------------------------------------------
constant c_CLK_REF_PER_DEF    : time    := (16008 ps /c_PLL_MAIN_VCO_MULT) * c_PLL_MAIN_VCO_MULT            ; --! Reference Clock period default value
constant c_SYNC_PER_DEF       : time    := c_MUX_FACT * c_PIXEL_ADC_NB_CYC *
                                             c_CLK_REF_MULT / c_CLK_ADC_DAC_MULT * c_CLK_REF_PER_DEF        ; --! Pixel sequence synchronization period default value
constant c_SYNC_SHIFT_DEF     : time    :=  1 * c_CLK_REF_PER_DEF                                           ; --! Pixel sequence synchronization shift default value

constant c_EP_CLK_PER_DEF     : time    := 18000 ps                                                         ; --! EP - System clock period default value
constant c_EP_CLK_PER_SHFT_DEF: time    := 3 ns                                                             ; --! EP - Clock period shift default value
constant c_EP_SCLK_L_DEF      : integer := 12                                                               ; --! EP - Number of clock period for elaborating SPI Serial Clock low  level default value
constant c_EP_SCLK_H_DEF      : integer := 1                                                                ; --! EP - Number of clock period for elaborating SPI Serial Clock high level default value
constant c_EP_BUF_DEL_DEF     : time    := 80 ns                                                            ; --! EP - Delay introduced by buffer

constant c_CLK_ADC_PER_DEF    : time    := c_CLK_REF_PER_DEF / c_CLK_ADC_DAC_MULT                           ; --! SQUID1 ADC - Clock period default value
constant c_TIM_ADC_TPD_DEF    : time    :=  3900 ps                                                         ; --! SQUID1 ADC - Time, Data Propagation Delay default value
constant c_SQ1_ADC_VREF_DEF   : real    := 1.0                                                              ; --! SQUID1 ADC - Voltage reference (Volt) default value
constant c_SQ1_DAC_VREF_DEF   : real    := 1.0                                                              ; --! SQUID1 DAC - Voltage reference (Volt) default value
constant c_SQ2_DAC_VREF_DEF   : real    := 1.0                                                              ; --! SQUID2 DAC - Voltage reference (Volt) default value
constant c_SQ2_DAC_TS_DEF     : time    := 12 us                                                            ; --! SQUID2 DAC - Output Voltage Settling time default value
constant c_SQ2_MUX_TPLH_DEF   : time    :=  4 ns                                                            ; --! SQUID2 MUX - Propagation delay switch in to out default value

constant c_PLS_SP_CHK_ENA_DEF : std_logic := '0'                                                            ; --! Pulse shaping check enable default value ('0' = Disable, '1' = Enable)

   -- ------------------------------------------------------------------------------------------------------
   --!   Model constants
   -- ------------------------------------------------------------------------------------------------------
constant c_CHK_OSC_DIS        : std_logic :=  '0'                                                           ; --! Check oscillation on clock when enable inactive: disable value
constant c_CHK_OSC_ENA        : std_logic :=  not(c_CHK_OSC_DIS)                                            ; --! Check oscillation on clock when enable inactive: enable  value
constant c_ERR_N_CLK_CHK_S    : integer   :=  5                                                             ; --! Clock check error number array size
constant c_SPI_ERR_CHK_NB     : integer   := 10                                                             ; --! SPI error check number

constant c_CLK_HPER           : time    := c_CLK_REF_PER_DEF/(2 * c_CLK_MULT)                               ; --! System Clock half-period timing
constant c_CLK_ADC_HPER       : time    := c_CLK_REF_PER_DEF/(2 * c_CLK_ADC_DAC_MULT)                       ; --! ADC Clock half-period timing
constant c_CLK_DAC_HPER       : time    := c_CLK_REF_PER_DEF/(2 * c_CLK_ADC_DAC_MULT)                       ; --! DAC Clock half-period timing
constant c_CLK_SC_HPER        : time    := c_CLK_REF_PER_DEF/(2 * c_CLK_MULT)                               ; --! Science Data Clock half-period timing

constant c_CLK_ST             : std_logic := '1'                                                            ; --! System Clock state value when the enable signal goes to active
constant c_CLK_ADC_ST         : std_logic := '1'                                                            ; --! ADC acquisition Clock state value when the enable signal goes to active
constant c_CLK_DAC_ST         : std_logic := '1'                                                            ; --! Pulse shaping Clock state value when the enable signal goes to active
constant c_CLK_CX_ADC_ST      : std_logic := '0'                                                            ; --! ADC, col. X Clock state value when the enable signal goes to active
constant c_CLK_CX_DAC_ST      : std_logic := '0'                                                            ; --! DAC, col. X Clock state value when the enable signal goes to active
constant c_CLK_SC_ST          : std_logic := '0'                                                            ; --! Science Data Clock state value when the enable signal goes to active

constant c_CLK_ST_DIS         : std_logic := not(c_CLK_ST)                                                  ; --! System Clock state value when the enable signal goes to inactive
constant c_CLK_ADC_ST_DIS     : std_logic := not(c_CLK_ADC_ST)                                              ; --! ADC acquisition Clock state value when the enable signal goes to inactive
constant c_CLK_DAC_ST_DIS     : std_logic := not(c_CLK_DAC_ST)                                              ; --! Pulse shaping Clock state value when the enable signal goes to inactive
constant c_CLK_CX_ADC_ST_DIS  : std_logic := '0'                                                            ; --! ADC, col. X Clock state value when the enable signal goes to inactive
constant c_CLK_CX_DAC_ST_DIS  : std_logic := '0'                                                            ; --! DAC, col. X Clock state value when the enable signal goes to inactive
constant c_CLK_SC_ST_DIS      : std_logic := '0'                                                            ; --! Science Data Clock state value when the enable signal goes to inactive

constant c_SYNC_HIGH          : time    :=  10 * c_CLK_REF_PER_DEF                                          ; --! Pixel sequence synchronization high level time

constant c_SW_ADC_VIN_S       : integer :=  2                                                               ; --! Switch ADC voltage input bus size
constant c_SW_ADC_VIN_ST_SQ1  : std_logic_vector(c_SW_ADC_VIN_S-1 downto 0) := "00"                         ; --! Switch ADC voltage input: SQUID1 voltage state
constant c_SW_ADC_VIN_ST_SQ2  : std_logic_vector(c_SW_ADC_VIN_S-1 downto 0) := "01"                         ; --! Switch ADC voltage input: SQUID2 voltage state

   -- ------------------------------------------------------------------------------------------------------
   --    Clock parameters to check
   -- ------------------------------------------------------------------------------------------------------
constant c_CCHK               : t_clk_chk_prm_arr(0 to c_CHK_ENA_CLK_NB-1) :=
                                (("clk              " , c_CLK_HPER,     c_CLK_HPER,     c_CLK_ST,        c_CLK_ST_DIS,        c_CHK_OSC_DIS),
                                 ("clk_sq1_adc      " , c_CLK_ADC_HPER, c_CLK_ADC_HPER, c_CLK_ADC_ST,    c_CLK_ADC_ST_DIS,    c_CHK_OSC_DIS),
                                 ("clk_sq1_pls_shape" , c_CLK_DAC_HPER, c_CLK_DAC_HPER, c_CLK_DAC_ST,    c_CLK_DAC_ST_DIS,    c_CHK_OSC_DIS),
                                 ("c0_clk_sq1_adc   " , c_CLK_ADC_HPER, c_CLK_ADC_HPER, c_CLK_CX_ADC_ST, c_CLK_CX_ADC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c1_clk_sq1_adc   " , c_CLK_ADC_HPER, c_CLK_ADC_HPER, c_CLK_CX_ADC_ST, c_CLK_CX_ADC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c2_clk_sq1_adc   " , c_CLK_ADC_HPER, c_CLK_ADC_HPER, c_CLK_CX_ADC_ST, c_CLK_CX_ADC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c3_clk_sq1_adc   " , c_CLK_ADC_HPER, c_CLK_ADC_HPER, c_CLK_CX_ADC_ST, c_CLK_CX_ADC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c0_clk_sq1_dac   " , c_CLK_DAC_HPER, c_CLK_DAC_HPER, c_CLK_CX_DAC_ST, c_CLK_CX_DAC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c1_clk_sq1_dac   " , c_CLK_DAC_HPER, c_CLK_DAC_HPER, c_CLK_CX_DAC_ST, c_CLK_CX_DAC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c2_clk_sq1_dac   " , c_CLK_DAC_HPER, c_CLK_DAC_HPER, c_CLK_CX_DAC_ST, c_CLK_CX_DAC_ST_DIS, c_CHK_OSC_ENA),
                                 ("c3_clk_sq1_dac   " , c_CLK_DAC_HPER, c_CLK_DAC_HPER, c_CLK_CX_DAC_ST, c_CLK_CX_DAC_ST_DIS, c_CHK_OSC_ENA),
                                 ("clk_science_01   " , c_CLK_SC_HPER,  c_CLK_SC_HPER,  c_CLK_SC_ST,     c_CLK_SC_ST_DIS,     c_CHK_OSC_ENA),
                                 ("clk_science_23   " , c_CLK_SC_HPER,  c_CLK_SC_HPER,  c_CLK_SC_ST,     c_CLK_SC_ST_DIS,     c_CHK_OSC_ENA));

   -- ------------------------------------------------------------------------------------------------------
   --    SPI parameters to check
   -- ------------------------------------------------------------------------------------------------------
constant c_SPI_TIME_CHK_HK    : t_time_arr(0 to c_SPI_ERR_CHK_NB-3) :=
                                (25600 ps, 25600 ps, 62500 ps, 125000 ps, 0 ps,    0 ps, 10000 ps, 10000 ps); --! SPI timings to check: ADC HK ADC128S102

constant c_SPI_TIME_CHK_SQ2   : t_time_arr(0 to c_SPI_ERR_CHK_NB-3) :=
                                (13000 ps, 13000 ps, 33000 ps, 999999 ps, 20000 ps, 1000 ps,5000 ps,4500 ps); --! SPI timings to check: DAC SQUID2 DAC121S101

constant c_SCHK               : t_spi_chk_prm_arr(0 to c_CHK_ENA_SPI_NB-1) :=
                                (("spi_hk           " , '1', c_SPI_TIME_CHK_HK ),
                                 ("spi_sq2_lsb(0)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_lsb(1)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_lsb(2)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_lsb(3)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_off(0)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_off(1)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_off(2)   " , '0', c_SPI_TIME_CHK_SQ2),
                                 ("spi_sq2_off(3)   " , '0', c_SPI_TIME_CHK_SQ2))                           ;

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
         g_EP_N_CLK_PER_SCLK_H: integer := c_EP_SCLK_H_DEF                                                  ; --! EP - Number of clock period for elaborating SPI Serial Clock high level
         g_EP_BUF_DEL         : time    := c_EP_BUF_DEL_DEF                                                   --! EP - Delay introduced by buffer
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

   component squid_model is generic
   (     g_SQ1_ADC_VREF       : real      := c_SQ1_ADC_VREF_DEF                                             ; --! SQUID1 ADC - Voltage reference (Volt)
         g_SQ1_DAC_VREF       : real      := c_SQ1_DAC_VREF_DEF                                             ; --! SQUID1 DAC - Voltage reference (Volt)
         g_SQ2_DAC_VREF       : real      := c_SQ2_DAC_VREF_DEF                                             ; --! SQUID2 DAC - Voltage reference (Volt)
         g_SQ2_DAC_TS         : time      := c_SQ2_DAC_TS_DEF                                               ; --! SQUID2 DAC - Output Voltage Settling time
         g_SQ2_MUX_TPLH       : time      := c_SQ2_MUX_TPLH_DEF                                             ; --! SQUID2 MUX - Propagation delay switch in to out
         g_CLK_ADC_PER        : time      := c_CLK_ADC_PER_DEF                                              ; --! SQUID1 ADC - Clock period
         g_TIM_ADC_TPD        : time      := c_TIM_ADC_TPD_DEF                                                --! SQUID1 ADC - Time, Data Propagation Delay
   ); port
   (     i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_clk_sq1_adc        : in     std_logic                                                            ; --! SQUID1 ADC - Clock
         i_sq1_adc_pwdn       : in     std_logic                                                            ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
         b_sq1_adc_spi_sdio   : inout  std_logic                                                            ; --! SQUID1 ADC - SPI Serial Data In Out
         i_sq1_adc_spi_sclk   : in     std_logic                                                            ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_sq1_adc_spi_cs_n   : in     std_logic                                                            ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         i_sw_adc_vin         : in     std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input
         o_sq1_adc_ana        : out    real                                                                 ; --! SQUID1 ADC - Analog
         o_sq1_adc_data       : out    std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC - Data
         o_sq1_adc_oor        : out    std_logic                                                            ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

         i_clk_sq1_dac        : in     std_logic                                                            ; --! SQUID1 DAC - Clock
         i_sq1_dac_data       : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC - Data
         i_sq1_dac_sleep      : in     std_logic                                                            ; --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)

         i_pls_shp_fc         : in     integer                                                              ; --! Pulse shaping cut frequency (Hz)
         o_err_num_pls_shp    : out    integer                                                              ; --! Pulse shaping error number

         i_sq2_dac_data       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Data
         i_sq2_dac_sclk       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Clock
         i_sq2_dac_snc_l_n    : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sq2_dac_snc_o_n    : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sq2_dac_mux        : in     std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC - Multiplexer
         i_sq2_dac_mx_en_n    : in     std_logic                                                              --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)
   );
   end component;

   component parser is generic
   (     g_SIM_TIME           : time    := c_SIM_TIME_DEF                                                   ; --! Simulation time
         g_TST_NUM            : string  := c_TST_NUM_DEF                                                      --! Test number
   ); port
   (     o_arst_n             : out    std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_err_chk_rpt        : in     t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)     ; --! Clock check error reports
         i_err_n_spi_chk      : in     t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)      ; --! SPI check error number:
         i_err_num_pls_shp    : in     t_int_arr(0 to c_NB_COL-1)                                           ; --! Pulse shaping error number

         i_c0_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         i_c1_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         i_c2_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         i_c3_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)

         i_c0_sq1_adc_ana     : in     real                                                                 ; --! SQUID1 ADC, col. 0 - Analog
         i_c1_sq1_adc_ana     : in     real                                                                 ; --! SQUID1 ADC, col. 1 - Analog
         i_c2_sq1_adc_ana     : in     real                                                                 ; --! SQUID1 ADC, col. 2 - Analog
         i_c3_sq1_adc_ana     : in     real                                                                 ; --! SQUID1 ADC, col. 3 - Analog

         i_c0_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_adc      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_dac      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq2_mux      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              : in     std_logic                                                            ; --! Internal design: System Clock
         i_d_clk_sq1_adc_acq  : in     std_logic                                                            ; --! Internal design: SQUID1 ADC acquisition Clock
         i_d_clk_sq1_pls_shap : in     std_logic                                                            ; --! Internal design: SQUID1 pulse shaping Clock

         i_c0_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 - Clock
         i_c1_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 - Clock
         i_c2_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 - Clock
         i_c3_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 - Clock

         i_c0_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Clock
         i_c1_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Clock
         i_c2_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Clock
         i_c3_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Clock

         i_sc_pkt_type        : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! Science packet type
         i_sc_pkt_err         : in     std_logic                                                            ; --! Science packet error ('0' = No error, '1' = Error)

         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Receipted data
         i_ep_data_rx_rdy     : in     std_logic                                                            ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Command to send
         o_ep_cmd_start       : out    std_logic                                                            ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      : in     std_logic                                                            ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)               ; --! EP - Serial word size

         o_brd_ref            : out    std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         o_brd_model          : out    std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model

         o_pls_shp_fc         : out    t_int_arr(0 to c_NB_COL-1)                                           ; --! Pulse shaping cut frequency (Hz)
         o_sw_adc_vin         : out    std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input

         o_adc_dmp_mem_add    : out    std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! ADC Dump memory for data compare: address
         o_adc_dmp_mem_data   : out    std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                        ; --! ADC Dump memory for data compare: data
         o_adc_dmp_mem_cs     : out    std_logic                                                              --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)
   );
   end component;

   component science_data_model is generic
   (     g_SIM_TIME           : time    := c_SIM_TIME_DEF                                                   ; --! Simulation time
         g_TST_NUM            : string  := c_TST_NUM_DEF                                                      --! Test number
   ); port
   (     i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_acq    : in     std_logic                                                            ; --! SQUID1 ADC acquisition Clock
         i_clk_science        : in     std_logic                                                            ; --! Science Clock

         i_science_ctrl_01    : in     std_logic                                                            ; --! Science Data – Control channel 0/1
         i_science_ctrl_23    : in     std_logic                                                            ; --! Science Data – Control channel 2/3
         i_c0_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 0 – Serial Data
         i_c1_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 1 – Serial Data
         i_c2_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 2 – Serial Data
         i_c3_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 3 – Serial Data

         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_tm_mode            : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)          ; --! Telemetry mode
         i_sw_adc_vin         : in     std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input

         i_sq1_adc_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_SQ1_ADC_DATA_S-1 downto 0)              ; --! SQUID1 ADC - Data buses
         i_sq1_adc_oor        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

         i_adc_dmp_mem_add    : in     std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   : in     std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                        ; --! ADC Dump memory for data compare: data
         i_adc_dmp_mem_cs     : in     std_logic                                                            ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_sc_pkt_type        : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! Science packet type
         o_sc_pkt_err         : out    std_logic                                                              --! Science packet error ('0' = No error, '1' = Error)
   );
   end component;

end pkg_model;
