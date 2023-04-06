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
--!   @file                   cd74hc4051_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Analog Multiplexer cd74hc4051 model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity cd74hc4051_model is generic
   (     g_TIME_TPS           : time                                                                          --! Time: Data Propagation switch in to out
   ); port
   (     i_s                  : in     std_logic_vector(2 downto 0)                                         ; --! Address select
         i_e_n                : in     std_logic                                                            ; --! Enable ('0' = Active, '1' = Inactive)

         i_a0                 : in     real                                                                 ; --! Analog input channel 0
         i_a1                 : in     real                                                                 ; --! Analog input channel 1
         i_a2                 : in     real                                                                 ; --! Analog input channel 2
         i_a3                 : in     real                                                                 ; --! Analog input channel 3
         i_a4                 : in     real                                                                 ; --! Analog input channel 4
         i_a5                 : in     real                                                                 ; --! Analog input channel 5
         i_a6                 : in     real                                                                 ; --! Analog input channel 6
         i_a7                 : in     real                                                                 ; --! Analog input channel 7

         o_com                : out    real                                                                   --! Analog output
   );
end entity cd74hc4051_model;

architecture Behavioral of cd74hc4051_model is
signal   vout_no_del          : real                                                                        ; --! Analog voltage without delay

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Analog voltage
   -- ------------------------------------------------------------------------------------------------------
   vout_no_del <= 0.0   when i_e_n = '1'                                        else
                  i_a0  when i_s = std_logic_vector(to_unsigned(0, i_s'length)) else
                  i_a1  when i_s = std_logic_vector(to_unsigned(1, i_s'length)) else
                  i_a2  when i_s = std_logic_vector(to_unsigned(2, i_s'length)) else
                  i_a3  when i_s = std_logic_vector(to_unsigned(3, i_s'length)) else
                  i_a4  when i_s = std_logic_vector(to_unsigned(4, i_s'length)) else
                  i_a5  when i_s = std_logic_vector(to_unsigned(5, i_s'length)) else
                  i_a6  when i_s = std_logic_vector(to_unsigned(6, i_s'length)) else
                  i_a7;

   o_com    <= transport vout_no_del after g_TIME_TPS;

end architecture Behavioral;
