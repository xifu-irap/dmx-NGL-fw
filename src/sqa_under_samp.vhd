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
--!   @file                   sqa_under_samp.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP under-sampling filters
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_fir.all;

entity sqa_under_samp is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_saofm              : in     std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)                      ; --! SQUID AMP offset mode
         i_saofc              : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP lockpoint coarse offset

         i_sqm_dta_err_frst   : in     std_logic                                                            ; --! SQUID MUX Data error corrected first pixel
         i_sqm_dta_err_cor    : in     std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         i_sqm_dta_err_cor_cs : in     std_logic                                                            ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         o_sqa_fb_close       : out    std_logic_vector(c_SQA_DAC_DATA_S-1 downto 0)                          --! SQUID AMP feedback close mode
   );
end entity sqa_under_samp;

architecture RTL of sqa_under_samp is
constant c_FIR1_DATA_S        : integer:= c_SQM_DATA_FBK_S                                                  ; --! Filter FIR1: Data input bus size
constant c_FIR2_DATA_S        : integer:= c_RAM_ECC_DATA_S                                                  ; --! Filter FIR2: Data input bus size
constant c_FIR2_RES_S         : integer:= c_SQA_DAC_DATA_S + 1                                              ; --! Filter FIR2: Result bus size

signal   sqm_dta_err_fst_r    : std_logic                                                                   ; --! SQUID MUX Data error corrected first pixel register
signal   sqm_dta_err_rdy      : std_logic                                                                   ; --! SQUID MUX Data error corrected ready

signal   fir_init_ena         : std_logic                                                                   ; --! Filter FIR: initialization enable

signal   fir1_saofc_stall_msb : std_logic_vector(c_FIR1_DATA_S-2 downto 0)                                  ; --! Filter FIR1: SQUID AMP lockpoint coarse offset stall on msb
signal   fir1_init_val        : std_logic_vector(c_FIR1_DATA_S-1 downto 0)                                  ; --! Filter FIR1: initialization value
signal   fir1_res             : std_logic_vector(c_FIR2_DATA_S   downto 0)                                  ; --! Filter FIR1: result
signal   fir1_res_sat         : std_logic_vector(c_FIR2_DATA_S-1 downto 0)                                  ; --! Filter FIR1: result with saturation
signal   fir1_res_rdy         : std_logic                                                                   ; --! Filter FIR1: result ready ('0' = Inactive, '1' = Active)
signal   fir1_res_rdy_r       : std_logic                                                                   ; --! Filter FIR1: result ready register

signal   fir2_saofc_stall_msb : std_logic_vector(c_FIR2_DATA_S-2 downto 0)                                  ; --! Filter FIR2: SQUID AMP lockpoint coarse offset stall on msb
signal   fir2_init_val        : std_logic_vector(c_FIR2_DATA_S-1 downto 0)                                  ; --! Filter FIR2: initialization value
signal   fir2_res             : std_logic_vector( c_FIR2_RES_S-1 downto 0)                                  ; --! Filter FIR2: result
signal   fir2_res_rdy         : std_logic                                                                   ; --! Filter FIR2: result ready ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_dta_err_fst_r <= c_LOW_LEV;
         fir1_res_rdy_r    <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         sqm_dta_err_fst_r <= i_sqm_dta_err_frst;
         fir1_res_rdy_r    <= fir1_res_rdy;

      end if;

   end process P_sig_r;

   sqm_dta_err_rdy <= sqm_dta_err_fst_r and i_sqm_dta_err_cor_cs;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR: initialization enable
   -- ------------------------------------------------------------------------------------------------------
   P_fir_init_ena : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_init_ena   <= c_HGH_LEV;

      elsif rising_edge(i_clk) then
         if (i_sqm_dta_err_cor_cs and i_sqm_dta_err_frst) = c_HGH_LEV then
            if i_saofm = c_DST_SAOFM_CLOSE then
               fir_init_ena   <= c_LOW_LEV;

            else
               fir_init_ena   <= c_HGH_LEV;

            end if;

         end if;

      end if;

   end process P_fir_init_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1: initialization value
   -- ------------------------------------------------------------------------------------------------------
   I_fir1_saofc_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SAOFC_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_FIR1_DATA_S - 1      -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_saofc              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => fir1_saofc_stall_msb , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   fir1_init_val <= std_logic_vector(resize(unsigned(fir1_saofc_stall_msb), fir1_init_val'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1
   -- ------------------------------------------------------------------------------------------------------
   I_fir_deci1: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_SQA_FIR1_DCI_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => c_SQA_FIR1_TAB_NW    , -- integer                                          ; --! Filter FIR table number word
         g_FIR_COEF_S         => c_SQA_FIR1_S         , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => c_SQA_FIR1_TAB       , -- t_slv_arr g_FIR_TAB_NW g_FIR_COEF_S              ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => c_SQA_FIR1_COEF_SM_S , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => c_FIR1_DATA_S        , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_RES_S          => c_FIR2_DATA_S + 1      -- integer                                            --! Filter FIR result bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => fir1_init_val        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => fir_init_ena         , -- in     std_logic                                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)

         i_data               => i_sqm_dta_err_cor    , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => sqm_dta_err_rdy      , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => fir1_res             , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => fir1_res_rdy           -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1 result with saturation
   -- ------------------------------------------------------------------------------------------------------
   P_fir1_res_sat : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir1_res_sat <= c_ZERO(fir1_res_sat'range);

      elsif rising_edge(i_clk) then

         -- Saturation on minimum value
         if    (fir1_res(fir1_res'high) and not(fir1_res(fir1_res'high-1))) = c_HGH_LEV then
            fir1_res_sat(fir1_res_sat'high)           <= c_HGH_LEV;
            fir1_res_sat(fir1_res_sat'high-1 downto 0)<= (others => c_LOW_LEV);

         -- Saturation on maximum value
         elsif (not(fir1_res(fir1_res'high)) and fir1_res(fir1_res'high-1)) = c_HGH_LEV then
            fir1_res_sat(fir1_res_sat'high)           <= c_LOW_LEV;
            fir1_res_sat(fir1_res_sat'high-1 downto 0)<= (others => c_HGH_LEV);

         else
            fir1_res_sat <= fir1_res(fir1_res_sat'high downto 0);

         end if;

      end if;

   end process P_fir1_res_sat;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2: initialization value
   -- ------------------------------------------------------------------------------------------------------
   I_fir2_saofc_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SAOFC_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_FIR2_DATA_S - 1      -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_saofc              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => fir2_saofc_stall_msb , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   fir2_init_val <= std_logic_vector(resize(unsigned(fir2_saofc_stall_msb), fir2_init_val'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2
   -- ------------------------------------------------------------------------------------------------------
   I_fir_deci2: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_SQA_FIR2_DCI_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => c_SQA_FIR2_TAB_NW    , -- integer                                          ; --! Filter FIR table number word
         g_FIR_COEF_S         => c_SQA_FIR2_S         , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => c_SQA_FIR2_TAB       , -- t_slv_arr g_FIR_TAB_NW g_FIR_COEF_S              ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => c_SQA_FIR2_COEF_SM_S , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => c_FIR2_DATA_S        , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_RES_S          => c_FIR2_RES_S           -- integer                                            --! Filter FIR result bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => fir2_init_val        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => fir_init_ena         , -- in     std_logic                                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)

         i_data               => fir1_res_sat         , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => fir1_res_rdy_r       , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => fir2_res             , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => fir2_res_rdy           -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fb_close : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqa_fb_close <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk) then
         if fir_init_ena = c_HGH_LEV then
            o_sqa_fb_close <= i_saofc;

         elsif fir2_res_rdy = c_HGH_LEV then

            -- Saturation in case of negative FIR2 filter output
            if fir2_res(fir2_res'high) = c_HGH_LEV then
               o_sqa_fb_close <= c_ZERO(o_sqa_fb_close'range);

            else
               o_sqa_fb_close <= std_logic_vector(resize(unsigned(fir2_res), o_sqa_fb_close'length));

            end if;

         end if;

      end if;

   end process P_sqa_fb_close;

end architecture RTL;
