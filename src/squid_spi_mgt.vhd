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
--!   @file                   squid_spi_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid SPI management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity squid_spi_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         o_sq1_adc_spi_mosi   : out    std_logic                                                            ; --! SQUID1 ADC - SPI Serial Data In Out
         o_sq1_adc_spi_sclk   : out    std_logic                                                            ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_sq1_adc_spi_cs_n   : out    std_logic                                                            ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sq2_dac_data       : out    std_logic                                                            ; --! SQUID2 DAC - Serial Data
         o_sq2_dac_sclk       : out    std_logic                                                            ; --! SQUID2 DAC - Serial Clock
         o_sq2_dac_sync_n     : out    std_logic                                                              --! SQUID2 DAC - Frame Synchronization ('0' = Active, '1' = Inactive)

   );
end entity squid_spi_mgt;

architecture RTL of squid_spi_mgt is
constant c_SPI_SER_WD_S_V_S   : integer := log2_ceil(c_SQ2_SPI_SER_WD_S+1)                                  ; --! SQUID2 DAC SPI: Serial word size vector bus size
constant c_SQ2_SPI_SER_WD_S_V : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_SQ2_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S))       ; --! SQUID2 DAC SPI: Serial word size vector

signal   sq2_spi_start        : std_logic                                                                   ; --! SQUID2 DAC SPI: Start transmit ('0' = Inactive, '1' = Active)
signal   sq2_spi_data_tx      : std_logic_vector(c_SQ2_SPI_SER_WD_S-1 downto 0)                             ; --! SQUID2 DAC SPI: Data to transmit (stall on MSB)
signal   sq2_spi_tx_busy_n    : std_logic                                                                   ; --! SQUID2 DAC SPI: Transmit link busy ('0' = Busy, '1' = Not Busy)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid 1 ADC, static configuration without SPI
   -- ------------------------------------------------------------------------------------------------------
   o_sq1_adc_spi_mosi   <= '1';     -- Duty Cycle Stabilizer ('0' = Disable, '1' = Enable)
   o_sq1_adc_spi_sclk   <= '0';     -- Data format ('0' = Binary, '1' = Twos complement)
   o_sq1_adc_spi_cs_n   <= '1';     -- Static configuration ('0' = No, '1' = Yes)

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid 2 SPI master
   --    @Req : DRE-DMX-FW-REQ-0340
   -- ------------------------------------------------------------------------------------------------------
   I_sq2_spi_master : entity work.spi_master generic map
   (     g_CPOL               => c_SQ2_SPI_CPOL       , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_SQ2_SPI_CPHA       , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => c_SQ2_SPI_SCLK_L     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => c_SQ2_SPI_SCLK_H     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => 0                    , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_SQ2_SPI_SER_WD_S     -- integer                                            --! Data bus size
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_start              => sq2_spi_start        , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => c_SQ2_SPI_SER_WD_S_V , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => sq2_spi_data_tx      , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => sq2_spi_tx_busy_n    , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => open                 , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => open                 , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => '0'                  , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => o_sq2_dac_data       , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => o_sq2_dac_sclk       , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => o_sq2_dac_sync_n       -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- TODO
   sq2_spi_start     <= '1';
   sq2_spi_data_tx   <= x"256A";

end architecture RTL;
