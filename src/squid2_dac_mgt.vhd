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
--!   @file                   squid2_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid2 DAC management
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

entity squid2_dac_mgt is port
   (     i_rst_sys_sq2_dac    : in     std_logic                                                            ; --! Reset for SQUID2 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_dac    : in     std_logic                                                            ; --! SQUID1 ADC/DAC internal Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sq2_dac_lsb        : in     std_logic_vector(c_DFLD_S2LSB_COL_S-1 downto 0)                      ; --! Squid2 DAC LSB
         i_sq2_fbk_mux        : in     std_logic_vector(c_DFLD_S2LKP_PIX_S-1 downto 0)                      ; --! Squid2 Feedback Multiplexer
         i_sq2_fbk_off        : in     std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                      ; --! Squid2 Feedback offset
         i_sq_off_dac_del     : in     std_logic_vector(c_DFLD_S2DCD_COL_S-1 downto 0)                      ; --! Squid offset DAC delay
         i_sq_off_mux_del     : in     std_logic_vector(c_DFLD_S2MXD_COL_S-1 downto 0)                      ; --! Squid offset MUX delay

         o_sq2_dac_mux        : out    std_logic_vector(c_SQ2_DAC_MUX_S -1 downto 0)                        ; --! SQUID2 DAC: Multiplexer
         o_sq2_dac_data       : out    std_logic                                                            ; --! SQUID2 DAC: Serial Data
         o_sq2_dac_sclk       : out    std_logic                                                            ; --! SQUID2 DAC: Serial Clock
         o_sq2_dac_snc_l_n    : out    std_logic                                                            ; --! SQUID2 DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sq2_dac_snc_o_n    : out    std_logic                                                              --! SQUID2 DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)

   );
end entity squid2_dac_mgt;

architecture RTL of squid2_dac_mgt is
constant c_PLS_RW_CNT_NB_VAL  : integer:= c_PIXEL_DAC_NB_CYC * c_MUX_FACT                                   ; --! Pulse by row counter: number of value
constant c_PLS_RW_CNT_MAX_VAL : integer:= c_PLS_RW_CNT_NB_VAL - 2                                           ; --! Pulse by row counter: maximal value
constant c_PLS_RW_CNT_INIT    : integer:= c_PLS_RW_CNT_MAX_VAL - c_S2D_SYNC_DATA_NPER                       ; --! Pulse by row counter: initialization value
constant c_PLS_RW_CNT_S       : integer:= log2_ceil(c_PLS_RW_CNT_MAX_VAL + 1) + 1                           ; --! Pulse by row counter: size bus (signed)

constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_DAC_NB_CYC                                                ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_PLS_CNT_MAX_VAL - c_S2M_SYNC_DATA_NPER                          ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= -1                                                                ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1) + 1                              ; --! Pixel position: size bus (signed)

constant c_SPI_SER_WD_S_V_S   : integer := log2_ceil(c_SQ2_SPI_SER_WD_S+1)                                  ; --! SQUID2 DAC SPI: Serial word size vector bus size
constant c_SQ2_SPI_SER_WD_S_V : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_SQ2_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S))       ; --! SQUID2 DAC SPI: Serial word size vector

signal   rst_sq2_dac          : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   sync_re              : std_logic                                                                   ; --! Pixel sequence sync. rising edge
signal   sq2_dac_lsb_r        : t_slv_arr(0 to c_FF_RSYNC_NB  )(c_DFLD_S2OFF_COL_S-1 downto 0)              ; --! Squid2 DAC LSB register
signal   sq2_fbk_mux_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_S2LKP_PIX_S-1 downto 0)              ; --! Squid2 Feedback Multiplexer register
signal   sq2_fbk_off_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_S2OFF_COL_S-1 downto 0)              ; --! Squid2 Feedback offset register
signal   sq_off_dac_del_r     : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_S2DCD_COL_S-1 downto 0)              ; --! Squid offset DAC delay register
signal   sq_off_mux_del_r     : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_S2MXD_COL_S-1 downto 0)              ; --! Squid offset MUX delay register

signal   sq2_fbk_off_sync     : std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                             ; --! Squid2 Feedback offset synchronized on pulse by row counter start
signal   sq2_fbk_off_final    : std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                             ; --! Squid2 Feedback offset final
signal   sq2_fbk_off_final_r  : std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                             ; --! Squid2 Feedback offset register
signal   sq2_dac_lsb_r_cmp    : std_logic                                                                   ; --! Squid2 DAC LSB register compare
signal   sq2_fbk_off_r_cmp    : std_logic                                                                   ; --! Squid2 Feedback offset register compare
signal   sq_off_dac_del_lim   : std_logic_vector(2 downto 0)                                                ; --! Squid offset DAC delay limits

signal   pls_rw_cnt           : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter
signal   pls_rw_cnt_init      : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter initialization
signal   pls_cnt              : std_logic_vector(   c_PLS_CNT_S-1 downto 0)                                 ; --! Pulse counter
signal   pls_cnt_init         : std_logic_vector(   c_PLS_CNT_S-1 downto 0)                                 ; --! Pulse shaping counter initialization
signal   pixel_pos            : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position
signal   pixel_pos_init       : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position initialization

signal   sq2_dac_lsb_tx_flg   : std_logic                                                                   ; --! Squid2 DAC LSB transmit flag ('0'= no data to transmit,'1'= data to transmit)
signal   sq2_fbk_off_tx_flg   : std_logic                                                                   ; --! Squid2 Feedback offset transmit flag ('0'= no data to transmit,'1'= data to transmit)
signal   sq2_fbk_off_tx_ena   : std_logic                                                                   ; --! Squid2 Feedback offset transmit enable ('0' = Inactive, '1' = Active)

signal   sq2_spi_start        : std_logic                                                                   ; --! SQUID2 DAC SPI: Start transmit ('0' = Inactive, '1' = Active)
signal   sq2_spi_data_tx      : std_logic_vector(c_SQ2_SPI_SER_WD_S-1 downto 0)                             ; --! SQUID2 DAC SPI: Data to transmit (stall on MSB)
signal   sq2_spi_tx_busy_n    : std_logic                                                                   ; --! SQUID2 DAC SPI: Transmit link busy ('0' = Busy, '1' = Not Busy)
signal   sq2_spi_tx_busy_n_r  : std_logic                                                                   ; --! SQUID2 DAC SPI: Transmit link busy register
signal   sq2_spi_tx_busy_n_fe : std_logic                                                                   ; --! SQUID2 DAC SPI: Transmit link busy falling edge

signal   sq2_dac_data         : std_logic                                                                   ; --! SQUID2 DAC: Serial Data
signal   sq2_dac_sclk         : std_logic                                                                   ; --! SQUID2 DAC: Serial Clock
signal   sq2_dac_sync_n       : std_logic                                                                   ; --! SQUID2 DAC: Frame Synchronization ('0' = Active, '1' = Inactive)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID2 DAC Clock generation
   --!     Necessity to generate local reset in order to reach expected frequency
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_sq2_dac: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RST_ADC_DAC_NB  , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '1'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst_sys_sq2_dac    , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => '0'                  , -- in     std_logic                                 ; --! Signal
         o_sig_r              => rst_sq2_dac            -- out    std_logic                                   --! Signal registered
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sync_r            <= (others => c_I_SYNC_DEF);
         sq2_dac_lsb_r     <= (others => c_EP_CMD_DEF_S2LSB);
         sq2_fbk_mux_r     <= (others => (others => '0'));
         sq2_fbk_off_r     <= (others => c_EP_CMD_DEF_S2OFF);
         sq_off_dac_del_r  <= (others => c_EP_CMD_DEF_S2DCD);
         sq_off_mux_del_r  <= (others => c_EP_CMD_DEF_S2MXD);

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sync_r            <= sync_r(sync_r'high-1 downto 0) & i_sync_rs;
         sq2_dac_lsb_r     <= i_sq2_dac_lsb & sq2_dac_lsb_r(0 to sq2_dac_lsb_r'high-1);
         sq2_fbk_mux_r     <= i_sq2_fbk_mux & sq2_fbk_mux_r(0 to sq2_fbk_mux_r'high-1);
         sq2_fbk_off_r     <= i_sq2_fbk_off & sq2_fbk_off_r(0 to sq2_fbk_off_r'high-1);
         sq_off_dac_del_r  <= i_sq_off_dac_del & sq_off_dac_del_r(0 to sq_off_dac_del_r'high-1);
         sq_off_mux_del_r  <= i_sq_off_mux_del & sq_off_mux_del_r(0 to sq_off_mux_del_r'high-1);

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Specific signals
   -- ------------------------------------------------------------------------------------------------------
   P_sig : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sync_re              <= '0';
         sq2_spi_tx_busy_n_r  <= '1';
         sq2_spi_tx_busy_n_fe <= '0';
         sq2_fbk_off_final_r  <= c_EP_CMD_DEF_S2OFF;
         sq2_fbk_off_sync     <= c_EP_CMD_DEF_S2OFF;
         sq2_dac_lsb_r_cmp    <= '0';
         sq2_fbk_off_r_cmp    <= '0';
         sq_off_dac_del_lim   <= (others=> '0');

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sync_re              <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);
         sq2_spi_tx_busy_n_r  <= sq2_spi_tx_busy_n;
         sq2_spi_tx_busy_n_fe <= sq2_spi_tx_busy_n_r and not(sq2_spi_tx_busy_n);
         sq2_fbk_off_final_r  <= sq2_fbk_off_final;

         if pls_rw_cnt(pls_rw_cnt'high) = '1' then
            sq2_fbk_off_sync <= sq2_fbk_off_r(sq2_fbk_off_r'high);

         end if;

         if sq2_dac_lsb_r(sq2_dac_lsb_r'high) /= sq2_dac_lsb_r(sq2_dac_lsb_r'high-1) then
            sq2_dac_lsb_r_cmp <= '1';

         else
            sq2_dac_lsb_r_cmp <= '0';

         end if;

         if sq2_fbk_off_final_r /= sq2_fbk_off_final then
            sq2_fbk_off_r_cmp <= '1';

         else
            sq2_fbk_off_r_cmp <= '0';

         end if;

         if unsigned(sq_off_dac_del_r(sq_off_dac_del_r'high)) >= to_unsigned(2*c_PLS_RW_CNT_NB_VAL-c_PLS_RW_CNT_INIT-1, c_DFLD_S2DCD_COL_S) then
            sq_off_dac_del_lim(0) <= '1';

         else
            sq_off_dac_del_lim(0) <= '0';

         end if;

         if unsigned(sq_off_dac_del_r(sq_off_dac_del_r'high)) >= to_unsigned(c_PLS_RW_CNT_NB_VAL-c_PLS_RW_CNT_INIT-1, c_DFLD_S2DCD_COL_S) then
            sq_off_dac_del_lim(1) <= '1';

         else
            sq_off_dac_del_lim(1) <= '0';

         end if;

         if unsigned(sq_off_dac_del_r(sq_off_dac_del_r'high)) > to_unsigned(c_PLS_RW_CNT_MAX_VAL, c_DFLD_S2DCD_COL_S) then
            sq_off_dac_del_lim(2) <= '1';

         else
            sq_off_dac_del_lim(2) <= '0';

         end if;

      end if;

   end process P_sig;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse by row counter initialization
   -- ------------------------------------------------------------------------------------------------------
   P_pls_rw_cnt_init : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         pls_rw_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_RW_CNT_INIT, pls_rw_cnt_init'length)));

      elsif rising_edge(i_clk_sq1_adc_dac) then
         if sq_off_dac_del_lim(0) = '1' then
            pls_rw_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_RW_CNT_INIT-2*c_PLS_RW_CNT_NB_VAL, pls_rw_cnt_init'length)) + unsigned(sq_off_dac_del_r(sq_off_dac_del_r'high)));

         elsif sq_off_dac_del_lim(1) = '1' then
            pls_rw_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_RW_CNT_INIT-c_PLS_RW_CNT_NB_VAL, pls_rw_cnt_init'length)) + unsigned(sq_off_dac_del_r(sq_off_dac_del_r'high)));

         else
            pls_rw_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_RW_CNT_INIT, pls_rw_cnt_init'length)) + unsigned(sq_off_dac_del_r(sq_off_dac_del_r'high)));

         end if;

      end if;

   end process P_pls_rw_cnt_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid2 Feedback offset final
   -- ------------------------------------------------------------------------------------------------------
   P_sq2_fbk_off_final : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sq2_fbk_off_final <= c_EP_CMD_DEF_S2OFF;

      elsif rising_edge(i_clk_sq1_adc_dac) then
         if sq_off_dac_del_lim(2) = '1' then
            sq2_fbk_off_final <= sq2_fbk_off_sync;

         else
            sq2_fbk_off_final <= sq2_fbk_off_r(sq2_fbk_off_r'high);

         end if;

      end if;

   end process P_sq2_fbk_off_final;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse by row counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_rw_cnt : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

      elsif rising_edge(i_clk_sq1_adc_dac) then
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
   P_pls_cnt_del : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)));
         pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

      elsif rising_edge(i_clk_sq1_adc_dac) then
         if    unsigned(sq_off_mux_del_r(sq_off_mux_del_r'high)) <= to_unsigned(c_S2M_SYNC_DATA_NPER, c_DFLD_S2MXD_COL_S) then
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)) + unsigned(sq_off_mux_del_r(sq_off_mux_del_r'high)));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

         else
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT - c_PIXEL_DAC_NB_CYC, pls_cnt_init'length)) + unsigned(sq_off_mux_del_r(sq_off_mux_del_r'high)));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT + 1 , pixel_pos'length));

         end if;

      end if;

   end process P_pls_cnt_del;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   --    @Req : DRE-DMX-FW-REQ-0375
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         pls_cnt    <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk_sq1_adc_dac) then
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
   P_pixel_pos : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         pixel_pos   <= (others => '1');

      elsif rising_edge(i_clk_sq1_adc_dac) then
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
   --!   Squid2 feedback DAC Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0360
   -- ------------------------------------------------------------------------------------------------------
   P_sq2_dac_mux : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         o_sq2_dac_mux <= (others => '0');

      elsif rising_edge(i_clk_sq1_adc_dac) then
         if pls_cnt(pls_cnt'high) = '1' then
            o_sq2_dac_mux <= sq2_fbk_mux_r(sq2_fbk_mux_r'high);

         end if;

      end if;

   end process P_sq2_dac_mux;

   -- ------------------------------------------------------------------------------------------------------
   --!   Transmit flags management
   --    @Req : DRE-DMX-FW-REQ-0370
   -- ------------------------------------------------------------------------------------------------------
   P_tx_flg : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sq2_dac_lsb_tx_flg <= '1';
         sq2_fbk_off_tx_flg <= '1';
         sq2_fbk_off_tx_ena <= '0';

      elsif rising_edge(i_clk_sq1_adc_dac) then
         if sq2_dac_lsb_r_cmp = '1' then
            sq2_dac_lsb_tx_flg <= '1';

         elsif (sq2_spi_tx_busy_n_fe and not(sq2_fbk_off_tx_ena)) = '1' then
            sq2_dac_lsb_tx_flg <= '0';

         end if;

         if sq2_fbk_off_r_cmp = '1' then
            sq2_fbk_off_tx_flg <= '1';

         elsif (sq2_spi_tx_busy_n_fe and sq2_fbk_off_tx_ena) = '1' then
            sq2_fbk_off_tx_flg <= '0';

         end if;

         if pls_rw_cnt(pls_rw_cnt'high) = '1' then
            sq2_fbk_off_tx_ena <= sq2_fbk_off_tx_flg;

         end if;

      end if;

   end process P_tx_flg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid2 SPI inputs
   --!   Feedback offset priority on DAC LSB for data transmit
   --    @Req : DRE-DMX-FW-REQ-0290
   --    @Req : DRE-DMX-FW-REQ-0370
   -- ------------------------------------------------------------------------------------------------------
   P_sq2_spi_in : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sq2_spi_start                                <= '0';
         sq2_spi_data_tx(c_SQ2_DAC_DATA_S-1 downto 0) <= c_EP_CMD_DEF_S2OFF;

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sq2_spi_start  <= (sq2_dac_lsb_tx_flg or sq2_fbk_off_tx_flg) and pls_rw_cnt(pls_rw_cnt'high);

         if sq2_fbk_off_tx_flg = '1' then
            sq2_spi_data_tx(c_SQ2_DAC_DATA_S-1 downto 0) <= sq2_fbk_off_final;

         else
            sq2_spi_data_tx(c_SQ2_DAC_DATA_S-1 downto 0) <= sq2_dac_lsb_r(sq2_dac_lsb_r'high);

         end if;

      end if;

   end process P_sq2_spi_in;

   sq2_spi_data_tx(c_SQ2_DAC_DATA_S+c_SQ2_DAC_MODE_S-1 downto   c_SQ2_DAC_DATA_S) <= c_DST_SQ2DAC_NORM;
   sq2_spi_data_tx(c_SQ2_SPI_SER_WD_S-1 downto c_SQ2_DAC_DATA_S+c_SQ2_DAC_MODE_S) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid 2 SPI master
   --    @Req : DRE-DMX-FW-REQ-0340
   --    @Req : DRE-DMX-FW-REQ-0350
   -- ------------------------------------------------------------------------------------------------------
   I_sq2_spi_master : entity work.spi_master generic map
   (     g_CPOL               => c_SQ2_SPI_CPOL       , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_SQ2_SPI_CPHA       , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => c_SQ2_SPI_SCLK_L     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => c_SQ2_SPI_SCLK_H     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => 0                    , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_SQ2_SPI_SER_WD_S     -- integer                                            --! Data bus size
   ) port map
   (     i_rst                => rst_sq2_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_start              => sq2_spi_start        , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => c_SQ2_SPI_SER_WD_S_V , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => sq2_spi_data_tx      , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => sq2_spi_tx_busy_n    , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => open                 , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => open                 , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => '0'                  , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => sq2_dac_data         , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => sq2_dac_sclk         , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => sq2_dac_sync_n         -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid2 SPI outputs
   --    @Req : DRE-DMX-FW-REQ-0340
   -- ------------------------------------------------------------------------------------------------------
   P_sq2_spi_out : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         o_sq2_dac_data    <= '0';
         o_sq2_dac_sclk    <= c_SQ2_SPI_CPOL;
         o_sq2_dac_snc_l_n <= c_PAD_REG_SET_AUTH;
         o_sq2_dac_snc_o_n <= c_PAD_REG_SET_AUTH;

      elsif rising_edge(i_clk_sq1_adc_dac) then
         o_sq2_dac_data    <= sq2_dac_data;
         o_sq2_dac_sclk    <= sq2_dac_sclk;
         o_sq2_dac_snc_l_n <= sq2_dac_sync_n or      sq2_fbk_off_tx_ena;
         o_sq2_dac_snc_o_n <= sq2_dac_sync_n or  not(sq2_fbk_off_tx_ena);

      end if;

   end process P_sq2_spi_out;

end architecture RTL;
