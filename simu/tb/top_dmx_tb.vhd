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
--!   @file                   top_dmx_tb.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Top level testbench
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity top_dmx_tb is
end entity top_dmx_tb;

architecture Simulation of top_dmx_tb is
signal   arst_n               : std_logic                                                                   ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
signal   clk_ref              : std_logic                                                                   ; --! Reference Clock

signal   c0_clk_sq1_adc       : std_logic                                                                   ; --! SQUID1 ADC, col. 0 - Clock
signal   c1_clk_sq1_adc       : std_logic                                                                   ; --! SQUID1 ADC, col. 1 - Clock
signal   c2_clk_sq1_adc       : std_logic                                                                   ; --! SQUID1 ADC, col. 2 - Clock
signal   c3_clk_sq1_adc       : std_logic                                                                   ; --! SQUID1 ADC, col. 3 - Clock
signal   c0_clk_sq1_dac       : std_logic                                                                   ; --! SQUID1 DAC, col. 0 - Clock
signal   c1_clk_sq1_dac       : std_logic                                                                   ; --! SQUID1 DAC, col. 1 - Clock
signal   c2_clk_sq1_dac       : std_logic                                                                   ; --! SQUID1 DAC, col. 2 - Clock
signal   c3_clk_sq1_dac       : std_logic                                                                   ; --! SQUID1 DAC, col. 3 - Clock
signal   clk_science          : std_logic                                                                   ; --! Science Data - Clock

signal   brd_ref              : std_logic_vector(     c_BRD_REF_S-1 downto 0)                               ; --! Board reference
signal   brd_model            : std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                               ; --! Board model
signal   sync                 : std_logic                                                                   ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

signal   c0_sq1_adc_data      : std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                               ; --! SQUID1 ADC, col. 0 - Data
signal   c0_sq1_adc_oor       : std_logic                                                                   ; --! SQUID1 ADC, col. 0 - Out of range (‘0’ = No, ‘1’ = under/over range)
signal   c1_sq1_adc_data      : std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                               ; --! SQUID1 ADC, col. 1 - Data
signal   c1_sq1_adc_oor       : std_logic                                                                   ; --! SQUID1 ADC, col. 1 - Out of range (‘0’ = No, ‘1’ = under/over range)
signal   c2_sq1_adc_data      : std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                               ; --! SQUID1 ADC, col. 2 - Data
signal   c2_sq1_adc_oor       : std_logic                                                                   ; --! SQUID1 ADC, col. 2 - Out of range (‘0’ = No, ‘1’ = under/over range)
signal   c3_sq1_adc_data      : std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                               ; --! SQUID1 ADC, col. 3 - Data
signal   c3_sq1_adc_oor       : std_logic                                                                   ; --! SQUID1 ADC, col. 3 - Out of range (‘0’ = No, ‘1’ = under/over range)

signal   c0_sq1_dac_data      : std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                               ; --! SQUID1 DAC, col. 0 - Data
signal   c1_sq1_dac_data      : std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                               ; --! SQUID1 DAC, col. 1 - Data
signal   c2_sq1_dac_data      : std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                               ; --! SQUID1 DAC, col. 2 - Data
signal   c3_sq1_dac_data      : std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                               ; --! SQUID1 DAC, col. 3 - Data

signal   science_ctrl         : std_logic                                                                   ; --! Science Data – Control
signal   c0_science_data      : std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                               ; --! Science Data, col. 0 – Serial Data
signal   c1_science_data      : std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                               ; --! Science Data, col. 1 – Serial Data
signal   c2_science_data      : std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                               ; --! Science Data, col. 2 – Serial Data
signal   c3_science_data      : std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                               ; --! Science Data, col. 3 – Serial Data

signal   hk1_spi_miso         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Master Input Slave Output
signal   hk1_spi_mosi         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Master Output Slave Input
signal   hk1_spi_sclk         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   hk1_spi_cs_n         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
signal   hk1_mux	            : std_logic_vector(     c_HK1_MUX_S-1 downto 0)                               ; --! HouseKeeping 1 - Multiplexer
signal   hk1_mux_ena_n	      : std_logic                                                                   ; --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   ep_spi_mosi          : std_logic                                                                   ; --! EP - SPI Master Input Slave Output (MSB first)
signal   ep_spi_miso          : std_logic                                                                   ; --! EP - SPI Master Output Slave Input (MSB first)
signal   ep_spi_sclk          : std_logic                                                                   ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   ep_spi_cs_n          : std_logic                                                                   ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   c0_sq1_adc_spi_sdio  : std_logic                                                                   ; --! SQUID1 ADC, col. 0 - SPI Serial Data In Out
signal   c0_sq1_adc_spi_sclk  : std_logic                                                                   ; --! SQUID1 ADC, col. 0 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   c0_sq1_adc_spi_cs_n  : std_logic                                                                   ; --! SQUID1 ADC, col. 0 - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   c1_sq1_adc_spi_sdio  : std_logic                                                                   ; --! SQUID1 ADC, col. 1 - SPI Serial Data In Out
signal   c1_sq1_adc_spi_sclk  : std_logic                                                                   ; --! SQUID1 ADC, col. 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   c1_sq1_adc_spi_cs_n  : std_logic                                                                   ; --! SQUID1 ADC, col. 1 - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   c2_sq1_adc_spi_sdio  : std_logic                                                                   ; --! SQUID1 ADC, col. 2 - SPI Serial Data In Out
signal   c2_sq1_adc_spi_sclk  : std_logic                                                                   ; --! SQUID1 ADC, col. 2 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   c2_sq1_adc_spi_cs_n  : std_logic                                                                   ; --! SQUID1 ADC, col. 2 - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   c3_sq1_adc_spi_sdio  : std_logic                                                                   ; --! SQUID1 ADC, col. 3 - SPI Serial Data In Out
signal   c3_sq1_adc_spi_sclk  : std_logic                                                                   ; --! SQUID1 ADC, col. 3 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   c3_sq1_adc_spi_cs_n  : std_logic                                                                   ; --! SQUID1 ADC, col. 3 - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   c0_sq1_adc_pwdn	   : std_logic                                                                   ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
signal   c1_sq1_adc_pwdn	   : std_logic                                                                   ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
signal   c2_sq1_adc_pwdn	   : std_logic                                                                   ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
signal   c3_sq1_adc_pwdn	   : std_logic                                                                   ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)

signal   c0_sq1_dac_sleep     : std_logic                                                                   ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
signal   c1_sq1_dac_sleep     : std_logic                                                                   ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
signal   c2_sq1_dac_sleep     : std_logic                                                                   ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
signal   c3_sq1_dac_sleep     : std_logic                                                                   ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

signal   c0_sq2_dac_data      : std_logic                                                                   ; --!	SQUID2 DAC, col. 0 - Serial Data
signal   c0_sq2_dac_sclk      : std_logic                                                                   ; --!	SQUID2 DAC, col. 0 - Serial Clock
signal   c0_sq2_dac_sync_n    : std_logic                                                                   ; --!	SQUID2 DAC, col. 0 - Frame Synchronization ('0' = Active, '1' = Inactive)
signal   c0_sq2_dac_mux       : std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                               ; --!	SQUID2 DAC, col. 0 - Multiplexer
signal   c0_sq2_dac_mx_en_n   : std_logic                                                                   ; --!	SQUID2 DAC, col. 0 - Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   c1_sq2_dac_data      : std_logic                                                                   ; --!	SQUID2 DAC, col. 1 - Serial Data
signal   c1_sq2_dac_sclk      : std_logic                                                                   ; --!	SQUID2 DAC, col. 1 - Serial Clock
signal   c1_sq2_dac_sync_n    : std_logic                                                                   ; --!	SQUID2 DAC, col. 1 - Frame Synchronization ('0' = Active, '1' = Inactive)
signal   c1_sq2_dac_mux       : std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                               ; --!	SQUID2 DAC, col. 1 - Multiplexer
signal   c1_sq2_dac_mx_en_n   : std_logic                                                                   ; --!	SQUID2 DAC, col. 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   c2_sq2_dac_data      : std_logic                                                                   ; --!	SQUID2 DAC, col. 2 - Serial Data
signal   c2_sq2_dac_sclk      : std_logic                                                                   ; --!	SQUID2 DAC, col. 2 - Serial Clock
signal   c2_sq2_dac_sync_n    : std_logic                                                                   ; --!	SQUID2 DAC, col. 2 - Frame Synchronization ('0' = Active, '1' = Inactive)
signal   c2_sq2_dac_mux       : std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                               ; --!	SQUID2 DAC, col. 2 - Multiplexer
signal   c2_sq2_dac_mx_en_n   : std_logic                                                                   ; --!	SQUID2 DAC, col. 2 - Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   c3_sq2_dac_data      : std_logic                                                                   ; --!	SQUID2 DAC, col. 3 - Serial Data
signal   c3_sq2_dac_sclk      : std_logic                                                                   ; --!	SQUID2 DAC, col. 3 - Serial Clock
signal   c3_sq2_dac_sync_n    : std_logic                                                                   ; --!	SQUID2 DAC, col. 3 - Frame Synchronization ('0' = Active, '1' = Inactive)
signal   c3_sq2_dac_mux       : std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                               ; --!	SQUID2 DAC, col. 3 - Multiplexer
signal   c3_sq2_dac_mx_en_n   : std_logic                                                                   ; --!	SQUID2 DAC, col. 3 - Multiplexer Enable ('0' = Active, '1' = Inactive)

alias    d_rst                : std_logic is <<signal .top_dmx_tb.I_top_dmx.rst              : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
alias    d_clk                : std_logic is <<signal .top_dmx_tb.I_top_dmx.clk              : std_logic>>  ; --! Internal design: System Clock
alias    d_clk_sq1_adc        : std_logic is <<signal .top_dmx_tb.I_top_dmx.clk_sq1_adc      : std_logic>>  ; --! Internal design: SQUID1 ADC Clock (MSB SQUID1 ADC Clocks vector)
alias    d_clk_sq1_pls_shape  : std_logic is <<signal .top_dmx_tb.I_top_dmx.clk_sq1_pls_shape: std_logic>>  ; --! Internal design: SQUID1 pulse shaping Clock

signal   ep_cmd               : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP - Command to send
signal   ep_cmd_start         : std_logic                                                                   ; --! EP - Start command transmit (one system clock pulse)
signal   ep_cmd_busy_n        : std_logic                                                                   ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
signal   ep_cmd_ser_wd_s      : std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)                      ; --! EP - Serial word size

signal   ep_data_rx           : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP - Receipted data
signal   ep_data_rx_rdy       : std_logic                                                                   ; --! EP - Receipted data ready ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX - Top level
   -- ------------------------------------------------------------------------------------------------------
   I_top_dmx: entity work.top_dmx port map
   (     i_arst_n             => arst_n               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => clk_ref              , -- in     std_logic                                 ; --! Reference Clock

         o_c0_clk_sq1_adc     => c0_clk_sq1_adc       , -- out    std_logic                                 ; --! SQUID1 ADC, col. 0 - Clock
         o_c1_clk_sq1_adc     => c1_clk_sq1_adc       , -- out    std_logic                                 ; --! SQUID1 ADC, col. 1 - Clock
         o_c2_clk_sq1_adc     => c2_clk_sq1_adc       , -- out    std_logic                                 ; --! SQUID1 ADC, col. 2 - Clock
         o_c3_clk_sq1_adc     => c3_clk_sq1_adc       , -- out    std_logic                                 ; --! SQUID1 ADC, col. 3 - Clock
         o_c0_clk_sq1_dac     => c0_clk_sq1_dac       , -- out    std_logic                                 ; --! SQUID1 DAC, col. 0 - Clock
         o_c1_clk_sq1_dac     => c1_clk_sq1_dac       , -- out    std_logic                                 ; --! SQUID1 DAC, col. 1 - Clock
         o_c2_clk_sq1_dac     => c2_clk_sq1_dac       , -- out    std_logic                                 ; --! SQUID1 DAC, col. 2 - Clock
         o_c3_clk_sq1_dac     => c3_clk_sq1_dac       , -- out    std_logic                                 ; --! SQUID1 DAC, col. 3 - Clock
         o_clk_science        => clk_science          , -- out    std_logic                                 ; --! Science Data - Clock

         i_brd_ref            => brd_ref              , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         i_brd_model          => brd_model            , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_c0_sq1_adc_data    => c0_sq1_adc_data      , -- in     slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC, col. 0 - Data
         i_c0_sq1_adc_oor     => c0_sq1_adc_oor       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 0 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c1_sq1_adc_data    => c1_sq1_adc_data      , -- in     slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC, col. 1 - Data
         i_c1_sq1_adc_oor     => c1_sq1_adc_oor       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 1 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c2_sq1_adc_data    => c2_sq1_adc_data      , -- in     slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC, col. 2 - Data
         i_c2_sq1_adc_oor     => c2_sq1_adc_oor       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 2 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c3_sq1_adc_data    => c3_sq1_adc_data      , -- in     slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC, col. 3 - Data
         i_c3_sq1_adc_oor     => c3_sq1_adc_oor       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 3 - Out of range (‘0’ = No, ‘1’ = under/over range)

         o_c0_sq1_dac_data    => c0_sq1_dac_data      , -- out    slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 0 - Data
         o_c1_sq1_dac_data    => c1_sq1_dac_data      , -- out    slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 1 - Data
         o_c2_sq1_dac_data    => c2_sq1_dac_data      , -- out    slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 2 - Data
         o_c3_sq1_dac_data    => c3_sq1_dac_data      , -- out    slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 3 - Data

         o_science_ctrl       => science_ctrl         , -- out    std_logic                                 ; --! Science Data – Control
         o_c0_science_data    => c0_science_data      , -- out    slv(c_SCIENCE_DATA_S-1 downto 0)          ; --! Science Data, col. 0 – Serial Data
         o_c1_science_data    => c1_science_data      , -- out    slv(c_SCIENCE_DATA_S-1 downto 0)          ; --! Science Data, col. 1 – Serial Data
         o_c2_science_data    => c2_science_data      , -- out    slv(c_SCIENCE_DATA_S-1 downto 0)          ; --! Science Data, col. 2 – Serial Data
         o_c3_science_data    => c3_science_data      , -- out    slv(c_SCIENCE_DATA_S-1 downto 0)          ; --! Science Data, col. 3 – Serial Data

         i_hk1_spi_miso       => hk1_spi_miso         , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Master Input Slave Output
         o_hk1_spi_mosi       => hk1_spi_mosi         , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Master Output Slave Input
         o_hk1_spi_sclk       => hk1_spi_sclk         , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_hk1_spi_cs_n       => hk1_spi_cs_n         , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux	         => hk1_mux              , -- out    std_logic_vector(c_HK1_MUX_S-1 downto 0)  ; --! HouseKeeping 1 - Multiplexer
         o_hk1_mux_ena_n	   => hk1_mux_ena_n        , -- out    std_logic                                 ; --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        => ep_spi_mosi          , -- in     std_logic                                 ; --! EP - SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        => ep_spi_miso          , -- out    std_logic                                 ; --! EP - SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        => ep_spi_sclk          , -- in     std_logic                                 ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_ep_spi_cs_n        => ep_spi_cs_n          , -- in     std_logic                                 ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c0_sq1_adc_spi_sdio=> c0_sq1_adc_spi_sdio  , -- inout  std_logic                                 ; --! SQUID1 ADC, col. 0 - SPI Serial Data In Out
         o_c0_sq1_adc_spi_sclk=> c0_sq1_adc_spi_sclk  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 0 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c0_sq1_adc_spi_cs_n=> c0_sq1_adc_spi_cs_n  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 0 - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c1_sq1_adc_spi_sdio=> c1_sq1_adc_spi_sdio  , -- inout  std_logic                                 ; --! SQUID1 ADC, col. 1 - SPI Serial Data In Out
         o_c1_sq1_adc_spi_sclk=> c1_sq1_adc_spi_sclk  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c1_sq1_adc_spi_cs_n=> c1_sq1_adc_spi_cs_n  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 1 - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c2_sq1_adc_spi_sdio=> c2_sq1_adc_spi_sdio  , -- inout  std_logic                                 ; --! SQUID1 ADC, col. 2 - SPI Serial Data In Out
         o_c2_sq1_adc_spi_sclk=> c2_sq1_adc_spi_sclk  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 2 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c2_sq1_adc_spi_cs_n=> c2_sq1_adc_spi_cs_n  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 2 - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c3_sq1_adc_spi_sdio=> c3_sq1_adc_spi_sdio  , -- inout  std_logic                                 ; --! SQUID1 ADC, col. 3 - SPI Serial Data In Out
         o_c3_sq1_adc_spi_sclk=> c3_sq1_adc_spi_sclk  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 3 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c3_sq1_adc_spi_cs_n=> c3_sq1_adc_spi_cs_n  , -- out    std_logic                                 ; --! SQUID1 ADC, col. 3 - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_c0_sq1_adc_pwdn	   => c0_sq1_adc_pwdn      , -- out    std_logic                                 ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         o_c1_sq1_adc_pwdn	   => c1_sq1_adc_pwdn      , -- out    std_logic                                 ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         o_c2_sq1_adc_pwdn	   => c2_sq1_adc_pwdn      , -- out    std_logic                                 ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         o_c3_sq1_adc_pwdn	   => c3_sq1_adc_pwdn      , -- out    std_logic                                 ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)

         o_c0_sq1_dac_sleep   => c0_sq1_dac_sleep     , -- out    std_logic                                 ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         o_c1_sq1_dac_sleep   => c1_sq1_dac_sleep     , -- out    std_logic                                 ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         o_c2_sq1_dac_sleep   => c2_sq1_dac_sleep     , -- out    std_logic                                 ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         o_c3_sq1_dac_sleep   => c3_sq1_dac_sleep     , -- out    std_logic                                 ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         o_c0_sq2_dac_data    => c0_sq2_dac_data      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 0 - Serial Data
         o_c0_sq2_dac_sclk    => c0_sq2_dac_sclk      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 0 - Serial Clock
         o_c0_sq2_dac_sync_n  => c0_sq2_dac_sync_n    , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 0 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c0_sq2_dac_mux     => c0_sq2_dac_mux       , -- out    slv(c_SQ2_DAC_MUX_S-1 downto 0)           ; --!	SQUID2 DAC, col. 0 - Multiplexer
         o_c0_sq2_dac_mx_en_n => c0_sq2_dac_mx_en_n   , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 0 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_c1_sq2_dac_data    => c1_sq2_dac_data      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 1 - Serial Data
         o_c1_sq2_dac_sclk    => c1_sq2_dac_sclk      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 1 - Serial Clock
         o_c1_sq2_dac_sync_n  => c1_sq2_dac_sync_n    , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 1 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c1_sq2_dac_mux     => c1_sq2_dac_mux       , -- out    slv(c_SQ2_DAC_MUX_S-1 downto 0)           ; --!	SQUID2 DAC, col. 1 - Multiplexer
         o_c1_sq2_dac_mx_en_n => c1_sq2_dac_mx_en_n   , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_c2_sq2_dac_data    => c2_sq2_dac_data      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 2 - Serial Data
         o_c2_sq2_dac_sclk    => c2_sq2_dac_sclk      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 2 - Serial Clock
         o_c2_sq2_dac_sync_n  => c2_sq2_dac_sync_n    , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 2 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c2_sq2_dac_mux     => c2_sq2_dac_mux       , -- out    slv(c_SQ2_DAC_MUX_S-1 downto 0)           ; --!	SQUID2 DAC, col. 2 - Multiplexer
         o_c2_sq2_dac_mx_en_n => c2_sq2_dac_mx_en_n   , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 2 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_c3_sq2_dac_data    => c3_sq2_dac_data      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 3 - Serial Data
         o_c3_sq2_dac_sclk    => c3_sq2_dac_sclk      , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 3 - Serial Clock
         o_c3_sq2_dac_sync_n  => c3_sq2_dac_sync_n    , -- out    std_logic                                 ; --!	SQUID2 DAC, col. 3 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c3_sq2_dac_mux     => c3_sq2_dac_mux       , -- out    slv(c_SQ2_DAC_MUX_S-1 downto 0)           ; --!	SQUID2 DAC, col. 3 - Multiplexer
         o_c3_sq2_dac_mx_en_n => c3_sq2_dac_mx_en_n     -- out    std_logic                                   --!	SQUID2 DAC, col. 3 - Multiplexer Enable ('0' = Active, '1' = Inactive)

   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock reference generation
   -- ------------------------------------------------------------------------------------------------------
   I_clock_model: clock_model port map
   (     o_clk_ref            => clk_ref              , -- in     std_logic                                 ; --! Reference Clock
         o_sync               => sync                   -- in     std_logic                                   --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP SPI model
   -- ------------------------------------------------------------------------------------------------------
   I_ep_spi_model: ep_spi_model port map
   (     i_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- in     slv(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0) ; --! EP - Serial word size
         i_ep_cmd_start       => ep_cmd_start         , -- in     std_logic                                 ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd             => ep_cmd               , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP - Command to send
         o_ep_cmd_busy_n      => ep_cmd_busy_n        , -- out    std_logic                                 ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)

         o_ep_data_rx         => ep_data_rx           , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP - Receipted data
         o_ep_data_rx_rdy     => ep_data_rx_rdy       , -- out    std_logic                                 ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)

         o_ep_spi_mosi        => ep_spi_mosi          , -- out    std_logic                                 ; --! EP - SPI Master Input Slave Output (MSB first)
         i_ep_spi_miso        => ep_spi_miso          , -- in     std_logic                                 ; --! EP - SPI Master Output Slave Input (MSB first)
         o_ep_spi_sclk        => ep_spi_sclk          , -- out    std_logic                                 ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_ep_spi_cs_n        => ep_spi_cs_n            -- out    std_logic                                   --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser
   -- ------------------------------------------------------------------------------------------------------
   I_parser: parser port map
   (     o_arst_n             => arst_n               , -- out    std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => clk_ref              , -- in     std_logic                                 ; --! Reference Clock
         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_c0_sq1_dac_data    => c0_sq1_dac_data      , -- in     slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 0 - Data
         i_c1_sq1_dac_data    => c1_sq1_dac_data      , -- in     slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 1 - Data
         i_c2_sq1_dac_data    => c2_sq1_dac_data      , -- in     slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 2 - Data
         i_c3_sq1_dac_data    => c3_sq1_dac_data      , -- in     slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC, col. 3 - Data

         i_c0_sq1_dac_sleep   => c0_sq1_dac_sleep     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   => c1_sq1_dac_sleep     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   => c2_sq1_dac_sleep     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   => c3_sq1_dac_sleep     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_clk              => d_clk                , -- in     std_logic                                 ; --! Internal design: System Clock
         i_d_clk_sq1_adc      => d_clk_sq1_adc        , -- in     std_logic                                 ; --! Internal design: SQUID1 ADC Clock (MSB SQUID1 ADC Clocks vector)
         i_d_clk_sq1_pls_shap => d_clk_sq1_pls_shape  , -- in     std_logic                                 ; --! Internal design: SQUID1 pulse shaping Clock

         i_ep_data_rx         => ep_data_rx           , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP - Receipted data
         i_ep_data_rx_rdy     => ep_data_rx_rdy       , -- in     std_logic                                 ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             => ep_cmd               , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP - Command to send
         o_ep_cmd_start       => ep_cmd_start         , -- out    std_logic                                 ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      => ep_cmd_busy_n        , -- in     std_logic                                 ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- out    slv(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0) ; --! EP - Serial word size

         o_brd_ref            => brd_ref              , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         o_brd_model          => brd_model              -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0)  --! Board model
   );

end simulation;
