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
--!   @file                   dac121s101_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                DAC DAC121S101 model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity dac121s101_model is generic (
         g_VA                 : real                                                                        ; --! Voltage reference (Volt)
         g_TIME_TS            : time                                                                          --! Time: Output Voltage Settling
   ); port (
         i_din                : in     std_logic                                                            ; --! Serial Data
         i_sclk               : in     std_logic                                                            ; --! Serial Clock
         i_sync_n             : in     std_logic                                                            ; --! Frame synchronization ('0' = Active, '1' = Inactive)

         o_vout               : out    real                                                                   --! Analog voltage ( 0.0 <= Vout < g_VA)
   );
end entity dac121s101_model;

architecture Behavioral of dac121s101_model is
constant c_CLK_PER            : time       := 8 ns                                                         ; --! Clock period

constant c_SPI_CPOL           : std_logic  := '0'                                                           ; --! SPI Clock polarity
constant c_SPI_CPHA           : std_logic  := '1'                                                           ; --! SPI Clock phase
constant c_SPI_DTA_WD_S       : integer    := 16                                                            ; --! SPI Data word bus size
constant c_SPI_DTA_WD_NB_S    : integer    :=  1                                                            ; --! SPI Data word number size
constant c_DAC_DATA_S         : integer    := 12                                                            ; --! SPI DAC data size bus
constant c_DAC_MODE_S         : integer    := 2                                                             ; --! SPI DAC mode size bus

constant c_VOUT_FACT          : real       := 1.0 / real(2**c_DAC_DATA_S)                                   ; --! Analog voltage factor

signal   rst                  : std_logic                                                                   ; --! Reset ('0' = Inactive, '1' = Active)
signal   clk                  : std_logic                                                                   ; --! Clock

signal   spi_data_rx_wd       : std_logic_vector(c_SPI_DTA_WD_S-1 downto 0)                                 ; --! Receipted data word (stall on LSB)
signal   vout_no_del          : real                                                                        ; --! Analog voltage without delay

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset & Clock generation
   -- ------------------------------------------------------------------------------------------------------
   P_rst: process
   begin
      rst   <= '1';
      wait for 3*c_CLK_PER/2;
      rst   <= '0';
      wait;

   end process P_rst;

   P_clk : process
   begin

      clk <= '1';
      wait for c_CLK_PER - (c_CLK_PER/2);
      clk <= '0';
      wait for c_CLK_PER/2;

   end process P_clk;

   -- ------------------------------------------------------------------------------------------------------
   --!   SPI slave
   -- ------------------------------------------------------------------------------------------------------
   I_spi_slave: entity work.spi_slave generic map (
         g_CPOL               => c_SPI_CPOL           , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_SPI_CPHA           , -- std_logic                                        ; --! Clock phase
         g_DTA_TX_WD_S        => c_SPI_DTA_WD_S       , -- integer                                          ; --! Data word to transmit bus size
         g_DTA_TX_WD_NB_S     => c_SPI_DTA_WD_NB_S    , -- integer                                          ; --! Data word to transmit number size
         g_DTA_RX_WD_S        => c_SPI_DTA_WD_S       , -- integer                                          ; --! Receipted data word bus size
         g_DTA_RX_WD_NB_S     => c_SPI_DTA_WD_NB_S      -- integer                                            --! Receipted data word number size
   ) port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! Clock

         i_data_tx_wd         => (others => '0')      , -- in     slv(g_DTA_TX_WD_S   -1 downto 0)          ; --! Data word to transmit (stall on MSB)
         o_data_tx_wd_nb      => open                 , -- out    slv(g_DTA_TX_WD_NB_S-1 downto 0)          ; --! Data word to transmit number

         o_data_rx_wd         => spi_data_rx_wd       , -- out    slv(g_DTA_RX_WD_S   -1 downto 0)          ; --! Receipted data word (stall on LSB)
         o_data_rx_wd_nb      => open                 , -- out    slv(g_DTA_RX_WD_NB_S-1 downto 0)          ; --! Receipted data word number
         o_data_rx_wd_lg      => open                 , -- out    slv(log2_ceil(g_DTA_RX_WD_S)-1 downto 0)  ; --! Receipted data word length minus 1
         o_data_rx_wd_rdy     => open                 , -- out    std_logic                                 ; --! Receipted data word ready ('0' = Not ready, '1' = Ready)

         o_spi_wd_end         => open                 , -- out    std_logic                                 ; --! SPI word end ('0' = Not end, '1' = End)

         o_miso               => open                 , -- out    std_logic                                 ; --! SPI Master Input Slave Output
         i_mosi               => i_din                , -- in     std_logic                                 ; --! SPI Master Output Slave Input
         i_sclk               => i_sclk               , -- in     std_logic                                 ; --! SPI Serial Clock
         i_cs_n               => i_sync_n               -- in     std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Analog voltage
   -- ------------------------------------------------------------------------------------------------------
   P_vout_no_del : process
   begin

      wait until rising_edge(i_sync_n);
         vout_no_del <= g_VA * c_VOUT_FACT * real(to_integer(unsigned(spi_data_rx_wd(c_DAC_DATA_S-1 downto 0)))) when spi_data_rx_wd(c_DAC_MODE_S+c_DAC_DATA_S-1 downto c_DAC_DATA_S) = "00"  else 0.0;

   end process P_vout_no_del;

   o_vout <= transport vout_no_del after g_TIME_TS when now> g_TIME_TS else 0.0;

end architecture Behavioral;
