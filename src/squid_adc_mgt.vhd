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
--!   @file                   squid_adc_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid ADC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;

entity squid_adc_mgt is port
      (  i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             : in     std_logic                                                            ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_adc_acq    : in     std_logic                                                            ; --! SQUID1 ADC acquisition Clock

         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sq1_adc_data       : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC - Data, no rsync
         i_sq1_adc_oor        : in     std_logic                                                            ; --! SQUID1 ADC - Out of range, no rsync (‘0’= No, ‘1’= under/over range)

         o_sq1_data_err       : out    std_logic_vector(c_SQ1_DATA_ERR_S-1 downto 0)                          --! SQUID1 Data error

   );
end entity squid_adc_mgt;

architecture RTL of squid_adc_mgt is
signal   rst_sq1_adc          : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)

signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

signal   sq1_adc_data_r       : t_sq1_adc_data_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 ADC, col. 0 - Data register
signal   sq1_adc_oor_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 0 - Out of range register (‘0’ = No, ‘1’ = under/over range)

signal   sq1_data_err         : std_logic_vector(c_SQ1_DATA_ERR_S-1 downto 0)                               ; --! SQUID1 Data error

--TODO
signal   sq1_data_err_rs      : t_sq1_data_err_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 Data error, sync. on System Clock
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID1 pulse shaping Clock generation
   --!     Necessity to generate local reset in order to reach expected frequency
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_sq1_adc: entity work.reset_gen generic map
   (     g_FF_RESET_NB        => c_FF_RST_SQ1_ADC_NB    -- integer                                            --! Flip-Flop number used for generated reset
   ) port map
   (     i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clock              => i_clk_sq1_adc_acq    , -- in     std_logic                                 ; --! Main Pll Status ('0' = Pll not locked, '1' = Pll locked)
         i_ck_rdy             => i_ck_rdy             , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              => rst_sq1_adc            -- out    std_logic                                   --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst_sq1_adc, i_clk_sq1_adc_acq)
   begin

      if rst_sq1_adc = '1' then
         sync_r            <= (others => c_I_SYNC_DEF);
         sq1_adc_data_r    <= (others => c_I_SQ1_ADC_DATA_DEF);
         sq1_adc_oor_r     <= (others => c_I_SQ1_ADC_OOR_DEF);

      elsif rising_edge(i_clk_sq1_adc_acq) then
         sync_r            <= sync_r(sync_r'high-1 downto 0) & i_sync_rs;
         sq1_adc_data_r    <= i_sq1_adc_data & sq1_adc_data_r(0 to sq1_adc_data_r'high-1);
         sq1_adc_oor_r     <= sq1_adc_oor_r(sq1_adc_oor_r'high-1 downto 0) & i_sq1_adc_oor;

      end if;

   end process P_rsync;

   -- TODO
   P_todo : process (rst_sq1_adc, i_clk_sq1_adc_acq)
   begin

      if rst_sq1_adc = '1' then
         sq1_data_err <= (others => '0');

      elsif rising_edge(i_clk_sq1_adc_acq) then
         if sq1_adc_oor_r(sq1_adc_oor_r'high) = '1' then
            sq1_data_err <= std_logic_vector(unsigned(sq1_data_err) + resize(unsigned(sq1_adc_data_r(sq1_adc_data_r'high)), sq1_data_err'length));

         end if;

      end if;

   end process P_todo;

   P_todo2 : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sq1_data_err_rs <= (others => (others => '0'));

      elsif rising_edge(i_clk) then
         sq1_data_err_rs <= sq1_data_err & sq1_data_err_rs(0 to sq1_data_err_rs'high-1);

      end if;

   end process P_todo2;

   o_sq1_data_err <= sq1_data_err_rs(sq1_data_err_rs'high);

end architecture RTL;
