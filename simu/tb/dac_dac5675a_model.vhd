-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-fw is free software: you can redistribute it and/or modify
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
--!   @file                   dac_dac5675a_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                DAC DAC5675A model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;

entity dac_dac5675a_model is generic (
         g_VREF               : real                                                                          --! Voltage reference (Volt)
   ); port (
         i_clk                : in     std_logic                                                            ; --! Clock
         i_sleep              : in     std_logic                                                            ; --! Sleep ('0' = Inactive, '1' = Active)
         i_d                  : in     std_logic_vector(13 downto 0)                                        ; --! Data

         o_delta_vout         : out    real                                                                   --! Analog voltage (-g_VREF <= Vout1 - Vout2 < g_VREF)
   );
end entity dac_dac5675a_model;

architecture Behavioral of dac_dac5675a_model is
constant c_DAC_RES            : real      := 2.0 * g_VREF / real(2**(i_d'length))                           ; --! DAC resolution (V)

constant c_TIME_TPD           : time      := 1 ns                                                           ; --! Time: Data Propagation Delay
constant c_PIPE_DEL           : integer   := 3                                                              ; --! Pipe stage delay number (Digital delay time)

signal   rst                  : std_logic                                                                   ; --! Reset ('0' = Inactive, '1' = Active)

signal   dac_data_r           : t_slv_arr(0 to c_PIPE_DEL-1)(i_d'length-1  downto 0)                        ; --! DAC data register
signal   delta_vout           : real                                                                        ; --! Analog voltage (no delays)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset generation
   -- ------------------------------------------------------------------------------------------------------
   P_rst: process
   begin
      rst   <= c_RST_LEV_ACT;
      wait for c_TIME_TPD;
      rst   <= not(c_RST_LEV_ACT);
      wait;

   end process P_rst;

   -- ------------------------------------------------------------------------------------------------------
   --!   DAC data register
   -- ------------------------------------------------------------------------------------------------------
   P_dac_data_r : process (rst, i_clk)
   begin

      if rst = c_RST_LEV_ACT then
         dac_data_r  <= (others => (i_d'high => '1',others =>'0'));

      elsif rising_edge(i_clk) then
         dac_data_r  <= i_d & dac_data_r(0 to dac_data_r'high-1);

      end if;

   end process P_dac_data_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Analog voltage
   -- ------------------------------------------------------------------------------------------------------
   delta_vout  <= 0.0   when i_sleep = '1' else
                  real(to_integer(unsigned(dac_data_r(dac_data_r'high)))) * c_DAC_RES - g_VREF;

   o_delta_vout <= transport delta_vout after c_TIME_TPD when now > c_TIME_TPD else 0.0;

end architecture Behavioral;
