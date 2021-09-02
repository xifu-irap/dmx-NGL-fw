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
--!   @file                   squid2_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid2 DAC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;

entity squid2_dac_mgt is port
      (  i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             : in     std_logic                                                            ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_pls_shape  : in     std_logic                                                            ; --! SQUID1 pulse shaping Clock

         i_sync               : in     std_logic                                                            ; --! Pixel sequence sync., no rsync (R.E. detected = position sequence to the first pixel)

         o_sq2_dac_mux        : out    std_logic_vector(c_SQ2_DAC_MUX_S -1 downto 0)                          --! SQUID2 DAC - Multiplexer

   );
end entity squid2_dac_mgt;

architecture RTL of squid2_dac_mgt is
signal   rst_sq1_pls_shape    : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)

signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

signal   sq2_dac_mux	         : std_logic_vector(c_SQ2_DAC_MUX_S-1 downto 0)                                ; --! SQUID2 DAC - Multiplexer
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID1 pulse shaping Clock generation
   --!     Necessity to generate local reset in order to reach expected frequency
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_sq1_pls_shape: entity work.reset_gen generic map
   (     g_FF_RESET_NB        => c_FF_RST_SQ1_ADC_NB    -- integer                                            --! Flip-Flop number used for generated reset
   ) port map
   (     i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clock              => i_clk_sq1_pls_shape  , -- in     std_logic                                 ; --! Main Pll Status ('0' = Pll not locked, '1' = Pll locked)
         i_ck_rdy             => i_ck_rdy             , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              => rst_sq1_pls_shape      -- out    std_logic                                   --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst_sq1_pls_shape, i_clk_sq1_pls_shape)
   begin

      if rst_sq1_pls_shape = '1' then
         sync_r <= (others => c_I_SYNC_DEF);

      elsif rising_edge(i_clk_sq1_pls_shape) then
         sync_r <= sync_r(sync_r'high-1 downto 0) & i_sync;

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID2 DAC - Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0560
   -- ------------------------------------------------------------------------------------------------------
   o_sq2_dac_mux <= sq2_dac_mux;

   -- TODO
   P_todo : process (rst_sq1_pls_shape, i_clk_sq1_pls_shape)
   begin

      if rst_sq1_pls_shape = '1' then
         sq2_dac_mux <= (others => '0');

      elsif rising_edge(i_clk_sq1_pls_shape) then
         sq2_dac_mux <= std_logic_vector(unsigned(sq2_dac_mux) + 1);

      end if;

   end process P_todo;

end architecture RTL;
