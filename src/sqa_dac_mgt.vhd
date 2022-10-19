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
--!   @file                   sqa_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP DAC management
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

entity sqa_dac_mgt is port
   (     i_rst_sqm_adc_dac_pd : in     std_logic                                                            ; --! Reset for SQUID ADC/DAC for pad, de-assertion on system clock
         i_rst_sqm_adc_dac    : in     std_logic                                                            ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID ADC/DAC internal Clock

         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_saofl              : in     std_logic_vector(c_DFLD_SAOFL_COL_S-1 downto 0)                      ; --! SQUID AMP offset DAC LSB
         i_sqa_fbk_mux        : in     std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                      ; --! SQUID AMP Feedback Multiplexer
         i_sqa_fbk_off        : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP coarse offset
         i_saodd              : in     std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0)                      ; --! SQUID AMP offset DAC delay
         i_saomd              : in     std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                      ; --! SQUID AMP offset MUX delay

         o_sqa_dac_mux        : out    std_logic_vector(c_SQA_DAC_MUX_S -1 downto 0)                        ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_data       : out    std_logic                                                            ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       : out    std_logic                                                            ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    : out    std_logic                                                            ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    : out    std_logic                                                              --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)

   );
end entity sqa_dac_mgt;

architecture RTL of sqa_dac_mgt is
constant c_PLS_RW_CNT_NB_VAL  : integer:= c_PIXEL_DAC_NB_CYC * c_MUX_FACT                                   ; --! Pulse by row counter: number of value
constant c_PLS_RW_CNT_MAX_VAL : integer:= c_PLS_RW_CNT_NB_VAL - 2                                           ; --! Pulse by row counter: maximal value
constant c_PLS_RW_CNT_INIT    : integer:= c_PLS_RW_CNT_MAX_VAL - c_SAD_SYNC_DATA_NPER                       ; --! Pulse by row counter: initialization value
constant c_PLS_RW_CNT_S       : integer:= log2_ceil(c_PLS_RW_CNT_MAX_VAL + 1) + 1                           ; --! Pulse by row counter: size bus (signed)

constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_DAC_NB_CYC                                                ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_PLS_CNT_MAX_VAL - c_SAM_SYNC_DATA_NPER                          ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= -1                                                                ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1) + 1                              ; --! Pixel position: size bus (signed)

constant c_SPI_SER_WD_S_V_S   : integer := log2_ceil(c_SQA_SPI_SER_WD_S+1)                                  ; --! SQUID AMP DAC SPI: Serial word size vector bus size
constant c_SQA_SPI_SER_WD_S_V : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_SQA_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S))       ; --! SQUID AMP DAC SPI: Serial word size vector

signal   rst_sqm_adc_dac_pad  : std_logic                                                                   ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock

signal   sync_rs_sys          : std_logic                                                                   ; --! Pixel sequence synchronization, synchronized on System Clock register (System clock)
signal   saofl_sys            : std_logic_vector(c_DFLD_SAOFL_COL_S-1 downto 0)                             ; --! SQUID AMP offset DAC LSB register (System clock)
signal   saodd_sys            : std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0)                             ; --! SQUID AMP offset DAC delay register (System clock)
signal   saomd_sys            : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                             ; --! SQUID AMP offset MUX delay register (System clock)

signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   sync_re              : std_logic                                                                   ; --! Pixel sequence sync. rising edge
signal   saofl_r              : t_slv_arr(0 to c_FF_RSYNC_NB  )(c_DFLD_SAOFC_COL_S-1 downto 0)              ; --! SQUID AMP offset DAC LSB register
signal   sqa_fbk_mux_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_SAOFF_PIX_S-1 downto 0)              ; --! SQUID AMP Feedback Multiplexer register
signal   sqa_fbk_off_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_SAOFC_COL_S-1 downto 0)              ; --! SQUID AMP coarse offset register
signal   saodd_r              : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_SAODD_COL_S-1 downto 0)              ; --! SQUID AMP offset DAC delay register
signal   saomd_r              : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_SAOMD_COL_S-1 downto 0)              ; --! SQUID AMP offset MUX delay register

signal   sqa_fbk_off_sync     : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! SQUID AMP coarse offset synchronized on pulse by row counter start
signal   sqa_fbk_off_final    : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! SQUID AMP coarse offset final
signal   sqa_fbk_off_final_r  : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! SQUID AMP coarse offset register
signal   saofl_r_cmp          : std_logic                                                                   ; --! SQUID AMP offset DAC LSB register compare
signal   sqa_fbk_off_r_cmp    : std_logic                                                                   ; --! SQUID AMP coarse offset register compare
signal   saodd_lim            : std_logic_vector(2 downto 0)                                                ; --! SQUID AMP offset DAC delay limits

signal   pls_rw_cnt           : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter
signal   pls_rw_cnt_init_oft  : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter initialization offset
signal   pls_rw_cnt_init      : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter initialization
signal   pls_cnt              : std_logic_vector(   c_PLS_CNT_S-1 downto 0)                                 ; --! Pulse counter
signal   pls_cnt_init         : std_logic_vector(   c_PLS_CNT_S-1 downto 0)                                 ; --! Pulse shaping counter initialization
signal   pixel_pos            : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position
signal   pixel_pos_init       : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position initialization

signal   saofl_tx_flg         : std_logic                                                                   ; --! SQUID AMP offset DAC LSB transmit flag ('0'= no data to transmit,'1'= data to transmit)
signal   sqa_fbk_off_tx_flg   : std_logic                                                                   ; --! SQUID AMP coarse offset transmit flag ('0'= no data to transmit,'1'= data to transmit)
signal   sqa_fbk_off_tx_ena   : std_logic                                                                   ; --! SQUID AMP coarse offset transmit enable ('0' = Inactive, '1' = Active)

signal   sqa_spi_start        : std_logic                                                                   ; --! SQUID AMP DAC SPI: Start transmit ('0' = Inactive, '1' = Active)
signal   sqa_spi_data_tx      : std_logic_vector(c_SQA_SPI_SER_WD_S-1 downto 0)                             ; --! SQUID AMP DAC SPI: Data to transmit (stall on MSB)
signal   sqa_spi_tx_busy_n    : std_logic                                                                   ; --! SQUID AMP DAC SPI: Transmit link busy ('0' = Busy, '1' = Not Busy)
signal   sqa_spi_tx_busy_n_r  : std_logic                                                                   ; --! SQUID AMP DAC SPI: Transmit link busy register
signal   sqa_spi_tx_busy_n_fe : std_logic                                                                   ; --! SQUID AMP DAC SPI: Transmit link busy falling edge

signal   sqa_dac_data         : std_logic                                                                   ; --! SQUID AMP DAC: Serial Data
signal   sqa_dac_sclk         : std_logic                                                                   ; --! SQUID AMP DAC: Serial Clock
signal   sqa_dac_sync_n       : std_logic                                                                   ; --! SQUID AMP DAC: Frame Synchronization ('0' = Active, '1' = Inactive)

attribute syn_preserve        : boolean                                                                     ;
attribute syn_preserve          of rst_sqm_adc_dac_pad   : signal is true                                   ;
attribute syn_preserve          of sync_r                : signal is true                                   ;
attribute syn_preserve          of sync_re               : signal is true                                   ;

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID ADC/DAC internal Clock Clock
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   P_rst_sqm_adc_dac_pd: process (i_rst_sqm_adc_dac_pd, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac_pd = '1' then
         rst_sqm_adc_dac_pad <= '1';

      elsif rising_edge(i_clk_sqm_adc_dac) then
         rst_sqm_adc_dac_pad <= '0';

      end if;

   end process P_rst_sqm_adc_dac_pd;

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs registered on system clock before resynchronization
   -- ------------------------------------------------------------------------------------------------------
   I_sync_rs_sys: entity work.signal_reg generic map
   (  g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
      g_SIG_DEF            => c_I_SYNC_DEF           -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
      i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

      i_sig                => i_sync_rs            , -- in     std_logic                                 ; --! Signal
      o_sig_r              => sync_rs_sys            -- out    std_logic                                   --! Signal registered
   );

   P_reg_sys: process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         saofl_sys         <= c_EP_CMD_DEF_SAOFL;
         saodd_sys         <= c_EP_CMD_DEF_SAODD;
         saomd_sys         <= c_EP_CMD_DEF_SAOMD;

      elsif rising_edge(i_clk) then
         saofl_sys         <= i_saofl;
         saodd_sys         <= i_saodd;
         saomd_sys         <= i_saomd;

      end if;

   end process P_reg_sys;

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         sync_r            <= (others => c_I_SYNC_DEF);
         saofl_r           <= (others => c_EP_CMD_DEF_SAOFL);
         sqa_fbk_mux_r     <= (others => (others => '0'));
         sqa_fbk_off_r     <= (others => c_EP_CMD_DEF_SAOFC);
         saodd_r           <= (others => c_EP_CMD_DEF_SAODD);
         saomd_r           <= (others => c_EP_CMD_DEF_SAOMD);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sync_r            <= sync_r(sync_r'high-1 downto 0) & sync_rs_sys;
         saofl_r           <= saofl_sys     & saofl_r(      0 to saofl_r'high-1);
         sqa_fbk_mux_r     <= i_sqa_fbk_mux & sqa_fbk_mux_r(0 to sqa_fbk_mux_r'high-1);
         sqa_fbk_off_r     <= i_sqa_fbk_off & sqa_fbk_off_r(0 to sqa_fbk_off_r'high-1);
         saodd_r           <= saodd_sys     & saodd_r(      0 to saodd_r'high-1);
         saomd_r           <= saomd_sys     & saomd_r(      0 to saomd_r'high-1);

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Specific signals
   -- ------------------------------------------------------------------------------------------------------
   P_sig : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         sync_re              <= '0';
         sqa_spi_tx_busy_n_r  <= '1';
         sqa_spi_tx_busy_n_fe <= '0';
         sqa_fbk_off_final_r  <= c_EP_CMD_DEF_SAOFC;
         sqa_fbk_off_sync     <= c_EP_CMD_DEF_SAOFC;
         saofl_r_cmp          <= '0';
         sqa_fbk_off_r_cmp    <= '0';
         saodd_lim            <= (others=> '0');

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sync_re              <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);
         sqa_spi_tx_busy_n_r  <= sqa_spi_tx_busy_n;
         sqa_spi_tx_busy_n_fe <= sqa_spi_tx_busy_n_r and not(sqa_spi_tx_busy_n);
         sqa_fbk_off_final_r  <= sqa_fbk_off_final;

         if pls_rw_cnt(pls_rw_cnt'high) = '1' then
            sqa_fbk_off_sync <= sqa_fbk_off_r(sqa_fbk_off_r'high);

         end if;

         if saofl_r(saofl_r'high) /= saofl_r(saofl_r'high-1) then
            saofl_r_cmp <= '1';

         else
            saofl_r_cmp <= '0';

         end if;

         if sqa_fbk_off_final_r /= sqa_fbk_off_final then
            sqa_fbk_off_r_cmp <= '1';

         else
            sqa_fbk_off_r_cmp <= '0';

         end if;

         if unsigned(saodd_r(saodd_r'high)) >= to_unsigned(2*c_PLS_RW_CNT_NB_VAL-c_PLS_RW_CNT_INIT-1, c_DFLD_SAODD_COL_S) then
            saodd_lim(0) <= '1';

         else
            saodd_lim(0) <= '0';

         end if;

         if unsigned(saodd_r(saodd_r'high)) >= to_unsigned(c_PLS_RW_CNT_NB_VAL-c_PLS_RW_CNT_INIT-1, c_DFLD_SAODD_COL_S) then
            saodd_lim(1) <= '1';

         else
            saodd_lim(1) <= '0';

         end if;

         if unsigned(saodd_r(saodd_r'high)) > to_unsigned(c_PLS_RW_CNT_MAX_VAL, c_DFLD_SAODD_COL_S) then
            saodd_lim(2) <= '1';

         else
            saodd_lim(2) <= '0';

         end if;

      end if;

   end process P_sig;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse by row counter initialization
   -- ------------------------------------------------------------------------------------------------------


   P_pls_rw_cnt_init : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         pls_rw_cnt_init_oft  <= std_logic_vector(unsigned(to_signed(c_PLS_RW_CNT_INIT, pls_rw_cnt_init_oft'length)));
         pls_rw_cnt_init      <= std_logic_vector(unsigned(to_signed(c_PLS_RW_CNT_INIT, pls_rw_cnt_init'length)));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if saodd_lim(0) = '1' then
            pls_rw_cnt_init_oft <=  std_logic_vector(to_signed(c_PLS_RW_CNT_INIT-2*c_PLS_RW_CNT_NB_VAL, pls_rw_cnt_init_oft'length));

         elsif saodd_lim(1) = '1' then
            pls_rw_cnt_init_oft <=  std_logic_vector(to_signed(c_PLS_RW_CNT_INIT-  c_PLS_RW_CNT_NB_VAL, pls_rw_cnt_init_oft'length));

         else
            pls_rw_cnt_init_oft <=  std_logic_vector(to_signed(c_PLS_RW_CNT_INIT, pls_rw_cnt_init_oft'length));

         end if;

         pls_rw_cnt_init   <= std_logic_vector(unsigned(pls_rw_cnt_init_oft) + unsigned(saodd_r(saodd_r'high)));

      end if;

   end process P_pls_rw_cnt_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP coarse offset final
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fbk_off_final : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         sqa_fbk_off_final <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if saodd_lim(2) = '1' then
            sqa_fbk_off_final <= sqa_fbk_off_sync;

         else
            sqa_fbk_off_final <= sqa_fbk_off_r(sqa_fbk_off_r'high);

         end if;

      end if;

   end process P_sqa_fbk_off_final;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse by row counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_rw_cnt : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = '1' then
            pls_rw_cnt <= pls_rw_cnt_init;

         elsif pls_rw_cnt(pls_rw_cnt'high) = '1' then
            pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

         else
            pls_rw_cnt <= std_logic_vector(signed(pls_rw_cnt) - 1);

         end if;

      end if;

   end process P_pls_rw_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter/Pixel position initialization
   --    @Req : DRE-DMX-FW-REQ-0380
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt_del : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)));
         pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if    unsigned(saomd_r(saomd_r'high)) <= to_unsigned(c_SAM_SYNC_DATA_NPER, c_DFLD_SAOMD_COL_S) then
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)) + unsigned(saomd_r(saomd_r'high)));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

         else
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT - c_PIXEL_DAC_NB_CYC, pls_cnt_init'length)) + unsigned(saomd_r(saomd_r'high)));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT + 1 , pixel_pos'length));

         end if;

      end if;

   end process P_pls_cnt_del;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   --    @Req : DRE-DMX-FW-REQ-0375
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         pls_cnt    <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = '1' then
            pls_cnt <= pls_cnt_init;

         elsif pls_cnt(pls_cnt'high) = '1' then
            pls_cnt <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

         else
            pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   --    @Req : DRE-DMX-FW-REQ-0080
   --    @Req : DRE-DMX-FW-REQ-0090
   --    @Req : DRE-DMX-FW-REQ-0385
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         pixel_pos   <= (others => '1');

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = '1' then
            pixel_pos <= pixel_pos_init;

         elsif (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = '1' then
            pixel_pos <= std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = '1' then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Transmit flags management
   --    @Req : DRE-DMX-FW-REQ-0370
   -- ------------------------------------------------------------------------------------------------------
   P_tx_flg : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         saofl_tx_flg       <= '1';
         sqa_fbk_off_tx_flg <= '1';
         sqa_fbk_off_tx_ena <= '0';

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if saofl_r_cmp = '1' then
            saofl_tx_flg <= '1';

         elsif (sqa_spi_tx_busy_n_fe and not(sqa_fbk_off_tx_ena)) = '1' then
            saofl_tx_flg <= '0';

         end if;

         if sqa_fbk_off_r_cmp = '1' then
            sqa_fbk_off_tx_flg <= '1';

         elsif (sqa_spi_tx_busy_n_fe and sqa_fbk_off_tx_ena) = '1' then
            sqa_fbk_off_tx_flg <= '0';

         end if;

         if pls_rw_cnt(pls_rw_cnt'high) = '1' then
            sqa_fbk_off_tx_ena <= sqa_fbk_off_tx_flg;

         end if;

      end if;

   end process P_tx_flg;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP SPI inputs
   --!   Feedback offset priority on DAC LSB for data transmit
   --    @Req : DRE-DMX-FW-REQ-0290
   --    @Req : DRE-DMX-FW-REQ-0340
   --    @Req : DRE-DMX-FW-REQ-0370
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_spi_in : process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = '1' then
         sqa_spi_start                                <= '0';
         sqa_spi_data_tx(c_SQA_DAC_DATA_S-1 downto 0) <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sqa_spi_start  <= (saofl_tx_flg or sqa_fbk_off_tx_flg) and pls_rw_cnt(pls_rw_cnt'high);

         if sqa_fbk_off_tx_flg = '1' then
            sqa_spi_data_tx(c_SQA_DAC_DATA_S-1 downto 0) <= sqa_fbk_off_final;

         else
            sqa_spi_data_tx(c_SQA_DAC_DATA_S-1 downto 0) <= saofl_r(saofl_r'high);

         end if;

      end if;

   end process P_sqa_spi_in;

   sqa_spi_data_tx(c_SQA_DAC_DATA_S+c_SQA_DAC_MODE_S-1 downto   c_SQA_DAC_DATA_S) <= c_DST_SQADAC_NORM;
   sqa_spi_data_tx(c_SQA_SPI_SER_WD_S-1 downto c_SQA_DAC_DATA_S+c_SQA_DAC_MODE_S) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP SPI master
   --    @Req : DRE-DMX-FW-REQ-0340
   --    @Req : DRE-DMX-FW-REQ-0350
   -- ------------------------------------------------------------------------------------------------------
   I_sqa_spi_master : entity work.spi_master generic map
   (     g_CPOL               => c_SQA_SPI_CPOL       , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_SQA_SPI_CPHA       , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => c_SQA_SPI_SCLK_L     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => c_SQA_SPI_SCLK_H     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => 0                    , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_SQA_SPI_SER_WD_S     -- integer                                            --! Data bus size
   ) port map
   (     i_rst                => i_rst_sqm_adc_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk_sqm_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_start              => sqa_spi_start        , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => c_SQA_SPI_SER_WD_S_V , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => sqa_spi_data_tx      , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => sqa_spi_tx_busy_n    , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => open                 , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => open                 , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => '0'                  , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => sqa_dac_data         , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => sqa_dac_sclk         , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => sqa_dac_sync_n         -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP SPI outputs
   --    @Req : DRE-DMX-FW-REQ-0340
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_spi_out : process (rst_sqm_adc_dac_pad, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_pad = '1' then
         o_sqa_dac_data    <= '0';
         o_sqa_dac_sclk    <= c_SQA_SPI_CPOL;
         o_sqa_dac_snc_l_n <= c_PAD_REG_SET_AUTH;
         o_sqa_dac_snc_o_n <= c_PAD_REG_SET_AUTH;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         o_sqa_dac_data    <= sqa_dac_data;
         o_sqa_dac_sclk    <= sqa_dac_sclk;
         o_sqa_dac_snc_l_n <= sqa_dac_sync_n or      sqa_fbk_off_tx_ena;
         o_sqa_dac_snc_o_n <= sqa_dac_sync_n or  not(sqa_fbk_off_tx_ena);

      end if;

   end process P_sqa_spi_out;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP feedback DAC Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0360
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_dac_mux : process (rst_sqm_adc_dac_pad, i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_pad = '1' then
         o_sqa_dac_mux <= (others => '0');

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if pls_cnt(pls_cnt'high) = '1' then
            o_sqa_dac_mux <= sqa_fbk_mux_r(sqa_fbk_mux_r'high);

         end if;

      end if;

   end process P_sqa_dac_mux;

end architecture RTL;
