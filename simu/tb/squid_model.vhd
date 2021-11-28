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
--!   @file                   squid_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID1/SQUID2 model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.math_real.all;

library work;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity squid_model is generic
   (     g_NB_COL             : integer                                                                     ; --! Column number
         g_CLK_ADC_PER        : time      := c_CLK_ADC_PER_DEF                                              ; --! SQUID1 ADC - Clock period
         g_TIM_ADC_TPD        : time      := c_TIM_ADC_TPD_DEF                                                --! SQUID1 ADC - Time, Data Propagation Delay
   ); port
   (     i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_clk_sq1_adc        : in     std_logic                                                            ; --! SQUID1 ADC - Clock
         i_sq1_adc_pwdn       : in     std_logic                                                            ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
         b_sq1_adc_spi_sdio   : inout  std_logic                                                            ; --! SQUID1 ADC - SPI Serial Data In Out
         i_sq1_adc_spi_sclk   : in     std_logic                                                            ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_sq1_adc_spi_cs_n   : in     std_logic                                                            ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sq1_adc_data       : out    std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC - Data
         o_sq1_adc_oor        : out    std_logic                                                            ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

         i_clk_sq1_dac        : in     std_logic                                                            ; --! SQUID1 DAC - Clock
         i_sq1_dac_data       : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC - Data
         i_sq1_dac_sleep      : in     std_logic                                                            ; --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)

         i_sq2_dac_data       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Data
         i_sq2_dac_sclk       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Clock
         i_sq2_dac_sync_n     : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization ('0' = Active, '1' = Inactive)
         i_sq2_dac_mux        : in     std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC - Multiplexer
         i_sq2_dac_mx_en_n    : in     std_logic                                                              --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)
   );
end entity squid_model;

architecture Behavioral of squid_model is
-- TODO
constant c_SQ1_ADC_V_MIN      : real      := - c_SQ1_ADC_VREF - 0.1 * real(g_NB_COL+1)                      ; --! SQUID1 ADC input minimum value
constant c_SQ1_ADC_V_MAX      : real      :=   c_SQ1_ADC_VREF                                               ; --! SQUID1 ADC input maximum value
constant c_SQ1_ADC_LIN_SLOP   : real      := (c_SQ1_ADC_V_MAX - c_SQ1_ADC_V_MIN)/ real(c_PIXEL_ADC_NB_CYC-1); --! SQUID1 ADC linear coefficient slope
constant c_SQ1_ADC_LIN_INTER  : real      := c_SQ1_ADC_V_MIN                                                ; --! SQUID1 ADC linear coefficient y-intercept

signal   sq1_adc_delta_vin    : real      := c_SQ1_ADC_V_MIN                                                ; --! SQUID1 ADC input (Vin+ - Vin-)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC model management
   -- ------------------------------------------------------------------------------------------------------
   I_adc_model: entity work.adc_ad9254_model generic map
   (     g_VREF               => c_SQ1_ADC_VREF       , -- real                                             ; --! Voltage reference (Volt)
         g_CLK_PER            => g_CLK_ADC_PER        , -- time                                             ; --! Clock period (>= 6700 ps)
         g_TIME_TPD           => g_TIM_ADC_TPD          -- time                                               --! Time: Data Propagation Delay
   ) port map
   (     i_clk                => i_clk_sq1_adc        , -- in     std_logic                                 ; --! Clock
         i_pwdn               => i_sq1_adc_pwdn       , -- in     std_logic                                 ; --! Power down ('0' = Inactive, '1' = Active)
         i_oeb_n              => '0'                  , -- in     std_logic                                 ; --! Output enable ('0' = Active, '1' = Inactive)
         b_sdio_dcs           => b_sq1_adc_spi_sdio   , -- inout  std_logic                                 ; --! SPI Data in/out, Duty Cycle stabilizer select ('0' = Disable, '1' = Enable)
         i_sclk_dfs           => i_sq1_adc_spi_sclk   , -- in     std_logic                                 ; --! SPI Serial clock, Data Format select ('0' = Binary, '1' = Twos complement)
         i_csb_n              => i_sq1_adc_spi_cs_n   , -- in     std_logic                                 ; --! SPI Chip Select ('0' = Active, '1' = Inactive)

         i_delta_vin          => sq1_adc_delta_vin    , -- in     real                                      ; --! Analog voltage (-g_VREF <= Vin+ - Vin- < g_VREF)
         o_dco                => open                 , -- out    std_logic                                 ; --! Data clock
         o_d                  => o_sq1_adc_data       , -- out    std_logic_vector(13 downto 0)             ; --! Data
         o_or                 => o_sq1_adc_oor          -- out    std_logic                                   --! Out of range indicator ('0' = Range, '1' = Out of range)
   );

   -- TODO
   P_todo : process
   begin

      wait until rising_edge(i_sync);

      G_pixel_nb: for j in 0 to c_MUX_FACT-1 loop

         G_pixel_time: for k in 0 to c_PIXEL_ADC_NB_CYC-1 loop

            sq1_adc_delta_vin  <= c_SQ1_ADC_LIN_SLOP * real(k) + c_SQ1_ADC_LIN_INTER;
            wait for 2*c_CLK_ADC_HPER;

         end loop G_pixel_time;

      end loop G_pixel_nb;

   end process P_todo;

end architecture Behavioral;
