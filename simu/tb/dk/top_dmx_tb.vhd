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
--!   @file                   top_dmx_tb.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Top level testbench (Devkit Model)
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
signal   clk_ref              : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Reference Clock
signal   clk_fpasim           : std_logic                                                                   ; --! FPASIM Clock
signal   clk_fpasim_shift     : std_logic                                                                   ; --! FPASIM Clock, 90 degrees shifted

signal   clk_science_01       : std_logic                                                                   ; --! Science Data: Clock channel 0/1
signal   clk_science_23       : std_logic                                                                   ; --! Science Data: Clock channel 2/3

signal   sync                 : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
signal   ras_data_valid       : std_logic                                                                   ; --! RAS Data valid ('0' = No, '1' = Yes)

signal   science_ctrl_01      : std_logic                                                                   ; --! Science Data: Control channel 0/1
signal   science_ctrl_23      : std_logic                                                                   ; --! Science Data: Control channel 2/3
signal   science_data         : t_slv_arr(0 to c_NB_COL  )(c_SC_DATA_SER_NB-1 downto 0)                     ; --! Science Data: Serial Data

signal   ep_spi_mosi          : std_logic_vector(1 downto 0)                                                ; --! EP: SPI Master Input Slave Output (MSB first)
signal   ep_spi_miso          : std_logic_vector(1 downto 0)                                                ; --! EP: SPI Master Output Slave Input (MSB first)
signal   ep_spi_sclk          : std_logic_vector(1 downto 0)                                                ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
signal   ep_spi_cs_n          : std_logic_vector(1 downto 0)                                                ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

signal   d_rst                : std_logic                                                                   ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_clk_sqm_adc_acq    : std_logic                                                                   ; --! Internal design: SQUID MUX ADC acquisition Clock

signal   d_aqmde              : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Internal design: Telemetry mode
signal   d_smfbd              : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)                   ; --! Internal design: SQUID MUX feedback delay
signal   d_saomd              : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)                   ; --! Internal design: SQUID AMP offset MUX delay
signal   d_sqm_fbm_cls_lp_n   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)

signal   sc_pkt_type          : t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)               ; --! Science packet type
signal   sc_pkt_err           : std_logic                                                                   ; --! Science packet error ('0' = No error, '1' = Error)

signal   ep_cmd               : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP: Command to send
signal   ep_cmd_start         : std_logic                                                                   ; --! EP: Start command transmit (one system clock pulse)
signal   ep_cmd_busy_n        : std_logic                                                                   ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)
signal   ep_cmd_ser_wd_s      : std_logic_vector(log2_ceil(c_SER_WD_MAX_S+1)-1 downto 0)                    ; --! EP: Serial word size

signal   ep_data_rx           : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP: Receipted data
signal   ep_data_rx_rdy       : std_logic                                                                   ; --! EP: Receipted data ready ('0' = Inactive, '1' = Active)

signal   frm_cnt_sc_rst       : std_logic                                                                   ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
signal   adc_dmp_mem_add      : std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                               ; --! ADC Dump memory for data compare: address
signal   adc_dmp_mem_data     : std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                               ; --! ADC Dump memory for data compare: data
signal   science_mem_data     : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! Science  memory for data compare: data
signal   adc_dmp_mem_cs       : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

signal   fpa_conf_busy        : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
signal   fpa_cmd_rdy          : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! FPASIM command ready ('0' = No, '1' = Yes)
signal   fpa_cmd              : t_slv_arr(0 to c_NB_COL-1)(c_FPA_CMD_S-1 downto 0)                          ; --! FPASIM command
signal   fpa_cmd_valid        : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! FPASIM command valid ('0' = No, '1' = Yes)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX: Top level
   -- ------------------------------------------------------------------------------------------------------
   I_top_dmx_dk: entity work.top_dmx_dk port map (
         i_clk_ref            => clk_ref(c_COL0)      , -- in     std_logic                                 ; --! Reference Clock

         o_clk_science_01     => clk_science_01       , -- out    std_logic                                 ; --! Science Data: Clock channel 0/1
         o_clk_science_23     => clk_science_23       , -- out    std_logic                                 ; --! Science Data: Clock channel 2/3

         i_ras_data_valid_n   => not(ras_data_valid)  , -- in     std_logic                                 ; --! RAS Data valid ('0' = Yes, '1' = No)

         o_science_ctrl_01    => science_ctrl_01      , -- out    std_logic                                 ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    => science_ctrl_23      , -- out    std_logic                                 ; --! Science Data: Control channel 2/3
         o_science_data       => science_data(0 to c_NB_COL-1), -- out t_slv_arr c_NB_COL c_SC_DATA_SER_NB  ; --! Science Data: Serial Data
         o_science_data_c2_0  => open                 , -- out    std_logic c_SC_DATA_SER_NB                ; --! Science Data: Serial Data column 2 bit 0 redundancy

         i_ep_spi_sel         => c_LOW_LEV            , -- in     std_logic                                 ; --! EP: SPI select ('0' = Channel 0, '1' = Channel 1)
         i_ep_spi_mosi        => ep_spi_mosi          , -- in     std_logic_vector(1 downto 0)              ; --! EP: SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        => ep_spi_miso          , -- out    std_logic_vector(1 downto 0)              ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        => ep_spi_sclk          , -- in     std_logic_vector(1 downto 0)              ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        => ep_spi_cs_n            -- in     std_logic_vector(1 downto 0)                --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

    );

   -- ------------------------------------------------------------------------------------------------------
   --!   Get top level internal signals
   -- ------------------------------------------------------------------------------------------------------
   G_get_top_level_sig: if true generate
   alias td_rst               : std_logic is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.rst: std_logic>>        ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_clk_sqm_adc_acq   : std_logic is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.clk_sqm_adc_dac:
                                   std_logic>>                                                              ; --! Internal design: SQUID MUX ADC acquisition Clock
   alias td_aqmde             : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.aqmde:
                                   std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)>>                            ; --! Internal design: Telemetry mode

   alias td_smfbd_0           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL0).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay
   alias td_smfbd_1           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL1).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay
   alias td_smfbd_2           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL2).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay
   alias td_smfbd_3           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL3).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay

   alias td_saomd_0           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL0).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay
   alias td_saomd_1           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL1).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay
   alias td_saomd_2           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL2).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay
   alias td_saomd_3           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.G_column_mgt(c_COL3).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay

   alias td_sqm_fbm_clslp_n   : std_logic_vector(c_NB_COL-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dk.I_top_dmx_dm_clk.squid_close_mode_n:
                                   std_logic_vector(c_NB_COL-1 downto 0)>>                                  ; --! Internal design: SQUID MUX feedback mode Closed loop
   begin

      d_rst                      <= td_rst;
      d_clk_sqm_adc_acq          <= td_clk_sqm_adc_acq;
      d_aqmde                    <= td_aqmde;
      d_smfbd(c_COL0)            <= td_smfbd_0;
      d_smfbd(c_COL1)            <= td_smfbd_1;
      d_smfbd(c_COL2)            <= td_smfbd_2;
      d_smfbd(c_COL3)            <= td_smfbd_3;
      d_saomd(c_COL0)            <= td_saomd_0;
      d_saomd(c_COL1)            <= td_saomd_1;
      d_saomd(c_COL2)            <= td_saomd_2;
      d_saomd(c_COL3)            <= td_saomd_3;
      d_sqm_fbm_cls_lp_n         <= td_sqm_fbm_clslp_n;

   end generate G_get_top_level_sig;

   -- ------------------------------------------------------------------------------------------------------
   --!   FPASIM clock reference generation
   -- ------------------------------------------------------------------------------------------------------
   I_clock_model: entity work.clock_model generic map (
         g_CLK_REF_PER        => c_CLK_FPA_PER_DEF    , -- time    := c_CLK_REF_PER_DEF                     ; --! Reference Clock period
         g_SYNC_PER           => c_SYNC_PER_DEF       , -- time    := c_SYNC_PER_DEF                        ; --! Pixel sequence synchronization period
         g_SYNC_SHIFT         => c_SYNC_SHIFT_DEF       -- time    := c_SYNC_SHIFT_DEF                        --! Pixel sequence synchronization shift
   ) port map (
         o_clk_ref            => clk_fpasim           , -- out    std_logic                                 ; --! Reference Clock
         o_sync               => open                   -- out    std_logic                                   --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   );

   clk_fpasim_shift <= transport clk_fpasim after c_CLK_FPA_SHIFT when now > c_CLK_FPA_SHIFT else c_LOW_LEV;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP SPI model
   -- ------------------------------------------------------------------------------------------------------
   I_ep_spi_model: ep_spi_model port map (
         i_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- in     slv log2_ceil(c_SER_WD_MAX_S+1)           ; --! EP: Serial word size
         i_ep_cmd_start       => ep_cmd_start         , -- in     std_logic                                 ; --! EP: Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd             => ep_cmd               , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Command to send
         o_ep_cmd_busy_n      => ep_cmd_busy_n        , -- out    std_logic                                 ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)

         o_ep_data_rx         => ep_data_rx           , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Receipted data
         o_ep_data_rx_rdy     => ep_data_rx_rdy       , -- out    std_logic                                 ; --! EP: Receipted data ready ('0' = Not ready, '1' = Ready)

         o_ep_spi_mosi        => ep_spi_mosi(0)       , -- out    std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first)
         i_ep_spi_miso        => ep_spi_miso(0)       , -- in     std_logic                                 ; --! EP: SPI Master Output Slave Input (MSB first)
         o_ep_spi_sclk        => ep_spi_sclk(0)       , -- out    std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_ep_spi_cs_n        => ep_spi_cs_n(0)         -- out    std_logic                                   --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX/SQUID AMP model
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

   -- ------------------------------------------------------------------------------------------------------
   --!   FPASIM model management
   -- ------------------------------------------------------------------------------------------------------
      I_fpasim_model: fpga_system_fpasim_top port map (
         i_make_pulse_valid   => fpa_cmd_valid(k)     , -- in     std_logic                                 ; --! FPASIM command valid ('0' = No, '1' = Yes)
         i_make_pulse         => fpa_cmd(k)           , -- in     std_logic_vector(c_FPA_CMD_S-1 downto 0)  ; --! FPASIM command
         o_auto_conf_busy     => fpa_conf_busy(k)     , -- out    std_logic                                 ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
         o_ready              => fpa_cmd_rdy(k)       , -- out    std_logic                                 ; --! FPASIM command ready ('0' = No, '1' = Yes)

         i_adc_clk_phase      => clk_fpasim_shift     , -- in     std_logic                                 ; --! FPASIM ADC 90 degrees shifted clock
         i_adc_clk            => clk_fpasim           , -- in     std_logic                                 ; --! FPASIM ADC clock
         i_adc0_real          => c_ZERO_REAL          , -- in     real                                      ; --! FPASIM ADC Analog Squid MUX
         i_adc1_real          => c_ZERO_REAL          , -- in     real                                      ; --! FPASIM ADC Analog Squid AMP

         o_clk_ref_p          => clk_ref(k)           , -- out    std_logic                                 ; --! Diff. Reference Clock
         o_clk_ref_n          => open                 , -- out    std_logic                                 ; --! Diff. Reference Clock
         o_clk_frame_p        => sync(k)              , -- out    std_logic                                 ; --! Diff. pixel sequence sync. (R.E. detected = position sequence to the first pixel)
         o_clk_frame_n        => open                 , -- out    std_logic                                 ; --! Diff. pixel sequence sync. (R.E. detected = position sequence to the first pixel)

         o_dac_real_valid     => open                 , -- out    std_logic                                 ; --! FPASIM DAC Error valid ('0' = No, '1' = Yes)
         o_dac_real           => open                   -- out    real                                        --! FPASIM DAC Analog Error
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Model
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_model: science_data_model port map (
         i_arst               => d_rst                , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_acq    => d_clk_sqm_adc_acq    , -- in     std_logic                                 ; --! SQUID MUX ADC acquisition Clock
         i_clk_science        => clk_science_01       , -- in     std_logic                                 ; --! Science Clock

         i_science_ctrl_01    => science_ctrl_01      , -- in     std_logic                                 ; --! Science Data: Control channel 0/1
         i_science_ctrl_23    => science_ctrl_23      , -- in     std_logic                                 ; --! Science Data: Control channel 2/3
         i_science_data       => science_data         , -- in     t_slv_arr c_NB_COL+1 c_SC_DATA_SER_NB     ; --! Science Data: Serial Data

         i_sync               => sync(c_COL0)         , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_aqmde              => d_aqmde              , -- in     t_slv_arr c_NB_COL c_DFLD_AQMDE_S         ; --! Telemetry mode
         i_smfbd              => d_smfbd              , -- in     t_slv_arr c_NB_COL c_DFLD_SMFBD_COL_S     ; --! SQUID MUX feedback delay
         i_saomd              => d_saomd              , -- in     t_slv_arr c_NB_COL c_DFLD_SAOMD_COL_S     ; --! SQUID AMP offset MUX delay
         i_sqm_fbm_cls_lp_n   => d_sqm_fbm_cls_lp_n   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)
         i_sw_adc_vin         => (others => c_LOW_LEV), -- in     slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input

         i_sqm_adc_data       => (others => (others => c_LOW_LEV)),-- in t_slv_arr c_NB_COL c_SQM_ADC_DATA_S; --! SQUID MUX ADC: Data buses
         i_sqm_adc_oor        => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)

         i_frm_cnt_sc_rst     => frm_cnt_sc_rst       , -- in     std_logic                                 ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         i_adc_dmp_mem_add    => adc_dmp_mem_add      , -- in     slv(  c_MEM_SC_ADD_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   => adc_dmp_mem_data     , -- in     slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         i_science_mem_data   => science_mem_data     , -- in     slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! Science  memory for data compare: data
         i_adc_dmp_mem_cs     => adc_dmp_mem_cs       , -- in     std_logic                                 ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_sc_pkt_type        => sc_pkt_type          , -- out    t_slv_arr c_SC_PKT_W_NB c_SC_DATA_SER_W_S ; --! Science packet type
         o_sc_pkt_err         => sc_pkt_err             -- out    std_logic                                   --! Science packet error ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser
   -- ------------------------------------------------------------------------------------------------------
   I_parser: parser port map (
         o_arst_n             => open                 , -- out    std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => clk_ref(c_COL0)      , -- in     std_logic                                 ; --! Reference Clock
         i_sync               => sync(c_COL0)         , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_err_chk_rpt        => (others => (others => c_ZERO_INT)),-- in t_int_arr_tab c_CHK_ENA_CLK_NB    ; --! Clock check error reports
         i_err_n_spi_chk      => (others => (others => c_ZERO_INT)),-- in t_int_arr_tab c_CHK_ENA_SPI_NB    ; --! SPI check error number:
         i_err_num_pls_shp    => (others => c_ZERO_INT),-- in     integer_vector(0 to c_NB_COL-1)           ; --! Pulse shaping error number

         i_sqm_adc_pwdn       => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         i_sqm_adc_ana        => (others => c_ZERO_REAL),--in     real_vector(0 to c_NB_COL-1)              ; --! SQUID MUX ADC: Analog
         i_sqm_dac_sleep      => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqm_adc      => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqm_dac      => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqa_mux      => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              => c_LOW_LEV            , -- in     std_logic                                 ; --! Internal design: System Clock
         i_d_clk_sqm_adc_acq  => c_LOW_LEV            , -- in     std_logic                                 ; --! Internal design: SQUID MUX ADC acquisition Clock
         i_d_clk_sqm_pls_shap => c_LOW_LEV            , -- in     std_logic                                 ; --! Internal design: SQUID MUX pulse shaping Clock

         i_clk_sqm_adc        => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Clock
         i_clk_sqm_dac        => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Clock
         i_clk_science_01     => clk_science_01       , -- in     std_logic                                 ; --! Science Data: Clock channel 0/1
         i_clk_science_23     => clk_science_23       , -- in     std_logic                                 ; --! Science Data: Clock channel 2/3

         i_sc_pkt_type        => sc_pkt_type          , -- in     t_slv_arr c_SC_PKT_W_NB c_SC_DATA_SER_W_S ; --! Science packet type
         i_sc_pkt_err         => sc_pkt_err           , -- out    std_logic                                 ; --! Science packet error ('0' = No error, '1' = Error)

         i_ep_data_rx         => ep_data_rx           , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Receipted data
         i_ep_data_rx_rdy     => ep_data_rx_rdy       , -- in     std_logic                                 ; --! EP: Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             => ep_cmd               , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Command to send
         o_ep_cmd_start       => ep_cmd_start         , -- out    std_logic                                 ; --! EP: Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      => ep_cmd_busy_n        , -- in     std_logic                                 ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- out    slv log2_ceil(c_SER_WD_MAX_S+1)           ; --! EP: Serial word size

         o_brd_ref            => open                 , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         o_brd_model          => open                 , -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         o_ras_data_valid     => ras_data_valid       , -- out    std_logic                                 ; --! RAS Data valid ('0' = No, '1' = Yes)

         o_frm_cnt_sc_rst     => frm_cnt_sc_rst       , -- out    std_logic                                 ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         o_adc_dmp_mem_add    => adc_dmp_mem_add      , -- out    slv(  c_MEM_SC_ADD_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         o_adc_dmp_mem_data   => adc_dmp_mem_data     , -- out    slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         o_science_mem_data   => science_mem_data     , -- out    slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! Science  memory for data compare: data
         o_adc_dmp_mem_cs     => adc_dmp_mem_cs       , -- out    std_logic                                 ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_pls_shp_fc         => open                 , -- out    integer_vector(0 to c_NB_COL-1)           ; --! Pulse shaping cut frequency (Hz)
         o_sw_adc_vin         => open                 , -- out    slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input

         i_fpa_conf_busy      => fpa_conf_busy        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
         i_fpa_cmd_rdy        => fpa_cmd_rdy          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! FPASIM command ready ('0' = No, '1' = Yes)
         o_fpa_cmd            => fpa_cmd              , -- out    t_slv_arr(0 to c_NB_COL-1)                ; --! FPASIM command
         o_fpa_cmd_valid      => fpa_cmd_valid          -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! FPASIM command valid ('0' = No, '1' = Yes)
   );

end Simulation;
