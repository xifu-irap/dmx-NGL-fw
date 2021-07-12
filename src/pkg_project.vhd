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

library work;
use     work.pkg_func_math.all;

package pkg_project is

   -- ------------------------------------------------------------------------------------------------------
   --    System parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_FF_RESET_NB        : integer   := 2                                                              ; --! Flip-Flop number used for internal reset
constant c_FF_RSYNC_NB        : integer   := 2                                                              ; --! Flip-Flop number used for FPGA input resynchronization

constant c_CLK_REF_MULT       : integer   := 1                                                              ; --! Reference Clock multiplier frequency factor
constant c_CLK_MULT           : integer   := 1                                                              ; --! System Clock multiplier frequency factor
constant c_CLK_ADC_MULT       : integer   := 2                                                              ; --! ADC Clock multiplier frequency factor
constant c_CLK_DAC_MULT       : integer   := 2                                                              ; --! DAC Clock multiplier frequency factor

   -- ------------------------------------------------------------------------------------------------------
   --  c_PLL_MAIN_VCO_MULT conditions to respect:
   --    - NG-LARGE:
   --       * Must be a common multiplier with c_CLK_REF_MULT, c_CLK_ADC_MULT, c_CLK_DAC_MULT and c_CLK_MULT
   --       * Vco frequency range : 200 MHz <= c_PLL_MAIN_VCO_MULT * c_CLK_COM_FREQ    <= 800 MHz
   --       * WFG pattern size    :            c_PLL_MAIN_VCO_MULT/  c_CLK_REF_MULT    <= 16
   -- ------------------------------------------------------------------------------------------------------
constant c_PLL_MAIN_VCO_MULT  : integer   := 12                                                             ; --! PLL main VCO multiplier frequency factor

constant c_CLK_COM_FREQ       : integer   := 60000000                                                       ; --! Clock frequency common to main clocks (Hz)
constant c_CLK_REF_FREQ       : integer   := c_CLK_REF_MULT      * c_CLK_COM_FREQ                           ; --! Reference Clock frequency (Hz)
constant c_CLK_FREQ           : integer   := c_CLK_MULT          * c_CLK_COM_FREQ                           ; --! System Clock frequency (Hz)
constant c_CLK_ADC_FREQ       : integer   := c_CLK_ADC_MULT      * c_CLK_COM_FREQ                           ; --! ADC Clock frequency (Hz)
constant c_CLK_DAC_FREQ       : integer   := c_CLK_DAC_MULT      * c_CLK_COM_FREQ                           ; --! DAC Clock frequency (Hz)
constant c_PLL_MAIN_VCO_FREQ  : integer   := c_PLL_MAIN_VCO_MULT * c_CLK_COM_FREQ                           ; --! PLL main VCO frequency (Hz)

   -- ------------------------------------------------------------------------------------------------------
   --    Interface parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_BRD_REF_S          : integer   := 5                                                              ; --! Board reference
constant c_BRD_MODEL_S        : integer   := 2                                                              ; --! Board model

constant c_SQ1_ADC_DATA_S     : integer   := 14                                                             ; --! SQUID1 ADC data size bus
constant c_SQ1_DAC_DATA_S     : integer   := 14                                                             ; --! SQUID1 DAC data size bus
constant c_SQ2_DAC_MUX_S      : integer   := 3                                                              ; --! SQUID2 DAC  Multiplexer size
constant c_SC_DATA_SER_W_S    : integer   := 8                                                              ; --! Science data serial word size
constant c_SC_DATA_SER_NB     : integer   := 2                                                              ; --! Science data serial link number by DEMUX column
constant c_HK1_MUX_S          : integer   := 3                                                              ; --! HouseKeeping 1 Multiplexer size

constant c_EP_CMD_S           : integer   := 32                                                             ; --! EP command bus size
constant c_EP_SPI_CPOL        : std_logic := '0'                                                            ; --! EP SPI Clock polarity
constant c_EP_SPI_CPHA        : std_logic := '0'                                                            ; --! EP SPI Clock phase
constant c_EP_SPI_WD_S        : integer   := c_EP_CMD_S/2                                                   ; --! EP SPI Data word size (receipt/transmit)
constant c_EP_SPI_TX_WD_NB_S  : integer   := 1                                                              ; --! EP SPI Data word to transmit number size
constant c_EP_SPI_RX_WD_NB_S  : integer   := 2                                                              ; --! EP SPI Receipted data word number size (more than expected, command length control)

   -- ------------------------------------------------------------------------------------------------------
   --    Inputs default value at reset
   -- ------------------------------------------------------------------------------------------------------
constant c_I_SPI_DATA_DEF     : std_logic := '0'                                                            ; --! SPI data input default value at reset
constant c_I_SPI_SCLK_DEF     : std_logic := c_EP_SPI_CPOL                                                  ; --! SPI Serial Clock input default value at reset
constant c_I_SPI_CS_N_DEF     : std_logic := '1'                                                            ; --! SPI Chip Select input default value at reset
constant c_I_SQ1_ADC_DATA_DEF : std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0):= (others =>'0')              ; --! SQUID1 ADC data input default value at reset
constant c_I_SQ1_ADC_OOR_DEF  : std_logic := '0'                                                            ; --! SQUID1 ADC out of range input default value at reset
constant c_I_SYNC_DEF         : std_logic := '0'                                                            ; --! Pixel sequence synchronization default value at reset

   -- ------------------------------------------------------------------------------------------------------
   --    Project parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_FW_VERSION         : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)    := x"0001"                    ; --! Firmware version
constant c_DMX_MUX_FACT       : integer   := 34                                                             ; --! DEMUX: multiplexing factor
constant c_DMX_NB_COL         : integer   := 4                                                              ; --! DEMUX: column number
constant c_DRE_PIX_NPER_COM   : integer   := 4                                                              ; --! DRE: period number of clock common to main clocks allocated to one sequence pixel (TBC)

   -- ------------------------------------------------------------------------------------------------------
   --    SQUID1 ADC parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_ADC_DATA_NPER      : integer   := 13                                                             ; --! Clock period number between the acquisition start and data output by the ADC
constant c_ADC_DATA_IO_NPER   : integer   := 1                                                              ; --! Clock period number applied on FPGA inputs for phasing ADC data with o_clk_sq1_adc

constant c_PIX_SEQ_NPER_ADC   : integer   := c_CLK_ADC_MULT * c_DRE_PIX_NPER_COM                            ; --! Period number of ADC clock allocated to one sequence pixel

   -- ------------------------------------------------------------------------------------------------------
   --    Global types
   -- ------------------------------------------------------------------------------------------------------
type     t_sq1_adc_data_v      is array (natural range <>) of std_logic_vector(c_SQ1_ADC_DATA_S-1  downto 0); --! SQUID1 ADC data vector type
type     t_sc_data_w           is array (natural range <>) of std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0); --! Science data word type

end pkg_project;
