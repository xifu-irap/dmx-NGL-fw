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
--!   @file                   signal_reg.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Signal registered, flip-flop number configurable
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

entity signal_reg is generic (
         g_SIG_FF_NB          : integer                                                                     ; --! Signal registered flip-flop number
         g_SIG_DEF            : std_logic                                                                     --! Signal registered default value at reset
   ); port (
         i_reset              : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              : in     std_logic                                                            ; --! Clock

         i_sig                : in     std_logic                                                            ; --! Signal
         o_sig_r              : out    std_logic                                                              --! Signal registered

   );
end entity signal_reg;

architecture RTL of signal_reg is
signal   sig_r                : std_logic_vector(g_SIG_FF_NB-1 downto 0)                                    ; --! Signal registered

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of sig_r                 : signal is true                                   ; --! Disabling signal optimization: sig_r

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   G_sig_ff_nb_1: if g_SIG_FF_NB = 1 generate

      P_sig_r : process (i_reset, i_clock)
      begin

         if i_reset = '1' then
            sig_r(0) <= g_SIG_DEF;

         elsif rising_edge(i_clock) then
            sig_r(0) <= i_sig;

         end if;

      end process P_sig_r;

   end generate;

   G_sig_ff_nb_not1: if g_SIG_FF_NB /= 1 generate

      P_sig_r : process (i_reset, i_clock)
      begin

         if i_reset = '1' then
            sig_r <= (others => g_SIG_DEF);

         elsif rising_edge(i_clock) then
            sig_r <= sig_r(sig_r'high-1 downto 0) & i_sig;

         end if;

      end process P_sig_r;

   end generate;

   o_sig_r <= sig_r(sig_r'high);

end architecture RTL;
