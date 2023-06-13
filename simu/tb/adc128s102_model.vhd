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
--!   @file                   adc128s102_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                ADC adc128s102 model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity adc128s102_model is generic (
         g_VA                 : real                                                                          --! Voltage reference (V)
   ); port (
         i_in0                : in     real                                                                 ; --! Analog input channel 0 ( 0.0 <= i_in0 < g_VA)
         i_in1                : in     real                                                                 ; --! Analog input channel 1 ( 0.0 <= i_in1 < g_VA)
         i_in2                : in     real                                                                 ; --! Analog input channel 2 ( 0.0 <= i_in2 < g_VA)
         i_in3                : in     real                                                                 ; --! Analog input channel 3 ( 0.0 <= i_in3 < g_VA)
         i_in4                : in     real                                                                 ; --! Analog input channel 4 ( 0.0 <= i_in4 < g_VA)
         i_in5                : in     real                                                                 ; --! Analog input channel 5 ( 0.0 <= i_in5 < g_VA)
         i_in6                : in     real                                                                 ; --! Analog input channel 6 ( 0.0 <= i_in6 < g_VA)
         i_in7                : in     real                                                                 ; --! Analog input channel 7 ( 0.0 <= i_in7 < g_VA)

         i_din                : in     std_logic                                                            ; --! Serial Data in
         i_sclk               : in     std_logic                                                            ; --! Serial Clock
         i_cs_n               : in     std_logic                                                            ; --! Chip Select ('0' = Active, '1' = Inactive)
         o_dout               : out    std_logic                                                              --! Serial Data out
   );
end entity adc128s102_model;

architecture Behavioral of adc128s102_model is
constant c_CLK_PER            : time       := 8 ns                                                          ; --! Clock period

constant c_SPI_CPOL           : std_logic  := '1'                                                           ; --! SPI Clock polarity
constant c_SPI_CPHA           : std_logic  := '1'                                                           ; --! SPI Clock phase
constant c_SPI_DTA_WD_S       : integer    := 16                                                            ; --! SPI Data word bus size
constant c_SPI_DTA_WD_NB_S    : integer    :=  1                                                            ; --! SPI Data word number size
constant c_ADD_S              : integer    :=  3                                                            ; --! SPI Address size bus
constant c_ADD_POS_LSB        : integer    := 11                                                            ; --! SPI Address position LSB
constant c_ADC_DATA_S         : integer    := 12                                                            ; --! SPI ADC data size bus

constant c_ADC_RES            : real       := g_VA / real(2**(c_ADC_DATA_S))                                ; --! ADC resolution (V)
constant c_VIN_MAX            : real       := (real(2**(c_ADC_DATA_S)) - 1.0) * c_ADC_RES                   ; --! Analog voltage maximum limit (V)

signal   rst                  : std_logic                                                                   ; --! Reset ('0' = Inactive, '1' = Active)
signal   clk                  : std_logic                                                                   ; --! Clock

signal   spi_data_tx_wd       : std_logic_vector(c_SPI_DTA_WD_S-1 downto 0)                                 ; --! Transmit  data word
signal   spi_data_rx_wd       : std_logic_vector(c_SPI_DTA_WD_S-1 downto 0)                                 ; --! Receipted data word
signal   miso                 : std_logic                                                                   ; --! SPI Master Input Slave Output

signal   add                  : std_logic_vector(     c_ADD_S-1 downto 0)                                   ; --! Address
signal   adc_data             : std_logic_vector(c_ADC_DATA_S-1 downto 0)                                   ; --! ADC data

signal   vin_sel              : real                                                                        ; --! Voltage input selected
signal   vin_sel_sat          : real                                                                        ; --! Voltage input selected saturation

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
   --!   Data management
   -- ------------------------------------------------------------------------------------------------------
   add            <= spi_data_rx_wd(c_ADD_S+c_ADD_POS_LSB-1 downto c_ADD_POS_LSB);

   vin_sel <=  i_in0 when add = std_logic_vector(to_unsigned(0, add'length)) else
               i_in1 when add = std_logic_vector(to_unsigned(1, add'length)) else
               i_in2 when add = std_logic_vector(to_unsigned(2, add'length)) else
               i_in3 when add = std_logic_vector(to_unsigned(3, add'length)) else
               i_in4 when add = std_logic_vector(to_unsigned(4, add'length)) else
               i_in5 when add = std_logic_vector(to_unsigned(5, add'length)) else
               i_in6 when add = std_logic_vector(to_unsigned(6, add'length)) else
               i_in7;

   vin_sel_sat    <= 0.0        when (vin_sel < 0.0  ) else
                     c_VIN_MAX  when (vin_sel > c_VIN_MAX) else
                     vin_sel;

   adc_data       <= std_logic_vector(to_unsigned(integer(round(vin_sel_sat/c_ADC_RES)), adc_data'length));

   spi_data_tx_wd <= std_logic_vector(resize(unsigned(adc_data), spi_data_tx_wd'length));

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

         i_data_tx_wd         => spi_data_tx_wd       , -- in     slv(g_DTA_TX_WD_S   -1 downto 0)          ; --! Data word to transmit (stall on MSB)
         o_data_tx_wd_nb      => open                 , -- out    slv(g_DTA_TX_WD_NB_S-1 downto 0)          ; --! Data word to transmit number

         o_data_rx_wd         => spi_data_rx_wd       , -- out    slv(g_DTA_RX_WD_S   -1 downto 0)          ; --! Receipted data word (stall on LSB)
         o_data_rx_wd_nb      => open                 , -- out    slv(g_DTA_RX_WD_NB_S-1 downto 0)          ; --! Receipted data word number
         o_data_rx_wd_lg      => open                 , -- out    slv(log2_ceil(g_DTA_RX_WD_S)-1 downto 0)  ; --! Receipted data word length minus 1
         o_data_rx_wd_rdy     => open                 , -- out    std_logic                                 ; --! Receipted data word ready ('0' = Not ready, '1' = Ready)

         o_spi_wd_end         => open                 , -- out    std_logic                                 ; --! SPI word end ('0' = Not end, '1' = End)

         o_miso               => miso                 , -- out    std_logic                                 ; --! SPI Master Input Slave Output
         i_mosi               => i_din                , -- in     std_logic                                 ; --! SPI Master Output Slave Input
         i_sclk               => i_sclk               , -- in     std_logic                                 ; --! SPI Serial Clock
         i_cs_n               => i_cs_n                 -- in     std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   o_dout         <= miso when i_cs_n = '0' else 'Z';

end architecture Behavioral;
