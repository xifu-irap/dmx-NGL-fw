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
--!   @file                   squid1_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid1 DAC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;

entity squid1_dac_mgt is port
      (  i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             : in     std_logic                                                            ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_pls_shape  : in     std_logic                                                            ; --! SQUID1 pulse shaping Clock

         i_sync               : in     std_logic                                                            ; --! Pixel sequence sync., no rsync (R.E. detected = position sequence to the first pixel)
         i_sq1_data_fbk       : in     std_logic_vector(c_SQ1_DATA_FBK_S-1 downto 0)                        ; --! SQUID1 Data feedback

         o_sq1_dac_data       : out    std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                          --! SQUID1 DAC - Data
   );
end entity squid1_dac_mgt;

architecture RTL of squid1_dac_mgt is
signal   rst_sq1_pls_shape    : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)

signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

signal   x_init               : std_logic_vector(c_SQ1_DATA_FBK_S-1 downto 0)                               ; --! Pulse shaping: Last value reached by y[k] at the end of last slice (unsigned)
signal   x_final              : std_logic_vector(c_SQ1_DATA_FBK_S-1 downto 0)                               ; --! Pulse shaping: Final value to reach by y[k] (unsigned)
signal   a_mant_k             : std_logic_vector(c_SQ1_PLS_SHP_A_EXP-1 downto 0)                            ; --! Pulse shaping: A[k] filter mantissa parameter (unsigned)
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
   --!   SQUID1 DAC - Pulse shaping
   -- ------------------------------------------------------------------------------------------------------
   I_pulse_shaping: entity work.pulse_shaping generic map
   (     g_X_K_S              => c_SQ1_DATA_FBK_S     , -- integer                                          ; --! Data in bus size (<= c_MULT_ALU_PORTB_S-1)
         g_A_EXP              => c_SQ1_PLS_SHP_A_EXP  , -- integer                                          ; --! A[k]: filter exponent parameter (<= c_MULT_ALU_PORTC_S-g_X_K_S-1)
         g_Y_K_S              => c_SQ1_DAC_DATA_S       -- integer                                            --! y[k]: filtered data out bus size
   ) port map
      (  i_rst_sq1_pls_shape  => rst_sq1_pls_shape    , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_sq1_pls_shape  => i_clk_sq1_pls_shape  , -- in     std_logic                                 ; --! SQUID1 pulse shaping Clock
         i_x_init             => x_init               , -- in     std_logic_vector(g_X_K_S-1 downto 0)      ; --! Last value reached by y[k] at the end of last slice (unsigned)
         i_x_final            => x_final              , -- in     std_logic_vector(g_X_K_S-1 downto 0)      ; --! Final value to reach by y[k] (unsigned)
         i_a_mant_k           => a_mant_k             , -- in     std_logic_vector(g_A_EXP-1 downto 0)      ; --! A[k]: filter mantissa parameter (unsigned)
         o_y_k                => o_sq1_dac_data         -- out    std_logic_vector(g_Y_K_S-1 downto 0)        --! y[k]: filtered data out (unsigned)
   );

   -- TODO
   P_todo : process (rst_sq1_pls_shape, i_clk_sq1_pls_shape)
   begin

      if rst_sq1_pls_shape = '1' then
         x_init      <= (others => '0');
         x_final     <= (others => '0');
         a_mant_k    <= (others => '0');

      elsif rising_edge(i_clk_sq1_pls_shape) then
         x_init      <= std_logic_vector(unsigned(i_sq1_data_fbk) + 1);
         x_final     <= std_logic_vector(unsigned( x_final) + 3);
         a_mant_k    <= std_logic_vector(unsigned(a_mant_k) + 5);

      end if;

   end process P_todo;

end architecture RTL;
