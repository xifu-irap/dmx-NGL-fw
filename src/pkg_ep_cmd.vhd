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
constant c_EP_CMD_ERR_SET     : std_logic := '1'                                                            ; --! EP command: Status, error set value
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
constant c_EP_CMD_POS_TM_MODE : integer   := 0                                                              ; --! EP command: Position, TM_MODE
constant c_EP_CMD_POS_SQ1FBMD : integer   := c_EP_CMD_POS_TM_MODE + 1                                       ; --! EP command: Position, SQ1_FB_MODE
constant c_EP_CMD_POS_SQ2FBMD : integer   := c_EP_CMD_POS_SQ1FBMD + 1                                       ; --! EP command: Position, SQ2_FB_MODE
constant c_EP_CMD_POS_STATUS  : integer   := c_EP_CMD_POS_SQ2FBMD + 1                                       ; --! EP command: Position, Status
constant c_EP_CMD_POS_VERSION : integer   := c_EP_CMD_POS_STATUS  + 1                                       ; --! EP command: Position, Version
constant c_EP_CMD_POS_S1FB0   : integer   := c_EP_CMD_POS_VERSION + 1                                       ; --! EP command: Position, CY_SQ1_FB0
constant c_EP_CMD_POS_S1FBM   : integer   := c_EP_CMD_POS_S1FB0   + 1                                       ; --! EP command: Position, CY_SQ1_FB_MODE
constant c_EP_CMD_POS_S2LKP   : integer   := c_EP_CMD_POS_S1FBM   + 1                                       ; --! EP command: Position, CY_SQ2_PXL_LOCKPOINT
constant c_EP_CMD_POS_S2LSB   : integer   := c_EP_CMD_POS_S2LKP   + 1                                       ; --! EP command: Position, CY_SQ2_PXL_LOCKPOINT_LSB
constant c_EP_CMD_POS_S2OFF   : integer   := c_EP_CMD_POS_S2LSB   + 1                                       ; --! EP command: Position, CY_SQ2_PXL_LOCKPOINT_OFFSET
constant c_EP_CMD_POS_S1FBD   : integer   := c_EP_CMD_POS_S2OFF   + 1                                       ; --! EP command: Position, CY_FB_SQ1_DELAY
constant c_EP_CMD_POS_S2FBD   : integer   := c_EP_CMD_POS_S1FBD   + 1                                       ; --! EP command: Position, CY_FB_SQ2_DELAY
constant c_EP_CMD_POS_PLSSH   : integer   := c_EP_CMD_POS_S2FBD   + 1                                       ; --! EP command: Position, CY_FB1_PULSE_SHAPING

constant c_EP_CMD_POS_LAST    : integer   := c_EP_CMD_POS_PLSSH   + 1                                       ; --! EP command: last position
constant c_EP_CMD_REG_MX_STNB : integer   := 3                                                              ; --! EP command: Register multiplexer stage number
constant c_EP_CMD_REG_MX_STIN : t_int_arr(0 to c_EP_CMD_REG_MX_STNB)   := (24, 30, 32, 33)                  ; --! EP command: Register inputs by multiplexer stage (accumulated)
constant c_EP_CMD_REG_MX_INNB : t_int_arr(0 to c_EP_CMD_REG_MX_STNB-1) := ( 4,  3,  2)                      ; --! EP command: Register inputs by multiplexer

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Address
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ADD_COLPOSL : integer   := 12                                                             ; --! EP command: Address column position low
constant c_EP_CMD_ADD_COLPOSH : integer   := c_EP_CMD_ADD_COLPOSL + log2_ceil(c_NB_COL) - 1                 ; --! EP command: Address column position high

constant c_EP_CMD_ADD_TM_MODE : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4000"                        ; --! EP command: Address, TM_MODE
constant c_EP_CMD_ADD_SQ1FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4001"                        ; --! EP command: Address, SQ1_FB_MODE
constant c_EP_CMD_ADD_SQ2FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4002"                        ; --! EP command: Address, SQ2_FB_MODE

constant c_EP_CMD_ADD_STATUS  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6000"                        ; --! EP command: Address, Status
constant c_EP_CMD_ADD_VERSION : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6001"                        ; --! EP command: Address, Version

constant c_EP_CMD_ADD_S1FB0   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0200", x"1200", x"2200", x"3200")                                       ; --! EP command: Address basis, CY_SQ1_FB0
constant c_EP_CMD_ADD_S1FBM   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0300", x"1300", x"2300", x"3300")                                       ; --! EP command: Address basis, CY_SQ1_FB_MODE
constant c_EP_CMD_ADD_S2LKP   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0400", x"1400", x"2400", x"3400")                                       ; --! EP command: Address basis, CY_SQ2_PXL_LOCKPOINT
constant c_EP_CMD_ADD_S2LSB   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0422", x"1422", x"2422", x"3422")                                       ; --! EP command: Address basis, CY_SQ2_PXL_LOCKPOINT_LSB
constant c_EP_CMD_ADD_S2OFF   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0423", x"1423", x"2423", x"3423")                                       ; --! EP command: Address basis, CY_SQ2_PXL_LOCKPOINT_OFFSET
constant c_EP_CMD_ADD_S1FBD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0500", x"1500", x"2500", x"3500")                                       ; --! EP command: Address basis, CY_FB_SQ1_DELAY
constant c_EP_CMD_ADD_S2FBD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0501", x"1501", x"2501", x"3501")                                       ; --! EP command: Address basis, CY_FB_SQ2_DELAY
constant c_EP_CMD_ADD_PLSSH   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0800", x"1800", x"2800", x"3800")                                       ; --! EP command: Address basis, CY_FB1_PULSE_SHAPING

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Table and Memory Address size
   -- ------------------------------------------------------------------------------------------------------
constant c_TAB_S1FB0_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word: CY_SQ1_FB0
constant c_MEM_S1FB0_ADD_S    : integer   := log2_ceil(c_TAB_S1FB0_NW)                                      ; --! Memory SQUID1 Feedback value in open loop: address size without ping-pong buffer bit

constant c_TAB_S1FBM_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word: CY_SQ1_FB_MODE
constant c_MEM_S1FBM_ADD_S    : integer   := log2_ceil(c_TAB_S1FBM_NW)                                      ; --! Memory SQUID1 Feedback Mode: address size without ping-pong buffer bit

constant c_TAB_S2LKP_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word: CY_SQ2_PXL_LOCKPOINT
constant c_MEM_S2LKP_ADD_S    : integer   := log2_ceil(c_TAB_S2LKP_NW)                                      ; --! Memory SQUID2 Pixel Lockpoint: address size without ping-pong buffer bit

constant c_TAB_PLSSH_NW       : integer   := c_PIXEL_DAC_NB_CYC                                             ; --! Table number word: CY_FB1_PULSE_SHAPING
constant c_TAB_PLSSH_S        : integer   := log2_ceil(c_TAB_PLSSH_NW)                                      ; --! Table size bus:    CY_FB1_PULSE_SHAPING
constant c_MEM_PLSSH_ADD_S    : integer   := log2_ceil(c_DAC_PLS_SHP_SET_NB) + c_TAB_PLSSH_S                ; --! Memory pulse shaping coefficient: address size without ping-pong buffer bit
constant c_MEM_PLSSH_ADD_END  : integer   := (c_DAC_PLS_SHP_SET_NB-1) * 2**c_TAB_PLSSH_S + c_TAB_PLSSH_NW-1 ; --! Memory pulse shaping coefficient: address end

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Write register authorization
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_AUTH_TM_MODE: std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, TM_MODE
constant c_EP_CMD_AUTH_SQ1FBMD: std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ1_FB_MODE
constant c_EP_CMD_AUTH_SQ2FBMD: std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ2_FB_MODE

constant c_EP_CMD_AUTH_STATUS : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Status
constant c_EP_CMD_AUTH_VERSION: std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Version

constant c_EP_CMD_AUTH_S1FB0  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_SQ1_FB0
constant c_EP_CMD_AUTH_S1FBM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_SQ1_FB_MODE
constant c_EP_CMD_AUTH_S2LKP  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_SQ2_PXL_LOCKPOINT
constant c_EP_CMD_AUTH_S2LSB  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_SQ2_PXL_LOCKPOINT_LSB
constant c_EP_CMD_AUTH_S2OFF  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_SQ2_PXL_LOCKPOINT_OFFSET
constant c_EP_CMD_AUTH_S1FBD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB_SQ1_DELAY
constant c_EP_CMD_AUTH_S2FBD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB_SQ2_DELAY
constant c_EP_CMD_AUTH_PLSSH  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB1_PULSE_SHAPING

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data field bus size
   -- ------------------------------------------------------------------------------------------------------
constant c_DFLD_TM_MODE_S     : integer   :=  2                                                             ; --! EP command: Data field, TM_MODE bus size
constant c_DFLD_SQ1FBMD_COL_S : integer   :=  1                                                             ; --! EP command: Data field, SQ1_FB_MODE mode bus size
constant c_DFLD_SQ1FBMD_PLS_S : integer   :=  log2_ceil(c_DAC_PLS_SHP_SET_NB)                               ; --! EP command: Data field, SQ1_FB_MODE pulse shaping coeficients set bus size
constant c_DFLD_SQ2FBMD_COL_S : integer   :=  2                                                             ; --! EP command: Data field, SQ2_FB_MODE bus size
constant c_DFLD_S1FB0_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_SQ1_FB0 bus size
constant c_DFLD_S1FBM_PIX_S   : integer   :=  2                                                             ; --! EP command: Data field, CY_SQ1_FB_MODE bus size
constant c_DFLD_S2LKP_PIX_S   : integer   :=  c_SQ2_DAC_MUX_S                                               ; --! EP command: Data field, CY_SQ2_PXL_LOCKPOINT bus size
constant c_DFLD_S2LSB_COL_S   : integer   :=  c_SQ2_DAC_DATA_S                                              ; --! EP command: Data field, CY_SQ2_PXL_LOCKPOINT_LSB bus size
constant c_DFLD_S2OFF_COL_S   : integer   :=  c_SQ2_DAC_DATA_S                                              ; --! EP command: Data field, CY_SQ2_PXL_LOCKPOINT_OFFSET bus size
constant c_DFLD_S1FBD_COL_S   : integer   :=  5                                                             ; --! EP command: Data field, CY_FB_SQ1_DELAY bus size
constant c_DFLD_S2DCD_COL_S   : integer   :=  10                                                            ; --! EP command: Data field, CY_FB_SQ2_DELAY, DAC field bus size
constant c_DFLD_S2MXD_COL_S   : integer   :=  5                                                             ; --! EP command: Data field, CY_FB_SQ2_DELAY, MUX field bus size
constant c_DFLD_S2FBD_COL_S   : integer   :=  c_DFLD_S2DCD_COL_S + c_DFLD_S2MXD_COL_S                       ; --! EP command: Data field, CY_FB_SQ2_DELAY bus size
constant c_DFLD_PLSSH_PLS_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_FB1_PULSE_SHAPING bus size

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data state
   -- ------------------------------------------------------------------------------------------------------
constant c_DST_TM_MODE_DUMP   : std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0):= "00"                        ; --! EP command: Data state, TM_MODE "Dump"
constant c_DST_TM_MODE_IDLE   : std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0):= "01"                        ; --! EP command: Data state, TM_MODE "Idle"
constant c_DST_TM_MODE_NORM   : std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0):= "10"                        ; --! EP command: Data state, TM_MODE "Normal"
constant c_DST_TM_MODE_TEST   : std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0):= "11"                        ; --! EP command: Data state, TM_MODE "Test Pattern"

constant c_DST_SQ1FBMD_OFF    : std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0):= "0"                     ; --! EP command: Data state, SQ1_FB_MODE "Off"
constant c_DST_SQ1FBMD_ON     : std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0):= "1"                     ; --! EP command: Data state, SQ1_FB_MODE "Test Pattern"

constant c_DST_SQ1FBMD_PLS_0  : std_logic_vector(c_DFLD_SQ1FBMD_PLS_S-1 downto 0):= "00"                    ; --! EP command: Data state, SQ1_FB_MODE pulse shaping coefficients set 0
constant c_DST_SQ1FBMD_PLS_1  : std_logic_vector(c_DFLD_SQ1FBMD_PLS_S-1 downto 0):= "01"                    ; --! EP command: Data state, SQ1_FB_MODE pulse shaping coefficients set 1
constant c_DST_SQ1FBMD_PLS_2  : std_logic_vector(c_DFLD_SQ1FBMD_PLS_S-1 downto 0):= "10"                    ; --! EP command: Data state, SQ1_FB_MODE pulse shaping coefficients set 2
constant c_DST_SQ1FBMD_PLS_3  : std_logic_vector(c_DFLD_SQ1FBMD_PLS_S-1 downto 0):= "11"                    ; --! EP command: Data state, SQ1_FB_MODE pulse shaping coefficients set 3

constant c_DST_SQ2FBMD_OFF    : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "00"                    ; --! EP command: Data state, SQ2_FB_MODE "Off"
constant c_DST_SQ2FBMD_OPEN   : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "01"                    ; --! EP command: Data state, SQ2_FB_MODE "Open Loop"
constant c_DST_SQ2FBMD_CLOSE  : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "10"                    ; --! EP command: Data state, SQ2_FB_MODE "Closed Loop"
constant c_DST_SQ2FBMD_TEST   : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "11"                    ; --! EP command: Data state, SQ2_FB_MODE "Test Pattern"

constant c_DST_SQ2DAC_NORM    : std_logic_vector(c_SQ2_DAC_MODE_S-1 downto 0):= "00"                        ; --! EP command: Data state, SQUID2 DACs mode "Normal"
constant c_DST_SQ2DAC_PD1K    : std_logic_vector(c_SQ2_DAC_MODE_S-1 downto 0):= "01"                        ; --! EP command: Data state, SQUID2 DACs mode "Power down 1k to GND"
constant c_DST_SQ2DAC_PD100K  : std_logic_vector(c_SQ2_DAC_MODE_S-1 downto 0):= "10"                        ; --! EP command: Data state, SQUID2 DACs mode "Power down 100k to GND"
constant c_DST_SQ2DAC_PDZ     : std_logic_vector(c_SQ2_DAC_MODE_S-1 downto 0):= "11"                        ; --! EP command: Data state, SQUID2 DACs mode "Power down High Z"

constant c_DST_SQ1FBMD_OPEN   : std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0):= "00"                      ; --! EP command: Data state, CY_SQ1_FB_MODE "Open Loop"
constant c_DST_SQ1FBMD_CLOSE  : std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0):= "01"                      ; --! EP command: Data state, CY_SQ1_FB_MODE "Closed Loop"
constant c_DST_SQ1FBMD_TEST   : std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0):= "10"                      ; --! EP command: Data state, CY_SQ1_FB_MODE "Test Pattern"

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Default value
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_DEF_TM_MODE : std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0):= c_DST_TM_MODE_IDLE          ; --! EP command: Default value, TM_MODE

constant c_EP_CMD_DEF_PLSFC   : integer   := 20000000                                                       ; --! EP command: Default value, pulse shaping cut frequency (Hz)
constant c_EP_CMD_DEF_SQ1FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):=
                                c_DST_SQ1FBMD_PLS_1 & "0" & c_DST_SQ1FBMD_OFF &
                                c_DST_SQ1FBMD_PLS_1 & "0" & c_DST_SQ1FBMD_OFF &
                                c_DST_SQ1FBMD_PLS_1 & "0" & c_DST_SQ1FBMD_OFF &
                                c_DST_SQ1FBMD_PLS_1 & "0" & c_DST_SQ1FBMD_OFF                               ; --! EP command: Default value, SQ1_FB_MODE

constant c_EP_CMD_DEF_SQ2FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):=
                                "00" & c_DST_SQ2FBMD_OFF & "00" & c_DST_SQ2FBMD_OFF &
                                "00" & c_DST_SQ2FBMD_OFF & "00" & c_DST_SQ2FBMD_OFF                         ; --! EP command: Default value, SQ2_FB_MODE

constant c_EP_CMD_DEF_S1FB0   : t_int_arr(0 to 2*c_TAB_S1FB0_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_SQ1_FB0 memory with ping-pong buffer bit

constant c_EP_CMD_DEF_S1FBM   : t_int_arr(0 to 2*c_TAB_S1FBM_NW-1) :=
                                (others => to_integer(unsigned(c_DST_SQ1FBMD_OPEN)))                        ; --! EP command: Default value, CY_SQ1_FB_MODE memory with ping-pong buffer bit

constant c_EP_CMD_DEF_S2LKP   : t_int_arr(0 to 2*c_TAB_S2LKP_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_SQ2_PXL_LOCKPOINT memory with ping-pong buffer bit
constant c_EP_CMD_DEF_S2LSB   : std_logic_vector(c_DFLD_S2LSB_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_S2LSB_COL_S))                        ; --! EP command: Default value, CY_SQ2_PXL_LOCKPOINT_LSB
constant c_EP_CMD_DEF_S2OFF   : std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(c_SQ2_DAC_MDL_POINT ,c_DFLD_S2OFF_COL_S))      ; --! EP command: Default value, CY_SQ2_PXL_LOCKPOINT_OFFSET

constant c_EP_CMD_DEF_S1FBD   : std_logic_vector(c_DFLD_S1FBD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_S1FBD_COL_S))                        ; --! EP command: Default value, CY_FB_SQ1_DELAY

constant c_EP_CMD_DEF_S2DCD   : std_logic_vector(c_DFLD_S2DCD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_S2DCD_COL_S))                        ; --! EP command: Default value, CY_FB_SQ2_DELAY, DAC field

constant c_EP_CMD_DEF_S2MXD   : std_logic_vector(c_DFLD_S2MXD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_S2MXD_COL_S))                        ; --! EP command: Default value, CY_FB_SQ2_DELAY, MUX² field

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

end pkg_ep_cmd;
