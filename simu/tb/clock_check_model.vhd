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
use     work.pkg_type.all;
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
         i_c0_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         i_c1_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         i_c2_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         i_c3_sq1_adc_pwdn    : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)
         i_c0_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         o_err_chk_rpt        : out    t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)       --! Clock check error reports

   );
end entity clock_check_model;

architecture Behavioral of clock_check_model is
signal   clock                : std_logic_vector(c_CHK_ENA_CLK_NB-1 downto 0)                               ; --! Clocks
signal   enable               : std_logic_vector(c_CHK_ENA_CLK_NB-1 downto 0)                               ; --! Enables
signal   chk_osc_ena_l        : std_logic_vector(c_CHK_ENA_CLK_NB-1 downto 0)                               ; --! Check oscillation on clock when enable inactive ('0' = No, '1' = Yes)
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock signals
   -- ------------------------------------------------------------------------------------------------------
   clock(c_CE_CLK)         <= i_clk;
   clock(c_CE_CK1_ADC)     <= i_clk_sq1_adc_acq;
   clock(c_CE_CK1_PLS)     <= i_clk_sq1_pls_shape;
   clock(c_CE_C0_CK1_ADC)  <= i_c0_clk_sq1_adc;
   clock(c_CE_C1_CK1_ADC)  <= i_c1_clk_sq1_adc;
   clock(c_CE_C2_CK1_ADC)  <= i_c2_clk_sq1_adc;
   clock(c_CE_C3_CK1_ADC)  <= i_c3_clk_sq1_adc;
   clock(c_CE_C0_CK1_DAC)  <= i_c0_clk_sq1_dac;
   clock(c_CE_C1_CK1_DAC)  <= i_c1_clk_sq1_dac;
   clock(c_CE_C2_CK1_DAC)  <= i_c2_clk_sq1_dac;
   clock(c_CE_C3_CK1_DAC)  <= i_c3_clk_sq1_dac;
   clock(c_CE_CLK_SC_01)   <= i_clk_science_01;
   clock(c_CE_CLK_SC_23)   <= i_clk_science_23;

   -- ------------------------------------------------------------------------------------------------------
   --!   Enable signals
   -- ------------------------------------------------------------------------------------------------------
   enable(c_CE_CLK)        <= not(i_rst);
   enable(c_CE_CK1_ADC)    <= not(i_rst);
   enable(c_CE_CK1_PLS)    <= not(i_rst);
   enable(c_CE_C0_CK1_ADC) <= not(i_c0_sq1_adc_pwdn);
   enable(c_CE_C1_CK1_ADC) <= not(i_c1_sq1_adc_pwdn);
   enable(c_CE_C2_CK1_ADC) <= not(i_c2_sq1_adc_pwdn);
   enable(c_CE_C3_CK1_ADC) <= not(i_c3_sq1_adc_pwdn);
   enable(c_CE_C0_CK1_DAC) <= not(i_c0_sq1_dac_sleep);
   enable(c_CE_C1_CK1_DAC) <= not(i_c1_sq1_dac_sleep);
   enable(c_CE_C2_CK1_DAC) <= not(i_c2_sq1_dac_sleep);
   enable(c_CE_C3_CK1_DAC) <= not(i_c3_sq1_dac_sleep);
   enable(c_CE_CLK_SC_01)  <= not(i_rst);
   enable(c_CE_CLK_SC_23)  <= not(i_rst);

   -- ------------------------------------------------------------------------------------------------------
   --!   Enable signals
   -- ------------------------------------------------------------------------------------------------------
   chk_osc_ena_l(c_CE_CLK)       <= c_CCHK(c_CE_CLK).chk_osc_en;
   chk_osc_ena_l(c_CE_CK1_ADC)   <= c_CCHK(c_CE_CK1_ADC).chk_osc_en;
   chk_osc_ena_l(c_CE_CK1_PLS)   <= c_CCHK(c_CE_CK1_PLS).chk_osc_en;
   chk_osc_ena_l(c_CE_C0_CK1_ADC)<= c_CCHK(c_CE_C0_CK1_ADC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C1_CK1_ADC)<= c_CCHK(c_CE_C1_CK1_ADC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C2_CK1_ADC)<= c_CCHK(c_CE_C2_CK1_ADC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C3_CK1_ADC)<= c_CCHK(c_CE_C3_CK1_ADC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C0_CK1_DAC)<= c_CCHK(c_CE_C0_CK1_DAC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C1_CK1_DAC)<= c_CCHK(c_CE_C1_CK1_DAC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C2_CK1_DAC)<= c_CCHK(c_CE_C2_CK1_DAC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_C3_CK1_DAC)<= c_CCHK(c_CE_C3_CK1_DAC).chk_osc_en and not(i_rst);
   chk_osc_ena_l(c_CE_CLK_SC_01) <= c_CCHK(c_CE_CLK_SC_01).chk_osc_en;
   chk_osc_ena_l(c_CE_CLK_SC_23) <= c_CCHK(c_CE_CLK_SC_23).chk_osc_en;

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock check
   -- ------------------------------------------------------------------------------------------------------
   G_clock_check: for k in 0 to c_CHK_ENA_CLK_NB-1 generate
   begin

      I_clock_check: entity work.clock_check generic map
      (  g_CLK_PER_L          => c_CCHK(k).clk_per_l  , -- time                                             ; --! Low  level clock period expected time
         g_CLK_PER_H          => c_CCHK(k).clk_per_h  , -- time                                             ; --! High level clock period expected time
         g_CLK_ST_ENA         => c_CCHK(k).clk_st_ena , -- std_logic                                        ; --! Clock state value when enable goes to active
         g_CLK_ST_DIS         => c_CCHK(k).clk_st_dis   -- std_logic                                          --! Clock state value when enable goes to inactive
      ) port map
      (  i_clk                => clock(k)             , -- in     std_logic                                 ; --! Clock
         i_ena                => enable(k)            , -- in     std_logic                                 ; --! Enable ('0' = Inactive, '1' = Active)
         i_chk_osc_ena_l      => chk_osc_ena_l(k)     , -- in     std_logic                                 ; --! Check oscillation on clock when enable inactive ('0' = No, '1' = Yes)
         o_err_n_clk_chk      => o_err_chk_rpt(k)       -- out    t_int_arr(0 to c_ERR_N_CLK_CHK_S-1)         --! Clock check error number
      );

   end generate G_clock_check;

end architecture Behavioral;
