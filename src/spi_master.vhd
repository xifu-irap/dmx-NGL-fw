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
--!   @file                   spi_master.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Serial Peripheral Interface master
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity spi_master is generic (
         g_CPOL               : std_logic                                                                   ; --! Clock polarity
         g_CPHA               : std_logic                                                                   ; --! Clock phase
         g_N_CLK_PER_SCLK_L   : integer                                                                     ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   : integer                                                                     ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL : integer                                                                     ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             : integer                                                                       --! Data bus size
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_start              : in     std_logic                                                            ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           : in     std_logic_vector(integer(ceil(log2(real(g_DATA_S+1))))-1 downto 0)   ; --! Serial word size
         i_data_tx            : in     std_logic_vector(g_DATA_S-1 downto 0)                                ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          : out    std_logic                                                            ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            : out    std_logic_vector(g_DATA_S-1 downto 0)                                ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        : out    std_logic                                                            ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               : in     std_logic                                                            ; --! SPI Master Input Slave Output
         o_mosi               : out    std_logic                                                            ; --! SPI Master Output Slave Input
         o_sclk               : out    std_logic                                                            ; --! SPI Serial Clock
         o_cs_n               : out    std_logic                                                              --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );
end entity spi_master;

architecture RTL of spi_master is
constant c_PULSE_GEN_L_MAX_VAL: integer:= g_N_CLK_PER_SCLK_L-2                                              ; --! Pulse generator: maximal value for elaborating SPI Serial Clock low  level
constant c_PULSE_GEN_H_MAX_VAL: integer:= g_N_CLK_PER_SCLK_H-2                                              ; --! Pulse generator: maximal value for elaborating SPI Serial Clock high level
constant c_PULSE_GEN_MAX_VAL  : integer:= maximum(1, maximum(c_PULSE_GEN_H_MAX_VAL, c_PULSE_GEN_L_MAX_VAL)) ; --! Pulse generator: maximal value
constant c_PULSE_GEN_S        : integer:= integer(ceil(log2(real(c_PULSE_GEN_MAX_VAL+1))))+1                ; --! Pulse generator: size bus (signed)

constant c_PLS_STE_CNT_NB_VAL : integer:= 2 * g_DATA_S                                                      ; --! Pulse state counter: number of value
constant c_PLS_STE_CNT_MAX_VAL: integer:= c_PLS_STE_CNT_NB_VAL-1                                            ; --! Pulse state counter: maximal value
constant c_PLS_STE_CNT_S      : integer:= integer(ceil(log2(real(c_PLS_STE_CNT_MAX_VAL+1))))+1              ; --! Pulse state counter: size bus (signed)

signal   pulse_gen            : std_logic_vector(c_PULSE_GEN_S-1 downto 0)                                  ; --! Pulse generator
signal   pls_ste_cnt          : std_logic_vector(c_PLS_STE_CNT_S-1 downto 0)                                ; --! Pulse state counter

signal   data_tx_ser          : std_logic_vector(g_DATA_S-1 downto 0)                                       ; --! Data transmit serial
signal   data_rx_ser          : std_logic_vector(g_DATA_S-1 downto 0)                                       ; --! Data receipt serial

signal   pls_smp_data_rx_ser  : std_logic_vector(g_N_CLK_PER_MISO_DEL+1 downto 0)                           ; --! Pulse for sampling data receipt serial
signal   data_rx_ser_init     : std_logic_vector(g_N_CLK_PER_MISO_DEL+1 downto 0)                           ; --! Data receipt serial initialization
signal   data_rx_ser_end      : std_logic_vector(g_N_CLK_PER_MISO_DEL+1 downto 0)                           ; --! Data receipt serial end
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse generator
   -- ------------------------------------------------------------------------------------------------------
   P_pulse_gen : process (i_rst, i_clk)
   begin

      if i_rst = '1' then

         if (g_CPOL xor g_CPHA) = '0' then
            pulse_gen <= std_logic_vector(to_signed(c_PULSE_GEN_L_MAX_VAL, pulse_gen'length));

         else
            pulse_gen <= std_logic_vector(to_signed(c_PULSE_GEN_H_MAX_VAL, pulse_gen'length));

         end if;

      elsif rising_edge(i_clk) then
         if pls_ste_cnt(pls_ste_cnt'high) = '0' then

           if pulse_gen(pulse_gen'high) = '1' then
               if (g_CPOL xor g_CPHA xor pls_ste_cnt(0)) = '0' then
                  pulse_gen <= std_logic_vector(to_signed(c_PULSE_GEN_L_MAX_VAL, pulse_gen'length));

               else
                  pulse_gen <= std_logic_vector(to_signed(c_PULSE_GEN_H_MAX_VAL, pulse_gen'length));

               end if;

            else
               pulse_gen <= std_logic_vector(signed(pulse_gen) - 1);

            end if;
         end if;
      end if;

   end process P_pulse_gen;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse state counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_ste_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_ste_cnt       <= (others => '1');

      elsif rising_edge(i_clk) then
         if i_start = '1' and pls_ste_cnt(pls_ste_cnt'high) = '1' then
            pls_ste_cnt <= std_logic_vector(resize(unsigned(i_ser_wd_s & '0'), pls_ste_cnt'length) - 1);

         elsif pulse_gen(pulse_gen'high) = '1' and pls_ste_cnt(pls_ste_cnt'high) = '0' then
            pls_ste_cnt <= std_logic_vector(signed(pls_ste_cnt) - 1);

         end if;

      end if;

   end process P_pls_ste_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data transmit serial management
   -- ------------------------------------------------------------------------------------------------------
   P_data_tx_ser : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         data_tx_ser <= (others => '0');

      elsif rising_edge(i_clk) then
         if i_start = '1' and pls_ste_cnt(pls_ste_cnt'high) = '1' then
            data_tx_ser <= i_data_tx;

         elsif pulse_gen(pulse_gen'high) = '1' and pls_ste_cnt(0) = '0' and pls_ste_cnt(pls_ste_cnt'high) = '0' then
            data_tx_ser <= data_tx_ser(data_tx_ser'high-1 downto 0) & '0';

         end if;

      end if;

   end process P_data_tx_ser;

   o_tx_busy_n <= pls_ste_cnt(pls_ste_cnt'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   Data receipt serial management
   -- ------------------------------------------------------------------------------------------------------
   P_data_rx_ser : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_smp_data_rx_ser  <= (others => '0');
         data_rx_ser_init     <= (others => '0');
         data_rx_ser_end      <= (others => '0');
         data_rx_ser          <= (others => '0');
         o_data_rx            <= (others => '0');
         o_data_rx_rdy        <= '0';

      elsif rising_edge(i_clk) then
         pls_smp_data_rx_ser  <= pls_smp_data_rx_ser(pls_smp_data_rx_ser'high-1 downto 0) & (pulse_gen(pulse_gen'high) and not(pls_ste_cnt(0)) and not(pls_ste_cnt(pls_ste_cnt'high)));
         data_rx_ser_init     <= data_rx_ser_init(      data_rx_ser_init'high-1 downto 0) & (i_start and pls_ste_cnt(pls_ste_cnt'high));
         data_rx_ser_end      <= data_rx_ser_end(        data_rx_ser_end'high-1 downto 0) & pls_ste_cnt(pls_ste_cnt'high);

         if data_rx_ser_init(data_rx_ser_init'high-1) = '1' then
            data_rx_ser <= (others => '0');

         elsif pls_smp_data_rx_ser(pls_smp_data_rx_ser'high-1) = '1' then
            data_rx_ser <= data_rx_ser(data_rx_ser'high-1 downto 0) & i_miso;

         end if;

         if (data_rx_ser_end(data_rx_ser_end'high-1) and not(data_rx_ser_end(data_rx_ser_end'high))) = '1' then
            o_data_rx <= data_rx_ser;

         end if;

         o_data_rx_rdy <= data_rx_ser_end(data_rx_ser_end'high-1) and not(data_rx_ser_end(data_rx_ser_end'high));

      end if;

   end process P_data_rx_ser;

   -- ------------------------------------------------------------------------------------------------------
   --!   SPI management
   -- ------------------------------------------------------------------------------------------------------
   P_spi_mgt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_mosi   <= '0';
         o_sclk   <= g_CPOL;
         o_cs_n   <= '1';

      elsif rising_edge(i_clk) then
         o_mosi   <= data_tx_ser(data_tx_ser'high);
         o_sclk   <= not(g_CPHA) xor g_CPOL xor (pls_ste_cnt(0) and not(g_CPHA and pls_ste_cnt(pls_ste_cnt'high)));
         o_cs_n   <= pls_ste_cnt(pls_ste_cnt'high);

      end if;

   end process P_spi_mgt;

end architecture RTL;
