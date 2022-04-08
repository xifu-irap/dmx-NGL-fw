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
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_ep_cmd.all;

entity top_dmx_tb is
end entity top_dmx_tb;

architecture Simulation of top_dmx_tb is
signal   arst_n               : std_logic                                                                   ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
signal   arst                 : std_logic                                                                   ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
signal   clk_ref              : std_logic                                                                   ; --! Reference Clock

signal   clk_sq1_adc          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Clocks
signal   clk_sq1_dac          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC - Clocks
signal   clk_science_01       : std_logic                                                                   ; --! Science Data - Clock channel 0/1
signal   clk_science_23       : std_logic                                                                   ; --! Science Data - Clock channel 2/3

signal   err_chk_rpt          : t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)            ; --! Clock check error reports
signal   err_n_spi_chk        : t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)             ; --! SPI check error number:
signal   err_num_pls_shp      : t_int_arr(0 to c_NB_COL-1)                                                  ; --! Pulse shaping error number

signal   brd_ref              : std_logic_vector(     c_BRD_REF_S-1 downto 0)                               ; --! Board reference
signal   brd_model            : std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                               ; --! Board model
signal   sync                 : std_logic                                                                   ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

signal   sq1_adc_ana          : t_real_arr(0 to c_NB_COL-1)                                                 ; --! SQUID1 ADC - Analog
signal   sq1_adc_data         : t_slv_arr( 0 to c_NB_COL-1)(c_SQ1_ADC_DATA_S-1 downto 0)                    ; --! SQUID1 ADC - Data buses
signal   sq1_adc_oor          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

signal   sq1_dac_data         : t_slv_arr(0 to c_NB_COL-1)(c_SQ1_DAC_DATA_S-1 downto 0)                     ; --! SQUID1 DAC - Data buses

signal   science_ctrl_01      : std_logic                                                                   ; --! Science Data – Control channel 0/1
signal   science_ctrl_23      : std_logic                                                                   ; --! Science Data – Control channel 2/3
signal   science_data         : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB-1 downto 0)                     ; --! Science Data – Serial Data

signal   hk1_spi_miso         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Master Input Slave Output
signal   hk1_spi_mosi         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Master Output Slave Input
signal   hk1_spi_sclk         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   hk1_spi_cs_n         : std_logic                                                                   ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
signal   hk1_mux              : std_logic_vector(      c_HK_MUX_S-1 downto 0)                               ; --! HouseKeeping 1 - Multiplexer
signal   hk1_mux_ena_n        : std_logic                                                                   ; --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   ep_spi_mosi          : std_logic                                                                   ; --! EP - SPI Master Input Slave Output (MSB first)
signal   ep_spi_miso          : std_logic                                                                   ; --! EP - SPI Master Output Slave Input (MSB first)
signal   ep_spi_sclk          : std_logic                                                                   ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   ep_spi_cs_n          : std_logic                                                                   ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   sq1_adc_spi_sdio     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - SPI Serial Data In Out
signal   sq1_adc_spi_sclk     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
signal   sq1_adc_spi_cs_n     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

signal   sq1_adc_pwdn         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
signal   sq1_dac_sleep        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)

signal   sq2_dac_data         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC - Serial Data
signal   sq2_dac_sclk         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC - Serial Clock
signal   sq2_dac_snc_l_n      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC, col. 0 - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
signal   sq2_dac_snc_o_n      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC, col. 0 - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
signal   sq2_dac_mux          : t_slv_arr(0 to c_NB_COL-1)(c_SQ2_DAC_MUX_S-1 downto 0)                      ; --! SQUID2 DAC - Multiplexer
signal   sq2_dac_mx_en_n      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   d_rst                : std_logic                                                                   ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_rst_sq1_adc        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_rst_sq1_dac        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_rst_sq2_mux        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

signal   d_clk                : std_logic                                                                   ; --! Internal design: System Clock
signal   d_clk_sq1_adc_acq    : std_logic                                                                   ; --! Internal design: SQUID1 ADC acquisition Clock
signal   d_clk_sq1_pls_shape  : std_logic                                                                   ; --! Internal design: SQUID1 pulse shaping Clock

signal   d_tm_mode            : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)                 ; --! Internal design: Telemetry mode

signal   sc_pkt_type          : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Science packet type
signal   sc_pkt_err           : std_logic                                                                   ; --! Science packet error ('0' = No error, '1' = Error)

signal   ep_cmd               : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP - Command to send
signal   ep_cmd_start         : std_logic                                                                   ; --! EP - Start command transmit (one system clock pulse)
signal   ep_cmd_busy_n        : std_logic                                                                   ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
signal   ep_cmd_ser_wd_s      : std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)                      ; --! EP - Serial word size

signal   ep_data_rx           : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP - Receipted data
signal   ep_data_rx_rdy       : std_logic                                                                   ; --! EP - Receipted data ready ('0' = Inactive, '1' = Active)

signal   pls_shp_fc           : t_int_arr(0 to c_NB_COL-1)                                                  ; --! Pulse shaping cut frequency (Hz)
signal   sw_adc_vin           : std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                                 ; --! Switch ADC Voltage input

signal   adc_dmp_mem_add      : std_logic_vector(    c_MUX_FACT_S-1 downto 0)                               ; --! ADC Dump memory for data compare: address
signal   adc_dmp_mem_data     : std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                               ; --! ADC Dump memory for data compare: data
signal   adc_dmp_mem_cs       : std_logic                                                                   ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX - Top level
   -- ------------------------------------------------------------------------------------------------------
   I_top_dmx: entity work.top_dmx port map
   (     i_arst_n             => arst_n               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => clk_ref              , -- in     std_logic                                 ; --! Reference Clock

         o_clk_sq1_adc        => clk_sq1_adc          , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC - Clock
         o_clk_sq1_dac        => clk_sq1_dac          , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC - Clock
         o_clk_science_01     => clk_science_01       , -- out    std_logic                                 ; --! Science Data - Clock channel 0/1
         o_clk_science_23     => clk_science_23       , -- out    std_logic                                 ; --! Science Data - Clock channel 2/3

         i_brd_ref            => brd_ref              , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         i_brd_model          => brd_model            , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_sq1_adc_data       => sq1_adc_data         , -- in     t_slv_arr c_NB_COL c_SQ1_ADC_DATA_S       ; --! SQUID1 ADC - Data
         i_sq1_adc_oor        => sq1_adc_oor          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)
         o_sq1_dac_data       => sq1_dac_data         , -- out    t_slv_arr c_NB_COL c_SQ1_DAC_DATA_S       ; --! SQUID1 DAC - Data

         o_science_ctrl_01    => science_ctrl_01      , -- out    std_logic                                 ; --! Science Data – Control channel 0/1
         o_science_ctrl_23    => science_ctrl_23      , -- out    std_logic                                 ; --! Science Data – Control channel 2/3
         o_science_data       => science_data         , -- out    t_slv_arr c_NB_COL c_SC_DATA_SER_NB       ; --! Science Data – Serial Data

         i_hk1_spi_miso       => hk1_spi_miso         , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Master Input Slave Output
         o_hk1_spi_mosi       => hk1_spi_mosi         , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Master Output Slave Input
         o_hk1_spi_sclk       => hk1_spi_sclk         , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_hk1_spi_cs_n       => hk1_spi_cs_n         , -- out    std_logic                                 ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux            => hk1_mux              , -- out    std_logic_vector(c_HK1_MUX_S-1 downto 0)  ; --! HouseKeeping 1 - Multiplexer
         o_hk1_mux_ena_n      => hk1_mux_ena_n        , -- out    std_logic                                 ; --! HouseKeeping 1 - Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        => ep_spi_mosi          , -- in     std_logic                                 ; --! EP - SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        => ep_spi_miso          , -- out    std_logic                                 ; --! EP - SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        => ep_spi_sclk          , -- in     std_logic                                 ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_ep_spi_cs_n        => ep_spi_cs_n          , -- in     std_logic                                 ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

         b_sq1_adc_spi_sdio   => sq1_adc_spi_sdio     , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC - SPI Serial Data In Out
         o_sq1_adc_spi_sclk   => sq1_adc_spi_sclk     , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_sq1_adc_spi_cs_n   => sq1_adc_spi_cs_n     , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sq1_adc_pwdn       => sq1_adc_pwdn         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
         o_sq1_dac_sleep      => sq1_dac_sleep        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)

         o_sq2_dac_data       => sq2_dac_data         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC - Serial Data
         o_sq2_dac_sclk       => sq2_dac_sclk         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC - Serial Clock
         o_sq2_dac_snc_l_n    => sq2_dac_snc_l_n      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sq2_dac_snc_o_n    => sq2_dac_snc_o_n      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_sq2_dac_mux        => sq2_dac_mux          , -- out    t_slv_arr c_NB_COL c_SQ2_DAC_MUX_S        ; --! SQUID2 DAC - Multiplexer
         o_sq2_dac_mx_en_n    => sq2_dac_mx_en_n        -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)

   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Get top level internal signals
   -- ------------------------------------------------------------------------------------------------------
   G_get_top_level_sig: if true generate
   alias td_rst               : std_logic is <<signal .top_dmx_tb.I_top_dmx.rst              : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_adc_0     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(0).I_squid_adc_mgt.rst_sq1_adc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_adc_1     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(1).I_squid_adc_mgt.rst_sq1_adc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_adc_2     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(2).I_squid_adc_mgt.rst_sq1_adc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_adc_3     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(3).I_squid_adc_mgt.rst_sq1_adc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_dac_0     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(0).I_squid1_dac_mgt.rst_sq1_pls_shape
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_dac_1     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(1).I_squid1_dac_mgt.rst_sq1_pls_shape
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_dac_2     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(2).I_squid1_dac_mgt.rst_sq1_pls_shape
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq1_dac_3     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(3).I_squid1_dac_mgt.rst_sq1_pls_shape
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq2_mux_0     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(0).I_squid2_dac_mgt.rst_sq2_dac
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq2_mux_1     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(1).I_squid2_dac_mgt.rst_sq2_dac
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq2_mux_2     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(2).I_squid2_dac_mgt.rst_sq2_dac
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sq2_mux_3     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx.G_column_mgt(3).I_squid2_dac_mgt.rst_sq2_dac
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_clk               : std_logic is <<signal .top_dmx_tb.I_top_dmx.clk              : std_logic>>  ; --! Internal design: System Clock
   alias td_clk_sq1_adc_acq   : std_logic is <<signal .top_dmx_tb.I_top_dmx.clk_sq1_adc_dac  : std_logic>>  ; --! Internal design: SQUID1 ADC acquisition Clock
   alias td_clk_sq1_pls_shape : std_logic is <<signal .top_dmx_tb.I_top_dmx.clk_sq1_adc_dac  : std_logic>>  ; --! Internal design: SQUID1 pulse shaping Clock
   alias td_tm_mode           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx.tm_mode:
                                   t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)>>            ; --! Internal design: Telemetry mode
   begin

      d_rst                <= td_rst;
      d_rst_sq1_adc(0)     <= td_rst_sq1_adc_0;
      d_rst_sq1_adc(1)     <= td_rst_sq1_adc_1;
      d_rst_sq1_adc(2)     <= td_rst_sq1_adc_2;
      d_rst_sq1_adc(3)     <= td_rst_sq1_adc_3;
      d_rst_sq1_dac(0)     <= td_rst_sq1_dac_0;
      d_rst_sq1_dac(1)     <= td_rst_sq1_dac_1;
      d_rst_sq1_dac(2)     <= td_rst_sq1_dac_2;
      d_rst_sq1_dac(3)     <= td_rst_sq1_dac_3;
      d_rst_sq2_mux(0)     <= td_rst_sq2_mux_0;
      d_rst_sq2_mux(1)     <= td_rst_sq2_mux_1;
      d_rst_sq2_mux(2)     <= td_rst_sq2_mux_2;
      d_rst_sq2_mux(3)     <= td_rst_sq2_mux_3;
      d_clk                <= td_clk;
      d_clk_sq1_adc_acq    <= td_clk_sq1_adc_acq;
      d_clk_sq1_pls_shape  <= td_clk_sq1_pls_shape;
      d_tm_mode            <= td_tm_mode;

   end generate G_get_top_level_sig;

   -- ------------------------------------------------------------------------------------------------------
   --!   Check all clocks
   -- ------------------------------------------------------------------------------------------------------
   I_clock_check_model: entity work.clock_check_model port map
   (     i_clk                => d_clk                , -- in     std_logic                                 ; --! Internal design: System Clock
         i_clk_sq1_adc_acq    => d_clk_sq1_adc_acq    , -- in     std_logic                                 ; --! Internal design: SQUID1 ADC acquisition Clock
         i_clk_sq1_pls_shape  => d_clk_sq1_pls_shape  , -- in     std_logic                                 ; --! Internal design: SQUID1 pulse shaping Clock
         i_c0_clk_sq1_adc     => clk_sq1_adc(0)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 0 - Clock
         i_c1_clk_sq1_adc     => clk_sq1_adc(1)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 1 - Clock
         i_c2_clk_sq1_adc     => clk_sq1_adc(2)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 2 - Clock
         i_c3_clk_sq1_adc     => clk_sq1_adc(3)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 3 - Clock
         i_c0_clk_sq1_dac     => clk_sq1_dac(0)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 0 - Clock
         i_c1_clk_sq1_dac     => clk_sq1_dac(1)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 1 - Clock
         i_c2_clk_sq1_dac     => clk_sq1_dac(2)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 2 - Clock
         i_c3_clk_sq1_dac     => clk_sq1_dac(3)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 3 - Clock
         i_clk_science_01     => clk_science_01       , -- in     std_logic                                 ; --! Science Data - Clock channel 0/1
         i_clk_science_23     => clk_science_23       , -- in     std_logic                                 ; --! Science Data - Clock channel 2/3

         i_rst                => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_c0_sq1_adc_pwdn    => sq1_adc_pwdn(0)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         i_c1_sq1_adc_pwdn    => sq1_adc_pwdn(1)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         i_c2_sq1_adc_pwdn    => sq1_adc_pwdn(2)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         i_c3_sq1_adc_pwdn    => sq1_adc_pwdn(3)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)
         i_c0_sq1_dac_sleep   => sq1_dac_sleep(0)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   => sq1_dac_sleep(1)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   => sq1_dac_sleep(2)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   => sq1_dac_sleep(3)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         o_err_chk_rpt        => err_chk_rpt            -- out    t_int_arr_tab c_CHK_ENA_CLK_NB              --! Clock check error reports
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Check SPI bus
   -- ------------------------------------------------------------------------------------------------------
   I_spi_check_model: entity work.spi_check_model port map
   (     i_hk1_spi_mosi       => hk1_spi_mosi         , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Master Output Slave Input
         i_hk1_spi_sclk       => hk1_spi_sclk         , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_hk1_spi_cs_n       => hk1_spi_cs_n         , -- in     std_logic                                 ; --! HouseKeeping 1 - SPI Chip Select ('0' = Active, '1' = Inactive)
         i_sq2_dac_data       => sq2_dac_data         , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC - Serial Data
         i_sq2_dac_sclk       => sq2_dac_sclk         , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC - Serial Clock
         i_sq2_dac_snc_l_n    => sq2_dac_snc_l_n      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC, col. 0 - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sq2_dac_snc_o_n    => sq2_dac_snc_o_n      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID2 DAC, col. 0 - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_err_n_spi_chk      => err_n_spi_chk          -- out    t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)      --! SPI check error number:
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset management
   -- ------------------------------------------------------------------------------------------------------
   arst <= not(arst_n);

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
   --!   SQUID1/SQUID2 model
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      I_squid_model: squid_model port map
      (  i_arst               => arst                 , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_clk_sq1_adc        => clk_sq1_adc(k)       , -- in     std_logic                                 ; --! SQUID1 ADC - Clock
         i_sq1_adc_pwdn       => sq1_adc_pwdn(k)      , -- in     std_logic                                 ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
         b_sq1_adc_spi_sdio   => sq1_adc_spi_sdio(k)  , -- inout  std_logic                                 ; --! SQUID1 ADC - SPI Serial Data In Out
         i_sq1_adc_spi_sclk   => sq1_adc_spi_sclk(k)  , -- in     std_logic                                 ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_sq1_adc_spi_cs_n   => sq1_adc_spi_cs_n(k)  , -- in     std_logic                                 ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         i_sw_adc_vin         => sw_adc_vin           , -- in     slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input
         o_sq1_adc_ana        => sq1_adc_ana(k)       , -- out    real                                      ; --! SQUID1 ADC - Analog
         o_sq1_adc_data       => sq1_adc_data(k)      , -- out    slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC - Data
         o_sq1_adc_oor        => sq1_adc_oor(k)       , -- out    std_logic                                 ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

         i_pls_shp_fc         => pls_shp_fc(k)        , -- in     integer                                   ; --! Pulse shaping cut frequency (Hz)
         o_err_num_pls_shp    => err_num_pls_shp(k)   , -- out    integer                                   ; --! Pulse shaping error number

         i_clk_sq1_dac        => clk_sq1_dac(k)       , -- in     std_logic                                 ; --! SQUID1 DAC - Clock
         i_sq1_dac_data       => sq1_dac_data(k)      , -- in     slv(c_SQ1_DAC_DATA_S-1 downto 0)          ; --! SQUID1 DAC - Data
         i_sq1_dac_sleep      => sq1_dac_sleep(k)     , -- in     std_logic                                 ; --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)

         i_sq2_dac_data       => sq2_dac_data(k)      , -- in     std_logic                                 ; --! SQUID2 DAC - Serial Data
         i_sq2_dac_sclk       => sq2_dac_sclk(k)      , -- in     std_logic                                 ; --! SQUID2 DAC - Serial Clock
         i_sq2_dac_snc_l_n    => sq2_dac_snc_l_n(k)   , -- in     std_logic                                 ; --! SQUID2 DAC - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sq2_dac_snc_o_n    => sq2_dac_snc_o_n(k)   , -- in     std_logic                                 ; --! SQUID2 DAC - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sq2_dac_mux        => sq2_dac_mux(k)       , -- in     slv( c_SQ2_DAC_MUX_S-1 downto 0)          ; --! SQUID2 DAC - Multiplexer
         i_sq2_dac_mx_en_n    => sq2_dac_mx_en_n(k)     -- in     std_logic                                   --! SQUID2 DAC - Multiplexer Enable ('0' = Active, '1' = Inactive)
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Model
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_model: science_data_model port map
   (     i_arst               => arst                 , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_acq    => d_clk_sq1_adc_acq    , -- in     std_logic                                 ; --! SQUID1 ADC acquisition Clock
         i_clk_science        => clk_science_01       , -- in     std_logic                                 ; --! Science Clock

         i_science_ctrl_01    => science_ctrl_01      , -- in     std_logic                                 ; --! Science Data – Control channel 0/1
         i_science_ctrl_23    => science_ctrl_23      , -- in     std_logic                                 ; --! Science Data – Control channel 2/3
         i_c0_science_data    => science_data(0)      , -- in     slv(c_SC_DATA_SER_NB-1 downto 0)          ; --! Science Data, col. 0 – Serial Data
         i_c1_science_data    => science_data(1)      , -- in     slv(c_SC_DATA_SER_NB-1 downto 0)          ; --! Science Data, col. 1 – Serial Data
         i_c2_science_data    => science_data(2)      , -- in     slv(c_SC_DATA_SER_NB-1 downto 0)          ; --! Science Data, col. 2 – Serial Data
         i_c3_science_data    => science_data(3)      , -- in     slv(c_SC_DATA_SER_NB-1 downto 0)          ; --! Science Data, col. 3 – Serial Data

         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_tm_mode            => d_tm_mode            , -- in     t_slv_arr c_NB_COL c_DFLD_TM_MODE_COL_S   ; --! Telemetry mode
         i_sw_adc_vin         => sw_adc_vin           , -- in     slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input

         i_sq1_adc_data       => sq1_adc_data         , -- in     t_slv_arr c_NB_COL c_SQ1_ADC_DATA_S       ; --! SQUID1 ADC - Data buses
         i_sq1_adc_oor        => sq1_adc_oor          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

         i_adc_dmp_mem_add    => adc_dmp_mem_add      , -- in     slv(    c_MUX_FACT_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   => adc_dmp_mem_data     , -- in     slv(c_SQ1_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         i_adc_dmp_mem_cs     => adc_dmp_mem_cs       , -- in     std_logic                                 ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_sc_pkt_type        => sc_pkt_type          , -- out    slv(c_SC_DATA_SER_W_S-1 downto 0)         ; --! Science packet type
         o_sc_pkt_err         => sc_pkt_err             -- out    std_logic                                   --! Science packet error ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser
   -- ------------------------------------------------------------------------------------------------------
   I_parser: parser port map
   (     o_arst_n             => arst_n               , -- out    std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => clk_ref              , -- in     std_logic                                 ; --! Reference Clock
         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_err_chk_rpt        => err_chk_rpt          , -- in     t_int_arr_tab c_CHK_ENA_CLK_NB            ; --! Clock check error reports
         i_err_n_spi_chk      => err_n_spi_chk        , -- in     t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)    ; --! SPI check error number:
         i_err_num_pls_shp    => err_num_pls_shp      , -- in     t_int_arr(0 to c_NB_COL-1)                ; --! Pulse shaping error number

         i_c0_sq1_adc_pwdn    => sq1_adc_pwdn(0)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         i_c1_sq1_adc_pwdn    => sq1_adc_pwdn(1)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         i_c2_sq1_adc_pwdn    => sq1_adc_pwdn(2)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         i_c3_sq1_adc_pwdn    => sq1_adc_pwdn(3)      , -- in     std_logic                                 ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)

         i_c0_sq1_adc_ana     => sq1_adc_ana(0)       , -- in     real                                      ; --! SQUID1 ADC, col. 0 - Analog
         i_c1_sq1_adc_ana     => sq1_adc_ana(1)       , -- in     real                                      ; --! SQUID1 ADC, col. 1 - Analog
         i_c2_sq1_adc_ana     => sq1_adc_ana(2)       , -- in     real                                      ; --! SQUID1 ADC, col. 2 - Analog
         i_c3_sq1_adc_ana     => sq1_adc_ana(3)       , -- in     real                                      ; --! SQUID1 ADC, col. 3 - Analog

         i_c0_sq1_dac_sleep   => sq1_dac_sleep(0)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   => sq1_dac_sleep(1)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   => sq1_dac_sleep(2)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   => sq1_dac_sleep(3)     , -- in     std_logic                                 ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_adc      => d_rst_sq1_adc        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_dac      => d_rst_sq1_dac        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq2_mux      => d_rst_sq2_mux        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              => d_clk                , -- in     std_logic                                 ; --! Internal design: System Clock
         i_d_clk_sq1_adc_acq  => d_clk_sq1_adc_acq    , -- in     std_logic                                 ; --! Internal design: SQUID1 ADC acquisition Clock
         i_d_clk_sq1_pls_shap => d_clk_sq1_pls_shape  , -- in     std_logic                                 ; --! Internal design: SQUID1 pulse shaping Clock

         i_c0_clk_sq1_adc     => clk_sq1_adc(0)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 0 - Clock
         i_c1_clk_sq1_adc     => clk_sq1_adc(1)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 1 - Clock
         i_c2_clk_sq1_adc     => clk_sq1_adc(2)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 2 - Clock
         i_c3_clk_sq1_adc     => clk_sq1_adc(3)       , -- in     std_logic                                 ; --! SQUID1 ADC, col. 3 - Clock

         i_c0_clk_sq1_dac     => clk_sq1_dac(0)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 0 - Clock
         i_c1_clk_sq1_dac     => clk_sq1_dac(1)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 1 - Clock
         i_c2_clk_sq1_dac     => clk_sq1_dac(2)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 2 - Clock
         i_c3_clk_sq1_dac     => clk_sq1_dac(3)       , -- in     std_logic                                 ; --! SQUID1 DAC, col. 3 - Clock

         i_sc_pkt_type        => sc_pkt_type          , -- in     slv(c_SC_DATA_SER_W_S-1 downto 0)         ; --! Science packet type
         i_sc_pkt_err         => sc_pkt_err           , -- out    std_logic                                 ; --! Science packet error ('0' = No error, '1' = Error)

         i_ep_data_rx         => ep_data_rx           , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP - Receipted data
         i_ep_data_rx_rdy     => ep_data_rx_rdy       , -- in     std_logic                                 ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             => ep_cmd               , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP - Command to send
         o_ep_cmd_start       => ep_cmd_start         , -- out    std_logic                                 ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      => ep_cmd_busy_n        , -- in     std_logic                                 ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- out    slv(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0) ; --! EP - Serial word size

         o_brd_ref            => brd_ref              , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         o_brd_model          => brd_model            , -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model

         o_adc_dmp_mem_add    => adc_dmp_mem_add      , -- out    slv(    c_MUX_FACT_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         o_adc_dmp_mem_data   => adc_dmp_mem_data     , -- out    slv(c_SQ1_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         o_adc_dmp_mem_cs     => adc_dmp_mem_cs       , -- out    std_logic                                 ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_pls_shp_fc         => pls_shp_fc           , -- out    t_int_arr(0 to c_NB_COL-1)                ; --! Pulse shaping cut frequency (Hz)
         o_sw_adc_vin         => sw_adc_vin             -- out    slv(c_SW_ADC_VIN_S-1 downto 0)              --! Switch ADC Voltage input
   );

end simulation;
