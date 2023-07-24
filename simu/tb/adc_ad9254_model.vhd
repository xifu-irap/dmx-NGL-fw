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
--!   @file                   adc_ad9254_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                ADC AD9254S model (configuration without SPI)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     work.pkg_type.all;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity adc_ad9254_model is generic (
         g_VREF               : real                                                                        ; --! Voltage reference (Volt)
         g_CLK_PER            : time                                                                        ; --! Clock period (>= 6700 ps)
         g_TIME_TPD           : time                                                                          --! Time: Data Propagation Delay
   ); port (
         i_clk                : in     std_logic                                                            ; --! Clock
         i_pwdn               : in     std_logic                                                            ; --! Power down ('0' = Inactive, '1' = Active)
         i_oeb_n              : in     std_logic                                                            ; --! Output enable ('0' = Active, '1' = Inactive)
         o_sdio_dcs           : out    std_logic                                                            ; --! SPI Data in/out, Duty Cycle stabilizer select ('0' = Disable, '1' = Enable)
         i_sclk_dfs           : in     std_logic                                                            ; --! SPI Serial clock, Data Format select ('0' = Binary, '1' = Twos complement)

         i_delta_vin          : in     real                                                                 ; --! Analog voltage (-g_VREF <= Vin+ - Vin- < g_VREF)
         o_dco                : out    std_logic                                                            ; --! Data clock
         o_d                  : out    std_logic_vector(13 downto 0)                                        ; --! Data
         o_or                 : out    std_logic                                                              --! Out of range indicator ('0' = Range, '1' = Out of range)
   );
end entity adc_ad9254_model;

architecture Behavioral of adc_ad9254_model is
constant c_LOW_LEV            : std_logic := '0'                                                            ; --! Low  level value
constant c_HGH_LEV            : std_logic := not(c_LOW_LEV)                                                 ; --! High level value

constant c_CLK_PER_HALF       : time       := g_CLK_PER/2                                                   ; --! Half clock period

constant c_ADC_RES            : real      := 2.0 * g_VREF / real(2**(o_d'length))                           ; --! ADC resolution (V)
constant c_VIN_MAX            : real      := (real(2**(o_d'length-1)) - 1.0) * c_ADC_RES                    ; --! Analog voltage maximum limit (V)

constant c_TIME_TA            : time      :=  800 ps                                                        ; --! Time: Aperture Delay
constant c_TIME_TDCO          : time      := 4400 ps                                                        ; --! Time: DCO Propagation Delay
constant c_PIPE_DEL           : integer   :=   12                                                           ; --! Pipe stage delay number

signal   delta_vin_sat        : real                                                                        ; --! Analog voltage with saturation management

signal   adc_data_acq         : std_logic_vector(o_d'length-1 downto 0)                                     ; --! ADC data acquisition
signal   out_range_acq        : std_logic                                                                   ; --! Out of range acquisition ('0' = Range, '1' = Out of range)

signal   adc_data_acq_r       : t_slv_arr(0 to c_PIPE_DEL-1)(o_d'length-1  downto 0)                        ; --! ADC data acquisition register
signal   out_range_acq_r      : std_logic_vector(c_PIPE_DEL-1 downto 0)                                     ; --! Out of range acquisition register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC data pipeline
   -- ------------------------------------------------------------------------------------------------------
   delta_vin_sat  <= -g_VREF    when (i_delta_vin < -g_VREF  ) else
                     c_VIN_MAX  when (i_delta_vin > c_VIN_MAX) else
                     i_delta_vin;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC data acquisition
   -- ------------------------------------------------------------------------------------------------------
   P_adc_data_acq : process
   begin

      wait until rising_edge(i_clk);
      wait for c_TIME_TA;

      adc_data_acq  <=  std_logic_vector(to_signed(integer(round((delta_vin_sat + g_VREF)/c_ADC_RES)), adc_data_acq'length)) when i_sclk_dfs = c_LOW_LEV else
                        std_logic_vector(to_signed(integer(round(delta_vin_sat/c_ADC_RES)), adc_data_acq'length));

      out_range_acq <= c_HGH_LEV when ((i_delta_vin < -g_VREF) or (i_delta_vin > c_VIN_MAX)) else c_LOW_LEV;

   end process P_adc_data_acq;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC data pipeline
   -- ------------------------------------------------------------------------------------------------------
   P_data_pipe : process
   begin

      wait until rising_edge(i_clk);
      wait for g_TIME_TPD;

      adc_data_acq_r  <= adc_data_acq & adc_data_acq_r(adc_data_acq_r'low to adc_data_acq_r'high-1);
      out_range_acq_r <= out_range_acq_r(out_range_acq_r'high-1 downto out_range_acq_r'low) & out_range_acq;

   end process P_data_pipe;

   o_d   <= (others => 'Z') when (i_oeb_n or i_pwdn) = c_HGH_LEV else adc_data_acq_r(adc_data_acq_r'high);
   o_or  <= 'Z' when (i_oeb_n or i_pwdn) = c_HGH_LEV else out_range_acq_r(out_range_acq_r'high);

   o_dco       <= transport i_clk after (c_TIME_TDCO - c_CLK_PER_HALF);
   o_sdio_dcs  <= 'Z';

end architecture Behavioral;
