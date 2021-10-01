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
--!   @file                   cmd_ck_rs.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Clock switch command clock resynchronization with local reset
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

entity cmd_ck_rs is generic
   (     g_FF_RESET_NB        : integer                                                                     ; --! Flip-Flop number used for generated reset
         g_FF_RSYNC_NB        : integer                                                                     ; --! Flip-Flop number used for resynchronization
         g_PLS_CK_SW_NB       : integer                                                                     ; --! Clock pulse number between clock switch command and output clock
         g_CK_CMD_DEF         : std_logic                                                                     --! Clock switch command default value at reset
   ); port
   (     i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clock              : in     std_logic                                                            ; --! Clock
         i_ck_rdy             : in     std_logic                                                            ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_ck_cmd             : in     std_logic                                                            ; --! Clock switch command ('0' = Inactive, '1' = Active)

         o_ck_cmd_rs          : out    std_logic                                                            ; --! Clock switch command, synchronized on Clock
         o_ck_cmd_sleep       : out    std_logic                                                              --! Clock switch command sleep ('0' = Inactive, '1' = Active)
   );
end entity cmd_ck_rs;

architecture RTL of cmd_ck_rs is
signal   reset                : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   ck_cmd_r             : std_logic_vector(g_PLS_CK_SW_NB+g_FF_RSYNC_NB-1 downto 0)                   ; --! Clock switch command register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Local Reset generation
   -- ------------------------------------------------------------------------------------------------------
   I_reset_gen: entity work.reset_gen generic map
   (     g_FF_RESET_NB        => g_FF_RESET_NB          -- integer                                            --! Flip-Flop number used for generated reset
   ) port map
   (     i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clock              => i_clock              , -- in     std_logic                                 ; --! Clock
         i_ck_rdy             => i_ck_rdy             , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              => reset                  -- out    std_logic                                   --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset generation
   -- ------------------------------------------------------------------------------------------------------
   P_ck_cmd_r : process (reset, i_clock)
   begin

      if reset = '1' then
         ck_cmd_r  <= (others => g_CK_CMD_DEF);

      elsif rising_edge(i_clock) then
         ck_cmd_r  <= ck_cmd_r(ck_cmd_r'high-1 downto 0) & i_ck_cmd;

      end if;

   end process P_ck_cmd_r;

   o_ck_cmd_rs    <=     ck_cmd_r(g_FF_RSYNC_NB-1);
   o_ck_cmd_sleep <= not(ck_cmd_r(ck_cmd_r'high));

end architecture RTL;
