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
--!   @file                   DRE_DMX_UT_0110_cfg.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                DRE DEMUX Unitary Test configuration file
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
configuration DRE_DMX_UT_0110_cfg of top_dmx_tb is

   for Simulation

      -- ------------------------------------------------------------------------------------------------------
      --!   Parser configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_parser : parser
         use entity work.parser generic map
         (
            g_SIM_TIME           => 1470000 ns           , -- time    := c_SIM_TIME_DEF                     ; --! Simulation time
            g_TST_NUM            => "0110"                 -- string  := c_TST_NUM_DEF                        --! Test number
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   Science data model configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_science_data_model: science_data_model
         use entity work.science_data_model generic map
         (
            g_SIM_TIME           => 1470000 ns           , -- time    := c_SIM_TIME_DEF                     ; --! Simulation time
            g_TST_NUM            => "0110"                 -- string  := c_TST_NUM_DEF                        --! Test number
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   Squid model configuration
      -- ------------------------------------------------------------------------------------------------------
      for G_column_mgt(0)
         for I_squid_model: squid_model
            use entity work.squid_model generic map
            (
            g_SQ1_ADC_VREF_DEF   => 0.9999               , -- real      := c_SQ1_ADC_VREF_DEF               ; --! SQUID1 ADC - Voltage reference (Volt)
            g_SQ1_DAC_VREF_DEF   => c_SQ1_DAC_VREF_DEF   , -- real      := c_SQ1_DAC_VREF_DEF               ; --! SQUID1 DAC - Voltage reference (Volt)
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID1 ADC - Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF      -- time      := c_TIM_ADC_TPD_DEF                  --! SQUID1 ADC - Time, Data Propagation Delay
            );
         end for;
      end for;

      for G_column_mgt(1)
         for I_squid_model: squid_model
            use entity work.squid_model generic map
            (
            g_SQ1_ADC_VREF_DEF   => 0.999                , -- real      := c_SQ1_ADC_VREF_DEF               ; --! SQUID1 ADC - Voltage reference (Volt)
            g_SQ1_DAC_VREF_DEF   => c_SQ1_DAC_VREF_DEF   , -- real      := c_SQ1_DAC_VREF_DEF               ; --! SQUID1 DAC - Voltage reference (Volt)
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID1 ADC - Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF      -- time      := c_TIM_ADC_TPD_DEF                  --! SQUID1 ADC - Time, Data Propagation Delay
            );
         end for;
      end for;

      for G_column_mgt(2)
         for I_squid_model: squid_model
            use entity work.squid_model generic map
            (
            g_SQ1_ADC_VREF_DEF   => 0.99                 , -- real      := c_SQ1_ADC_VREF_DEF               ; --! SQUID1 ADC - Voltage reference (Volt)
            g_SQ1_DAC_VREF_DEF   => c_SQ1_DAC_VREF_DEF   , -- real      := c_SQ1_DAC_VREF_DEF               ; --! SQUID1 DAC - Voltage reference (Volt)
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID1 ADC - Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF      -- time      := c_TIM_ADC_TPD_DEF                  --! SQUID1 ADC - Time, Data Propagation Delay
            );
         end for;
      end for;

      for G_column_mgt(3)
         for I_squid_model: squid_model
            use entity work.squid_model generic map
            (
            g_SQ1_ADC_VREF_DEF   => 0.97                 , -- real      := c_SQ1_ADC_VREF_DEF               ; --! SQUID1 ADC - Voltage reference (Volt)
            g_SQ1_DAC_VREF_DEF   => c_SQ1_DAC_VREF_DEF   , -- real      := c_SQ1_DAC_VREF_DEF               ; --! SQUID1 DAC - Voltage reference (Volt)
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID1 ADC - Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF      -- time      := c_TIM_ADC_TPD_DEF                  --! SQUID1 ADC - Time, Data Propagation Delay
            );
         end for;
      end for;

   end for;

end configuration DRE_DMX_UT_0110_cfg;
