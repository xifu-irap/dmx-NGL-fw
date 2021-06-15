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
--!   @file                   in_rs_clk.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Data resynchronization on System Clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;

entity in_rs_clk is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_hk1_spi_miso       : in     std_logic                                                            ; --! HouseKeeping 1 - SPI Master Input Slave Output
         i_hk2_spi_miso       : in     std_logic                                                            ; --! HouseKeeping 2 - SPI Master Input Slave Output

         i_ep_spi_mosi        : in     std_logic                                                            ; --! EP - SPI Master Input Slave Output (MSB first)
         i_ep_spi_sclk        : in     std_logic                                                            ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_ep_spi_cs_n        : in     std_logic                                                            ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

         i_c0_sq1_adc_spi_sdio: in     std_logic                                                            ; --! SQUID1 ADC, col. 0 - SPI Serial Data In Out
         i_c1_sq1_adc_spi_sdio: in     std_logic                                                            ; --! SQUID1 ADC, col. 1 - SPI Serial Data In Out
         i_c2_sq1_adc_spi_sdio: in     std_logic                                                            ; --! SQUID1 ADC, col. 2 - SPI Serial Data In Out
         i_c3_sq1_adc_spi_sdio: in     std_logic                                                            ; --! SQUID1 ADC, col. 3 - SPI Serial Data In Out

         o_sync_rs            : out    std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock

         o_hk1_spi_miso_rs    : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Master Input Slave Output, synchronized on System Clock
         o_hk2_spi_miso_rs    : out    std_logic                                                            ; --! HouseKeeping 2 - SPI Master Input Slave Output, synchronized on System Clock

         o_ep_spi_mosi_rs     : out    std_logic                                                            ; --! EP - SPI Master Input Slave Output (MSB first), synchronized on System Clock
         o_ep_spi_sclk_rs     : out    std_logic                                                            ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’), synchronized on System Clock
         o_ep_spi_cs_n_rs     : out    std_logic                                                            ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock

         o_sq1_adc_spi_sdio_rs: out    std_logic_vector(c_DMX_NB_COL-1 downto 0)                              --! SQUID1 ADC - SPI Serial Data In Out, synchronized on System Clock
   );
end entity in_rs_clk;

architecture RTL of in_rs_clk is
signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

signal   hk1_spi_miso_r       : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! HouseKeeping 1 - SPI Master Input Slave Output register
signal   hk2_spi_miso_r       : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! HouseKeeping 2 - SPI Master Input Slave Output register

signal   ep_spi_mosi_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP - SPI Master Input Slave Output register (MSB first)
signal   ep_spi_sclk_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP - SPI Serial Clock register (CPOL = ‘0’, CPHA = ’0’)
signal   ep_spi_cs_n_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP - SPI Chip Select register ('0' = Active, '1' = Inactive)

signal   c0_sq1_adc_spi_sdio_r: std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 0 - SPI Serial Data In Out register
signal   c1_sq1_adc_spi_sdio_r: std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 1 - SPI Serial Data In Out register
signal   c2_sq1_adc_spi_sdio_r: std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 2 - SPI Serial Data In Out register
signal   c3_sq1_adc_spi_sdio_r: std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 3 - SPI Serial Data In Out register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sync_r               <= (others => c_I_SYNC_DEF);
         hk1_spi_miso_r       <= (others => c_I_SPI_DATA_DEF);
         hk2_spi_miso_r       <= (others => c_I_SPI_DATA_DEF);

         ep_spi_mosi_r        <= (others => c_I_SPI_DATA_DEF);
         ep_spi_sclk_r        <= (others => c_I_SPI_SCLK_DEF);
         ep_spi_cs_n_r        <= (others => c_I_SPI_CS_N_DEF);

         c0_sq1_adc_spi_sdio_r<= (others => c_I_SPI_DATA_DEF);
         c1_sq1_adc_spi_sdio_r<= (others => c_I_SPI_DATA_DEF);
         c2_sq1_adc_spi_sdio_r<= (others => c_I_SPI_DATA_DEF);
         c3_sq1_adc_spi_sdio_r<= (others => c_I_SPI_DATA_DEF);

      elsif rising_edge(i_clk) then
         sync_r               <= sync_r(                sync_r'high-1 downto 0) & i_sync;
         hk1_spi_miso_r       <= hk1_spi_miso_r(hk1_spi_miso_r'high-1 downto 0) & i_hk1_spi_miso;
         hk2_spi_miso_r       <= hk2_spi_miso_r(hk2_spi_miso_r'high-1 downto 0) & i_hk2_spi_miso;

         ep_spi_mosi_r        <= ep_spi_mosi_r(ep_spi_mosi_r'high-1 downto 0) & i_ep_spi_mosi;
         ep_spi_sclk_r        <= ep_spi_sclk_r(ep_spi_sclk_r'high-1 downto 0) & i_ep_spi_sclk;
         ep_spi_cs_n_r        <= ep_spi_cs_n_r(ep_spi_cs_n_r'high-1 downto 0) & i_ep_spi_cs_n;

         c0_sq1_adc_spi_sdio_r<= c0_sq1_adc_spi_sdio_r(c0_sq1_adc_spi_sdio_r'high-1 downto 0) & i_c0_sq1_adc_spi_sdio;
         c1_sq1_adc_spi_sdio_r<= c1_sq1_adc_spi_sdio_r(c1_sq1_adc_spi_sdio_r'high-1 downto 0) & i_c1_sq1_adc_spi_sdio;
         c2_sq1_adc_spi_sdio_r<= c2_sq1_adc_spi_sdio_r(c2_sq1_adc_spi_sdio_r'high-1 downto 0) & i_c2_sq1_adc_spi_sdio;
         c3_sq1_adc_spi_sdio_r<= c3_sq1_adc_spi_sdio_r(c3_sq1_adc_spi_sdio_r'high-1 downto 0) & i_c3_sq1_adc_spi_sdio;

      end if;

   end process P_rsync;

   o_sync_rs               <= sync_r(                sync_r'high);
   o_hk1_spi_miso_rs       <= hk1_spi_miso_r(hk1_spi_miso_r'high);
   o_hk2_spi_miso_rs       <= hk2_spi_miso_r(hk2_spi_miso_r'high);

   o_ep_spi_mosi_rs        <= ep_spi_mosi_r(ep_spi_mosi_r'high);
   o_ep_spi_sclk_rs        <= ep_spi_sclk_r(ep_spi_sclk_r'high);
   o_ep_spi_cs_n_rs        <= ep_spi_cs_n_r(ep_spi_cs_n_r'high);

   o_sq1_adc_spi_sdio_rs(0)<= c0_sq1_adc_spi_sdio_r(c0_sq1_adc_spi_sdio_r'high);
   o_sq1_adc_spi_sdio_rs(1)<= c1_sq1_adc_spi_sdio_r(c1_sq1_adc_spi_sdio_r'high);
   o_sq1_adc_spi_sdio_rs(2)<= c2_sq1_adc_spi_sdio_r(c2_sq1_adc_spi_sdio_r'high);
   o_sq1_adc_spi_sdio_rs(3)<= c3_sq1_adc_spi_sdio_r(c3_sq1_adc_spi_sdio_r'high);

end architecture rtl;
