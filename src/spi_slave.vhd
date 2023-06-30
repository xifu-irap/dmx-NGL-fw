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
--!   @file                   spi_slave.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Serial Peripheral Interface slave
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity spi_slave is generic (
         g_RST_LEV_ACT        : std_logic                                                                   ; --! Reset level activation value
         g_CPOL               : std_logic                                                                   ; --! Clock polarity
         g_CPHA               : std_logic                                                                   ; --! Clock phase
         g_DTA_TX_WD_S        : integer                                                                     ; --! Data word to transmit bus size
         g_DTA_TX_WD_NB_S     : integer                                                                     ; --! Data word to transmit number size
         g_DTA_RX_WD_S        : integer                                                                     ; --! Receipted data word bus size
         g_DTA_RX_WD_NB_S     : integer                                                                       --! Receipted data word number size
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_data_tx_wd         : in     std_logic_vector(g_DTA_TX_WD_S   -1 downto 0)                        ; --! Data word to transmit (stall on MSB)
         o_data_tx_wd_nb      : out    std_logic_vector(g_DTA_TX_WD_NB_S-1 downto 0)                        ; --! Data word to transmit number

         o_data_rx_wd         : out    std_logic_vector(g_DTA_RX_WD_S   -1 downto 0)                        ; --! Receipted data word (stall on LSB)
         o_data_rx_wd_nb      : out    std_logic_vector(g_DTA_RX_WD_NB_S-1 downto 0)                        ; --! Receipted data word number
         o_data_rx_wd_lg      : out    std_logic_vector(integer(ceil(log2(real(g_DTA_RX_WD_S))))-1 downto 0); --! Receipted data word length minus 1
         o_data_rx_wd_rdy     : out    std_logic                                                            ; --! Receipted data word ready ('0' = Not ready, '1' = Ready)

         o_spi_wd_end         : out    std_logic                                                            ; --! SPI word end ('0' = Not end, '1' = End)

         o_miso               : out    std_logic                                                            ; --! SPI Master Input Slave Output
         i_mosi               : in     std_logic                                                            ; --! SPI Master Output Slave Input
         i_sclk               : in     std_logic                                                            ; --! SPI Serial Clock
         i_cs_n               : in     std_logic                                                              --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );
end entity spi_slave;

architecture RTL of spi_slave is
constant c_TX_BIT_CNT_NB_VAL  : integer:= g_DTA_TX_WD_S                                                     ; --! Data transmit bit counter: number of value
constant c_TX_BIT_CNT_MAX_VAL : integer:= c_TX_BIT_CNT_NB_VAL-2                                             ; --! Data transmit bit counter: maximal value
constant c_TX_BIT_CNT_S       : integer:= integer(ceil(log2(real(c_TX_BIT_CNT_MAX_VAL+1))))+1               ; --! Data transmit bit counter: size bus (signed)

constant c_RX_BIT_CNT_NB_VAL  : integer:= g_DTA_RX_WD_S                                                     ; --! Data receipt bit counter: number of value
constant c_RX_BIT_CNT_MAX_VAL : integer:= c_RX_BIT_CNT_NB_VAL-2                                             ; --! Data receipt bit counter: maximal value
constant c_RX_BIT_CNT_S       : integer:= integer(ceil(log2(real(c_RX_BIT_CNT_MAX_VAL+1))))+1               ; --! Data receipt bit counter: size bus (signed)

signal   sclk_r               : std_logic                                                                   ; --! SPI Serial Clock register
signal   cs_n_r               : std_logic                                                                   ; --! SPI Chip Select register ('0' = Active, '1' = Inactive)
signal   cs_n_fe              : std_logic                                                                   ; --! SPI Chip Select falling edge
signal   cs_n_re              : std_logic                                                                   ; --! SPI Chip Select rising edge

signal   pls_mosi             : std_logic                                                                   ; --! Pulse for sampling mosi signal
signal   pls_miso             : std_logic                                                                   ; --! Pulse for updating miso signal
signal   pls_mosi_r           : std_logic                                                                   ; --! Pulse for updating mosi signal register

signal   data_tx_bit_cnt      : std_logic_vector(c_TX_BIT_CNT_S  -1 downto 0)                               ; --! Data transmit bit counter
signal   data_tx_wd_nb        : std_logic_vector(g_DTA_TX_WD_NB_S-1 downto 0)                               ; --! Data transmit word number internal
signal   data_tx_wd_ser       : std_logic_vector(g_DTA_TX_WD_S   -1 downto 0)                               ; --! Data transmit word serial

signal   data_rx_bit_cnt      : std_logic_vector(c_RX_BIT_CNT_S  -1 downto 0)                               ; --! Data receipt bit counter
signal   data_rx_wd_nb        : std_logic_vector(g_DTA_RX_WD_NB_S-1 downto 0)                               ; --! Data receipt word number internal
signal   data_rx_wd_ser       : std_logic_vector(g_DTA_RX_WD_S   -1 downto 0)                               ; --! Data receipt word serial

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SPI signals
   -- ------------------------------------------------------------------------------------------------------
   P_spi_r : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         sclk_r      <= '0';
         cs_n_r      <= '1';
         pls_mosi_r  <= '0';

      elsif rising_edge(i_clk) then
         sclk_r      <= i_sclk;
         cs_n_r      <= i_cs_n;
         pls_mosi_r  <= pls_mosi;

      end if;

   end process P_spi_r;

   cs_n_fe <=     cs_n_r  and not(i_cs_n);
   cs_n_re <= not(cs_n_r) and     i_cs_n;

   G_pls_cpol_cpha_equ: if g_CPOL = g_CPHA generate
      pls_miso <=(     sclk_r  and not(i_sclk) and not(i_cs_n)) or cs_n_fe;
      pls_mosi <=  not(sclk_r) and     i_sclk  and not(i_cs_n);

   end generate G_pls_cpol_cpha_equ;

   G_pls_cpol_cpha_diff: if g_CPOL /= g_CPHA generate
      pls_miso <=( not(sclk_r) and     i_sclk  and not(i_cs_n)) or cs_n_fe;
      pls_mosi <=      sclk_r  and not(i_sclk) and not(i_cs_n);

   end generate G_pls_cpol_cpha_diff;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data transmit bit counter
   -- ------------------------------------------------------------------------------------------------------
   P_data_tx_bit_cnt : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         data_tx_bit_cnt <= (others => '1');

      elsif rising_edge(i_clk) then
         if cs_n_re = '1' then
            data_tx_bit_cnt <= (others => '1');

         elsif (pls_miso and data_tx_bit_cnt(data_tx_bit_cnt'high)) = '1' then
            data_tx_bit_cnt   <= std_logic_vector(to_signed(c_TX_BIT_CNT_MAX_VAL, data_tx_bit_cnt'length));

         elsif pls_miso = '1' then
            data_tx_bit_cnt   <= std_logic_vector(signed(data_tx_bit_cnt) - 1);

         end if;

      end if;

   end process P_data_tx_bit_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data transmit serial
   -- ------------------------------------------------------------------------------------------------------
   P_data_tx_wd_ser : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         data_tx_wd_ser    <= (others => '0');

      elsif rising_edge(i_clk) then
         if (pls_miso and data_tx_bit_cnt(data_tx_bit_cnt'high)) = '1' then
            data_tx_wd_ser <= i_data_tx_wd;

         elsif pls_miso = '1' then
            data_tx_wd_ser <= data_tx_wd_ser(data_tx_wd_ser'high-1 downto 0) & '0';

         end if;

      end if;

   end process P_data_tx_wd_ser;

   o_miso <= data_tx_wd_ser(data_tx_wd_ser'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   Data transmit word number
   -- ------------------------------------------------------------------------------------------------------
   P_data_tx_wd_nb : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         data_tx_wd_nb     <= (others => '0');

      elsif rising_edge(i_clk) then
         if cs_n_re = '1' then
            data_tx_wd_nb  <= (others => '0');

         elsif (pls_miso and data_tx_bit_cnt(data_tx_bit_cnt'high)) = '1' then
            data_tx_wd_nb     <= std_logic_vector(unsigned(data_tx_wd_nb) + 1);

         end if;

      end if;

   end process P_data_tx_wd_nb;

   o_data_tx_wd_nb <= data_tx_wd_nb;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data receipt bit counter
   -- ------------------------------------------------------------------------------------------------------
   P_data_rx_bit_cnt : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         data_rx_bit_cnt <= (others => '1');

      elsif rising_edge(i_clk) then
         if cs_n_re = '1' then
            data_rx_bit_cnt <= (others => '1');

         elsif (pls_mosi and data_rx_bit_cnt(data_rx_bit_cnt'high)) = '1' then
            data_rx_bit_cnt   <= std_logic_vector(to_signed(c_RX_BIT_CNT_MAX_VAL, data_rx_bit_cnt'length));

         elsif pls_mosi = '1' then
            data_rx_bit_cnt   <= std_logic_vector(signed(data_rx_bit_cnt) - 1);

         end if;

      end if;

   end process P_data_rx_bit_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data receipt serial
   -- ------------------------------------------------------------------------------------------------------
   P_data_rx_wd_ser : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         data_rx_wd_ser <= (others => '0');

      elsif rising_edge(i_clk) then
         if (pls_mosi and data_rx_bit_cnt(data_rx_bit_cnt'high)) = '1' then
            data_rx_wd_ser(data_rx_wd_ser'high downto 1) <= (others => '0');
            data_rx_wd_ser(0)                            <= i_mosi;

         elsif pls_mosi = '1' then
            data_rx_wd_ser <= data_rx_wd_ser(data_rx_wd_ser'high-1 downto 0) & i_mosi;

         end if;

      end if;

   end process P_data_rx_wd_ser;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data receipt word number internal
   -- ------------------------------------------------------------------------------------------------------
   P_data_rx_wd_nb : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         data_rx_wd_nb     <= (others => '0');

      elsif rising_edge(i_clk) then
         if cs_n_re = '1' then
            data_rx_wd_nb  <= (others => '0');

         elsif (pls_mosi_r and data_rx_bit_cnt(data_rx_bit_cnt'high)) = '1' then
            data_rx_wd_nb     <= std_logic_vector(unsigned(data_rx_wd_nb) + 1);

         end if;

      end if;

   end process P_data_rx_wd_nb;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data receipt word number
   -- ------------------------------------------------------------------------------------------------------
   P_o_data_rx_wd_nb : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         o_data_rx_wd_nb   <= (others => '0');

      elsif rising_edge(i_clk) then
         if ((pls_mosi_r and data_rx_bit_cnt(data_rx_bit_cnt'high)) or (cs_n_re and not(data_rx_bit_cnt(data_rx_bit_cnt'high)))) = '1' then
            o_data_rx_wd_nb   <= data_rx_wd_nb;

         end if;

      end if;

   end process P_o_data_rx_wd_nb;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data receipt
   -- ------------------------------------------------------------------------------------------------------
   P_data_rx : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         o_data_rx_wd      <= (others => '0');
         o_data_rx_wd_lg   <= std_logic_vector(to_unsigned(c_RX_BIT_CNT_MAX_VAL+1, o_data_rx_wd_lg'length));
         o_data_rx_wd_rdy  <= '0';
         o_spi_wd_end      <= '0';

      elsif rising_edge(i_clk) then
         if ((pls_mosi_r and data_rx_bit_cnt(data_rx_bit_cnt'high)) or cs_n_re) = '1' then
            o_data_rx_wd      <= data_rx_wd_ser;
            o_data_rx_wd_lg   <= std_logic_vector(to_unsigned(c_RX_BIT_CNT_MAX_VAL, o_data_rx_wd_lg'length) - unsigned(data_rx_bit_cnt(o_data_rx_wd_lg'high downto 0)));
         end if;

         o_data_rx_wd_rdy <= (pls_mosi_r and data_rx_bit_cnt(data_rx_bit_cnt'high));
         o_spi_wd_end     <= cs_n_re;

      end if;

   end process P_data_rx;

end architecture RTL;
