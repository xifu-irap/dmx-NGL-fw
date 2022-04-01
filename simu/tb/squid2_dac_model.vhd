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
--!   @file                   squid2_dac_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID2 DAC model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity squid2_dac_model is generic
   (     g_SQ2_DAC_VREF       : real                                                                        ; --! SQUID2 DAC - Voltage reference (Volt)
         g_SQ2_DAC_TS         : time                                                                        ; --! SQUID2 DAC - Output Voltage Settling time
         g_SQ2_MUX_TPLH       : time                                                                          --! SQUID2 MUX - Propagation delay switch in to out
   ); port
   (     i_sq2_dac_data       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Data
         i_sq2_dac_sclk       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Clock
         i_sq2_dac_snc_l_n    : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sq2_dac_snc_o_n    : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sq2_dac_mux        : in     std_logic_vector(c_SQ2_DAC_MUX_S-1 downto 0)                         ; --! SQUID2 DAC - Multiplexer
         i_sq2_dac_mx_en_n    : in     std_logic                                                            ; --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_sq2_vout           : out    real                                                                   --! Analog voltage (-g_SQ2_DAC_VREF <= o_sq2_vout < g_SQ2_DAC_VREF)
   );
end entity squid2_dac_model;

architecture Behavioral of squid2_dac_model is
signal   sq2_dac_lsb_volt     : real                                                                        ; --! SQUID2 DAC LSB voltage (Volt)
signal   sq2_dac_off_volt     : real                                                                        ; --! SQUID2 DAC Offset voltage (Volt)
signal   sq2_mux_volt         : real                                                                        ; --! SQUID2 Multiplexer voltage (Volt)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID2 DAC LSB
   -- ------------------------------------------------------------------------------------------------------
   I_sq2_dac_lsb: entity work.dac121s101_model generic map
   (     g_VA                 => g_SQ2_DAC_VREF       , -- real                                             ; --! Voltage reference (Volt)
         g_TIME_TS            => g_SQ2_DAC_TS           -- time                                               --! Time: Output Voltage Settling
   ) port map
   (     i_din                => i_sq2_dac_data       , -- in     std_logic                                 ; --! Serial Data
         i_sclk               => i_sq2_dac_sclk       , -- in     std_logic                                 ; --! Serial Clock
         i_sync_n             => i_sq2_dac_snc_l_n    , -- in     std_logic                                 ; --! Frame synchronization ('0' = Active, '1' = Inactive)

         o_vout               => sq2_dac_lsb_volt       -- out    real                                        --! Analog voltage ( 0.0 <= Vout < g_VA)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID2 DAC Offset
   -- ------------------------------------------------------------------------------------------------------
   I_sq2_dac_off: entity work.dac121s101_model generic map
   (     g_VA                 => g_SQ2_DAC_VREF       , -- real                                             ; --! Voltage reference (Volt)
         g_TIME_TS            => g_SQ2_DAC_TS           -- time                                               --! Time: Output Voltage Settling
   ) port map
   (     i_din                => i_sq2_dac_data       , -- in     std_logic                                 ; --! Serial Data
         i_sclk               => i_sq2_dac_sclk       , -- in     std_logic                                 ; --! Serial Clock
         i_sync_n             => i_sq2_dac_snc_o_n    , -- in     std_logic                                 ; --! Frame synchronization ('0' = Active, '1' = Inactive)

         o_vout               => sq2_dac_off_volt       -- out    real                                        --! Analog voltage ( 0.0 <= Vout < g_VA)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID2 voltage output
   -- ------------------------------------------------------------------------------------------------------
   sq2_mux_volt <= transport (real(to_integer(unsigned(i_sq2_dac_mux))) * sq2_dac_lsb_volt) after g_SQ2_MUX_TPLH when now> g_SQ2_MUX_TPLH else 0.0;
   o_sq2_vout   <= (2.0 * (sq2_dac_off_volt + sq2_mux_volt) - g_SQ2_DAC_VREF ) when now > 0 ps else -g_SQ2_DAC_VREF;

end architecture Behavioral;
