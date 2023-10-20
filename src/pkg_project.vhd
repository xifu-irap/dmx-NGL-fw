-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-fw is free software: you can redistribute it and/or modify
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
--!   @file                   pkg_project.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Specific project constants
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_fpga_tech.all;

package pkg_project is

   -- ------------------------------------------------------------------------------------------------------
   --    System parameters
   --    @Req : DRE-DMX-FW-REQ-0040
   --    @Req : DRE-DMX-FW-REQ-0120
   --    @Req : DRE-DMX-FW-REQ-0270
   -- ------------------------------------------------------------------------------------------------------
constant c_FW_VERSION         : integer   :=  1                                                             ; --! Firmware version

constant c_FF_RSYNC_NB        : integer   := 2                                                              ; --! Flip-Flop number used for FPGA input resynchronization
constant c_FF_RST_NB          : integer   := 6                                                              ; --! Flip-Flop number used for internal reset: System Clock
constant c_FF_RST_ADC_DAC_NB  : integer   := 10                                                             ; --! Flip-Flop number used for internal reset: ADC/DAC Clock

constant c_MEM_RD_DATA_NPER   : integer   := 2                                                              ; --! Clock period number for accessing memory data output
constant c_DSP_NPER           : integer   := 3                                                              ; --! Clock period number for DSP calculation

constant c_CLK_REF_MULT       : integer   := 1                                                              ; --! Reference Clock multiplier frequency factor
constant c_CLK_MULT           : integer   := 1                                                              ; --! System Clock multiplier frequency factor
constant c_CLK_ADC_DAC_MULT   : integer   := 2                                                              ; --! ADC/DAC Clock multiplier frequency factor
constant c_CLK_DAC_OUT_MULT   : integer   := 4                                                              ; --! DAC output Clock multiplier frequency factor

constant c_COL0               : integer   := 0                                                              ; --! Column 0 value
constant c_COL1               : integer   := 1                                                              ; --! Column 1 value
constant c_COL2               : integer   := 2                                                              ; --! Column 2 value
constant c_COL3               : integer   := 3                                                              ; --! Column 3 value

   -- ------------------------------------------------------------------------------------------------------
   --  c_PLL_MAIN_VCO_MULT conditions to respect:
   --    - NG-LARGE:
   --       * Must be a common multiplier with c_CLK_REF_MULT, c_CLK_ADC_DAC_MULT, c_CLK_DAC_OUT_MULT
   --          and c_CLK_MULT
   --       * Vco frequency range : 200 MHz <= c_PLL_MAIN_VCO_MULT * c_CLK_COM_FREQ    <= 800 MHz
   --       * WFG pattern size    :            c_PLL_MAIN_VCO_MULT/  c_CLK_REF_MULT    <= 16
   -- ------------------------------------------------------------------------------------------------------
constant c_PLL_MAIN_VCO_MULT  : integer   := 12                                                             ; --! PLL main VCO multiplier frequency factor

constant c_CLK_COM_FREQ       : integer   := 62500000                                                       ; --! Clock frequency common to main clocks (Hz)
constant c_CLK_REF_FREQ       : integer   := c_CLK_REF_MULT      * c_CLK_COM_FREQ                           ; --! Reference Clock frequency (Hz)
constant c_CLK_FREQ           : integer   := c_CLK_MULT          * c_CLK_COM_FREQ                           ; --! System Clock frequency (Hz)
constant c_CLK_ADC_FREQ       : integer   := c_CLK_ADC_DAC_MULT  * c_CLK_COM_FREQ                           ; --! ADC/DAC Clock frequency (Hz)
constant c_CLK_DAC_OUT_FREQ   : integer   := c_CLK_DAC_OUT_MULT  * c_CLK_COM_FREQ                           ; --! DAC output Clock frequency (Hz)
constant c_PLL_MAIN_VCO_FREQ  : integer   := c_PLL_MAIN_VCO_MULT * c_CLK_COM_FREQ                           ; --! PLL main VCO frequency (Hz)

constant c_CLK_ADC_DEL_STEP   : integer   := div_floor(15*10**5/(c_CLK_ADC_FREQ/10**6) - 4400,c_IO_DEL_STEP); --! ADC Clock propagation delay step number

   -- ------------------------------------------------------------------------------------------------------
   --    Interface parameters
   --    @Req : DRE-DMX-FW-REQ-0340
   --    @Req : DRE-DMX-FW-REQ-0360
   --    @Req : DRE-DMX-FW-REQ-0550
   --    @Req : DRE-DMX-FW-REQ-0560
   -- ------------------------------------------------------------------------------------------------------
constant c_BRD_REF_S          : integer   := 5                                                              ; --! Board reference size bus
constant c_BRD_MODEL_S        : integer   := 3                                                              ; --! Board model size bus

constant c_SQM_ADC_DATA_S     : integer   := 14                                                             ; --! SQUID MUX ADC data size bus
constant c_SQM_DAC_DATA_S     : integer   := 14                                                             ; --! SQUID MUX DAC data size bus

constant c_SQA_DAC_DATA_S     : integer   := 12                                                             ; --! SQUID AMP DAC data size bus
constant c_SQA_DAC_MODE_S     : integer   := 2                                                              ; --! SQUID AMP DAC mode size bus
constant c_SQA_SPI_CPOL       : std_logic := c_LOW_LEV                                                      ; --! SQUID AMP DAC SPI: Clock polarity
constant c_SQA_SPI_CPHA       : std_logic := c_HGH_LEV                                                      ; --! SQUID AMP DAC SPI: Clock phase
constant c_SQA_SPI_SER_WD_S   : integer   := c_SQA_DAC_DATA_S + c_SQA_DAC_MODE_S + 2                        ; --! SQUID AMP DAC SPI: Data bus size
constant c_SQA_SPI_SCLK_H     : integer   := div_ceil(c_CLK_ADC_FREQ * 13, 1000000000)                      ; --! SQUID AMP DAC SPI: Number of clock period for elaborating SPI Serial Clock high level
constant c_SQA_SPI_SCLK_L     : integer   := maximum(c_SQA_SPI_SCLK_H,
                                                     div_ceil(c_CLK_ADC_FREQ, 30000000) - c_SQA_SPI_SCLK_H) ; --! SQUID AMP DAC SPI: Number of clock period for elaborating SPI Serial Clock low level
constant c_SQA_DAC_MUX_S      : integer   := 3                                                              ; --! SQUID AMP DAC Multiplexer size

constant c_SC_DATA_SER_W_S    : integer   := 8                                                              ; --! Science data serial word size
constant c_SC_DATA_SER_NB     : integer   := 2                                                              ; --! Science data serial link number by DEMUX column

constant c_HK_SPI_CPOL        : std_logic := c_HGH_LEV                                                      ; --! HK SPI: Clock polarity
constant c_HK_SPI_CPHA        : std_logic := c_HGH_LEV                                                      ; --! HK SPI: Clock phase
constant c_HK_SPI_SER_WD_S    : integer   := 16                                                             ; --! HK SPI: Data bus size
constant c_HK_SPI_SCLK_L      : integer   := 2                                                              ; --! HK SPI: Number of clock period for elaborating SPI Serial Clock low level
constant c_HK_SPI_SCLK_H      : integer   := 2                                                              ; --! HK SPI: Number of clock period for elaborating SPI Serial Clock high level
constant c_HK_SPI_ADD_S       : integer   := 3                                                              ; --! HK SPI: Address size
constant c_HK_SPI_ADD_POS_LSB : integer   := 11                                                             ; --! HK SPI: Address position LSB
constant c_HK_SPI_DATA_S      : integer   := 12                                                             ; --! HK SPI: Data size
constant c_HK_SPI_SCLK_NB_ACQ : integer   := 3                                                              ; --! HK SPI: SCLK cycle number for analog signal acquisition
constant c_HK_MUX_S           : integer   := 3                                                              ; --! HK Multiplexer size
constant c_HK_NW              : integer   := 14                                                             ; --! HK Number words

constant c_EP_CMD_S           : integer   := 32                                                             ; --! EP command bus size
constant c_EP_SPI_CPOL        : std_logic := c_LOW_LEV                                                      ; --! EP SPI Clock polarity
constant c_EP_SPI_CPHA        : std_logic := c_LOW_LEV                                                      ; --! EP SPI Clock phase
constant c_EP_SPI_WD_S        : integer   := c_EP_CMD_S/2                                                   ; --! EP SPI Data word size (receipt/transmit)
constant c_EP_SPI_TX_WD_NB_S  : integer   := 1                                                              ; --! EP SPI Data word to transmit number size
constant c_EP_SPI_RX_WD_NB_S  : integer   := 2                                                              ; --! EP SPI Receipted data word number size (more than expected, command length control)

   -- ------------------------------------------------------------------------------------------------------
   --    Housekeeping interface
   -- ------------------------------------------------------------------------------------------------------
constant c_HK_ADC_P1V8_ANA    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P1V8_ANA
constant c_HK_ADC_P2V5_ANA    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P2V5_ANA
constant c_HK_ADC_M2V5_ANA    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_M2V5_ANA
constant c_HK_ADC_P3V3_ANA    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 3, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P3V3_ANA
constant c_HK_ADC_M5V0_ANA    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_M5V0_ANA
constant c_HK_ADC_P1V2_DIG    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P1V2_DIG
constant c_HK_ADC_P2V5_DIG    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P2V5_DIG
constant c_HK_ADC_P2V5_AUX    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P2V5_AUX
constant c_HK_ADC_P3V3_DIG    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P3V3_DIG
constant c_HK_ADC_VREF_TMP    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_VREF_TMP
constant c_HK_ADC_VREF_R2R    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_VREF_R2R
constant c_HK_ADC_P5V0_ANA    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 5, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_P5V0_ANA
constant c_HK_ADC_TEMP_AVE    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 6, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_TEMP_AVE
constant c_HK_ADC_TEMP_MAX    : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 7, c_HK_SPI_ADD_S))                           ; --! Housekeeping ADC position, HK_TEMP_MAX

constant c_HK_MUX_P1V8_ANA    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P1V8_ANA
constant c_HK_MUX_P2V5_ANA    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P2V5_ANA
constant c_HK_MUX_M2V5_ANA    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_M2V5_ANA
constant c_HK_MUX_P3V3_ANA    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P3V3_ANA
constant c_HK_MUX_M5V0_ANA    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_M5V0_ANA
constant c_HK_MUX_P1V2_DIG    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P1V2_DIG
constant c_HK_MUX_P2V5_DIG    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P2V5_DIG
constant c_HK_MUX_P2V5_AUX    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 3, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P2V5_AUX
constant c_HK_MUX_P3V3_DIG    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P3V3_DIG
constant c_HK_MUX_VREF_TMP    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 5, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_VREF_TMP
constant c_HK_MUX_VREF_R2R    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 6, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_VREF_R2R
constant c_HK_MUX_P5V0_ANA    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_P5V0_ANA
constant c_HK_MUX_TEMP_AVE    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_TEMP_AVE
constant c_HK_MUX_TEMP_MAX    : std_logic_vector(c_HK_MUX_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_HK_MUX_S))                               ; --! Housekeeping MUX position, HK_TEMP_MAX

constant c_HK_ADC_SEQ         : t_slv_arr(0 to c_HK_NW-1)(c_HK_SPI_ADD_S-1 downto 0) :=
                                (c_HK_ADC_P2V5_ANA, c_HK_ADC_M2V5_ANA, c_HK_ADC_P3V3_ANA, c_HK_ADC_M5V0_ANA,
                                 c_HK_ADC_P1V2_DIG, c_HK_ADC_P2V5_DIG, c_HK_ADC_P2V5_AUX, c_HK_ADC_P3V3_DIG,
                                 c_HK_ADC_VREF_TMP, c_HK_ADC_VREF_R2R, c_HK_ADC_P5V0_ANA, c_HK_ADC_TEMP_AVE,
                                 c_HK_ADC_TEMP_MAX, c_HK_ADC_P1V8_ANA)                                      ; --! Housekeeping ADC sequence

constant c_HK_MUX_SEQ         : t_slv_arr(0 to c_HK_NW-1)(c_HK_MUX_S-1 downto 0) :=
                                (c_HK_MUX_P1V8_ANA, c_HK_MUX_P2V5_ANA, c_HK_MUX_M2V5_ANA, c_HK_MUX_P3V3_ANA,
                                 c_HK_MUX_M5V0_ANA, c_HK_MUX_P1V2_DIG, c_HK_MUX_P2V5_DIG, c_HK_MUX_P2V5_AUX,
                                 c_HK_MUX_P3V3_DIG, c_HK_MUX_VREF_TMP, c_HK_MUX_VREF_R2R, c_HK_MUX_P5V0_ANA,
                                 c_HK_MUX_TEMP_AVE, c_HK_MUX_TEMP_MAX)                                      ; --! Housekeeping MUX sequence

   -- ------------------------------------------------------------------------------------------------------
   --    Inputs default value at reset
   -- ------------------------------------------------------------------------------------------------------
constant c_I_SPI_DATA_DEF     : std_logic := c_LOW_LEV                                                      ; --! SPI data input default value at reset
constant c_I_SPI_SCLK_DEF     : std_logic := c_EP_SPI_CPOL                                                  ; --! SPI Serial Clock input default value at reset
constant c_I_SPI_CS_N_DEF     : std_logic := c_HGH_LEV                                                      ; --! SPI Chip Select input default value at reset
constant c_I_SQM_ADC_DATA_DEF : std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_SQM_ADC_DATA_S))                          ; --! SQUID MUX ADC data input default value at reset
constant c_I_SQM_ADC_OOR_DEF  : std_logic := c_LOW_LEV                                                      ; --! SQUID MUX ADC out of range input default value at reset
constant c_I_SYNC_DEF         : std_logic := c_HGH_LEV                                                      ; --! Pixel sequence synchronization default value at reset

constant c_CMD_CK_SQM_ADC_DEF : std_logic := c_LOW_LEV                                                      ; --! SQUID MUX ADC clock switch command default value at reset
constant c_CMD_CK_SQM_DAC_DEF : std_logic := c_LOW_LEV                                                      ; --! SQUID MUX DAC clock switch command default value at reset

constant c_MEM_STR_ADD_PP_DEF : std_logic := c_LOW_LEV                                                      ; --! Memory storage parameters, ping-pong buffer bit for address default value at reset

   -- ------------------------------------------------------------------------------------------------------
   --    Project parameters
   --    @Req : DRE-DMX-FW-REQ-0070
   --    @Req : DRE-DMX-FW-REQ-0080
   -- ------------------------------------------------------------------------------------------------------
constant c_MUX_FACT           : integer   := 34                                                             ; --! DEMUX: multiplexing factor
constant c_NB_COL             : integer   := 4                                                              ; --! DEMUX: column number
constant c_DMP_SEQ_ACQ_NB     : integer   := 2                                                              ; --! DEMUX: sequence acquisition number for the ADC data dump mode

constant c_SQM_ADC_SMP_AVE_S  : integer   := 4                                                              ; --! ADC sample number for averaging bus size
constant c_SQM_DATA_ERR_S     : integer   := c_SQM_ADC_DATA_S + c_SQM_ADC_SMP_AVE_S                         ; --! SQUID MUX Data error bus size
constant c_SQM_DATA_FBK_S     : integer   := 16                                                             ; --! SQUID MUX Data feedback bus size (<= c_MULT_ALU_PORTB_S-1)
constant c_SQM_PLS_SHP_A_EXP  : integer   := c_EP_SPI_WD_S                                                  ; --! Pulse shaping: Filter exponent parameter (<=c_MULT_ALU_PORTC_S-c_SQM_PLS_SHP_X_K_S-1)

constant c_PIX_POS_SW_ON      : integer   := 2                                                              ; --! Pixel position for command switch clocks on
constant c_PIX_POS_SW_ADC_OFF : integer   := c_MUX_FACT - 1                                                 ; --! Pixel position for command ADC switch clocks off

constant c_MUX_FACT_S         : integer   := log2_ceil(c_MUX_FACT)                                          ; --! DEMUX: multiplexing factor bus size

constant c_TST_PAT_RGN_NB     : integer   := 5                                                              ; --! Test pattern: region number
constant c_TST_PAT_COEF_NB    : integer   := 4                                                              ; --! Test pattern: coefficient by region number
constant c_TST_PAT_COEF_NB_S  : integer   := log2_ceil(c_TST_PAT_COEF_NB)                                   ; --! Test pattern: coefficient position size bus

constant c_TST_ITCPT_COEF_POS : integer   := 0                                                              ; --! Test pattern: Intercept coefficient position
constant c_TST_INDMAX_FRM_POS : integer   := 1                                                              ; --! Test pattern: Index Maximum frame by step position
constant c_TST_SLOPE_COEF_POS : integer   := 2                                                              ; --! Test pattern: Slope coefficient position
constant c_TST_INDMAX_POS     : integer   := 3                                                              ; --! Test pattern: Index Maximum step by region position

constant c_TST_COEF_RD_SEQ_S  : integer   := 8                                                              ; --! Test pattern: Coefficient reading sequence size
constant c_TST_COEF_RD_SEQ    : t_slv_arr(0 to c_TST_COEF_RD_SEQ_S-1)(c_TST_PAT_COEF_NB_S-1 downto 0) :=
                                (std_logic_vector(to_unsigned(c_TST_INDMAX_POS,     c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_INDMAX_POS,     c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_INDMAX_POS,     c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_INDMAX_POS,     c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_INDMAX_FRM_POS, c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_SLOPE_COEF_POS, c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_ITCPT_COEF_POS, c_TST_PAT_COEF_NB_S)),
                                 std_logic_vector(to_unsigned(c_TST_INDMAX_POS,     c_TST_PAT_COEF_NB_S)))  ; --! Test pattern: Coefficient reading sequence

constant c_TST_INDMAX_CHK_RDY : integer   := 2                                                              ; --! Test pattern: Index Maximum Check ready
constant c_TST_INDMAX_RDY     : integer   := c_MEM_RD_DATA_NPER + 3                                         ; --! Test pattern: Index Maximum step by region ready
constant c_TST_INDMAX_FRM_RDY : integer   := c_MEM_RD_DATA_NPER + 4                                         ; --! Test pattern: Index Maximum frame by step ready
constant c_TST_SLOPE_COEF_RDY : integer   := c_MEM_RD_DATA_NPER + 5                                         ; --! Test pattern: Slope coefficient ready
constant c_TST_ITCPT_COEF_RDY : integer   := c_MEM_RD_DATA_NPER + 6                                         ; --! Test pattern: Intercept coefficient ready
constant c_TST_RES_RDY        : integer   := c_TST_ITCPT_COEF_RDY + c_DSP_NPER + 1                          ; --! Test pattern: Result ready
constant c_TST_IND_FRM_RDY    : integer   := c_TST_INDMAX_FRM_RDY + 1                                       ; --! Test pattern: Index frame by step ready

constant c_ERR_NIN_MX_STNB    : integer   := 2                                                              ; --! Error parameter to read not initialized yet: Multiplexer stage number
constant c_ERR_NIN_MX_STIN    : integer_vector(0 to c_ERR_NIN_MX_STNB+1) := ( 0, 16, 20, 21)                ; --! Error parameter to read not initialized yet: Inputs by multiplexer stage (accumulated)
constant c_ERR_NIN_MX_INNB    : integer_vector(0 to c_ERR_NIN_MX_STNB-1) := ( 4,  4)                        ; --! Error parameter to read not initialized yet: Inputs by multiplexer

constant c_DLFLG_MX_STNB      : integer   := 3                                                              ; --! Delock flag: Multiplexer stage number
constant c_DLFLG_MX_STIN      : integer_vector(0 to c_DLFLG_MX_STNB+1) := ( 0, 36, 45, 48, 49)              ; --! Delock flag: Inputs by multiplexer stage (accumulated)
constant c_DLFLG_MX_INNB      : integer_vector(0 to c_DLFLG_MX_STNB-1) := ( 4,  3,  3)                      ; --! Delock flag: Inputs by multiplexer

   -- ------------------------------------------------------------------------------------------------------
   --    SQUID MUX ADC parameters
   --    @Req : DRE-DMX-FW-REQ-0130
   -- ------------------------------------------------------------------------------------------------------
constant c_PIXEL_ADC_NB_CYC   : integer := 20                                                               ; --! ADC clock period number allocated to one pixel acquisition
constant c_ADC_DATA_NPER      : integer := 12                                                               ; --! ADC clock period number between the acquisition start and data output by the ADC

constant c_ADC_SYNC_RDY_NPER  : integer := (c_FF_RSYNC_NB + 1)*(c_CLK_ADC_DAC_MULT/c_CLK_MULT)
                                          + c_FF_RSYNC_NB                                                   ; --! ADC clock period number for getting pixel sequence synchronization, synchronized
constant c_ADC_DATA_RDY_NPER  : integer := c_ADC_DATA_NPER + c_FF_RSYNC_NB - 1                              ; --! ADC clock period number between the ADC acquisition start and ADC data ready

constant c_MEM_DUMP_ADD_S     : integer := c_RAM_ECC_ADD_S                                                  ; --! Memory Dump: address bus size (<= c_RAM_ECC_ADD_S)

constant c_ADC_SMP_AVE_ADD_S  : integer := c_SQM_ADC_SMP_AVE_S                                              ; --! ADC sample number for averaging table address bus size
constant c_ASP_CF_S           : integer := c_MULT_ALU_PORTA_S - 1                                           ; --! ADC sample number for averaging coefficient bus size (<= c_MULT_ALU_PORTA_S)
constant c_ASP_CF_FACT        : integer := 2**(c_ASP_CF_S-1)                                                ; --! ADC sample number for averaging factor
constant c_ADC_SMP_AVE_TAB    : t_slv_arr(0 to 2**c_ADC_SMP_AVE_ADD_S-1)(c_ASP_CF_S-1 downto 0) :=
                                (std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  1), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  2), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  3), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  4), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  5), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  6), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  7), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  8), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT,  9), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 10), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 11), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 12), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 13), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 14), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 15), c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(c_ASP_CF_FACT, 16), c_ASP_CF_S)))   ; --! ADC sample number for averaging table

   -- ------------------------------------------------------------------------------------------------------
   --    SQUID MUX DAC parameters
   --    @Req : DRE-DMX-FW-REQ-0230
   --    @Req : DRE-DMX-FW-REQ-0275
   -- ------------------------------------------------------------------------------------------------------
constant c_PIXEL_DAC_NB_CYC   : integer := 20                                                               ; --! DAC clock period number allocated to one pixel acquisition
constant c_DAC_MDL_POINT      : integer := 2**(c_SQM_DATA_FBK_S-1)                                          ; --! DAC middle point
constant c_DAC_PLS_SHP_SET_NB : integer := 4                                                                ; --! DAC pulse shaping set number

constant c_DAC_SYNC_RDY_NPER  : integer := (c_FF_RSYNC_NB + 1)*(c_CLK_ADC_DAC_MULT/c_CLK_MULT)
                                          + c_FF_RSYNC_NB                                                   ; --! DAC clock period number for getting pixel sequence synchronization, synchronized
constant c_DAC_SYNC_RE_NPER   : integer := 1                                                                ; --! DAC clock period number for getting pixel sequence synchronization rising edge
constant c_DAC_MEM_PRM_NPER   : integer := c_MEM_RD_DATA_NPER + 1                                           ; --! DAC clock period number for getting parameters stored in memory from pixel sequence
constant c_DAC_SHP_PRC_NPER   : integer := c_DSP_NPER + 1                                                   ; --! DAC clock period number for pulse shaping processing and DAC data input
constant c_DAC_DATA_NPER      : integer := 3                                                                ; --! DAC clock period number between DAC data input and analog output
constant c_DAC_SYNC_DATA_NPER : integer := c_DAC_SYNC_RDY_NPER + c_DAC_SYNC_RE_NPER + c_DAC_MEM_PRM_NPER +
                                           c_DAC_SHP_PRC_NPER  + c_DAC_DATA_NPER                            ; --! DAC clock period number for stalling analog output to pixel sequence synchronization

constant c_SQM_PLS_CNT_MX_VAL : integer := c_PIXEL_DAC_NB_CYC - 2                                           ; --! SQUID MUX, Pulse shaping counter: maximal value
constant c_SQM_PLS_CNT_INIT   : integer := c_SQM_PLS_CNT_MX_VAL - c_DAC_SYNC_DATA_NPER                      ; --! SQUID MUX, Pulse shaping counter: initialization value
constant c_SQM_PLS_CNT_S      : integer := log2_ceil(c_SQM_PLS_CNT_MX_VAL + 1) + 1                          ; --! SQUID MUX, Pulse shaping counter: size bus (signed)

constant c_SQM_PXL_POS_MX_VAL : integer := c_MUX_FACT - 2                                                   ; --! SQUID MUX, Pixel position: maximal value
constant c_SQM_PXL_POS_INIT   : integer := -1                                                               ; --! SQUID MUX, Pixel position: initialization value
constant c_SQM_PXL_POS_S      : integer := log2_ceil(c_SQM_PXL_POS_MX_VAL+1)+1                              ; --! SQUID MUX, Pixel position: size bus (signed)

   -- ------------------------------------------------------------------------------------------------------
   --    SQUID AMP parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_SQA_DAC_MDL_POINT  : integer := 2**(c_SQA_DAC_DATA_S-1)                                          ; --! SQUID AMP DAC middle point
constant c_SAM_SYNC_DATA_NPER : integer := c_DAC_SYNC_RDY_NPER + c_DAC_SYNC_RE_NPER                         ; --! MUX clock period number for stalling analog output to pixel sequence synchronization

constant c_SAD_PRC_NPER       : integer := (c_SQA_SPI_SCLK_L + c_SQA_SPI_SCLK_H) *  c_SQA_SPI_SER_WD_S + 3  ; --! DAC clock period number for sending data to DAC
constant c_SAD_SYNC_DATA_NPER : integer := c_DAC_SYNC_RDY_NPER + c_DAC_SYNC_RE_NPER + c_SAD_PRC_NPER        ; --! DAC clock period number for stalling sending data end to pixel sequence sync.

constant c_SQA_PLS_CNT_MX_VAL : integer := c_PIXEL_DAC_NB_CYC - 2                                           ; --! SQUID AMP, Pulse counter: maximal value
constant c_SQA_PLS_CNT_INIT   : integer := c_SQA_PLS_CNT_MX_VAL - c_SAM_SYNC_DATA_NPER                      ; --! SQUID AMP, Pulse counter: initialization value
constant c_SQA_PLS_CNT_S      : integer := log2_ceil(c_SQA_PLS_CNT_MX_VAL + 1) + 1                          ; --! SQUID AMP, Pulse counter: size bus (signed)

constant c_SQA_PXL_POS_MX_VAL : integer := c_MUX_FACT - 2                                                   ; --! SQUID AMP, Pixel position: maximal value
constant c_SQA_PXL_POS_INIT   : integer := -1                                                               ; --! SQUID AMP, Pixel position: initialization value
constant c_SQA_PXL_POS_S      : integer := log2_ceil(c_SQA_PXL_POS_MX_VAL+1)+1                              ; --! SQUID AMP, Pixel position: size bus (signed)

constant c_SQA_FIR1_DCI_VAL   : integer := 32                                                               ; --! SQUID AMP: Filter FIR1 decimation value
constant c_SQA_FIR1_TAB_NW    : integer := 256                                                              ; --! SQUID AMP: Filter FIR1 table number word
constant c_SQA_FIR1_S         : integer := c_RAM_ECC_DATA_S                                                 ; --! SQUID AMP: Filter FIR1 coefficient bus size
constant c_SQA_FIR1_FRC_S     : integer := integer(ceil(real(c_RAM_ECC_DATA_S-2) - log2(0.033186060773188))); --! SQUID AMP: Filter FIR1 coefficient fractional part
constant c_SQA_FIR1_COEF_SM_S : integer := c_SQA_FIR1_FRC_S + 1                                             ; --! SQUID AMP: Filter FIR1 coefficient sum bus size (sum slightly higher than 1.0)
constant c_SQA_FIR1_TAB       : integer_vector(0 to c_SQA_FIR1_TAB_NW-1) :=                                   --! SQUID AMP: Filter FIR1 coefficients (symetrical FIR, Fs = 6.25 MHz)
                               ( integer(round(-0.0000000000000000000257 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000000896358117296806 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000003074050729944920 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000005676776418460560 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000007747629430165470 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000008254423670411830 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000006117630629136700 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000000240636295918251 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000010458020130680500 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000027010808964361800 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000050366206797981300 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000081353011937011800 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000120644516679525000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000168723128365884000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000225846083397909000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000292012947339411000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000366935637659348000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000450011741421972000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000540301925940706000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000636512253759712000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000736982212040602000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000839679248388443000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000942200568453274000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001041782893697690000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001135320799314810000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001219394151650650000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001290305041380540000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001344124463422110000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001376748828055750000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001383966201512960000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001361531970573670000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001305253407310410000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001211082380473760000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001075215223148740000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000894198526770055000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000665039394359647000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000385318456301609000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000053303735720836700 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000331936746644370000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000770425910488983000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0001261174521055390000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0001802086591174630000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0002389875874706430000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0003019996064803510000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0003686587279811850000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0004382441336304110000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0005098988170486880000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0005826305574774570000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0006553154165513840000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0007267039191646060000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0007954300434674930000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0008600231041035900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0009189225673424000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0009704957873587580000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0010130586002418200000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0010448986571789400000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0010643013215372700000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0010695778972266700000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0010590958988011000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0010313110183244000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0009848003911961310000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0009182967140234380000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0008307227233384720000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0007212255055674890000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0005892100771702490000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0004343716502188080000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0002567259837068660000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000566372152862144000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001651574275111260000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0004075266227702810000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0006689282172574440000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0009473972818505240000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0012405394375238600000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0015455298732126200000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0018591184102846600000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0021776408927207700000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0024970370983413800000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0028128752755932300000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0031203833137580600000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0034144864533539700000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0036898513394809500000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0039409361155334900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0041620461497624900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0043473948843657400000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0044911691978911200000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0045875985785133300000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0046310273199151500000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0046159888747196900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0045372814342294900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0043900437490480400000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0041698301642454600000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0038726838161516300000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0034952069264763400000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0030346271338968800000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0024888588239006400000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0018565584546490900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0011371729297963200000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0003309801381371120000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0005608791360054640000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0015363786295610000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0025925939314375800000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0037257001913225100000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0049309805381794000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0062028453995380900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0075348627661432400000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0089197992961380200000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0103496720009581000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0118158101038099000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0133089265133430000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0148191982122344000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0163363547251468000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0178497737051041000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0193485825638017000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0208217649716314000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0222582709689609000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0236471293629406000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0249775610350351000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0262390917545484000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0274216630832794000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0285157399664571000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0295124136352954000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0304034984965834000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0311816217540957000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0318403045943456000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0323740338741209000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0327783233678413000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0330497637673357000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0331860607731880000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0331860607731880000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0330497637673357000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0327783233678413000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0323740338741209000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0318403045943456000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0311816217540957000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0304034984965834000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0295124136352954000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0285157399664571000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0274216630832794000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0262390917545484000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0249775610350351000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0236471293629406000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0222582709689609000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0208217649716314000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0193485825638017000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0178497737051041000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0163363547251468000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0148191982122344000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0133089265133430000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0118158101038099000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0103496720009581000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0089197992961380200000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0075348627661432400000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0062028453995380900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0049309805381794000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0037257001913225100000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0025925939314375800000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0015363786295610000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0005608791360054640000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0003309801381371120000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0011371729297963200000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0018565584546490900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0024888588239006400000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0030346271338968800000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0034952069264763400000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0038726838161516300000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0041698301642454600000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0043900437490480400000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0045372814342294900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0046159888747196900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0046310273199151500000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0045875985785133300000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0044911691978911200000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0043473948843657400000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0041620461497624900000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0039409361155334900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0036898513394809500000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0034144864533539700000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0031203833137580600000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0028128752755932300000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0024970370983413800000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0021776408927207700000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0018591184102846600000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0015455298732126200000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0012405394375238600000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0009473972818505240000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0006689282172574440000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0004075266227702810000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001651574275111260000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000566372152862144000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0002567259837068660000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0004343716502188080000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0005892100771702490000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0007212255055674890000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0008307227233384720000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0009182967140234380000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0009848003911961310000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0010313110183244000000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0010590958988011000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0010695778972266700000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0010643013215372700000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0010448986571789400000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0010130586002418200000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0009704957873587580000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0009189225673424000000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0008600231041035900000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0007954300434674930000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0007267039191646060000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0006553154165513840000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0005826305574774570000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0005098988170486880000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0004382441336304110000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0003686587279811850000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0003019996064803510000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0002389875874706430000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0001802086591174630000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0001261174521055390000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000770425910488983000 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000331936746644370000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000053303735720836700 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000385318456301609000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000665039394359647000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000894198526770055000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001075215223148740000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001211082380473760000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001305253407310410000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001361531970573670000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001383966201512960000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001376748828055750000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001344124463422110000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001290305041380540000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001219394151650650000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0001135320799314810000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0001041782893697690000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000942200568453274000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000839679248388443000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000736982212040602000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000636512253759712000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000540301925940706000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000450011741421972000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000366935637659348000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000292012947339411000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000225846083397909000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000168723128365884000 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000120644516679525000 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000081353011937011800 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000050366206797981300 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round(-0.0000027010808964361800 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000010458020130680500 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000000240636295918251 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000006117630629136700 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000008254423670411830 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000007747629430165470 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000005676776418460560 * real(2**c_SQA_FIR1_FRC_S))), integer(round( 0.0000003074050729944920 * real(2**c_SQA_FIR1_FRC_S))),
                                 integer(round( 0.0000000896358117296806 * real(2**c_SQA_FIR1_FRC_S))), integer(round(-0.0000000000000000000257 * real(2**c_SQA_FIR1_FRC_S))));

constant c_SQA_FIR2_DCI_VAL   : integer := 4                                                                ; --! SQUID AMP: Filter FIR2 decimation value
constant c_SQA_FIR2_TAB_NW    : integer := 256                                                              ; --! SQUID AMP: Filter FIR2 table number word
constant c_SQA_FIR2_S         : integer := c_RAM_ECC_DATA_S                                                 ; --! SQUID AMP: Filter FIR2 coefficient bus size
constant c_SQA_FIR2_FRC_S     : integer := integer(ceil(real(c_RAM_ECC_DATA_S-2) - log2(0.222953780772677))); --! SQUID AMP: Filter FIR2 coefficient fractional part
constant c_SQA_FIR2_COEF_SM_S : integer := c_SQA_FIR2_FRC_S                                                 ; --! SQUID AMP: Filter FIR2 coefficient sum bus size
constant c_SQA_FIR2_TAB       : integer_vector(0 to c_SQA_FIR2_TAB_NW-1) :=                                   --! SQUID AMP: Filter FIR2 coefficients (symetrical FIR, Fs = 195.3125 kHz)
                               ( integer(round(-0.0000492418739540020000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000217321195356045000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000093968699264814700 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000133631009058699000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000336510421238082000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000413688453312139000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000264029196251721000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000057415035393666900 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000433829219751607000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000640667690243118000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000549259618375960000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000125905475937706000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000437586061536967000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000880205237242807000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000912708745930467000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000468717895609838000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000314880862189598000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001044111602521890000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001338680226091650000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000948370123397689000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000005923762346516250 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0001085291617740160000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0001734846114447710000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0001559293139213710000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000519959662739864000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000911635032173165000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0002043663785960250000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0002210885434278110000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001238453886277280000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000508406891108996000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0002157130795107710000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0002845257328977410000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0002082157919719960000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000156744246857962000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0002043797420123490000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0003345693508232680000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0003000100307112450000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001018542110467950000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0001654066725095820000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0003674204080627780000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0003878973098251260000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0002041394899520200000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001039891953482560000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0003773575918558810000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0004687940612028890000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0003124093770793600000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000223582414839610000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0003696002569291540000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0005380063055930360000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0004256070137275040000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000705567568851404000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0003465030067912420000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0006031481110436850000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0005421258288479270000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001763651303386690000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0003172332742969680000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0006696106570007760000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0006749939436557510000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0002978439522727870000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0002788790601334240000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0007505695608823480000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0008369883812596750000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0004561700691412910000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0002249760380282810000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0008459268326297710000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0010512032637623700000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0006761460631485840000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001254001521054140000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0009497002339055180000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0013278176500983800000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0009981254018063930000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000597691747018400000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0010260662490850000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0016702079084377700000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0014529004938426400000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0003947816920922620000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0010213059320155200000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0020463272718394800000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0020671200020058000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0009423479656368900000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0008447623481433730000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0023977702197975200000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0028297466972683500000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0017699346619492500000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0003935823075694630000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0026139782803903900000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0036978466910130500000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0029121089481873400000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0004573080545972120000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0025536095344542000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0045625887810055700000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0043748417612825300000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0018165168756299900000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0020264295352477300000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0052656954786007100000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0060942787794946000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0037843911741176900000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0008277096686133240000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0055692637808884000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0079511480389550500000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0064118984345662200000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0012850216251477700000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0051805021256380400000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0097316213407248400000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0097297173996229300000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0045711959863830100000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0036983533427344900000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0111512811989739000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0137337962255860000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0094042637457603000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0005769311873571400000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0117825878416710000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0185004320252314000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0164297305093638000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0051758543000060500000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0109737499154514000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0243640458669072000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0273203768091315000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0159172466289296000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0072230839454243900000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0328939822567855000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0480279752015271000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0407704879778593000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0054914208294543100000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0538173822880139000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.1239898470503380000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.1862721098016710000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.2229537807726770000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.2229537807726770000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.1862721098016710000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.1239898470503380000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0538173822880139000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0054914208294543100000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0407704879778593000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0480279752015271000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0328939822567855000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0072230839454243900000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0159172466289296000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0273203768091315000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0243640458669072000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0109737499154514000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0051758543000060500000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0164297305093638000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0185004320252314000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0117825878416710000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0005769311873571400000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0094042637457603000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0137337962255860000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0111512811989739000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0036983533427344900000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0045711959863830100000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0097297173996229300000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0097316213407248400000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0051805021256380400000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0012850216251477700000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0064118984345662200000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0079511480389550500000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0055692637808884000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0008277096686133240000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0037843911741176900000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0060942787794946000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0052656954786007100000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0020264295352477300000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0018165168756299900000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0043748417612825300000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0045625887810055700000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0025536095344542000000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0004573080545972120000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0029121089481873400000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0036978466910130500000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0026139782803903900000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0003935823075694630000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0017699346619492500000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0028297466972683500000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0023977702197975200000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0008447623481433730000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0009423479656368900000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0020671200020058000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0020463272718394800000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0010213059320155200000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0003947816920922620000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0014529004938426400000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0016702079084377700000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0010260662490850000000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000597691747018400000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0009981254018063930000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0013278176500983800000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0009497002339055180000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001254001521054140000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0006761460631485840000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0010512032637623700000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0008459268326297710000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0002249760380282810000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0004561700691412910000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0008369883812596750000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0007505695608823480000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0002788790601334240000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0002978439522727870000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0006749939436557510000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0006696106570007760000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0003172332742969680000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001763651303386690000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0005421258288479270000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0006031481110436850000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0003465030067912420000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000705567568851404000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0004256070137275040000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0005380063055930360000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0003696002569291540000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000223582414839610000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0003124093770793600000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0004687940612028890000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0003773575918558810000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001039891953482560000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0002041394899520200000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0003878973098251260000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0003674204080627780000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0001654066725095820000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001018542110467950000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0003000100307112450000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0003345693508232680000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0002043797420123490000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000156744246857962000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0002082157919719960000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0002845257328977410000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0002157130795107710000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000508406891108996000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001238453886277280000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0002210885434278110000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0002043663785960250000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000911635032173165000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000519959662739864000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0001559293139213710000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0001734846114447710000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0001085291617740160000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000005923762346516250 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000948370123397689000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0001338680226091650000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0001044111602521890000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000314880862189598000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000468717895609838000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000912708745930467000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000880205237242807000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000437586061536967000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000125905475937706000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000549259618375960000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000640667690243118000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000433829219751607000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000057415035393666900 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000264029196251721000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000413688453312139000 * real(2**c_SQA_FIR2_FRC_S))), integer(round( 0.0000336510421238082000 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round( 0.0000133631009058699000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000093968699264814700 * real(2**c_SQA_FIR2_FRC_S))),
                                 integer(round(-0.0000217321195356045000 * real(2**c_SQA_FIR2_FRC_S))), integer(round(-0.0000492418739540020000 * real(2**c_SQA_FIR2_FRC_S))));

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Transmit parameters
   --    @Req : DRE-DMX-FW-REQ-0590
   -- ------------------------------------------------------------------------------------------------------
constant c_SC_CTRL_DTA_W      : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11000000"                ; --! Science data, control word value: Data Word
constant c_SC_CTRL_ADC_DMP    : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11000010"                ; --! Science data, control word value: SQUID MUX ADC dump packet first word
constant c_SC_CTRL_SC_DTA     : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11001000"                ; --! Science data, control word value: Science data packet first word
constant c_SC_CTRL_RAS_VLD    : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11001010"                ; --! Science data, control word value: RAS Data valid packet first word
constant c_SC_CTRL_TST_PAT    : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11100000"                ; --! Science data, control word value: Test pattern packet first word
constant c_SC_CTRL_ERRS       : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11100010"                ; --! Science data, control word value: Error signal first word
constant c_SC_CTRL_EOD        : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "11101010"                ; --! Science data, control word value: End of Data
constant c_SC_CTRL_IDLE       : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := "00000000"                ; --! Science data, control word value: Idle

constant c_SC_DATA_IDLE_VAL   : std_logic_vector(c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB-1 downto 0) := x"0000"  ; --! Science data: word sent when Telemetry mode on one column is in Idle

end pkg_project;
