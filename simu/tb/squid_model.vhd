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
   (     g_SQ1_ADC_VREF_DEF   : real      := c_SQ1_ADC_VREF_DEF                                             ; --! SQUID1 ADC - Voltage reference (Volt)
         g_SQ1_DAC_VREF_DEF   : real      := c_SQ1_DAC_VREF_DEF                                             ; --! SQUID1 DAC - Voltage reference (Volt)
         g_CLK_ADC_PER        : time      := c_CLK_ADC_PER_DEF                                              ; --! SQUID1 ADC - Clock period
         g_TIM_ADC_TPD        : time      := c_TIM_ADC_TPD_DEF                                                --! SQUID1 ADC - Time, Data Propagation Delay
   ); port
   (     i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

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

         i_pls_shp_fc         : in     integer                                                              ; --! Pulse shaping cut frequency (Hz)
         o_sq1_dac_ana        : out    real                                                                 ; --! SQUID1 DAC - Analog
         o_err_num_pls_shp    : out    integer                                                              ; --! Pulse shaping error number

         i_sq2_dac_data       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Data
         i_sq2_dac_sclk       : in     std_logic                                                            ; --! SQUID2 DAC - Serial Clock
         i_sq2_dac_snc_l_n    : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sq2_dac_snc_o_n    : in     std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sq2_dac_mux        : in     std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC - Multiplexer
         i_sq2_dac_mx_en_n    : in     std_logic                                                              --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)
   );
end entity squid_model;

architecture Behavioral of squid_model is
signal   sq1_dac_delta_vout   : real                                                                        ; --! SQUID1 DAC output (Vin+ - Vin-)
signal   sq1_adc_delta_vin    : real                                                                        ; --! SQUID1 ADC input (Vin+ - Vin-)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   DAC model management
   -- ------------------------------------------------------------------------------------------------------
   I_dac_model: entity work.dac_dac5675a_model generic map
   (     g_VREF               => c_SQ1_DAC_VREF_DEF     -- real                                               --! Voltage reference (Volt)
   ) port map
   (     i_clk                => i_clk_sq1_dac        , -- in     std_logic                                 ; --! Clock
         i_sleep              => i_sq1_dac_sleep      , -- in     std_logic                                 ; --! Sleep ('0' = Inactive, '1' = Active)
         i_d                  => i_sq1_dac_data       , -- in     std_logic_vector(13 downto 0)             ; --! Data
         o_delta_vout         => sq1_dac_delta_vout     -- out    real                                        --! Analog voltage (-g_VREF <= Vout1 - Vout2 < g_VREF)
   );

   o_sq1_dac_ana     <= sq1_dac_delta_vout;
   sq1_adc_delta_vin <= sq1_dac_delta_vout;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse shaping check
   -- ------------------------------------------------------------------------------------------------------
   I_pulse_shaping_check: entity work.pulse_shaping_check port map
   (     i_arst               => i_arst               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sq1_dac        => i_clk_sq1_dac        , -- in     std_logic                                 ; --! SQUID1 DAC - Clock
         i_sync               => i_sync               , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_sq1_dac_ana        => sq1_dac_delta_vout   , -- in     real                                      ; --! SQUID1 DAC - Analog
         i_pls_shp_fc         => i_pls_shp_fc         , -- in     integer                                   ; --! Pulse shaping cut frequency (Hz)

         o_err_num_pls_shp    => o_err_num_pls_shp      -- out    integer                                     --! Pulse shaping error number
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC model management
   -- ------------------------------------------------------------------------------------------------------
   I_adc_model: entity work.adc_ad9254_model generic map
   (     g_VREF               => g_SQ1_ADC_VREF_DEF   , -- real                                             ; --! Voltage reference (Volt)
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

end architecture Behavioral;
