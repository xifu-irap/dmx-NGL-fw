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
constant c_SQA_SPI_CPOL       : std_logic := '0'                                                            ; --! SQUID AMP DAC SPI: Clock polarity
constant c_SQA_SPI_CPHA       : std_logic := '1'                                                            ; --! SQUID AMP DAC SPI: Clock phase
constant c_SQA_SPI_SER_WD_S   : integer   := c_SQA_DAC_DATA_S + c_SQA_DAC_MODE_S + 2                        ; --! SQUID AMP DAC SPI: Data bus size
constant c_SQA_SPI_SCLK_H     : integer   := div_ceil(c_CLK_ADC_FREQ * 13, 1000000000)                      ; --! SQUID AMP DAC SPI: Number of clock period for elaborating SPI Serial Clock high level
constant c_SQA_SPI_SCLK_L     : integer   := maximum(c_SQA_SPI_SCLK_H,
                                                     div_ceil(c_CLK_ADC_FREQ, 30000000) - c_SQA_SPI_SCLK_H) ; --! SQUID AMP DAC SPI: Number of clock period for elaborating SPI Serial Clock low level
constant c_SQA_DAC_MUX_S      : integer   := 3                                                              ; --! SQUID AMP DAC Multiplexer size

constant c_SC_DATA_SER_W_S    : integer   := 8                                                              ; --! Science data serial word size
constant c_SC_DATA_SER_NB     : integer   := 2                                                              ; --! Science data serial link number by DEMUX column

constant c_HK_SPI_CPOL        : std_logic := '1'                                                            ; --! HK SPI: Clock polarity
constant c_HK_SPI_CPHA        : std_logic := '1'                                                            ; --! HK SPI: Clock phase
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
constant c_EP_SPI_CPOL        : std_logic := '0'                                                            ; --! EP SPI Clock polarity
constant c_EP_SPI_CPHA        : std_logic := '0'                                                            ; --! EP SPI Clock phase
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
constant c_I_SPI_DATA_DEF     : std_logic := '0'                                                            ; --! SPI data input default value at reset
constant c_I_SPI_SCLK_DEF     : std_logic := c_EP_SPI_CPOL                                                  ; --! SPI Serial Clock input default value at reset
constant c_I_SPI_CS_N_DEF     : std_logic := '1'                                                            ; --! SPI Chip Select input default value at reset
constant c_I_SQM_ADC_DATA_DEF : std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_SQM_ADC_DATA_S))                          ; --! SQUID MUX ADC data input default value at reset
constant c_I_SQM_ADC_OOR_DEF  : std_logic := '0'                                                            ; --! SQUID MUX ADC out of range input default value at reset
constant c_I_SYNC_DEF         : std_logic := '1'                                                            ; --! Pixel sequence synchronization default value at reset

constant c_CMD_CK_SQM_ADC_DEF : std_logic := '0'                                                            ; --! SQUID MUX ADC clock switch command default value at reset
constant c_CMD_CK_SQM_DAC_DEF : std_logic := '0'                                                            ; --! SQUID MUX DAC clock switch command default value at reset

constant c_MEM_STR_ADD_PP_DEF : std_logic := '0'                                                            ; --! Memory storage parameters, ping-pong buffer bit for address default value at reset

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

constant c_TST_PAT_COEF_NB    : integer   := 3                                                              ; --! Test pattern: coefficient by region number
constant c_TST_PAT_RGN_NB     : integer   := 5                                                              ; --! Test pattern: region number

constant c_ERR_NIN_MX_STNB    : integer   := 2                                                              ; --! Error parameter to read not initialized yet: Multiplexer stage number
constant c_ERR_NIN_MX_STIN    : t_int_arr(0 to c_ERR_NIN_MX_STNB)   := (16, 20, 21)                         ; --! Error parameter to read not initialized yet: Inputs by multiplexer stage (accumulated)
constant c_ERR_NIN_MX_INNB    : t_int_arr(0 to c_ERR_NIN_MX_STNB-1) := ( 4,  4)                             ; --! Error parameter to read not initialized yet: Inputs by multiplexer

constant c_DLFLG_MX_STNB      : integer   := 3                                                              ; --! Delock flag: Multiplexer stage number
constant c_DLFLG_MX_STIN      : t_int_arr(0 to c_DLFLG_MX_STNB)   := (36, 45, 48, 49)                       ; --! Delock flag: Inputs by multiplexer stage (accumulated)
constant c_DLFLG_MX_INNB      : t_int_arr(0 to c_DLFLG_MX_STNB-1) := ( 4,  3,  3)                           ; --! Delock flag: Inputs by multiplexer

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
constant c_ADC_SMP_AVE_TAB    : t_slv_arr(0 to 2**c_ADC_SMP_AVE_ADD_S-1)(c_ASP_CF_S-1 downto 0) :=
                                (std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  1),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  2),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  3),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  4),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  5),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  6),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  7),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  8),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1),  9),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 10),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 11),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 12),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 13),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 14),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 15),c_ASP_CF_S)),
                                 std_logic_vector(to_unsigned(div_round(2**(c_ASP_CF_S-1), 16),c_ASP_CF_S))); --! ADC sample number for averaging table

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
constant c_SAD_SYNC_DATA_NPER : integer := c_DAC_SYNC_RDY_NPER + c_DAC_SYNC_RE_NPER + c_SAD_PRC_NPER        ; --! DAC clock period number for stalling sending data end to pixel sequence synchronization

constant c_SQA_PLS_CNT_MX_VAL : integer := c_PIXEL_DAC_NB_CYC - 2                                           ; --! SQUID AMP, Pulse counter: maximal value
constant c_SQA_PLS_CNT_INIT   : integer := c_SQA_PLS_CNT_MX_VAL - c_SAM_SYNC_DATA_NPER                      ; --! SQUID AMP, Pulse counter: initialization value
constant c_SQA_PLS_CNT_S      : integer := log2_ceil(c_SQA_PLS_CNT_MX_VAL + 1) + 1                          ; --! SQUID AMP, Pulse counter: size bus (signed)

constant c_SQA_PXL_POS_MX_VAL : integer := c_MUX_FACT - 2                                                   ; --! SQUID AMP, Pixel position: maximal value
constant c_SQA_PXL_POS_INIT   : integer := -1                                                               ; --! SQUID AMP, Pixel position: initialization value
constant c_SQA_PXL_POS_S      : integer := log2_ceil(c_SQA_PXL_POS_MX_VAL+1)+1                              ; --! SQUID AMP, Pixel position: size bus (signed)

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
