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
--!   @file                   fpga_system_fpasim_top.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Model when FPASIM is not required
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity fpga_system_fpasim_top is generic (
         g_ADC_VPP            : natural := c_FPA_ADC_VPP_DEF                                                ; --! ADC differential input voltage (Volt)
         g_ADC_DELAY          : natural := c_FPA_ADC_DEL_DEF                                                ; --! ADC conversion delay (clock cycle number)
         g_DAC_VPP            : natural := c_FPA_DAC_VPP_DEF                                                ; --! DAC differential output voltage (Volt)
         g_DAC_DELAY          : natural := c_FPA_DAC_DEL_DEF                                                ; --! DAC conversion delay (clock cycle number)
         g_FPASIM_GAIN        : natural := c_FPA_ERR_GAIN_DEF                                               ; --! FPASIM cmd: Error gain (0:0.25, 1:0.5, 3:1, 4:1.5, 5:2, 6:3, 7:4)
         g_MUX_SQ_FB_DELAY    : natural := c_FPA_MUX_SQ_DEL_DEF                                             ; --! FPASIM cmd: Squid MUX delay (clock cycle number) (<= 63)
         g_AMP_SQ_OF_DELAY    : natural := c_FPA_AMP_SQ_DEL_DEF                                             ; --! FPASIM cmd: Squid AMP delay (clock cycle number) (<= 63)
         g_ERROR_DELAY        : natural := c_FPA_ERR_DEL_DEF                                                ; --! FPASIM cmd: Error delay (clock cycle number) (<= 63)
         g_RA_DELAY           : natural := c_FPA_SYNC_DEL_DEF                                               ; --! FPASIM cmd: Pixel sequence sync. delay (clock cycle number) (<= 63)
         g_INTER_SQUID_GAIN   : natural := c_FPA_INR_SQ_GN_DEF                                              ; --! FPASIM cmd: Inter squid gain (<= 255)
         g_NB_PIXEL_BY_FRAME  : natural := c_MUX_FACT                                                       ; --! DEMUX multiplexing factor
         g_NB_SAMPLE_BY_PIXEL : natural := c_FPA_PXL_NB_CYC_DEF                                               --! Clock cycles number by pixel
   ); port (
         i_make_pulse_valid   : in     std_logic                                                            ; --! FPASIM command valid ('0' = No, '1' = Yes)
         i_make_pulse         : in     std_logic_vector(c_FPA_CMD_S-1 downto 0)                             ; --! FPASIM command
         o_auto_conf_busy     : out    std_logic                                                            ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
         o_ready              : out    std_logic                                                            ; --! FPASIM command ready ('0' = No, '1' = Yes)

         i_adc_clk_phase      : in     std_logic                                                            ; --! FPASIM ADC 90 degrees shifted clock
         i_adc_clk            : in     std_logic                                                            ; --! FPASIM ADC clock
         i_adc0_real          : in     real                                                                 ; --! FPASIM ADC Analog Squid MUX
         i_adc1_real          : in     real                                                                 ; --! FPASIM ADC Analog Squid AMP

         o_ref_clk            : out    std_logic                                                            ; --! Reference Clock
         o_sync               : out    std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         o_dac_real_valid     : out    std_logic                                                            ; --! FPASIM DAC Error valid ('0' = No, '1' = Yes)
         o_dac_real           : out    real                                                                   --! FPASIM DAC Analog Error
   );
end entity fpga_system_fpasim_top;

architecture Behavioral of fpga_system_fpasim_top is

begin

   o_auto_conf_busy  <= c_LOW_LEV;
   o_ready           <= c_HGH_LEV;

   o_dac_real_valid  <= c_LOW_LEV;
   o_dac_real        <= c_ZERO_REAL;

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock reference generation
   -- ------------------------------------------------------------------------------------------------------
   I_clock_model: clock_model port map (
         o_clk_ref            => o_ref_clk            , -- out    std_logic                                 ; --! Reference Clock
         o_sync               => o_sync                 -- out    std_logic                                   --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   );

end architecture Behavioral;
