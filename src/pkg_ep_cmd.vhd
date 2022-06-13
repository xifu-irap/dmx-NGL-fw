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
--!   @file                   pkg_ep_cmd.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command constants
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

package pkg_ep_cmd is

   -- ------------------------------------------------------------------------------------------------------
   --    EP command
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ADD_RW_R    : std_logic := '0'                                                            ; --! EP command: Address, Read/Write field Read value
constant c_EP_CMD_ADD_RW_W    : std_logic := not(c_EP_CMD_ADD_RW_R)                                         ; --! EP command: Address, Read/Write field Write value

constant c_EP_CMD_WD_ADD_POS  : integer   := 0                                                              ; --! EP command: Address word position
constant c_EP_CMD_WD_DATA_POS : integer   := 1                                                              ; --! EP command: Data word position
constant c_EP_CMD_ADD_RW_POS  : integer   := 0                                                              ; --! EP command: Address, Read/Write field position

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Status error
   --    @Req : REG_Status
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ERR_SET     : std_logic := '0'                                                            ; --! EP command: Status, error set value
constant c_EP_CMD_ERR_CLR     : std_logic := not(c_EP_CMD_ERR_SET)                                          ; --! EP command: Status, error clear value

constant c_EP_CMD_ERR_ADD_POS : integer   := 15                                                             ; --! EP command: Status, error position invalid address
constant c_EP_CMD_ERR_LGT_POS : integer   := 14                                                             ; --! EP command: Status, error position SPI command length not complete
constant c_EP_CMD_ERR_WRT_POS : integer   := 13                                                             ; --! EP command: Status, error position try to write in a read only register
constant c_EP_CMD_ERR_OUT_POS : integer   := 12                                                             ; --! EP command: Status, error position SPI data out of range
constant c_EP_CMD_ERR_NIN_POS : integer   := 11                                                             ; --! EP command: Status, error position parameter to read not initialized yet
constant c_EP_CMD_ERR_DIS_POS : integer   := 10                                                             ; --! EP command: Status, error position last SPI command discarded

constant c_EP_CMD_ERR_FST_POS : integer   := 10                                                             ; --! EP command: Status, error first position

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: register reading position
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_POS_AQMDE   : integer   := 0                                                              ; --! EP command: Position, DATA_ACQ_MODE
constant c_EP_CMD_POS_SMFMD   : integer   := c_EP_CMD_POS_AQMDE   + 1                                       ; --! EP command: Position, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_POS_SAOFM   : integer   := c_EP_CMD_POS_SMFMD   + 1                                       ; --! EP command: Position, SQ_AMP_OFFSET_MODE
constant c_EP_CMD_POS_STATUS  : integer   := c_EP_CMD_POS_SAOFM   + 1                                       ; --! EP command: Position, Status
constant c_EP_CMD_POS_FW_VER  : integer   := c_EP_CMD_POS_STATUS  + 1                                       ; --! EP command: Position, Firmware Version
constant c_EP_CMD_POS_HW_VER  : integer   := c_EP_CMD_POS_FW_VER  + 1                                       ; --! EP command: Position, Hardware Version
constant c_EP_CMD_POS_SMFB0   : integer   := c_EP_CMD_POS_HW_VER  + 1                                       ; --! EP command: Position, CY_MUX_SQ_FB0
constant c_EP_CMD_POS_SMFBM   : integer   := c_EP_CMD_POS_SMFB0   + 1                                       ; --! EP command: Position, CY_MUX_SQ_FB_MODE
constant c_EP_CMD_POS_SAOFF   : integer   := c_EP_CMD_POS_SMFBM   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_FINE
constant c_EP_CMD_POS_SAOFC   : integer   := c_EP_CMD_POS_SAOFF   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_POS_SAOFL   : integer   := c_EP_CMD_POS_SAOFC   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_LSB
constant c_EP_CMD_POS_SMFBD   : integer   := c_EP_CMD_POS_SAOFL   + 1                                       ; --! EP command: Position, CY_MUX_SQ_FB_DELAY
constant c_EP_CMD_POS_SAODD   : integer   := c_EP_CMD_POS_SMFBD   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_CMD_POS_SAOMD   : integer   := c_EP_CMD_POS_SAODD   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_CMD_POS_PLSSH   : integer   := c_EP_CMD_POS_SAOMD   + 1                                       ; --! EP command: Position, CY_FB1_PULSE_SHAPING
constant c_EP_CMD_POS_PLSSS   : integer   := c_EP_CMD_POS_PLSSH   + 1                                       ; --! EP command: Position, CY_FB1_PULSE_SHAPING_SELECTION

constant c_EP_CMD_POS_LAST    : integer   := c_EP_CMD_POS_PLSSS   + 1                                       ; --! EP command: last position
constant c_EP_CMD_REG_MX_STNB : integer   := 3                                                              ; --! EP command: Register multiplexer stage number
constant c_EP_CMD_REG_MX_STIN : t_int_arr(0 to c_EP_CMD_REG_MX_STNB)   := (24, 30, 32, 33)                  ; --! EP command: Register inputs by multiplexer stage (accumulated)
constant c_EP_CMD_REG_MX_INNB : t_int_arr(0 to c_EP_CMD_REG_MX_STNB-1) := ( 4,  3,  2)                      ; --! EP command: Register inputs by multiplexer

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Address
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ADD_COLPOSL : integer   := 12                                                             ; --! EP command: Address column position low
constant c_EP_CMD_ADD_COLPOSH : integer   := c_EP_CMD_ADD_COLPOSL + log2_ceil(c_NB_COL) - 1                 ; --! EP command: Address column position high

constant c_EP_CMD_ADD_AQMDE   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4000"                        ; --! EP command: Address, DATA_ACQ_MODE
constant c_EP_CMD_ADD_SMFMD   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4001"                        ; --! EP command: Address, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_ADD_SAOFM   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4002"                        ; --! EP command: Address, SQ_AMP_OFFSET_MODE

constant c_EP_CMD_ADD_STATUS  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6000"                        ; --! EP command: Address, Status
constant c_EP_CMD_ADD_FW_VER  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6001"                        ; --! EP command: Address, Firmware Version
constant c_EP_CMD_ADD_HW_VER  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6002"                        ; --! EP command: Address, Hardware Version

constant c_EP_CMD_ADD_SMFB0   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0200", x"1200", x"2200", x"3200")                                       ; --! EP command: Address basis, CY_MUX_SQ_FB0
constant c_EP_CMD_ADD_SMFBM   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0300", x"1300", x"2300", x"3300")                                       ; --! EP command: Address basis, CY_MUX_SQ_FB_MODE
constant c_EP_CMD_ADD_SAOFF   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0400", x"1400", x"2400", x"3400")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_FINE
constant c_EP_CMD_ADD_SAOFC   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0422", x"1422", x"2422", x"3422")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_ADD_SAOFL   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0423", x"1423", x"2423", x"3423")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_LSB
constant c_EP_CMD_ADD_SMFBD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0500", x"1500", x"2500", x"3500")                                       ; --! EP command: Address basis, CY_MUX_SQ_FB_DELAY
constant c_EP_CMD_ADD_SAODD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0501", x"1501", x"2501", x"3501")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_CMD_ADD_SAOMD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0502", x"1502", x"2502", x"3502")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_CMD_ADD_PLSSH   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0800", x"1800", x"2800", x"3800")                                       ; --! EP command: Address basis, CY_FB1_PULSE_SHAPING
constant c_EP_CMD_ADD_PLSSS   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0880", x"1880", x"2880", x"3880")                                       ; --! EP command: Address basis, CY_FB1_PULSE_SHAPING_SELECTION

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Table and Memory Address size
   -- ------------------------------------------------------------------------------------------------------
constant c_TAB_SMFB0_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_MUX_SQ_FB0
constant c_MEM_SMFB0_ADD_S    : integer   := log2_ceil(c_TAB_SMFB0_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_MUX_SQ_FB0

constant c_TAB_SMFBM_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_MUX_SQ_FB_MODE
constant c_MEM_SMFBM_ADD_S    : integer   := log2_ceil(c_TAB_SMFBM_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_MUX_SQ_FB_MODE

constant c_TAB_SAOFF_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_AMP_SQ_OFFSET_FINE
constant c_MEM_SAOFF_ADD_S    : integer   := log2_ceil(c_TAB_SAOFF_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_AMP_SQ_OFFSET_FINE

constant c_TAB_PLSSH_NW       : integer   := c_PIXEL_DAC_NB_CYC                                             ; --! Table number word, CY_FB1_PULSE_SHAPING
constant c_TAB_PLSSH_S        : integer   := log2_ceil(c_TAB_PLSSH_NW)                                      ; --! Table size bus,    CY_FB1_PULSE_SHAPING
constant c_MEM_PLSSH_ADD_S    : integer   := log2_ceil(c_DAC_PLS_SHP_SET_NB) + c_TAB_PLSSH_S                ; --! Address size memory without ping-pong buffer bit, CY_FB1_PULSE_SHAPING
constant c_MEM_PLSSH_ADD_END  : integer   := (c_DAC_PLS_SHP_SET_NB-1) * 2**c_TAB_PLSSH_S + c_TAB_PLSSH_NW-1 ; --! Address end, CY_FB1_PULSE_SHAPING

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Write register authorization
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_AUTH_AQMDE  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, DATA_ACQ_MODE
constant c_EP_CMD_AUTH_SMFMD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_AUTH_SAOFM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ_AMP_OFFSET_MODE

constant c_EP_CMD_AUTH_STATUS : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Status
constant c_EP_CMD_AUTH_FW_VER : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Firmware Version
constant c_EP_CMD_AUTH_HW_VER : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Hardware Version

constant c_EP_CMD_AUTH_SMFB0  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_FB0
constant c_EP_CMD_AUTH_SMFBM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_FB_MODE
constant c_EP_CMD_AUTH_SAOFF  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_FINE
constant c_EP_CMD_AUTH_SAOFC  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_AUTH_SAOFL  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_LSB
constant c_EP_CMD_AUTH_SMFBD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_FB_DELAY
constant c_EP_CMD_AUTH_SAODD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_CMD_AUTH_SAOMD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_CMD_AUTH_PLSSH  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB1_PULSE_SHAPING
constant c_EP_CMD_AUTH_PLSSS  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB1_PULSE_SHAPING_SELECTION

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data field bus size
   -- ------------------------------------------------------------------------------------------------------
constant c_DFLD_AQMDE_S       : integer   :=  3                                                             ; --! EP command: Data field, DATA_ACQ_MODE bus size
constant c_DFLD_SMFMD_COL_S   : integer   :=  1                                                             ; --! EP command: Data field, SQ_MUX_FB_ON_OFF mode bus size
constant c_DFLD_SAOFM_COL_S   : integer   :=  2                                                             ; --! EP command: Data field, SQ_AMP_OFFSET_MODE bus size
constant c_DFLD_SMFB0_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_MUX_SQ_FB0 bus size
constant c_DFLD_SMFBM_PIX_S   : integer   :=  2                                                             ; --! EP command: Data field, CY_MUX_SQ_FB_MODE bus size
constant c_DFLD_SAOFF_PIX_S   : integer   :=  c_SQA_DAC_MUX_S                                               ; --! EP command: Data field, CY_AMP_SQ_OFFSET_FINE bus size
constant c_DFLD_SAOFC_COL_S   : integer   :=  c_SQA_DAC_DATA_S                                              ; --! EP command: Data field, CY_AMP_SQ_OFFSET_COARSE bus size
constant c_DFLD_SAOFL_COL_S   : integer   :=  c_SQA_DAC_DATA_S                                              ; --! EP command: Data field, CY_AMP_SQ_OFFSET_LSB bus size
constant c_DFLD_SMFBD_COL_S   : integer   :=  5                                                             ; --! EP command: Data field, CY_MUX_SQ_FB_DELAY bus size
constant c_DFLD_SAODD_COL_S   : integer   :=  10                                                            ; --! EP command: Data field, CY_AMP_SQ_OFFSET_DAC_DELAY bus size
constant c_DFLD_SAOMD_COL_S   : integer   :=  5                                                             ; --! EP command: Data field, CY_AMP_SQ_OFFSET_MUX_DELAY bus size
constant c_DFLD_PLSSH_PLS_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_FB1_PULSE_SHAPING bus size
constant c_DFLD_PLSSS_PLS_S   : integer   :=  log2_ceil(c_DAC_PLS_SHP_SET_NB)                               ; --! EP command: Data field, CY_FB1_PULSE_SHAPING_SELECTION bus size

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data state
   -- ------------------------------------------------------------------------------------------------------
constant c_DST_AQMDE_IDLE     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "000"                         ; --! EP command: Data state, DATA_ACQ_MODE "Idle"
constant c_DST_AQMDE_SCIE     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "001"                         ; --! EP command: Data state, DATA_ACQ_MODE "Science"
constant c_DST_AQMDE_ERRS     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "010"                         ; --! EP command: Data state, DATA_ACQ_MODE "Error Signal"
constant c_DST_AQMDE_DUMP     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "100"                         ; --! EP command: Data state, DATA_ACQ_MODE "Dump"
constant c_DST_AQMDE_TEST     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "111"                         ; --! EP command: Data state, DATA_ACQ_MODE "Test Pattern"

constant c_DST_SMFMD_OFF      : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0):= "0"                       ; --! EP command: Data state, SQ_MUX_FB_ON_OFF "Off"
constant c_DST_SMFMD_ON       : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0):= "1"                       ; --! EP command: Data state, SQ_MUX_FB_ON_OFF "On"

constant c_DST_SAOFM_OFF      : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "00"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Off"
constant c_DST_SAOFM_OFFSET   : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "01"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Offset"
constant c_DST_SAOFM_CLOSE    : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "10"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Closed Loop"
constant c_DST_SAOFM_TEST     : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "11"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Test Pattern"

constant c_DST_SMFBM_OPEN     : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0):= "00"                      ; --! EP command: Data state, CY_MUX_SQ_FB_MODE "Open Loop"
constant c_DST_SMFBM_CLOSE    : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0):= "01"                      ; --! EP command: Data state, CY_MUX_SQ_FB_MODE "Closed Loop"
constant c_DST_SMFBM_TEST     : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0):= "10"                      ; --! EP command: Data state, CY_MUX_SQ_FB_MODE "Test Pattern"

constant c_DST_PLSSS_PLS_0    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "00"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 0
constant c_DST_PLSSS_PLS_1    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "01"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 1
constant c_DST_PLSSS_PLS_2    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "10"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 2
constant c_DST_PLSSS_PLS_3    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "11"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 3

constant c_DST_SQADAC_NORM    : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "00"                        ; --! EP command: Data state, SQUID AMP DACs mode "Normal"
constant c_DST_SQADAC_PD1K    : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "01"                        ; --! EP command: Data state, SQUID AMP DACs mode "Power down 1k to GND"
constant c_DST_SQADAC_PD100K  : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "10"                        ; --! EP command: Data state, SQUID AMP DACs mode "Power down 100k to GND"
constant c_DST_SQADAC_PDZ     : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "11"                        ; --! EP command: Data state, SQUID AMP DACs mode "Power down High Z"

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Default value
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_DEF_AQMDE   : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)      := c_DST_AQMDE_IDLE        ; --! EP command: Default value, DATA_ACQ_MODE

constant c_EP_CMD_DEF_SMFMD   : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)  := c_DST_SMFMD_OFF         ; --! EP command: Default value, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_DEF_SAOFM   : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)  := c_DST_SAOFM_OFF         ; --! EP command: Default value, SQ_AMP_OFFSET_MODE

constant c_EP_CMD_DEF_SMFB0   : t_int_arr(0 to 2*c_TAB_SMFB0_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_MUX_SQ_FB0 memory with ping-pong buffer bit

constant c_EP_CMD_DEF_SMFBM   : t_int_arr(0 to 2*c_TAB_SMFBM_NW-1) :=
                                (others => to_integer(unsigned(c_DST_SMFBM_OPEN)))                          ; --! EP command: Default value, CY_MUX_SQ_FB_MODE memory with ping-pong buffer bit

constant c_EP_CMD_DEF_SAOFF   : t_int_arr(0 to 2*c_TAB_SAOFF_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_AMP_SQ_OFFSET_FINE memory with ping-pong buffer bit
constant c_EP_CMD_DEF_SAOFC   : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(c_SQA_DAC_MDL_POINT ,c_DFLD_SAOFC_COL_S))      ; --! EP command: Default value, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_DEF_SAOFL   : std_logic_vector(c_DFLD_SAOFL_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SAOFL_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_LSB

constant c_EP_CMD_DEF_SMFBD   : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SMFBD_COL_S))                        ; --! EP command: Default value, CY_MUX_SQ_FB_DELAY

constant c_EP_CMD_DEF_SAODD   : std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SAODD_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_DAC_DELAY

constant c_EP_CMD_DEF_SAOMD   : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SAOMD_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_MUX_DELAY

constant c_EP_CMD_DEF_PLSSH   : t_int_arr(0 to 2**(c_MEM_PLSSH_ADD_S+1)-1) :=
                                (37364, 21302, 12145,  6924,  3948,  2251,  1283,   732,
                                   417,   238,   136,    77,    44,    25,    14,     8,
                                     5,     3,     2,     1,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 32681, 16297,  8127,  4053,  2021,  1008,   503,   251,
                                   125,    62,    31,    15,     8,     4,     2,     1,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 29041, 12869,  5703,  2527,  1120,   496,   220,    97,
                                    43,    19,     8,     4,     2,     1,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 26131, 10419,  4154,  1657,   661,   263,   105,    42,
                                    17,     7,     3,     1,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 37364, 21302, 12145,  6924,  3948,  2251,  1283,   732,
                                   417,   238,   136,    77,    44,    25,    14,     8,
                                     5,     3,     2,     1,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 32681, 16297,  8127,  4053,  2021,  1008,   503,   251,
                                   125,    62,    31,    15,     8,     4,     2,     1,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 29041, 12869,  5703,  2527,  1120,   496,   220,    97,
                                    43,    19,     8,     4,     2,     1,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 26131, 10419,  4154,  1657,   661,   263,   105,    42,
                                    17,     7,     3,     1,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0)                    ; --! EP command: Default value, CY_FB1_PULSE_SHAPING mem. (Low filter fc=15/20/25/30 MHz)

constant c_EP_CMD_DEF_PLSSS   : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= c_DST_PLSSS_PLS_1         ; --! EP command: Default value, CY_FB1_PULSE_SHAPING_SELECTION

end pkg_ep_cmd;
