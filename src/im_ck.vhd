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
--!   @file                   im_ck.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Image clock, frequency divided by 2
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

entity im_ck is generic
   (     g_FF_RSYNC_NB        : integer                                                                     ; --! Flip-Flop number used for resynchronization
         g_FF_CK_REF_NB       : integer                                                                       --! Flip-Flop number used for delaying image clock reference
   ); port
   (     i_reset              : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              : in     std_logic                                                            ; --! Clock
         i_cmd_ck             : in     std_logic                                                            ; --! Clock switch command ('0' = Inactive, '1' = Active)
         o_im_ck              : out    std_logic                                                              --! Image clock, frequency divided by 2
   );
end entity im_ck;

architecture RTL of im_ck is
signal   cmd_ck_r             : std_logic_vector(g_FF_RSYNC_NB-1 downto 0)                                  ; --! Clock switch command register
signal   ck_ref               : std_logic                                                                   ; --! Image clock reference
signal   ck_ref_r             : std_logic_vector(g_FF_CK_REF_NB-1 downto 0)                                 ; --! Image clock reference register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (i_clock)
   begin

      if rising_edge(i_clock) then
         cmd_ck_r <= cmd_ck_r(cmd_ck_r'high-1 downto 0) & i_cmd_ck;

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Image clock
   -- ------------------------------------------------------------------------------------------------------
   P_ck_ref : process (i_clock)
   begin

      if rising_edge(i_clock) then
         if cmd_ck_r(cmd_ck_r'high) = '0' then
            ck_ref   <= '0';

         else
            ck_ref   <= not(ck_ref);

         end if;

         ck_ref_r <= ck_ref_r(ck_ref_r'high-1 downto 0) & ck_ref;

      end if;

   end process P_ck_ref;

   P_im_ck : process (i_reset, i_clock)
   begin

      if i_reset = '1' then
         o_im_ck  <= '0';

      elsif rising_edge(i_clock) then
         o_im_ck  <= ck_ref_r(ck_ref_r'high);

      end if;

   end process P_im_ck;

end architecture RTL;
