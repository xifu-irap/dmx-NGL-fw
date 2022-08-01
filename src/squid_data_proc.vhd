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
--!   @file                   squid_data_proc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid_data_proc is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_bxlgt              : in     std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging
         i_sqm_data_err       : in     std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error
         i_sqm_data_err_frst  : in     std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  : in     std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   : in     std_logic                                                            ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_sqm_data_sc_msb    : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! SQUID MUX Data science MSB
         o_sqm_data_sc_lsb    : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! SQUID MUX Data science LSB
         o_sqm_data_sc_first  : out    std_logic                                                            ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   : out    std_logic                                                            ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    : out    std_logic                                                            ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_sqm_dta_pixel_pos  : out    std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_cor    : out    std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         o_sqm_dta_err_cor_cs : out    std_logic                                                              --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)
   );
end entity squid_data_proc;

architecture RTL of squid_data_proc is
constant c_ADC_SMP_AVE_NPER   : integer := c_DSP_NPER + 2                                                   ; --! Clock period number for ADC sample average from SQUID MUX Data error ready

constant c_ADC_SMP_AVE_TOT_S  : integer := c_SQM_ADC_DATA_S + c_ASP_CF_S - 1                                ; --! ADC sample average: DSP Result total size
constant c_ADC_SMP_AVE_LSB    : integer := c_ADC_SMP_AVE_TOT_S - c_ADC_SMP_AVE_S                            ; --! ADC sample average: DSP Result LSB position
constant c_ADC_SMP_AVE_SAT    : integer := c_ADC_SMP_AVE_TOT_S - 1                                          ; --! ADC sample average: saturation

signal   sqm_data_err_frst_r  : std_logic_vector(c_ADC_SMP_AVE_NPER-1 downto 0)                             ; --! SQUID MUX Data science first pixel register
signal   sqm_data_err_last_r  : std_logic_vector(c_ADC_SMP_AVE_NPER-1 downto 0)                             ; --! SQUID MUX Data science last pixel register
signal   sqm_data_err_rdy_r   : std_logic_vector(c_ADC_SMP_AVE_NPER-1 downto 0)                             ; --! SQUID MUX Data science ready register

signal   sqm_adc_ena          : std_logic                                                                   ; --! ADC enable ('0'= No, '1'= Yes)
signal   aqmde_sync           : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Telemetry mode, sync. on first pixel
signal   bxlgt_sync           : std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                             ; --! ADC sample number for averaging, sync. on first pixel

signal   sqm_data_err         : std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                               ; --! SQUID MUX Data error

signal   adc_smp_ave_coef     : std_logic_vector(c_ASP_CF_S-1 downto 0)                                     ; --! ADC sample number for averaging coefficient (unsigned)
signal   adc_smp_ave          : std_logic_vector(c_ADC_SMP_AVE_S-1 downto 0)                                ; --! ADC sample average (unsigned)
signal   adc_smp_ave_sc       : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! ADC sample average for data science (unsigned)

signal   sqm_data_sc          : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! SQUID MUX Data science
signal   sqm_data_sc_first    : std_logic                                                                   ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
signal   sqm_data_sc_last     : std_logic                                                                   ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
signal   sqm_data_sc_rdy      : std_logic                                                                   ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_data_err_frst_r  <= (others => '0');
         sqm_data_err_last_r  <= (others => '0');
         sqm_data_err_rdy_r   <= (others => '0');

      elsif rising_edge(i_clk) then
         sqm_data_err_frst_r  <= sqm_data_err_frst_r(sqm_data_err_frst_r'high-1 downto 0) & i_sqm_data_err_frst;
         sqm_data_err_last_r  <= sqm_data_err_last_r(sqm_data_err_last_r'high-1 downto 0) & i_sqm_data_err_last;
         sqm_data_err_rdy_r   <= sqm_data_err_rdy_r( sqm_data_err_rdy_r'high-1  downto 0) & i_sqm_data_err_rdy;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Registers sync. on first pixel
   -- ------------------------------------------------------------------------------------------------------
   P_reg_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_adc_ena <= '0';
         aqmde_sync  <= c_EP_CMD_DEF_AQMDE;
         bxlgt_sync  <= c_EP_CMD_DEF_BXLGT;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_frst_r(2) and sqm_data_err_rdy_r(2)) = '1' then
            aqmde_sync <= i_aqmde;

         end if;

         if (i_sqm_data_err_frst and i_sqm_data_err_rdy) = '1' then

            if i_aqmde = c_DST_AQMDE_DUMP or i_aqmde = c_DST_AQMDE_SCIE or i_aqmde = c_DST_AQMDE_ERRS or i_smfmd = c_DST_SMFMD_ON then
               sqm_adc_ena <= '1';

            else
               sqm_adc_ena <= '0';

            end if;

         end if;

         if sqm_adc_ena = '0' then
            bxlgt_sync <= c_EP_CMD_DEF_BXLGT;

         elsif (i_sqm_data_err_frst and i_sqm_data_err_rdy) = '1' then
            bxlgt_sync <= i_bxlgt;

         end if;

      end if;

   end process P_reg_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data error
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_err : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_data_err <= std_logic_vector(resize(unsigned(c_I_SQM_ADC_DATA_DEF), sqm_data_err'length));

      elsif rising_edge(i_clk) then
         if sqm_adc_ena = '1' then
            sqm_data_err <= i_sqm_data_err;

         else
            sqm_data_err <= std_logic_vector(resize(unsigned(c_I_SQM_ADC_DATA_DEF), sqm_data_err'length));

         end if;

      end if;

   end process P_sqm_data_err;

   -- ------------------------------------------------------------------------------------------------------
   --!   Get ADC sample number for averaging coefficient from table
   --    @Req : DRE-DMX-FW-REQ-0145
   -- ------------------------------------------------------------------------------------------------------
   P_adc_smp_ave_coef : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         adc_smp_ave_coef <= c_ADC_SMP_AVE_TAB(to_integer(unsigned(c_EP_CMD_DEF_BXLGT)));

      elsif rising_edge(i_clk) then
         adc_smp_ave_coef <= c_ADC_SMP_AVE_TAB(to_integer(unsigned(bxlgt_sync)));

      end if;

   end process P_adc_smp_ave_coef;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC sample average
   --    @Req : DRE-DMX-FW-REQ-0140
   -- ------------------------------------------------------------------------------------------------------
   I_adc_smp_ave: entity work.dsp generic map
   (     g_PORTA_S            => c_ASP_CF_S           , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SQM_DATA_ERR_S     , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_SQM_DATA_ERR_S     , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_ADC_SMP_AVE_S      , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_ADC_SMP_AVE_LSB    , -- integer                                          ; --! Result LSB position

         g_DATA_TYPE          => c_MULT_ALU_UNSIGNED  , -- bit                                              ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           => c_ADC_SMP_AVE_SAT    , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => '0'                  , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => '0'                    -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => '0'                  , -- in     std_logic                                 ; --! Carry In
         i_a                  => adc_smp_ave_coef     , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => sqm_data_err         , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => (others => '0')      , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => (others => '0')      , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => (others => '0')      , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         o_z                  => adc_smp_ave          , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC sample average for science (rounded operation)
   -- ------------------------------------------------------------------------------------------------------
   adc_smp_ave_sc <= std_logic_vector(unsigned(adc_smp_ave(adc_smp_ave'high                                        downto adc_smp_ave'length-c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S)) +
                               resize(unsigned(adc_smp_ave(adc_smp_ave'length-c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto adc_smp_ave'length-c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1)),
                                               adc_smp_ave_sc'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_sc : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sqm_data_sc_msb    <= (others => '0');
         o_sqm_data_sc_lsb    <= (others => '0');
         o_sqm_data_sc_first  <= '0';
         o_sqm_data_sc_last   <= '0';
         o_sqm_data_sc_rdy    <= '0';

      elsif rising_edge(i_clk) then
         if aqmde_sync = c_DST_AQMDE_ERRS then
            o_sqm_data_sc_msb    <= adc_smp_ave_sc(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
            o_sqm_data_sc_lsb    <= adc_smp_ave_sc(  c_SC_DATA_SER_W_S-1 downto 0);
            o_sqm_data_sc_first  <= sqm_data_err_frst_r(sqm_data_err_frst_r'high);
            o_sqm_data_sc_last   <= sqm_data_err_last_r(sqm_data_err_last_r'high);
            o_sqm_data_sc_rdy    <= sqm_data_err_rdy_r(sqm_data_err_rdy_r'high);

         else
            o_sqm_data_sc_msb    <= sqm_data_sc(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
            o_sqm_data_sc_lsb    <= sqm_data_sc(  c_SC_DATA_SER_W_S-1 downto 0);
            o_sqm_data_sc_first  <= sqm_data_sc_first;
            o_sqm_data_sc_last   <= sqm_data_sc_last;
            o_sqm_data_sc_rdy    <= sqm_data_sc_rdy;

         end if;
      end if;

   end process P_sqm_data_sc;

   --TODO
   sqm_data_sc       <= (others => '0');
   sqm_data_sc_first <= sqm_data_err_frst_r(sqm_data_err_frst_r'high);
   sqm_data_sc_last  <= sqm_data_err_last_r(sqm_data_err_last_r'high);
   sqm_data_sc_rdy   <= sqm_data_err_rdy_r(sqm_data_err_rdy_r'high);

   o_sqm_dta_pixel_pos  <= (others => '0');
   o_sqm_dta_err_cor    <= (others => '0');
   o_sqm_dta_err_cor_cs <= '0';

end architecture RTL;
