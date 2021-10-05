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
--!   @file                   top_dmx.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Top level
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity top_dmx is port
   (     i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         o_c0_clk_sq1_adc     : out    std_logic                                                            ; --! SQUID1 ADC, col. 0 - Clock
         o_c1_clk_sq1_adc     : out    std_logic                                                            ; --! SQUID1 ADC, col. 1 - Clock
         o_c2_clk_sq1_adc     : out    std_logic                                                            ; --! SQUID1 ADC, col. 2 - Clock
         o_c3_clk_sq1_adc     : out    std_logic                                                            ; --! SQUID1 ADC, col. 3 - Clock
         o_c0_clk_sq1_dac     : out    std_logic                                                            ; --! SQUID1 DAC, col. 0 - Clock
         o_c1_clk_sq1_dac     : out    std_logic                                                            ; --! SQUID1 DAC, col. 1 - Clock
         o_c2_clk_sq1_dac     : out    std_logic                                                            ; --! SQUID1 DAC, col. 2 - Clock
         o_c3_clk_sq1_dac     : out    std_logic                                                            ; --! SQUID1 DAC, col. 3 - Clock
         o_clk_science_01     : out    std_logic                                                            ; --! Science Data - Clock channel 0/1
         o_clk_science_23     : out    std_logic                                                            ; --! Science Data - Clock channel 2/3

         i_brd_ref            : in     std_logic_vector(     c_BRD_REF_S-1 downto 0)                        ; --! Board reference
         i_brd_model          : in     std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                        ; --! Board model
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_c0_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 0 - Data
         i_c0_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c1_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 1 - Data
         i_c1_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c2_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 2 - Data
         i_c2_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c3_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 3 - Data
         i_c3_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 - Out of range (‘0’ = No, ‘1’ = under/over range)

         o_c0_sq1_dac_data    : out    std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 0 - Data
         o_c1_sq1_dac_data    : out    std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 1 - Data
         o_c2_sq1_dac_data    : out    std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 2 - Data
         o_c3_sq1_dac_data    : out    std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 3 - Data

         o_science_ctrl_01    : out    std_logic                                                            ; --! Science Data – Control channel 0/1
         o_science_ctrl_23    : out    std_logic                                                            ; --! Science Data – Control channel 2/3
         o_c0_science_data    : out    std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 0 – Serial Data
         o_c1_science_data    : out    std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 1 – Serial Data
         o_c2_science_data    : out    std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 2 – Serial Data
         o_c3_science_data    : out    std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 3 – Serial Data

         i_hk1_spi_miso       : in     std_logic                                                            ; --! HouseKeeping 1 - SPI Master Input Slave Output
         o_hk1_spi_mosi       : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Master Output Slave Input
         o_hk1_spi_sclk       : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_hk1_spi_cs_n       : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux            : out    std_logic_vector(      c_HK_MUX_S-1 downto 0)                        ; --! HouseKeeping 1 - Multiplexer
         o_hk1_mux_ena_n      : out    std_logic                                                            ; --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        : in     std_logic                                                            ; --! EP - SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        : out    std_logic                                                            ; --! EP - SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        : in     std_logic                                                            ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_ep_spi_cs_n        : in     std_logic                                                            ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c0_sq1_adc_spi_sdio: out    std_logic                                                            ; --! SQUID1 ADC, col. 0 - SPI Serial Data In Out
         o_c0_sq1_adc_spi_sclk: out    std_logic                                                            ; --! SQUID1 ADC, col. 0 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c0_sq1_adc_spi_cs_n: out    std_logic                                                            ; --! SQUID1 ADC, col. 0 - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c1_sq1_adc_spi_sdio: out    std_logic                                                            ; --! SQUID1 ADC, col. 1 - SPI Serial Data In Out
         o_c1_sq1_adc_spi_sclk: out    std_logic                                                            ; --! SQUID1 ADC, col. 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c1_sq1_adc_spi_cs_n: out    std_logic                                                            ; --! SQUID1 ADC, col. 1 - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c2_sq1_adc_spi_sdio: out    std_logic                                                            ; --! SQUID1 ADC, col. 2 - SPI Serial Data In Out
         o_c2_sq1_adc_spi_sclk: out    std_logic                                                            ; --! SQUID1 ADC, col. 2 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c2_sq1_adc_spi_cs_n: out    std_logic                                                            ; --! SQUID1 ADC, col. 2 - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_c3_sq1_adc_spi_sdio: out    std_logic                                                            ; --! SQUID1 ADC, col. 3 - SPI Serial Data In Out
         o_c3_sq1_adc_spi_sclk: out    std_logic                                                            ; --! SQUID1 ADC, col. 3 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_c3_sq1_adc_spi_cs_n: out    std_logic                                                            ; --! SQUID1 ADC, col. 3 - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_c0_sq1_adc_pwdn    : out    std_logic                                                            ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         o_c1_sq1_adc_pwdn    : out    std_logic                                                            ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         o_c2_sq1_adc_pwdn    : out    std_logic                                                            ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         o_c3_sq1_adc_pwdn    : out    std_logic                                                            ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)

         o_c0_sq1_dac_sleep   : out    std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         o_c1_sq1_dac_sleep   : out    std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         o_c2_sq1_dac_sleep   : out    std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         o_c3_sq1_dac_sleep   : out    std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         o_c0_sq2_dac_data    : out    std_logic                                                            ; --! SQUID2 DAC, col. 0 - Serial Data
         o_c0_sq2_dac_sclk    : out    std_logic                                                            ; --! SQUID2 DAC, col. 0 - Serial Clock
         o_c0_sq2_dac_sync_n  : out    std_logic                                                            ; --! SQUID2 DAC, col. 0 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c0_sq2_dac_mux     : out    std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC, col. 0 - Multiplexer
         o_c0_sq2_dac_mx_en_n : out    std_logic                                                            ; --! SQUID2 DAC, col. 0 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_c1_sq2_dac_data    : out    std_logic                                                            ; --! SQUID2 DAC, col. 1 - Serial Data
         o_c1_sq2_dac_sclk    : out    std_logic                                                            ; --! SQUID2 DAC, col. 1 - Serial Clock
         o_c1_sq2_dac_sync_n  : out    std_logic                                                            ; --! SQUID2 DAC, col. 1 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c1_sq2_dac_mux     : out    std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC, col. 1 - Multiplexer
         o_c1_sq2_dac_mx_en_n : out    std_logic                                                            ; --! SQUID2 DAC, col. 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_c2_sq2_dac_data    : out    std_logic                                                            ; --! SQUID2 DAC, col. 2 - Serial Data
         o_c2_sq2_dac_sclk    : out    std_logic                                                            ; --! SQUID2 DAC, col. 2 - Serial Clock
         o_c2_sq2_dac_sync_n  : out    std_logic                                                            ; --! SQUID2 DAC, col. 2 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c2_sq2_dac_mux     : out    std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC, col. 2 - Multiplexer
         o_c2_sq2_dac_mx_en_n : out    std_logic                                                            ; --! SQUID2 DAC, col. 2 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_c3_sq2_dac_data    : out    std_logic                                                            ; --! SQUID2 DAC, col. 3 - Serial Data
         o_c3_sq2_dac_sclk    : out    std_logic                                                            ; --! SQUID2 DAC, col. 3 - Serial Clock
         o_c3_sq2_dac_sync_n  : out    std_logic                                                            ; --! SQUID2 DAC, col. 3 - Frame Synchronization ('0' = Active, '1' = Inactive)
         o_c3_sq2_dac_mux     : out    std_logic_vector( c_SQ2_DAC_MUX_S-1 downto 0)                        ; --! SQUID2 DAC, col. 3 - Multiplexer
         o_c3_sq2_dac_mx_en_n : out    std_logic                                                              --! SQUID2 DAC, col. 3 - Multiplexer Enable ('0' = Active, '1' = Inactive)

   );
end entity top_dmx;

architecture RTL of top_dmx is
type     t_sq1_dac_data_v      is array (natural range <>) of std_logic_vector(c_SQ1_DAC_DATA_S-1  downto 0); --! SQUID1 DAC data vector type
type     t_sq2_dac_mux_v       is array (natural range <>) of std_logic_vector(c_SQ2_DAC_MUX_S -1  downto 0); --! SQUID2 DAC multiplexer vector type

signal   ck_rdy               : std_logic                                                                   ; --! Clocks ready ('0' = Not ready, '1' = Ready)
signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   sync_re              : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge

signal   clk                  : std_logic                                                                   ; --! System Clock
signal   clk_sq1_adc_acq      : std_logic                                                                   ; --! SQUID1 ADC acquisition Clock
signal   clk_sq1_adc_v        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC Clocks vector
signal   clk_sq1_dac_v        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC Clocks
signal   clk_sq1_pls_shape    : std_logic                                                                   ; --! SQUID1 pulse shaping Clock

signal   brd_ref_rs           : std_logic_vector(  c_BRD_REF_S-1 downto 0)                                  ; --! Board reference, synchronized on System Clock
signal   brd_model_rs         : std_logic_vector(c_BRD_MODEL_S-1 downto 0)                                  ; --! Board model, synchronized on System Clock
signal   sync_rs              : std_logic                                                                   ; --! Pixel sequence synchronization, synchronized on System Clock
signal   hk1_spi_miso_rs      : std_logic                                                                   ; --! HouseKeeping 1 - SPI Master Input Slave Output, synchronized on System Clock
signal   hk2_spi_miso_rs      : std_logic                                                                   ; --! HouseKeeping 2 - SPI Master Input Slave Output, synchronized on System Clock
signal   ep_spi_mosi_rs       : std_logic                                                                   ; --! EP - SPI Master Input Slave Output (MSB first), synchronized on System Clock
signal   ep_spi_sclk_rs       : std_logic                                                                   ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’), synchronized on System Clock
signal   ep_spi_cs_n_rs       : std_logic                                                                   ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock

signal   cmd_ck_sq1_adc       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC Clocks switch commands
signal   cmd_ck_sq1_dac       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC Clocks switch commands
signal   sq1_adc_pwdn         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
signal   sq1_dac_sleep        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)

signal   sq1_adc_data         : t_sq1_adc_data_v(0 to c_NB_COL-1)                                           ; --! SQUID1 ADC - Data, no rsync
signal   sq1_adc_oor          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Out of range, no rsync (‘0’= No, ‘1’= under/over range)

signal   sq1_data_err         : t_sq1_data_err_v(0 to c_NB_COL-1)                                           ; --! SQUID1 Data error
signal   sq1_data_fbk         : t_sq1_data_fbk_v(0 to c_NB_COL-1)                                           ; --! SQUID1 Data feedback

signal   sq1_dac_data         : t_sq1_dac_data_v(0 to c_NB_COL-1)                                           ; --! SQUID1 DAC - Data
signal   sq2_dac_mux          : t_sq2_dac_mux_v( 0 to c_NB_COL-1)                                           ; --! SQUID2 DAC - Multiplexer

signal   sq1_adc_spi_mosi     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - SPI  Master Output Slave Input
signal   sq1_adc_spi_sclk     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   sq1_adc_spi_cs_n     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   sq2_dac_data         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC - Serial Data
signal   sq2_dac_sclk         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC - Serial Clock
signal   sq2_dac_sync_n       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC - Frame Synchronization ('0' = Active, '1' = Inactive)

signal   clk_science          : std_logic                                                                   ; --! Science Data - Clock channel
signal   science_ctrl         : std_logic                                                                   ; --! Science Data – Control channel
signal   science_data_tx_ena  : std_logic                                                                   ; --! Science Data transmit enable
signal   science_data         : t_sc_data_w(0 to c_NB_COL*c_SC_DATA_SER_NB)                                 ; --! Science Data word
signal   science_data_ser     : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                        ; --! Science Data – Serial Data

signal   ep_cmd_sts_err_nin   : std_logic                                                                   ; --! EP command: Status, error parameter to read not initialized yet
signal   ep_cmd_sts_err_dis   : std_logic                                                                   ; --! EP command: Status, error last SPI command discarded
signal   ep_cmd_sts_rg        : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: status register

signal   ep_cmd_rx_wd_add     : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared
signal   ep_cmd_rx_wd_data    : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word
signal   ep_cmd_rx_rw         : std_logic                                                                   ; --! EP command receipted: read/write bit
signal   ep_cmd_rx_nerr_rdy   : std_logic                                                                   ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

signal   ep_cmd_tx_wd_rd_rg   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command to transmit: read register word

signal   tm_mode_sync         : std_logic                                                                   ; --! Telemetry mode synchronization

signal   tm_mode              : t_rg_tm_mode(0 to c_NB_COL-1)                                               ; --! Telemetry mode
signal   sq1_fb_mode          : t_rg_sq1fbmd(0 to c_NB_COL-1)                                               ; --! Squid 1 Feedback mode
signal   sq2_fb_mode          : t_rg_sq2fbmd(0 to c_NB_COL-1)                                               ; --! Squid 2 Feedback mode

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Manage the internal reset and generate the clocks
   -- ------------------------------------------------------------------------------------------------------
   I_rst_clk_mgt: entity work.rst_clk_mgt port map
   (     i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock

         i_cmd_ck_sq1_adc     => cmd_ck_sq1_adc       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks switch commands (for each column: '0' = Inactive, '1' = Active)
         i_cmd_ck_sq1_dac     => cmd_ck_sq1_dac       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Clocks switch commands (for each column: '0' = Inactive, '1' = Active)

         o_ck_rdy             => ck_rdy               , -- out    std_logic                                 ; --! Clocks ready ('0' = Not ready, '1' = Ready)
         o_rst                => rst                  , -- out    std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)

         o_clk                => clk                  , -- out    std_logic                                 ; --! System Clock
         o_clk_sq1_adc_acq    => clk_sq1_adc_acq      , -- out    std_logic                                 ; --! SQUID1 ADC acquisition Clock
         o_clk_sq1_pls_shape  => clk_sq1_pls_shape    , -- out    std_logic                                 ; --! SQUID1 pulse shaping Clock
         o_clk_sq1_adc        => clk_sq1_adc_v        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks
         o_clk_sq1_dac        => clk_sq1_dac_v        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Clocks
         o_clk_science        => clk_science          , -- out    std_logic                                   --! Science Data Clock

         o_sq1_adc_pwdn       => sq1_adc_pwdn         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
         o_sq1_dac_sleep      => sq1_dac_sleep          -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Data resynchronization on System Clock
   -- ------------------------------------------------------------------------------------------------------
   I_in_rs_clk: entity work.in_rs_clk port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_brd_ref            => i_brd_ref            , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         i_brd_model          => i_brd_model          , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         i_sync               => i_sync               , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_hk1_spi_miso       => i_hk1_spi_miso       , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Master Input Slave Output

         i_ep_spi_mosi        => i_ep_spi_mosi        , -- in     std_logic                                 ; --! EP - SPI Master Input Slave Output (MSB first)
         i_ep_spi_sclk        => i_ep_spi_sclk        , -- in     std_logic                                 ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_ep_spi_cs_n        => i_ep_spi_cs_n        , -- in     std_logic                                 ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_brd_ref_rs         => brd_ref_rs           , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference, synchronized on System Clock
         o_brd_model_rs       => brd_model_rs         , -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model, synchronized on System Clock
         o_sync_rs            => sync_rs              , -- out    std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock

         o_hk1_spi_miso_rs    => hk1_spi_miso_rs      , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Master Input Slave Output, synchronized on System Clock

         o_ep_spi_mosi_rs     => ep_spi_mosi_rs       , -- out    std_logic                                 ; --! EP - SPI Master Input Slave Output (MSB first), synchronized on System Clock
         o_ep_spi_sclk_rs     => ep_spi_sclk_rs       , -- out    std_logic                                 ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’), synchronized on System Clock
         o_ep_spi_cs_n_rs     => ep_spi_cs_n_rs         -- out    std_logic                                   --! EP - SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Transmit
   --    @Req : DRE-DMX-FW-REQ-0590
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_tx: entity work.science_data_tx port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_science_data_tx_ena=> science_data_tx_ena  , -- in     std_logic                                 ; --! Science Data transmit enable
         i_science_data       => science_data         , -- in     t_sc_data_w c_NB_COL*c_SC_DATA_SER_NB     ; --! Science Data word
         o_science_data_ser   => science_data_ser       -- out    slv         c_NB_COL*c_SC_DATA_SER_NB       --! Science Data – Serial Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Registers management
   -- ------------------------------------------------------------------------------------------------------
   I_register_mgt: entity work.register_mgt port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_tm_mode_sync       => tm_mode_sync         , -- in     std_logic                                 ; --! Telemetry mode synchronization

         i_brd_ref_rs         => brd_ref_rs           , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference, synchronized on System Clock
         i_brd_model_rs       => brd_model_rs         , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model, synchronized on System Clock

         o_ep_cmd_sts_err_nin => ep_cmd_sts_err_nin   , -- out    std_logic                                 ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis => ep_cmd_sts_err_dis   , -- out    std_logic                                 ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      => ep_cmd_sts_rg        , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command: Status register

         i_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add     , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy   , -- in     std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg => ep_cmd_tx_wd_rd_rg   , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command to transmit: read register word

         o_tm_mode            => tm_mode              , -- out    t_rg_tm_mode(0 to c_NB_COL-1)             ; --! Telemetry mode
         o_sq1_fb_mode        => sq1_fb_mode          , -- out    t_rg_sq1fbmd(0 to c_NB_COL-1)             ; --! Squid 1 Feedback mode
         o_sq2_fb_mode        => sq2_fb_mode            -- out    t_rg_sq2fbmd(0 to c_NB_COL-1)               --! Squid 2 Feedback mode
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command
   -- ------------------------------------------------------------------------------------------------------
   I_ep_cmd: entity work.ep_cmd port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_sts_err_nin => ep_cmd_sts_err_nin   , -- in     std_logic                                 ; --! EP command: Status, error parameter to read not initialized yet
         i_ep_cmd_sts_err_dis => ep_cmd_sts_err_dis   , -- in     std_logic                                 ; --! EP command: Status, error last SPI command discarded
         o_ep_cmd_sts_rg      => ep_cmd_sts_rg        , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command: Status register

         o_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add     , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         o_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         o_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- out    std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy   , -- out    std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         i_ep_cmd_tx_wd_rd_rg => ep_cmd_tx_wd_rd_rg   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command to transmit: read register word

         o_ep_spi_miso        => o_ep_spi_miso        , -- out    std_logic                                 ; --! EP - SPI Master Output Slave Input (MSB first)
         i_ep_spi_mosi_rs     => ep_spi_mosi_rs       , -- in     std_logic                                 ; --! EP - SPI Master Input Slave Output (MSB first), synchronized on System Clock
         i_ep_spi_sclk_rs     => ep_spi_sclk_rs       , -- in     std_logic                                 ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’), synchronized on System Clock
         i_ep_spi_cs_n_rs     => ep_spi_cs_n_rs         -- in     std_logic                                   --! EP - SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX commands
   -- ------------------------------------------------------------------------------------------------------
   I_dmx_cmd: entity work.dmx_cmd port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_sync_rs            => sync_rs              , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_tm_mode            => tm_mode              , -- in     t_rg_tm_mode(0 to c_NB_COL-1)             ; --! Telemetry mode
         i_sq1_fb_mode        => sq1_fb_mode          , -- in     t_rg_sq1fbmd(0 to c_NB_COL-1)             ; --! Squid 1 Feedback mode
         i_sq2_fb_mode        => sq2_fb_mode          , -- in     t_rg_sq2fbmd(0 to c_NB_COL-1)             ; --! Squid 2 Feedback mode
         o_sync_re            => sync_re              , -- out    std_logic                                 ; --! Pixel sequence synchronization, rising edge
         o_tm_mode_sync       => tm_mode_sync         , -- out    std_logic                                 ; --! Telemetry mode synchronization
         o_cmd_ck_sq1_adc     => cmd_ck_sq1_adc       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks switch commands, synchronized on SQUID1 ADC Clock
         o_cmd_ck_sq1_dac     => cmd_ck_sq1_dac         -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID1 DAC Clocks switch commands, synchronized on pulse shaping Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Housekeeping management
   -- ------------------------------------------------------------------------------------------------------
   I_hk_mgt: entity work.hk_mgt port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_hk1_spi_miso_rs    => hk1_spi_miso_rs      , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Master Input Slave Output
         o_hk1_spi_mosi       => o_hk1_spi_mosi       , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Master Output Slave Input
         o_hk1_spi_sclk       => o_hk1_spi_sclk       , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_hk1_spi_cs_n       => o_hk1_spi_cs_n       , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux            => o_hk1_mux            , -- out    std_logic_vector( cc_HK_MUX_S-1 downto 0) ; --! HouseKeeping 1 - Multiplexer
         o_hk1_mux_ena_n      => o_hk1_mux_ena_n        -- out    std_logic                                   --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Columns management
   --    @Req : DRE-DMX-FW-REQ-0070
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      I_squid_adc_mgt: entity work.squid_adc_mgt port map
      (  i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             => ck_rdy               , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_adc_acq    => clk_sq1_adc_acq      , -- in     std_logic                                 ; --! SQUID1 ADC acquisitionClock

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => sync_rs              , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sq1_adc_data       => sq1_adc_data(k)      , -- in     slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC - Data, no rsync
         i_sq1_adc_oor        => sq1_adc_oor(k)       , -- in     std_logic                                 ; --! SQUID1 ADC - Out of range, no rsync (‘0’= No, ‘1’= under/over range)

         o_sq1_data_err       => sq1_data_err(k)        -- out    slv(c_SQ1_DATA_ERR_S-1 downto 0)          ; --! SQUID1 Data error
      );

      I_squid_data_proc: entity work.squid_data_proc port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sq1_data_err       => sq1_data_err(k)      , -- in     slv(c_SQ1_DATA_ERR_S-1 downto 0)          ; --! SQUID1 Data error
         o_sq1_data_fbk       => sq1_data_fbk(k)        -- out    slv(c_SQ1_DATA_FBK_S-1 downto 0)            --! SQUID1 Data feedback
      );

      I_squid1_dac_mgt: entity work.squid1_dac_mgt port map
      (  i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             => ck_rdy               , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_pls_shape  => clk_sq1_pls_shape    , -- in     std_logic                                 ; --! SQUID1 pulse shaping Clock

         i_sync_rs            => sync_rs              , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sq1_data_fbk       => sq1_data_fbk(k)      , -- out    slv(c_SQ1_DATA_FBK_S-1 downto 0)          ; --! SQUID1 Data feedback

         o_sq1_dac_data       => sq1_dac_data(k)        -- out    slv(c_SQ1_DAC_DATA_S-1 downto 0)            --! SQUID1 DAC - Data
      );

      I_squid2_dac_mgt: entity work.squid2_dac_mgt port map
      (  i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             => ck_rdy               , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_pls_shape  => clk_sq1_pls_shape    , -- in     std_logic                                 ; --! SQUID1 pulse shaping Clock

         i_sync_rs            => sync_rs              , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock

         o_sq2_dac_mux        => sq2_dac_mux(k)         -- out    slv(c_SQ2_DAC_MUX_S -1 downto 0)          ; --! SQUID2 DAC - Multiplexer
      );

      I_squid_spi_mgt: entity work.squid_spi_mgt port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         o_sq1_adc_spi_mosi   => sq1_adc_spi_mosi(k)  , -- out    std_logic                                 ; --! SQUID1 ADC - SPI Serial Data In Out
         o_sq1_adc_spi_sclk   => sq1_adc_spi_sclk(k)  , -- out    std_logic                                 ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_sq1_adc_spi_cs_n   => sq1_adc_spi_cs_n(k)  , -- out    std_logic                                 ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sq2_dac_data       => sq2_dac_data(k)      , -- out    std_logic                                 ; --! SQUID2 DAC - Serial Data
         o_sq2_dac_sclk       => sq2_dac_sclk(k)      , -- out    std_logic                                 ; --! SQUID2 DAC - Serial Clock
         o_sq2_dac_sync_n     => sq2_dac_sync_n(k)      -- out    std_logic                                   --! SQUID2 DAC - Frame Synchronization ('0' = Active, '1' = Inactive)
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID1 ADC I/O association
   -- ------------------------------------------------------------------------------------------------------
   sq1_adc_data(0)      <= i_c0_sq1_adc_data;
   sq1_adc_data(1)      <= i_c1_sq1_adc_data;
   sq1_adc_data(2)      <= i_c2_sq1_adc_data;
   sq1_adc_data(3)      <= i_c3_sq1_adc_data;

   sq1_adc_oor(0)       <= i_c0_sq1_adc_oor;
   sq1_adc_oor(1)       <= i_c1_sq1_adc_oor;
   sq1_adc_oor(2)       <= i_c2_sq1_adc_oor;
   sq1_adc_oor(3)       <= i_c3_sq1_adc_oor;

   o_c0_clk_sq1_adc     <= clk_sq1_adc_v(0);
   o_c1_clk_sq1_adc     <= clk_sq1_adc_v(1);
   o_c2_clk_sq1_adc     <= clk_sq1_adc_v(2);
   o_c3_clk_sq1_adc     <= clk_sq1_adc_v(3);

   o_c0_sq1_adc_pwdn    <= sq1_adc_pwdn(0);
   o_c1_sq1_adc_pwdn    <= sq1_adc_pwdn(1);
   o_c2_sq1_adc_pwdn    <= sq1_adc_pwdn(2);
   o_c3_sq1_adc_pwdn    <= sq1_adc_pwdn(3);

   b_c0_sq1_adc_spi_sdio<= sq1_adc_spi_mosi(0);
   b_c1_sq1_adc_spi_sdio<= sq1_adc_spi_mosi(1);
   b_c2_sq1_adc_spi_sdio<= sq1_adc_spi_mosi(2);
   b_c3_sq1_adc_spi_sdio<= sq1_adc_spi_mosi(3);

   o_c0_sq1_adc_spi_sclk<= sq1_adc_spi_sclk(0);
   o_c1_sq1_adc_spi_sclk<= sq1_adc_spi_sclk(1);
   o_c2_sq1_adc_spi_sclk<= sq1_adc_spi_sclk(2);
   o_c3_sq1_adc_spi_sclk<= sq1_adc_spi_sclk(3);

   o_c0_sq1_adc_spi_cs_n<= sq1_adc_spi_cs_n(0);
   o_c1_sq1_adc_spi_cs_n<= sq1_adc_spi_cs_n(1);
   o_c2_sq1_adc_spi_cs_n<= sq1_adc_spi_cs_n(2);
   o_c3_sq1_adc_spi_cs_n<= sq1_adc_spi_cs_n(3);

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID1 DAC outputs association
   -- ------------------------------------------------------------------------------------------------------
   o_c0_clk_sq1_dac     <= clk_sq1_dac_v(0);
   o_c1_clk_sq1_dac     <= clk_sq1_dac_v(1);
   o_c2_clk_sq1_dac     <= clk_sq1_dac_v(2);
   o_c3_clk_sq1_dac     <= clk_sq1_dac_v(3);

   o_c0_sq1_dac_data    <= sq1_dac_data(0);
   o_c1_sq1_dac_data    <= sq1_dac_data(1);
   o_c2_sq1_dac_data    <= sq1_dac_data(2);
   o_c3_sq1_dac_data    <= sq1_dac_data(3);

   o_c0_sq1_dac_sleep   <= sq1_dac_sleep(0);
   o_c1_sq1_dac_sleep   <= sq1_dac_sleep(1);
   o_c2_sq1_dac_sleep   <= sq1_dac_sleep(2);
   o_c3_sq1_dac_sleep   <= sq1_dac_sleep(3);

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID2 DAC outputs association
   -- ------------------------------------------------------------------------------------------------------
   o_c0_sq2_dac_mux     <= sq2_dac_mux(0);
   o_c1_sq2_dac_mux     <= sq2_dac_mux(1);
   o_c2_sq2_dac_mux     <= sq2_dac_mux(2);
   o_c3_sq2_dac_mux     <= sq2_dac_mux(3);

   o_c0_sq2_dac_mx_en_n <= '0';
   o_c1_sq2_dac_mx_en_n <= '0';
   o_c2_sq2_dac_mx_en_n <= '0';
   o_c3_sq2_dac_mx_en_n <= '0';

   o_c0_sq2_dac_data    <= sq2_dac_data(0);
   o_c1_sq2_dac_data    <= sq2_dac_data(1);
   o_c2_sq2_dac_data    <= sq2_dac_data(2);
   o_c3_sq2_dac_data    <= sq2_dac_data(3);

   o_c0_sq2_dac_sclk    <= sq2_dac_sclk(0);
   o_c1_sq2_dac_sclk    <= sq2_dac_sclk(1);
   o_c2_sq2_dac_sclk    <= sq2_dac_sclk(2);
   o_c3_sq2_dac_sclk    <= sq2_dac_sclk(3);

   o_c0_sq2_dac_sync_n  <= sq2_dac_sync_n(0);
   o_c1_sq2_dac_sync_n  <= sq2_dac_sync_n(1);
   o_c2_sq2_dac_sync_n  <= sq2_dac_sync_n(2);
   o_c3_sq2_dac_sync_n  <= sq2_dac_sync_n(3);

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data outputs association
   -- ------------------------------------------------------------------------------------------------------
   o_clk_science_01     <= clk_science;
   o_clk_science_23     <= clk_science;

   o_science_ctrl_01    <= science_data_ser(4*c_SC_DATA_SER_NB);
   o_science_ctrl_23    <= science_data_ser(4*c_SC_DATA_SER_NB);

   o_c0_science_data    <= science_data_ser(1*c_SC_DATA_SER_NB-1 downto 0*c_SC_DATA_SER_NB);
   o_c1_science_data    <= science_data_ser(2*c_SC_DATA_SER_NB-1 downto 1*c_SC_DATA_SER_NB);
   o_c2_science_data    <= science_data_ser(3*c_SC_DATA_SER_NB-1 downto 2*c_SC_DATA_SER_NB);
   o_c3_science_data    <= science_data_ser(4*c_SC_DATA_SER_NB-1 downto 3*c_SC_DATA_SER_NB);

   -- TODO
   science_data_tx_ena  <= '1';
   science_data(0)      <= "10101010";
   science_data(1)      <= "01010101";
   science_data(2)      <= "01110010";
   science_data(3)      <= "00011000";
   science_data(4)      <= "10001101";
   science_data(5)      <= "11100111";
   science_data(6)      <= "11000001";
   science_data(7)      <= "01001011";
   science_data(8)      <= "11000000";

end architecture rtl;
