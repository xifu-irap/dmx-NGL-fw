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
--!   @file                   sqm_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID MUX DAC management
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

entity sqm_dac_mgt is port (
         i_rst_sqm_adc_dac    : in     std_logic                                                            ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID ADC/DAC internal Clock
         i_clk_sqm_adc_dac_90 : in     std_logic                                                            ; --! SQUID ADC/DAC internal 90 degrees shift

         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sqm_data_fbk       : in     std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data feedback (signed)
         i_sqm_pixel_pos_init : in     std_logic_vector( c_SQM_PXL_POS_S-1 downto 0)                        ; --! SQUID MUX Pixel position initialization
         i_sqm_pls_cnt_init   : in     std_logic_vector( c_SQM_PLS_CNT_S-1 downto 0)                        ; --! SQUID MUX Pulse shaping counter initialization

         i_plsss              : in     std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0)                      ; --! SQUID MUX feedback pulse shaping set
         i_mem_plssh          : in     t_mem(
                                       add(              c_MEM_PLSSH_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_PLSSH_PLS_S-1 downto 0))                     ; --! SQUID MUX feedback pulse shaping coefficient: memory inputs
         o_plssh_data         : out    std_logic_vector(c_DFLD_PLSSH_PLS_S-1 downto 0)                      ; --! SQUID MUX feedback pulse shaping coefficient: data read

         o_sqm_dac_data       : out    std_logic_vector(c_SQM_DAC_DATA_S-1 downto 0)                          --! SQUID MUX DAC: Data
   );
end entity sqm_dac_mgt;

architecture RTL of sqm_dac_mgt is
constant c_PLS_VAL_SYNC_PRM   : integer:= c_SQM_PLS_CNT_MX_VAL - (c_DAC_MEM_PRM_NPER-1)                     ; --! Pulse shaping counter value for synchronized data inputs with A[k] filter parameter

signal   sync_rs_rsys         : std_logic                                                                   ; --! Pixel sequence synchronization register (System Clock)
signal   plsss_rsys           : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0)                             ; --! SQUID MUX feedback pulse shaping set register (System clock)

signal   rst_sqm_adc_dac_loc  : std_logic                                                                   ; --! Local reset for SQUID ADC/DAC, de-assertion on system clock

signal   sync_r               : std_logic_vector(     c_FF_RSYNC_NB+1 downto 0)                             ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   sync_re              : std_logic                                                                   ; --! Pixel sequence sync. rising edge
signal   sqm_data_fbk_r       : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_SQM_DATA_FBK_S-1 downto 0)                ; --! SQUID MUX Data feedback register
signal   sqm_pixel_pos_init_r : t_slv_arr(0 to c_FF_RSYNC_NB-1)(   c_SQM_PXL_POS_S-1 downto 0)              ; --! Pixel position initialization register
signal   sqm_pls_cnt_init_r   : t_slv_arr(0 to c_FF_RSYNC_NB-1)(   c_SQM_PLS_CNT_S-1 downto 0)              ; --! Pulse shaping counter initialization register
signal   plsss_r              : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_PLSSS_PLS_S-1 downto 0)              ; --! SQUID MUX feedback pulse shaping set register
signal   mem_plssh_pp_r       : std_logic_vector(       c_FF_RSYNC_NB-1 downto 0)                           ; --! Memory pulse shaping coefficient: ping-pong buffer bit for address management register

signal   pls_cnt              : std_logic_vector(     c_SQM_PLS_CNT_S-1 downto 0)                           ; --! Pulse shaping counter
signal   pls_cnt_msb_r        : std_logic                                                                   ; --! Pulse shaping counter MSB register
signal   pixel_pos            : std_logic_vector(     c_SQM_PXL_POS_S-1 downto 0)                           ; --! Pixel position

signal   mem_plssh_add_lsb    : std_logic_vector(     c_SQM_PLS_CNT_S-1 downto 0)                           ; --! Memory pulse shaping coefficient, DAC side: address lsb
signal   mem_plssh_pp         : std_logic                                                                   ; --! SQUID MUX feedback pulse shaping coefficient, TC/HK side: ping-pong buffer bit
signal   mem_plssh_prm        : t_mem(
                                add(                c_MEM_PLSSH_ADD_S-1 downto 0),
                                data_w(            c_DFLD_PLSSH_PLS_S-1 downto 0))                          ; --! SQUID MUX feedback pulse shaping coefficient, DAC side: memory inputs

signal   x_init               : std_logic_vector(    c_SQM_DATA_FBK_S-1 downto 0)                           ; --! Pulse shaping: Last value reached by y[k] at the end of last slice (unsigned)
signal   x_final              : std_logic_vector(    c_SQM_DATA_FBK_S-1 downto 0)                           ; --! Pulse shaping: Final value to reach by y[k] (unsigned)
signal   a_mant_k             : std_logic_vector(  c_DFLD_PLSSH_PLS_S-1 downto 0)                           ; --! Pulse shaping: A[k] filter mantissa parameter (unsigned)
signal   a_mant_k_rs          : std_logic_vector( c_SQM_PLS_SHP_A_EXP-1 downto 0)                           ; --! Pulse shaping: A[k] filter mantissa parameter (unsigned) resized

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of rst_sqm_adc_dac_loc   : signal is true                                   ; --! Disabling signal optimization: rst_sqm_adc_dac_loc
attribute syn_preserve          of sync_rs_rsys          : signal is true                                   ; --! Disabling signal optimization: sync_rs_sys
attribute syn_preserve          of sync_r                : signal is true                                   ; --! Disabling signal optimization: sync_r
attribute syn_preserve          of sync_re               : signal is true                                   ; --! Disabling signal optimization: sync_re

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs entity register on System Clock
   -- ------------------------------------------------------------------------------------------------------
   I_sqm_dac_sys: entity work.sqm_dac_sys port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => i_sync_rs            , -- in     std_logic                                 ; --! Pixel sequence synchronization (System Clock)
         i_plsss              => i_plsss              , -- in     slv(c_DFLD_PLSSS_PLS_S-1 downto 0)        ; --! SQUID MUX feedback pulse shaping set (System Clock)

         o_sync_rs_rsys       => sync_rs_rsys         , -- out    std_logic                                 ; --! Pixel sequence synchronization register (System Clock)
         o_plsss_rsys         => plsss_rsys             -- out    slv(c_DFLD_PLSSS_PLS_S-1 downto 0)          --! SQUID MUX feedback pulse shaping set register (System Clock)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Local reset on SQUID MUX ADC acquisition Clock
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   P_rst_sqm_adc_dac_lc: process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = c_RST_LEV_ACT then
         rst_sqm_adc_dac_loc <= c_RST_LEV_ACT;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         rst_sqm_adc_dac_loc <= not(c_RST_LEV_ACT);

      end if;

   end process P_rst_sqm_adc_dac_lc;

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst_sqm_adc_dac_loc, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_loc = c_RST_LEV_ACT then
         sync_r               <= (others => c_I_SYNC_DEF);
         sqm_data_fbk_r       <= (others => std_logic_vector(to_unsigned(c_DAC_MDL_POINT, c_SQM_DATA_FBK_S)));
         sqm_pixel_pos_init_r <= (others => std_logic_vector(to_signed(c_SQM_PXL_POS_INIT, c_SQM_PXL_POS_S)));
         sqm_pls_cnt_init_r   <= (others => std_logic_vector(to_signed(c_SQM_PLS_CNT_INIT, c_SQM_PLS_CNT_S)));
         plsss_r              <= (others => c_EP_CMD_DEF_PLSSS);
         mem_plssh_pp_r       <= (others => c_MEM_STR_ADD_PP_DEF);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sync_r               <= sync_r(sync_r'high-1 downto 0) & sync_rs_rsys;
         sqm_data_fbk_r       <= i_sqm_data_fbk       & sqm_data_fbk_r(       0 to sqm_data_fbk_r'high-1);
         sqm_pixel_pos_init_r <= i_sqm_pixel_pos_init & sqm_pixel_pos_init_r( 0 to sqm_pixel_pos_init_r'high-1);
         sqm_pls_cnt_init_r   <= i_sqm_pls_cnt_init   & sqm_pls_cnt_init_r(   0 to sqm_pls_cnt_init_r'high-1);
         plsss_r              <= plsss_rsys           & plsss_r(              0 to plsss_r'high-1);
         mem_plssh_pp_r       <= mem_plssh_pp_r(mem_plssh_pp_r'high-1 downto 0) & mem_plssh_pp;

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Specific signals
   -- ------------------------------------------------------------------------------------------------------
   P_sig : process (rst_sqm_adc_dac_loc, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_loc = c_RST_LEV_ACT then
         sync_re            <= c_LOW_LEV;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sync_re  <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);

      end if;

   end process P_sig;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse shaping counter
   --    @Req : DRE-DMX-FW-REQ-0275
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (rst_sqm_adc_dac_loc, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_loc = c_RST_LEV_ACT then
         pls_cnt        <= std_logic_vector(to_unsigned(c_SQM_PLS_CNT_MX_VAL, pls_cnt'length));
         pls_cnt_msb_r  <= c_LOW_LEV;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = c_HGH_LEV then
            pls_cnt <= sqm_pls_cnt_init_r(sqm_pls_cnt_init_r'high);

         elsif pls_cnt(pls_cnt'high) = c_HGH_LEV then
            pls_cnt <= std_logic_vector(to_unsigned(c_SQM_PLS_CNT_MX_VAL, pls_cnt'length));

         else
            pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

         end if;

         pls_cnt_msb_r <= pls_cnt(pls_cnt'high);

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   --    @Req : DRE-DMX-FW-REQ-0080
   --    @Req : DRE-DMX-FW-REQ-0090
   --    @Req : DRE-DMX-FW-REQ-0285
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (rst_sqm_adc_dac_loc, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_loc = c_RST_LEV_ACT then
         pixel_pos   <= c_MINUSONE(pixel_pos'range);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = c_HGH_LEV then
            pixel_pos <= sqm_pixel_pos_init_r(sqm_pixel_pos_init_r'high);

         elsif (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(to_signed(c_SQM_PXL_POS_MX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for pulse shaping coefficient
   --    @Req : REG_CY_PULSE_SHAPING
   --    @Req : DRE-DMX-FW-REQ-0230
   -- ------------------------------------------------------------------------------------------------------
   I_mem_pls_shape: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_PLSSH_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_PLSSH_PLS_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_PLSSH     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_plssh          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_plssh_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_plssh_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => rst_sqm_adc_dac_loc  , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk_sqm_adc_dac    , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_sqm_adc_dac_90 , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_plssh_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => a_mant_k             , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   a_mant_k_rs <= std_logic_vector(resize(unsigned(a_mant_k), a_mant_k_rs'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory pulse shaping coefficient signals, DAC side
   -- ------------------------------------------------------------------------------------------------------
   P_mem_plssh_dac : process (rst_sqm_adc_dac_loc, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_loc = c_RST_LEV_ACT then
         mem_plssh_add_lsb <= c_ZERO(mem_plssh_add_lsb'range);
         mem_plssh_prm.add(mem_plssh_prm.add'high downto mem_plssh_add_lsb'high) <= c_EP_CMD_DEF_PLSSS;
         mem_plssh_prm.pp <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         mem_plssh_add_lsb <= std_logic_vector(to_signed(c_SQM_PLS_CNT_MX_VAL, mem_plssh_add_lsb'length) - signed(pls_cnt));

         if (pixel_pos(pixel_pos'high) and pls_cnt_msb_r) = c_HGH_LEV then
            mem_plssh_prm.add(mem_plssh_prm.add'high downto mem_plssh_add_lsb'high) <= plsss_r(plsss_r'high);
            mem_plssh_prm.pp <= mem_plssh_pp_r(mem_plssh_pp_r'high);

         end if;

      end if;

   end process P_mem_plssh_dac;

   mem_plssh_prm.add(mem_plssh_add_lsb'high-1 downto 0) <= mem_plssh_add_lsb(mem_plssh_add_lsb'high-1 downto 0);
   mem_plssh_prm.we      <= c_LOW_LEV;
   mem_plssh_prm.cs      <= c_HGH_LEV;
   mem_plssh_prm.data_w  <= c_ZERO(mem_plssh_prm.data_w'range);

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX DAC: Pulse shaping inputs
   --     x_final signed input adapted in order to get the correspondence:
   --     - i_sqm_data_fbk = -2^(c_SQM_DATA_FBK_S-1)   -> o_sqm_dac_data = 0                      (DAC analog output = - Vref)
   --     - i_sqm_data_fbk =  2^(c_SQM_DATA_FBK_S-1)-1 -> o_sqm_dac_data = 2^(c_SQM_DAC_DATA_S)-1 (DAC analog output =   Vref)
   --     Either: x_final = i_sqm_data_fbk + 2^(c_SQM_DATA_FBK_S-1)
   -- ------------------------------------------------------------------------------------------------------
   P_pulse_shaping_in : process (rst_sqm_adc_dac_loc, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_loc = c_RST_LEV_ACT then
         x_init   <= std_logic_vector(to_unsigned(c_DAC_MDL_POINT, x_init'length));
         x_final  <= std_logic_vector(to_unsigned(c_DAC_MDL_POINT, x_final'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if pls_cnt = std_logic_vector(to_unsigned(c_PLS_VAL_SYNC_PRM, pls_cnt'length)) then
            x_init   <= x_final;
            x_final  <= not(sqm_data_fbk_r(sqm_data_fbk_r'high)(x_final'high)) & sqm_data_fbk_r(sqm_data_fbk_r'high)(x_final'high-1 downto 0);

         end if;

      end if;

   end process P_pulse_shaping_in;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX DAC: Pulse shaping
   --    @Req : DRE-DMX-FW-REQ-0220
   --    @Req : DRE-DMX-FW-REQ-0240
   -- ------------------------------------------------------------------------------------------------------
   I_pulse_shaping: entity work.pulse_shaping generic map (
         g_X_K_S              => c_SQM_DATA_FBK_S     , -- integer                                          ; --! Data in bus size (<= c_MULT_ALU_PORTB_S-1)
         g_A_EXP              => c_SQM_PLS_SHP_A_EXP  , -- integer                                          ; --! A[k]: filter exponent parameter (<= c_MULT_ALU_PORTC_S-g_X_K_S-1)
         g_Y_K_S              => c_SQM_DAC_DATA_S       -- integer                                            --! y[k]: filtered data out bus size
   ) port map (
         i_rst_sqm_adc_dac_lc => rst_sqm_adc_dac_loc  , -- in     std_logic                                 ; --! Local reset for SQUID ADC/DAC, de-assertion on system clock
         i_clk_sqm_adc_dac    => i_clk_sqm_adc_dac    , -- in     std_logic                                 ; --! SQUID MUX pulse shaping Clock
         i_x_init             => x_init               , -- in     std_logic_vector(g_X_K_S-1 downto 0)      ; --! Last value reached by y[k] at the end of last slice (unsigned)
         i_x_final            => x_final              , -- in     std_logic_vector(g_X_K_S-1 downto 0)      ; --! Final value to reach by y[k] (unsigned)
         i_a_mant_k           => a_mant_k_rs          , -- in     std_logic_vector(g_A_EXP-1 downto 0)      ; --! A[k]: filter mantissa parameter (unsigned)
         o_y_k                => o_sqm_dac_data         -- out    std_logic_vector(g_Y_K_S-1 downto 0)        --! y[k]: filtered data out (unsigned)
   );

end architecture RTL;
