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
   --    EP command: Address
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ADD_TM_MODE : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4000"                        ; --! EP command: Address, TM_MODE
constant c_EP_CMD_ADD_SQ1FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4001"                        ; --! EP command: Address, SQ1_FB_MODE
constant c_EP_CMD_ADD_SQ2FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4002"                        ; --! EP command: Address, SQ2_FB_MODE

constant c_EP_CMD_ADD_STATUS  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6000"                        ; --! EP command: Address, Status
constant c_EP_CMD_ADD_VERSION : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6001"                        ; --! EP command: Address, Version

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Write register authorization
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_AUTH_TM_MODE: std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, TM_MODE
constant c_EP_CMD_AUTH_SQ1FBMD: std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ1_FB_MODE
constant c_EP_CMD_AUTH_SQ2FBMD: std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ2_FB_MODE

constant c_EP_CMD_AUTH_STATUS : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Status
constant c_EP_CMD_AUTH_VERSION: std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Version

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data field bus size
   -- ------------------------------------------------------------------------------------------------------
constant c_DFLD_TM_MODE_DUR_S : integer   :=  8                                                             ; --! EP command: Data field, TM_MODE Duration bus size
constant c_DFLD_TM_MODE_COL_S : integer   :=  2                                                             ; --! EP command: Data field, TM_MODE by column bus size
constant c_DFLD_SQ1FBMD_COL_S : integer   :=  1                                                             ; --! EP command: Data field, SQ1_FB_MODE by column bus size
constant c_DFLD_SQ2FBMD_COL_S : integer   :=  2                                                             ; --! EP command: Data field, SQ2_FB_MODE by column bus size

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data state
   -- ------------------------------------------------------------------------------------------------------
constant c_DST_TM_MODE_DUMP   : std_logic_vector(c_DFLD_TM_MODE_COL_S-1 downto 0):= "00"                    ; --! EP command: Data state, TM_MODE "Dump"
constant c_DST_TM_MODE_IDLE   : std_logic_vector(c_DFLD_TM_MODE_COL_S-1 downto 0):= "01"                    ; --! EP command: Data state, TM_MODE "Idle"
constant c_DST_TM_MODE_NORM   : std_logic_vector(c_DFLD_TM_MODE_COL_S-1 downto 0):= "10"                    ; --! EP command: Data state, TM_MODE "Normal"
constant c_DST_TM_MODE_TEST   : std_logic_vector(c_DFLD_TM_MODE_COL_S-1 downto 0):= "11"                    ; --! EP command: Data state, TM_MODE "Test Pattern"

constant c_DST_SQ1FBMD_OFF    : std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0):= "0"                     ; --! EP command: Data state, SQ1_FB_MODE "Off"
constant c_DST_SQ1FBMD_ON     : std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0):= "1"                     ; --! EP command: Data state, SQ1_FB_MODE "Test Pattern"

constant c_DST_SQ2FBMD_OFF    : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "00"                    ; --! EP command: Data state, SQ2_FB_MODE "Off"
constant c_DST_SQ2FBMD_OPEN   : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "01"                    ; --! EP command: Data state, SQ2_FB_MODE "Open Loop"
constant c_DST_SQ2FBMD_CLOSE  : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "10"                    ; --! EP command: Data state, SQ2_FB_MODE "Open Loop"
constant c_DST_SQ2FBMD_TEST   : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0):= "11"                    ; --! EP command: Data state, SQ2_FB_MODE "Test Pattern"

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data value
   -- ------------------------------------------------------------------------------------------------------
constant c_D_TM_MODE_DUR_DUMP : integer   := c_DMP_SEQ_ACQ_NB * 2**(log2_ceil(c_SQ1_ADC_DATA_S)) *
                                             c_CLK_ADC_MULT / (c_CLK_MULT * c_NB_COL * c_SC_DATA_SER_NB)    ; --! EP command: Data value, TM_MODE "Duration" during Dump mode
constant c_D_TM_MODE_DUR_INF  : integer   :=  0                                                             ; --! EP command: Data value, TM_MODE "Duration" infinity value

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Default value
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_DEF_TMDE_DR : integer   :=  0                                                             ; --! EP command: Default value, TM_MODE "Duration"
constant c_EP_CMD_DEF_TM_MODE : std_logic_vector(c_DFLD_TM_MODE_COL_S-1 downto 0):= c_DST_TM_MODE_IDLE      ; --! EP command: Default value, TM_MODE by column

constant c_EP_CMD_DEF_SQ1FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):=
                                "000" & c_DST_SQ1FBMD_OFF & "000" & c_DST_SQ1FBMD_OFF &
                                "000" & c_DST_SQ1FBMD_OFF & "000" & c_DST_SQ1FBMD_OFF                       ; --! EP command: Default value, SQ1_FB_MODE

constant c_EP_CMD_DEF_SQ2FBMD : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):=
                                "00" & c_DST_SQ2FBMD_OFF & "00" & c_DST_SQ2FBMD_OFF &
                                "00" & c_DST_SQ2FBMD_OFF & "00" & c_DST_SQ2FBMD_OFF                         ; --! EP command: Default value, SQ2_FB_MODE

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: type
   -- ------------------------------------------------------------------------------------------------------
type     t_rg_tm_mode          is array (natural range <>) of
                               std_logic_vector(c_DFLD_TM_MODE_COL_S-1 downto 0)                            ; --! EP command: register TM_MODE by column
type     t_rg_sq1fbmd          is array (natural range <>) of
                               std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0)                            ; --! EP command: register SQ1_FB_MODE by column
type     t_rg_sq2fbmd          is array (natural range <>) of
                               std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0)                            ; --! EP command: register SQ2_FB_MODE by column

end pkg_ep_cmd;
