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
--!   @file                   ep_spi_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP Serial Peripheral Interface master model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_model.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity ep_spi_model is generic (
         g_EP_CLK_PER         : time    := c_EP_CLK_PER_DEF                                                 ; --! EP: System clock period (ps)
         g_EP_CLK_PER_SHIFT   : time    := c_EP_CLK_PER_SHFT_DEF                                            ; --! EP: Clock period shift
         g_EP_N_CLK_PER_SCLK_L: integer := c_EP_SCLK_L_DEF                                                  ; --! EP: Number of clock period for elaborating SPI Serial Clock low  level
         g_EP_N_CLK_PER_SCLK_H: integer := c_EP_SCLK_H_DEF                                                  ; --! EP: Number of clock period for elaborating SPI Serial Clock high level
         g_EP_BUF_DEL         : time    := c_EP_BUF_DEL_DEF                                                   --! EP: Delay introduced by buffer
   ); port (
         i_ep_cmd_ser_wd_s    : in     std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)               ; --! EP: Serial word size
         i_ep_cmd_start       : in     std_logic                                                            ; --! EP: Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd             : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP: Command to send
         o_ep_cmd_busy_n      : out    std_logic                                                            ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)

         o_ep_data_rx         : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP: Receipted data
         o_ep_data_rx_rdy     : out    std_logic                                                            ; --! EP: Receipted data ready ('0' = Not ready, '1' = Ready)

         o_ep_spi_mosi        : out    std_logic                                                            ; --! EP: SPI Master Input Slave Output (MSB first)
         i_ep_spi_miso        : in     std_logic                                                            ; --! EP: SPI Master Output Slave Input (MSB first)
         o_ep_spi_sclk        : out    std_logic                                                            ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), period = 2*g_EP_CLK_PER
         o_ep_spi_cs_n        : out    std_logic                                                              --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)
   );
end entity ep_spi_model;

architecture Behavioral of ep_spi_model is
constant c_CLK_PER_HALF       : time       := g_EP_CLK_PER/2                                                ; --! Half clock period
constant c_RST_ACT_TIME       : time       := 3 * g_EP_CLK_PER/2                                            ; --! Reset activation time

constant c_N_CLK_PER_MISO_DEL : integer   := 2                                                              ; --! Number of clock period for miso signal delay from spi pin input to spi master input

constant c_SER_WD_MAX_S       : integer   := 2*c_EP_CMD_S                                                   ; --! Serial word maximal size

signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   clk                  : std_logic                                                                   ; --! System Clock

signal   ep_cmd_start_r       : std_logic                                                                   ; --! EP: Start command transmit register

signal   ep_cmd               : std_logic_vector(c_SER_WD_MAX_S-1 downto 0)                                 ; --! EP: Command to send
signal   ep_data_rx           : std_logic_vector(c_SER_WD_MAX_S-1 downto 0)                                 ; --! EP: Receipted data
signal   ep_spi_miso_r        : std_logic_vector(c_N_CLK_PER_MISO_DEL-1 downto 0)                           ; --! EP: SPI Master Output Slave Input register
signal   ep_spi_miso_r_msb    : std_logic                                                                   ; --! EP: SPI Master Output Slave Input register MSB

signal   ep_cmd_ser_wd_s_srt  : std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)                      ; --! EP: Serial word size recorded on start rising edge
signal   ep_cmd_ser_wd_s_srt2 : std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)                      ; --! EP: Serial word size recorded on start rising edge (second record)

signal   ep_data_rx_mux       : t_slv_arr(0 to c_SER_WD_MAX_S-1)(c_EP_CMD_S-1 downto 0)                     ; --! EP: Receipted data multiplexer
signal   ep_data_rx_mux_or    : t_slv_arr(0 to c_SER_WD_MAX_S  )(c_EP_CMD_S-1 downto 0)                     ; --! EP: Receipted data multiplexer or

signal   ep_spi_mosi_bf_buf   : std_logic                                                                   ; --! EP: SPI Master Input Slave Output before buffer (MSB first)
signal   ep_spi_miso_bf_buf   : std_logic                                                                   ; --! EP: SPI Master Output Slave Input before buffer (MSB first)
signal   ep_spi_sclk_bf_buf   : std_logic                                                                   ; --! EP: SPI Serial Clock before buffer (CPOL = '0', CPHA = '0'), period = 2*g_EP_CLK_PER
signal   ep_spi_cs_n_bf_buf   : std_logic                                                                   ; --! EP: SPI Chip Select before buffer ('0' = Active, '1' = Inactive)
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset & Clock generation
   -- ------------------------------------------------------------------------------------------------------
   P_rst: process
   begin
      rst   <= c_RST_LEV_ACT;
      wait for c_RST_ACT_TIME;
      rst   <= not(c_RST_LEV_ACT);
      wait;
   end process P_rst;

   --! Clock generation
   P_clk: process
   begin
      clk   <= c_LOW_LEV;
      wait for c_CLK_PER_HALF - g_EP_CLK_PER_SHIFT;
      clk   <= c_HGH_LEV;
      wait for c_CLK_PER_HALF;
      clk   <= c_LOW_LEV;
      wait for g_EP_CLK_PER_SHIFT;
   end process P_clk;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP: SPI links delay introduced by buffer
   -- ------------------------------------------------------------------------------------------------------
   ep_spi_miso_bf_buf   <= transport i_ep_spi_miso      after g_EP_BUF_DEL when ep_spi_cs_n_bf_buf = c_LOW_LEV else c_LOW_LEV;
   o_ep_spi_mosi        <= transport ep_spi_mosi_bf_buf after g_EP_BUF_DEL when now > g_EP_BUF_DEL else c_LOW_LEV;
   o_ep_spi_sclk        <= transport ep_spi_sclk_bf_buf after g_EP_BUF_DEL when now > g_EP_BUF_DEL else c_LOW_LEV;
   o_ep_spi_cs_n        <= transport ep_spi_cs_n_bf_buf after g_EP_BUF_DEL when now > g_EP_BUF_DEL else c_HGH_LEV;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP: SPI Master Output Slave Input delay management
   -- ------------------------------------------------------------------------------------------------------
   P_ep_spi_miso_del : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         ep_spi_miso_r <= c_ZERO(ep_spi_miso_r'range);

      elsif rising_edge(clk) then
         ep_spi_miso_r <= ep_spi_miso_r(ep_spi_miso_r'high-1 downto ep_spi_miso_r'low) & ep_spi_miso_bf_buf;

      end if;

   end process P_ep_spi_miso_del;

   ep_spi_miso_r_msb <= ep_spi_miso_r(ep_spi_miso_r'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   EP: Serial word size recorded on start rising edge
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_ser_wd_s : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         ep_cmd_start_r       <= c_LOW_LEV;
         ep_cmd_ser_wd_s_srt  <= std_logic_vector(to_unsigned(c_EP_CMD_S, ep_cmd_ser_wd_s_srt'length));
         ep_cmd_ser_wd_s_srt2 <= std_logic_vector(to_unsigned(c_EP_CMD_S, ep_cmd_ser_wd_s_srt2'length));

      elsif rising_edge(clk) then
         ep_cmd_start_r          <= i_ep_cmd_start;

         if (not(ep_cmd_start_r) and i_ep_cmd_start) = c_HGH_LEV then
            ep_cmd_ser_wd_s_srt  <= i_ep_cmd_ser_wd_s;
            ep_cmd_ser_wd_s_srt2 <= ep_cmd_ser_wd_s_srt;

         end if;

      end if;

   end process P_ep_cmd_ser_wd_s;

   -- ------------------------------------------------------------------------------------------------------
   --!   SPI Data rx/tx adaptation according to serial word size requested
   -- ------------------------------------------------------------------------------------------------------
   ep_cmd            <= i_ep_cmd & c_ZERO(c_SER_WD_MAX_S-c_EP_CMD_S-1 downto c_ZERO'low);

   ep_data_rx_mux_or(ep_data_rx_mux_or'low) <= c_ZERO(ep_data_rx_mux_or(ep_data_rx_mux_or'low)'range);

   G_ep_cmd_ser_wd_s: for i in 0 to c_SER_WD_MAX_S-1 generate
   begin

      G_ep_data_rx_mux_bit: for j in 0 to c_EP_CMD_S-1 generate
      begin

         G_wd_s_less: if i < c_EP_CMD_S generate

            G_bit_less: if j < c_EP_CMD_S-i generate
               ep_data_rx_mux(i)(j) <= c_EP_CMD_ERR_CLR when ep_cmd_ser_wd_s_srt2 = std_logic_vector(to_unsigned(i,ep_cmd_ser_wd_s_srt2'length)) else
                                       c_LOW_LEV;
            end generate G_bit_less;

            G_bit_greater: if j >= c_EP_CMD_S-i generate
               ep_data_rx_mux(i)(j) <= ep_data_rx(i-c_EP_CMD_S+j) when ep_cmd_ser_wd_s_srt2 = std_logic_vector(to_unsigned(i,ep_cmd_ser_wd_s_srt2'length)) else
                                       c_LOW_LEV;
            end generate G_bit_greater;

         end generate G_wd_s_less;

         G_wd_s_greater: if i >= c_EP_CMD_S generate
            ep_data_rx_mux(i)(j) <= ep_data_rx(i-c_EP_CMD_S+j) when ep_cmd_ser_wd_s_srt2 = std_logic_vector(to_unsigned(i,ep_cmd_ser_wd_s_srt2'length)) else
                                    c_LOW_LEV;
         end generate G_wd_s_greater;

      end generate G_ep_data_rx_mux_bit;

      ep_data_rx_mux_or(i+1) <= ep_data_rx_mux(i) or ep_data_rx_mux_or(i);

   end generate G_ep_cmd_ser_wd_s;

   o_ep_data_rx   <= ep_data_rx_mux_or(ep_data_rx_mux_or'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   SPI master
   -- ------------------------------------------------------------------------------------------------------
   I_spi_master : entity work.spi_master generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_CPOL               => c_EP_SPI_CPOL        , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_EP_SPI_CPHA        , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => g_EP_N_CLK_PER_SCLK_L, -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => g_EP_N_CLK_PER_SCLK_H, -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => c_N_CLK_PER_MISO_DEL , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_SER_WD_MAX_S         -- integer                                            --! Data bus size
   ) port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! Clock

         i_start              => i_ep_cmd_start       , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => i_ep_cmd_ser_wd_s    , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => ep_cmd               , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => o_ep_cmd_busy_n      , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => ep_data_rx           , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => o_ep_data_rx_rdy     , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => ep_spi_miso_r_msb    , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => ep_spi_mosi_bf_buf   , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => ep_spi_sclk_bf_buf   , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => ep_spi_cs_n_bf_buf     -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

end architecture Behavioral;
