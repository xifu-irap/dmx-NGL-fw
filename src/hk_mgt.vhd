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
--!   @file                   hk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Housekeeping management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity hk_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_hk1_spi_miso_rs    : in     std_logic                                                            ; --! HouseKeeping 1 - SPI Master Input Slave Output
         o_hk1_spi_mosi       : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Master Output Slave Input
         o_hk1_spi_sclk       : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_hk1_spi_cs_n       : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux	         : out    std_logic_vector(      c_HK_MUX_S-1 downto 0)                        ; --! HouseKeeping 1 - Multiplexer
         o_hk1_mux_ena_n	   : out    std_logic                                                              --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

   );
end entity hk_mgt;

architecture RTL of hk_mgt is
constant c_HK_SPI_SER_WD_S_V_S: integer := log2_ceil(c_HK_SPI_SER_WD_S+1)                                   ; --! HK SPI: Serial word size vector bus size
constant c_HK_SPI_SER_WD_S_V  : std_logic_vector(c_HK_SPI_SER_WD_S_V_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_HK_SPI_SER_WD_S, c_HK_SPI_SER_WD_S_V_S))     ; --! HK SPI: Serial word size vector

signal   hk_spi_start         : std_logic                                                                   ; --! HK SPI: Start transmit ('0' = Inactive, '1' = Active)
signal   hk_spi_data_tx       : std_logic_vector(c_HK_SPI_SER_WD_S-1 downto 0)                              ; --! HK SPI: Data to transmit (stall on MSB)
signal   hk_spi_tx_busy_n     : std_logic                                                                   ; --! HK SPI: Transmit link busy ('0' = Busy, '1' = Not Busy)
signal   hk_spi_data_rx       : std_logic_vector(c_HK_SPI_SER_WD_S-1 downto 0)                              ; --! HK SPI: Receipted data (stall on LSB)
signal   hk_spi_data_rx_rdy   : std_logic                                                                   ; --! HK SPI: Receipted data ready ('0' = Not ready, '1' = Ready)

signal   hk_mux	            : std_logic_vector(       c_HK_MUX_S-1 downto 0)                              ; --! HK Multiplexer
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   HK SPI master
   --    @Req : DRE-DMX-FW-REQ-0550
   -- ------------------------------------------------------------------------------------------------------
   I_hk_spi_master : entity work.spi_master generic map
   (     g_CPOL               => c_HK_SPI_CPOL        , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_HK_SPI_CPHA        , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => c_HK_SPI_SCLK_L      , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => c_HK_SPI_SCLK_H      , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => c_FF_RSYNC_NB        , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_HK_SPI_SER_WD_S      -- integer                                            --! Data bus size
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_start              => hk_spi_start         , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => c_HK_SPI_SER_WD_S_V  , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => hk_spi_data_tx       , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => hk_spi_tx_busy_n     , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => hk_spi_data_rx       , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => hk_spi_data_rx_rdy   , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => i_hk1_spi_miso_rs    , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => o_hk1_spi_mosi       , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => o_hk1_spi_sclk       , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => o_hk1_spi_cs_n         -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   HK Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0560
   -- ------------------------------------------------------------------------------------------------------
   o_hk1_mux            <= hk_mux;
   o_hk1_mux_ena_n	   <= '0';

   -- TODO
   hk_spi_start         <= '1';
   hk_spi_data_tx       <= hk_spi_data_rx;

   P_todo : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         hk_mux   <= (others => '0');

      elsif rising_edge(i_clk) then
         hk_mux   <= std_logic_vector(std_logic_vector(unsigned(hk_mux) + 1));

      end if;

   end process P_todo;

end architecture RTL;
