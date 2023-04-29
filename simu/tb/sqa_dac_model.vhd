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
--!   @file                   sqa_dac_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP DAC model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity sqa_dac_model is generic (
         g_SQA_DAC_VREF       : real                                                                        ; --! SQUID AMP DAC: Voltage reference (Volt)
         g_SQA_DAC_TS         : time                                                                        ; --! SQUID AMP DAC: Output Voltage Settling time
         g_SQA_MUX_TPLH       : time                                                                          --! SQUID AMP MUX: Propagation delay switch in to out
   ); port (
         i_sqa_dac_data       : in     std_logic                                                            ; --! SQUID AMP DAC: Serial Data
         i_sqa_dac_sclk       : in     std_logic                                                            ; --! SQUID AMP DAC: Serial Clock
         i_sqa_dac_snc_l_n    : in     std_logic                                                            ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sqa_dac_snc_o_n    : in     std_logic                                                            ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sqa_dac_mux        : in     std_logic_vector(c_SQA_DAC_MUX_S-1 downto 0)                         ; --! SQUID AMP DAC: Multiplexer
         i_sqa_dac_mx_en_n    : in     std_logic                                                            ; --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_sqa_vout           : out    real                                                                   --! Analog voltage (0.0 <= o_sqa_vout < c_SQA_COEF * g_SQA_DAC_VREF,
                                                                                                              --!  with c_SQA_COEF = (2^(c_SQA_DAC_MUX_S+1)-1)/(c_SQA_DAC_COEF_DIV*2^c_SQA_DAC_MUX_S))
   );
end entity sqa_dac_model;

architecture Behavioral of sqa_dac_model is
constant c_SQA_MUX_VOLT_FACT  : real   := 1.0 / real(2**c_SQA_DAC_MUX_S)                                    ; --! SQUID AMP Multiplexer voltage factor

signal   sqa_dac_lsb_volt     : real                                                                        ; --! SQUID AMP offset DAC LSB voltage (Volt)
signal   sqa_dac_off_volt     : real                                                                        ; --! SQUID AMP DAC Offset voltage (Volt)
signal   sqa_mux              : std_logic_vector(c_SQA_DAC_MUX_S-1 downto 0)                                ; --! SQUID AMP Multiplexer
signal   sqa_mux_volt         : real                                                                        ; --! SQUID AMP Multiplexer voltage (Volt)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP offset DAC LSB
   -- ------------------------------------------------------------------------------------------------------
   I_sqa_dac_lsb: entity work.dac121s101_model generic map (
         g_VA                 => g_SQA_DAC_VREF       , -- real                                             ; --! Voltage reference (Volt)
         g_TIME_TS            => g_SQA_DAC_TS           -- time                                               --! Time: Output Voltage Settling
   ) port map (
         i_din                => i_sqa_dac_data       , -- in     std_logic                                 ; --! Serial Data
         i_sclk               => i_sqa_dac_sclk       , -- in     std_logic                                 ; --! Serial Clock
         i_sync_n             => i_sqa_dac_snc_l_n    , -- in     std_logic                                 ; --! Frame synchronization ('0' = Active, '1' = Inactive)

         o_vout               => sqa_dac_lsb_volt       -- out    real                                        --! Analog voltage ( 0.0 <= Vout < g_VA)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP DAC Offset
   -- ------------------------------------------------------------------------------------------------------
   I_sqa_dac_off: entity work.dac121s101_model generic map (
         g_VA                 => g_SQA_DAC_VREF       , -- real                                             ; --! Voltage reference (Volt)
         g_TIME_TS            => g_SQA_DAC_TS           -- time                                               --! Time: Output Voltage Settling
   ) port map (
         i_din                => i_sqa_dac_data       , -- in     std_logic                                 ; --! Serial Data
         i_sclk               => i_sqa_dac_sclk       , -- in     std_logic                                 ; --! Serial Clock
         i_sync_n             => i_sqa_dac_snc_o_n    , -- in     std_logic                                 ; --! Frame synchronization ('0' = Active, '1' = Inactive)

         o_vout               => sqa_dac_off_volt       -- out    real                                        --! Analog voltage ( 0.0 <= Vout < g_VA)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP voltage output
   -- ------------------------------------------------------------------------------------------------------
   sqa_mux      <= i_sqa_dac_mux when i_sqa_dac_mx_en_n = '0' else std_logic_vector(to_unsigned(0, sqa_mux'length));
   sqa_mux_volt <= transport (real(to_integer(unsigned(sqa_mux))) * sqa_dac_lsb_volt * c_SQA_MUX_VOLT_FACT) after g_SQA_MUX_TPLH when now> g_SQA_MUX_TPLH else 0.0;
   o_sqa_vout   <= ((sqa_dac_off_volt + sqa_mux_volt) * c_SQA_DAC_COEF_FACT) when now > 0 ps else 0.0;

end architecture Behavioral;
