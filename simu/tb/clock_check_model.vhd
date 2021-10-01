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
--!   @file                   clock_check_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Periodic signals model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_model.all;

entity clock_check_model is port
   (     i_clk                : in     std_logic                                                            ; --! Internal design: System Clock
         i_clk_sq1_adc_acq    : in     std_logic                                                            ; --! Internal design: SQUID1 ADC acquisition Clock
         i_clk_sq1_pls_shape  : in     std_logic                                                            ; --! Internal design: SQUID1 pulse shaping Clock
         i_c0_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 - Clock
         i_c1_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 - Clock
         i_c2_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 - Clock
         i_c3_clk_sq1_adc     : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 - Clock
         i_c0_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Clock
         i_c1_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Clock
         i_c2_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Clock
         i_c3_clk_sq1_dac     : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Clock
         i_clk_science_01     : in     std_logic                                                            ; --! Science Data - Clock channel 0/1
         i_clk_science_23     : in     std_logic                                                            ; --! Science Data - Clock channel 2/3

         i_rst                : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_c0_sq1_adc_pwdn	   : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         i_c1_sq1_adc_pwdn	   : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         i_c2_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         i_c3_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)
         i_c0_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         o_err_chk_rpt        : out    t_err_n_clk_chk_arr(0 to c_CE_S-1)                                     --! Clock check error reports

   );
end entity clock_check_model;

architecture Behavioral of clock_check_model is
signal   clock                : std_logic_vector(c_CE_S-1 downto 0)                                         ; --! Clocks
signal   enable               : std_logic_vector(c_CE_S-1 downto 0)                                         ; --! Enables
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock signals
   -- ------------------------------------------------------------------------------------------------------
   clock(0)    <= i_clk;
   clock(1)    <= i_clk_sq1_adc_acq;
   clock(2)    <= i_clk_sq1_pls_shape;
   clock(3)    <= i_c0_clk_sq1_adc;
   clock(4)    <= i_c1_clk_sq1_adc;
   clock(5)    <= i_c2_clk_sq1_adc;
   clock(6)    <= i_c3_clk_sq1_adc;
   clock(7)    <= i_c0_clk_sq1_dac;
   clock(8)    <= i_c1_clk_sq1_dac;
   clock(9)    <= i_c2_clk_sq1_dac;
   clock(10)   <= i_c3_clk_sq1_dac;
   clock(11)   <= i_clk_science_01;
   clock(12)   <= i_clk_science_23;

   -- ------------------------------------------------------------------------------------------------------
   --!   Enable signals
   -- ------------------------------------------------------------------------------------------------------
   enable(0)   <= not(i_rst);
   enable(1)   <= not(i_rst);
   enable(2)   <= not(i_rst);
   enable(3)   <= not(i_c0_sq1_adc_pwdn);
   enable(4)   <= not(i_c1_sq1_adc_pwdn);
   enable(5)   <= not(i_c2_sq1_adc_pwdn);
   enable(6)   <= not(i_c3_sq1_adc_pwdn);
   enable(7)   <= not(i_c0_sq1_dac_sleep);
   enable(8)   <= not(i_c1_sq1_dac_sleep);
   enable(9)   <= not(i_c2_sq1_dac_sleep);
   enable(10)  <= not(i_c3_sq1_dac_sleep);
   enable(11)  <= not(i_rst);
   enable(12)  <= not(i_rst);

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock check
   -- ------------------------------------------------------------------------------------------------------
   G_clock_check: for k in 0 to c_CE_S-1 generate
   begin

      I_clock_check: entity work.clock_check generic map
      (  g_CLK_PER_L          => c_CCHK(k).clk_per_l  , -- time                                             ; --! Low  level clock period expected time
         g_CLK_PER_H          => c_CCHK(k).clk_per_h  , -- time                                             ; --! High level clock period expected time
         g_CLK_ST_ENA_H       => c_CCHK(k).clk_st_ena   -- std_logic                                          --! Clock state value when enable goes to active
      ) port map
      (  i_clk                => clock(k)             , -- in     std_logic                                 ; --! Clock
         i_ena                => enable(k)            , -- in     std_logic                                 ; --! Enable ('0' = Inactive, '1' = Active)
         i_chk_osc_ena_l      => c_CCHK(k).chk_osc_en , -- in     std_logic                                 ; --! Check oscillation on clock when enable inactive ('0' = No, '1' = Yes)
         o_err_n_clk_chk      => o_err_chk_rpt(k)       -- out    t_err_n_clk_chk                             --! Clock check error number
      );

   end generate G_clock_check;

end architecture Behavioral;
