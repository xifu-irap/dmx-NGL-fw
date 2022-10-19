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
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity top_dmx is port
   (     i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         o_clk_sqm_adc        : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Clock
         o_clk_sqm_dac        : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC: Clock
         o_clk_science_01     : out    std_logic                                                            ; --! Science Data: Clock channel 0/1
         o_clk_science_23     : out    std_logic                                                            ; --! Science Data: Clock channel 2/3

         i_brd_ref            : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         i_brd_model          : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_sqm_adc_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S-1 downto 0)              ; --! SQUID MUX ADC: Data
         i_sqm_adc_oor        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)
         o_sqm_dac_data       : out    t_slv_arr(0 to c_NB_COL-1)(c_SQM_DAC_DATA_S-1 downto 0)              ; --! SQUID MUX DAC: Data

         o_science_ctrl_01    : out    std_logic                                                            ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    : out    std_logic                                                            ; --! Science Data: Control channel 2/3
         o_science_data       : out    t_slv_arr(0 to c_NB_COL)(c_SC_DATA_SER_NB-1 downto 0)                ; --! Science Data: Serial Data

         i_hk1_spi_miso       : in     std_logic                                                            ; --! HouseKeeping 1: SPI Master Input Slave Output
         o_hk1_spi_mosi       : out    std_logic                                                            ; --! HouseKeeping 1: SPI Master Output Slave Input
         o_hk1_spi_sclk       : out    std_logic                                                            ; --! HouseKeeping 1: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_hk1_spi_cs_n       : out    std_logic                                                            ; --! HouseKeeping 1: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux            : out    std_logic_vector(c_HK_MUX_S-1 downto 0)                              ; --! HouseKeeping 1: Multiplexer
         o_hk1_mux_ena_n      : out    std_logic                                                            ; --! HouseKeeping 1: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        : in     std_logic                                                            ; --! EP: SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        : out    std_logic                                                            ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        : in     std_logic                                                            ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        : in     std_logic                                                            ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         b_sqm_adc_spi_sdio   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_pwdn       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         o_sqa_dac_data       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_sqa_dac_mux        : out    t_slv_arr(0 to c_NB_COL-1)(c_SQA_DAC_MUX_S downto 1)                 ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_mx_en_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)
    );
end entity top_dmx;

architecture RTL of top_dmx is
signal   arst                 : std_logic                                                                   ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   rst_sqm_adc_dac      : std_logic                                                                   ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
signal   rst_sqm_adc_dac_pd   :  std_logic                                                                  ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock

signal   clk                  : std_logic                                                                   ; --! System Clock
signal   clk_sqm_adc_dac      : std_logic                                                                   ; --! SQUID ADC/DAC internal Clock
signal   clk_90               : std_logic                                                                   ; --! System Clock 90 degrees shift
signal   clk_sqm_adc_dac_90   : std_logic                                                                   ; --! SQUID ADC/DAC internal 90 degrees shift

signal   brd_ref_rs           : std_logic_vector(  c_BRD_REF_S-1 downto 0)                                  ; --! Board reference, synchronized on System Clock
signal   brd_model_rs         : std_logic_vector(c_BRD_MODEL_S-1 downto 0)                                  ; --! Board model, synchronized on System Clock
signal   sync_rs              : std_logic_vector(     c_NB_COL   downto 0)                                  ; --! Pixel sequence synchronization, synchronized on System Clock

signal   hk1_spi_miso_rs      : std_logic                                                                   ; --! HouseKeeping 1: SPI Master Input Slave Output, synchronized on System Clock
signal   ep_spi_mosi_rs       : std_logic                                                                   ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
signal   ep_spi_sclk_rs       : std_logic                                                                   ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
signal   ep_spi_cs_n_rs       : std_logic                                                                   ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock

signal   sync_re              : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge

signal   cmd_ck_adc_ena       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
signal   cmd_ck_adc_dis       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
signal   cmd_ck_sqm_dac_ena   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
signal   cmd_ck_sqm_dac_dis   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

signal   sqm_mem_dump_add     : std_logic_vector( c_MEM_DUMP_ADD_S-1 downto 0)                              ; --! SQUID MUX Memory Dump: address
signal   sqm_mem_dump_data    : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)                     ; --! SQUID MUX Memory Dump: data
signal   sqm_mem_dump_bsy     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

signal   sqm_data_err         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DATA_ERR_S-1 downto 0)                     ; --! SQUID MUX Data error (signed)
signal   sqm_data_err_frst    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
signal   sqm_data_err_last    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
signal   sqm_data_err_rdy     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

signal   sqm_dta_pixel_pos    : t_slv_arr(0 to c_NB_COL-1)(c_MUX_FACT_S-1     downto 0)                     ; --! SQUID MUX Data error corrected pixel position
signal   sqm_dta_err_cor      : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DATA_FBK_S-1 downto 0)                     ; --! SQUID MUX Data error corrected (signed)
signal   sqm_dta_err_cor_cs   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

signal   sqm_data_sc_msb      : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)                    ; --! SQUID MUX Data science MSB
signal   sqm_data_sc_lsb      : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)                    ; --! SQUID MUX Data science LSB
signal   sqm_data_sc_first    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
signal   sqm_data_sc_last     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
signal   sqm_data_sc_rdy      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

signal   sqm_data_fbk         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DATA_FBK_S-1 downto 0)                     ; --! SQUID MUX Data feedback (signed)
signal   sqa_fbk_mux          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFF_PIX_S-1 downto 0)                   ; --! SQUID AMP Feedback Multiplexer
signal   sqa_fbk_off          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)                   ; --! SQUID AMP coarse offset

signal   ck_science           : std_logic                                                                   ; --! Science Data: Image Clock channel
signal   science_ctrl         : std_logic                                                                   ; --! Science Data: Control channel
signal   science_data_ser     : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                        ; --! Science Data: Serial Data

signal   ep_cmd_sts_err_add   : std_logic                                                                   ; --! EP command: Status, error invalid address
signal   ep_cmd_sts_err_nin   : std_logic                                                                   ; --! EP command: Status, error parameter to read not initialized yet
signal   ep_cmd_sts_err_dis   : std_logic                                                                   ; --! EP command: Status, error last SPI command discarded
signal   ep_cmd_sts_rg        : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: status register

signal   ep_cmd_rx_wd_add     : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared
signal   ep_cmd_rx_wd_data    : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word
signal   ep_cmd_rx_rw         : std_logic                                                                   ; --! EP command receipted: read/write bit
signal   ep_cmd_rx_nerr_rdy   : std_logic                                                                   ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

signal   ep_cmd_tx_wd_rd_rg   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command to transmit: read register word

signal   aqmde_dmp_tx_end     : std_logic                                                                   ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
signal   aqmde_tst_tx_end     : std_logic                                                                   ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)
signal   aqmde                : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Telemetry mode
signal   aqmde_dmp_cmp        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

signal   smfmd                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)                   ; --! SQUID MUX feedback mode
signal   saofm                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)                   ; --! SQUID AMP offset mode
signal   bxlgt                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)                   ; --! ADC sample number for averaging
signal   saofc                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)                   ; --! SQUID AMP lockpoint coarse offset
signal   saofl                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)                   ; --! SQUID AMP offset DAC LSB
signal   smfbd                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)                   ; --! SQUID MUX feedback delay
signal   saodd                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAODD_COL_S-1 downto 0)                   ; --! SQUID AMP offset DAC delay
signal   saomd                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)                   ; --! SQUID AMP offset MUX delay
signal   smpdl                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMPDL_COL_S-1 downto 0)                   ; --! ADC sample delay
signal   plsss                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSS_PLS_S-1 downto 0)                   ; --! SQUID MUX feedback pulse shaping set

signal   mem_parma            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_PARMA_ADD_S-1 downto 0),
                                data_w(c_DFLD_PARMA_PIX_S-1 downto 0))                                      ; --! SQUID MUX feedback value in open loop: memory inputs
signal   parma_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PARMA_PIX_S-1 downto 0)                   ; --! SQUID MUX feedback value in open loop: data read

signal   mem_kiknm            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_KIKNM_ADD_S-1 downto 0),
                                data_w(c_DFLD_KIKNM_PIX_S-1 downto 0))                                      ; --! SQUID MUX feedback value in open loop: memory inputs
signal   kiknm_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_KIKNM_PIX_S-1 downto 0)                   ; --! SQUID MUX feedback value in open loop: data read

signal   mem_knorm            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_KNORM_ADD_S-1 downto 0),
                                data_w(c_DFLD_KNORM_PIX_S-1 downto 0))                                      ; --! SQUID MUX feedback value in open loop: memory inputs
signal   knorm_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_KNORM_PIX_S-1 downto 0)                   ; --! SQUID MUX feedback value in open loop: data read

signal   mem_smfb0            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_SMFB0_ADD_S-1 downto 0),
                                data_w(c_DFLD_SMFB0_PIX_S-1 downto 0))                                      ; --! SQUID MUX feedback value in open loop: memory inputs
signal   smfb0_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFB0_PIX_S-1 downto 0)                   ; --! SQUID MUX feedback value in open loop: data read

signal   mem_smlkv            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_SMLKV_ADD_S-1 downto 0),
                                data_w(c_DFLD_SMLKV_PIX_S-1 downto 0))                                      ; --! SQUID MUX feedback value in open loop: memory inputs
signal   smlkv_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMLKV_PIX_S-1 downto 0)                   ; --! SQUID MUX feedback value in open loop: data read

signal   mem_smfbm            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_SMFBM_ADD_S-1 downto 0),
                                data_w(c_DFLD_SMFBM_PIX_S-1 downto 0))                                      ; --! SQUID MUX feedback mode: memory inputs
signal   smfbm_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBM_PIX_S-1 downto 0)                   ; --! SQUID MUX feedback mode: data read

signal   mem_saoff            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_SAOFF_ADD_S-1 downto 0),
                                data_w(c_DFLD_SAOFF_PIX_S-1 downto 0))                                      ; --! SQUID AMP lockpoint fine offset: memory inputs
signal   saoff_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFF_PIX_S-1 downto 0)                   ; --! SQUID AMP lockpoint fine offset: data read

signal   mem_plssh            : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_PLSSH_ADD_S-1 downto 0),
                                data_w(c_DFLD_PLSSH_PLS_S-1 downto 0))                                      ; --! SQUID MUX feedback pulse shaping coefficient: memory inputs
signal   plssh_data           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSH_PLS_S-1 downto 0)                   ; --! SQUID MUX feedback pulse shaping coefficient: data read

signal   init_fbk_pixel_pos   : t_slv_arr(0 to c_NB_COL-1)(c_MUX_FACT_S-1 downto 0)                         ; --! Initialization feedback chain accumulators Pixel position
signal   init_fbk_acc         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Initialization feedback chain accumulators ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Manage the internal reset and generate the clocks
   -- ------------------------------------------------------------------------------------------------------
   arst <= not(i_arst_n);

   I_rst_clk_mgt: entity work.rst_clk_mgt port map
   (     i_arst               => arst                 , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock

         i_cmd_ck_adc_ena     => cmd_ck_adc_ena       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_adc_dis     => cmd_ck_adc_dis       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         i_cmd_ck_sqm_dac_ena => cmd_ck_sqm_dac_ena   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_sqm_dac_dis => cmd_ck_sqm_dac_dis   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         o_rst                => rst                  , -- out    std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         o_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- out    std_logic                                 ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         o_rst_sqm_adc_dac_pd => rst_sqm_adc_dac_pd   , -- out    std_logic                                 ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock

         o_clk                => clk                  , -- out    std_logic                                 ; --! System Clock
         o_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- out    std_logic                                 ; --! SQUID ADC/DAC internal Clock

         o_ck_sqm_adc         => o_clk_sqm_adc        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Image Clocks
         o_ck_sqm_dac         => o_clk_sqm_dac        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Image Clocks
         o_ck_science         => ck_science           , -- out    std_logic                                 ; --! Science Data Image Clock

         o_clk_90             => clk_90               , -- out    std_logic                                 ; --! System Clock 90 degrees shift
         o_clk_sqm_adc_dac_90 => clk_sqm_adc_dac_90   , -- out    std_logic                                 ; --! SQUID ADC/DAC internal 90 degrees shift

         o_sqm_adc_pwdn       => o_sqm_adc_pwdn       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      => o_sqm_dac_sleep        -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)
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

         i_hk1_spi_miso       => i_hk1_spi_miso       , -- in     std_logic                                 ; --! HouseKeeping 1: SPI Master Input Slave Output

         i_ep_spi_mosi        => i_ep_spi_mosi        , -- in     std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first)
         i_ep_spi_sclk        => i_ep_spi_sclk        , -- in     std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        => i_ep_spi_cs_n        , -- in     std_logic                                 ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_brd_ref_rs         => brd_ref_rs           , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference, synchronized on System Clock
         o_brd_model_rs       => brd_model_rs         , -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model, synchronized on System Clock
         o_sync_rs            => sync_rs              , -- out    std_logic_vector(     c_NB_COL   downto 0); --! Pixel sequence synchronization, synchronized on System Clock

         o_hk1_spi_miso_rs    => hk1_spi_miso_rs      , -- out    std_logic                                 ; --! HouseKeeping 1: SPI Master Input Slave Output, synchronized on System Clock

         o_ep_spi_mosi_rs     => ep_spi_mosi_rs       , -- out    std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
         o_ep_spi_sclk_rs     => ep_spi_sclk_rs       , -- out    std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
         o_ep_spi_cs_n_rs     => ep_spi_cs_n_rs         -- out    std_logic                                   --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Management
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_mgt: entity work.science_data_mgt port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_aqmde              => aqmde                , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode

         i_sqm_data_sc_msb    => sqm_data_sc_msb      , -- in     t_slv_arr c_NB_COL c_SC_DATA_SER_W_S      ; --! SQUID MUX Data science MSB
         i_sqm_data_sc_lsb    => sqm_data_sc_lsb      , -- in     t_slv_arr c_NB_COL c_SC_DATA_SER_W_S      ; --! SQUID MUX Data science LSB
         i_sqm_data_sc_first  => sqm_data_sc_first    , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_last   => sqm_data_sc_last     , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_rdy    => sqm_data_sc_rdy      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         i_sqm_mem_dump_bsy   => sqm_mem_dump_bsy(0)  , -- in     std_logic                                 ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)
         o_sqm_mem_dump_add   => sqm_mem_dump_add     , -- out    slv(c_MEM_DUMP_ADD_S-1 downto 0)          ; --! SQUID MUX Memory Dump: address
         i_sqm_mem_dump_data  => sqm_mem_dump_data    , -- in     t_slv_arr c_NB_COL c_SQM_ADC_DATA_S+1     ; --! SQUID MUX Memory Dump: data

         o_aqmde_dmp_tx_end   => aqmde_dmp_tx_end     , -- out    std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         o_aqmde_tst_tx_end   => aqmde_tst_tx_end     , -- out    std_logic                                 ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)

         o_science_data_ser   => science_data_ser       -- out    slv       c_NB_COL*c_SC_DATA_SER_NB         --! Science Data: Serial Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Registers management
   -- ------------------------------------------------------------------------------------------------------
   I_register_mgt: entity work.register_mgt port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_brd_ref_rs         => brd_ref_rs           , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference, synchronized on System Clock
         i_brd_model_rs       => brd_model_rs         , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model, synchronized on System Clock

         o_ep_cmd_sts_err_add => ep_cmd_sts_err_add   , -- out    std_logic                                 ; --! EP command: Status, error invalid address
         o_ep_cmd_sts_err_nin => ep_cmd_sts_err_nin   , -- out    std_logic                                 ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis => ep_cmd_sts_err_dis   , -- out    std_logic                                 ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      => ep_cmd_sts_rg        , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command: Status register

         i_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add     , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy   , -- in     std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg => ep_cmd_tx_wd_rd_rg   , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command to transmit: read register word

         i_aqmde_dmp_tx_end   => aqmde_dmp_tx_end     , -- in     std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         i_aqmde_tst_tx_end   => aqmde_tst_tx_end     , -- in     std_logic                                 ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)
         o_aqmde              => aqmde                , -- out    slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         o_aqmde_dmp_cmp      => aqmde_dmp_cmp        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

         o_smfmd              => smfmd                , -- out    t_slv_arr c_NB_COL c_DFLD_SMFMD_COL_S     ; --! SQUID MUX feedback mode
         o_saofm              => saofm                , -- out    t_slv_arr c_NB_COL c_DFLD_SAOFM_COL_S     ; --! SQUID AMP offset mode
         o_bxlgt              => bxlgt                , -- out    t_slv_arr c_NB_COL c_DFLD_BXLGT_COL_S     ; --! ADC sample number for averaging
         o_saofc              => saofc                , -- out    t_slv_arr c_NB_COL c_DFLD_SAOFC_COL_S     ; --! SQUID AMP lockpoint coarse offset
         o_saofl              => saofl                , -- out    t_slv_arr c_NB_COL c_DFLD_SAOFC_COL_S     ; --! SQUID AMP offset DAC LSB
         o_smfbd              => smfbd                , -- out    t_slv_arr c_NB_COL c_DFLD_SMFBD_COL_S     ; --! SQUID MUX feedback delay
         o_saodd              => saodd                , -- out    t_slv_arr c_NB_COL c_DFLD_SAODD_COL_S     ; --! SQUID AMP offset DAC delay
         o_saomd              => saomd                , -- out    t_slv_arr c_NB_COL c_DFLD_SAOMD_COL_S     ; --! SQUID AMP offset MUX delay
         o_smpdl              => smpdl                , -- out    t_slv_arr c_NB_COL c_DFLD_SMPDL_COL_S     ; --! ADC sample delay
         o_plsss              => plsss                , -- out    t_slv_arr c_NB_COL c_DFLD_PLSSS_PLS_S     ; --! SQUID MUX feedback pulse shaping set

         o_mem_parma          => mem_parma            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback value in open loop: memory inputs
         i_parma_data         => parma_data           , -- in     t_slv_arr c_NB_COL c_DFLD_PARMA_PIX_S     ; --! SQUID MUX feedback value in open loop: data read

         o_mem_kiknm          => mem_kiknm            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback value in open loop: memory inputs
         i_kiknm_data         => kiknm_data           , -- in     t_slv_arr c_NB_COL c_DFLD_KIKNM_PIX_S     ; --! SQUID MUX feedback value in open loop: data read

         o_mem_knorm          => mem_knorm            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback value in open loop: memory inputs
         i_knorm_data         => knorm_data           , -- in     t_slv_arr c_NB_COL c_DFLD_KNORM_PIX_S     ; --! SQUID MUX feedback value in open loop: data read

         o_mem_smfb0          => mem_smfb0            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback value in open loop: memory inputs
         i_smfb0_data         => smfb0_data           , -- in     t_slv_arr c_NB_COL c_DFLD_SMFB0_PIX_S     ; --! SQUID MUX feedback value in open loop: data read

         o_mem_smlkv          => mem_smlkv            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback value in open loop: memory inputs
         i_smlkv_data         => smlkv_data           , -- in     t_slv_arr c_NB_COL c_DFLD_SMLKV_PIX_S     ; --! SQUID MUX feedback value in open loop: data read

         o_mem_smfbm          => mem_smfbm            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback mode: memory inputs
         i_smfbm_data         => smfbm_data           , -- in     t_slv_arr c_NB_COL c_DFLD_SMFBM_PIX_S     ; --! SQUID MUX feedback mode: data read

         o_mem_saoff          => mem_saoff            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID AMP lockpoint fine offset: memory inputs
         i_saoff_data         => saoff_data           , -- in     t_slv_arr c_NB_COL c_DFLD_SAOFF_PIX_S     ; --! SQUID AMP lockpoint fine offset: data read

         o_mem_plssh          => mem_plssh            , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! SQUID MUX feedback pulse shaping coefficient: memory inputs
         i_plssh_data         => plssh_data             -- in     t_slv_arr c_NB_COL c_DFLD_PLSSH_PLS_S       --! SQUID MUX feedback pulse shaping coefficient: data read
      );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command
   -- ------------------------------------------------------------------------------------------------------
   I_ep_cmd: entity work.ep_cmd port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_sts_err_add => ep_cmd_sts_err_add   , -- in     std_logic                                 ; --! EP command: Status, error invalid address
         i_ep_cmd_sts_err_nin => ep_cmd_sts_err_nin   , -- in     std_logic                                 ; --! EP command: Status, error parameter to read not initialized yet
         i_ep_cmd_sts_err_dis => ep_cmd_sts_err_dis   , -- in     std_logic                                 ; --! EP command: Status, error last SPI command discarded
         o_ep_cmd_sts_rg      => ep_cmd_sts_rg        , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command: Status register

         o_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add     , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         o_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         o_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- out    std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy   , -- out    std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         i_ep_cmd_tx_wd_rd_rg => ep_cmd_tx_wd_rd_rg   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command to transmit: read register word

         o_ep_spi_miso        => o_ep_spi_miso        , -- out    std_logic                                 ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_mosi_rs     => ep_spi_mosi_rs       , -- in     std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
         i_ep_spi_sclk_rs     => ep_spi_sclk_rs       , -- in     std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
         i_ep_spi_cs_n_rs     => ep_spi_cs_n_rs         -- in     std_logic                                   --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX commands
   -- ------------------------------------------------------------------------------------------------------
   I_dmx_cmd: entity work.dmx_cmd port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_sync_rs            => sync_rs(sync_rs'high), -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_aqmde              => aqmde                , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         i_smfmd              => smfmd                , -- in     t_slv_arr c_NB_COL c_DFLD_SMFMD_COL_S     ; --! SQUID MUX feedback mode
         o_sync_re            => sync_re              , -- out    std_logic                                 ; --! Pixel sequence synchronization, rising edge
         o_cmd_ck_adc_ena     => cmd_ck_adc_ena       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_adc_dis     => cmd_ck_adc_dis       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
         o_cmd_ck_sqm_dac_ena => cmd_ck_sqm_dac_ena   , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_sqm_dac_dis => cmd_ck_sqm_dac_dis     -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Housekeeping management
   -- ------------------------------------------------------------------------------------------------------
   I_hk_mgt: entity work.hk_mgt port map
   (     i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_hk1_spi_miso_rs    => hk1_spi_miso_rs      , -- in     std_logic                                 ; --! HouseKeeping 1: SPI Master Input Slave Output
         o_hk1_spi_mosi       => o_hk1_spi_mosi       , -- out    std_logic                                 ; --! HouseKeeping 1: SPI Master Output Slave Input
         o_hk1_spi_sclk       => o_hk1_spi_sclk       , -- out    std_logic                                 ; --! HouseKeeping 1: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_hk1_spi_cs_n       => o_hk1_spi_cs_n       , -- out    std_logic                                 ; --! HouseKeeping 1: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk1_mux            => o_hk1_mux            , -- out    std_logic_vector( cc_HK_MUX_S-1 downto 0) ; --! HouseKeeping 1: Multiplexer
         o_hk1_mux_ena_n      => o_hk1_mux_ena_n        -- out    std_logic                                   --! HouseKeeping 1: Multiplexer Enable ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Columns management
   --    @Req : DRE-DMX-FW-REQ-0070
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      I_squid_adc_mgt: entity work.squid_adc_mgt port map
      (  i_rst_sqm_adc_dac_pd => rst_sqm_adc_dac_pd   , -- in     std_logic                                 ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => sync_rs(c_FPGA_POS_ADC(k)), --in std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_aqmde_dmp_cmp      => aqmde_dmp_cmp(k)     , -- in     std_logic                                 ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_bxlgt              => bxlgt(k)             , -- in     slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging
         i_smpdl              => smpdl(k)             , -- in     slv(c_DFLD_SMPDL_COL_S-1 downto 0)        ; --! ADC sample delay
         i_sqm_adc_data       => i_sqm_adc_data(k)    , -- in     slv(c_SQM_ADC_DATA_S-1 downto 0)          ; --! SQUID MUX ADC: Data, no rsync
         i_sqm_adc_oor        => i_sqm_adc_oor(k)     , -- in     std_logic                                 ; --! SQUID MUX ADC: Out of range, no rsync ('0'= No, '1'= under/over range)

         i_sqm_mem_dump_add   => sqm_mem_dump_add     , -- in     slv(c_MEM_DUMP_ADD_S-1 downto 0)          ; --! SQUID MUX Memory Dump: address
         o_sqm_mem_dump_data  => sqm_mem_dump_data(k) , -- out    slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! SQUID MUX Memory Dump: data
         o_sqm_mem_dump_bsy   => sqm_mem_dump_bsy(k)  , -- out    std_logic                                 ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

         o_sqm_data_err       => sqm_data_err(k)      , -- out    slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error
         o_sqm_data_err_frst  => sqm_data_err_frst(k) , -- out    std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         o_sqm_data_err_last  => sqm_data_err_last(k) , -- out    std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         o_sqm_data_err_rdy   => sqm_data_err_rdy(k)    -- out    std_logic                                   --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)
      );

      I_squid_data_proc: entity work.squid_data_proc port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_aqmde              => aqmde                , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         i_smfmd              => smfmd(k)             , -- in     slv(c_DFLD_SMFMD_COL_S-1 downto 0)        ; --! SQUID MUX feedback mode
         i_bxlgt              => bxlgt(k)             , -- in     slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging
         i_sqm_adc_pwdn       => o_sqm_adc_pwdn(k)    , -- in     std_logic                                 ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)

         i_mem_parma          => mem_parma(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback value in open loop: memory inputs
         o_parma_data         => parma_data(k)        , -- out    slv(c_DFLD_PARMA_PIX_S-1 downto 0)        ; --! SQUID MUX feedback value in open loop: data read

         i_mem_kiknm          => mem_kiknm(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback value in open loop: memory inputs
         o_kiknm_data         => kiknm_data(k)        , -- out    slv(c_DFLD_KIKNM_PIX_S-1 downto 0)        ; --! SQUID MUX feedback value in open loop: data read

         i_mem_knorm          => mem_knorm(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback value in open loop: memory inputs
         o_knorm_data         => knorm_data(k)        , -- out    slv(c_DFLD_KNORM_PIX_S-1 downto 0)        ; --! SQUID MUX feedback value in open loop: data read

         i_mem_smlkv          => mem_smlkv(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback value in open loop: memory inputs
         o_smlkv_data         => smlkv_data(k)        , -- out    slv(c_DFLD_SMLKV_PIX_S-1 downto 0)        ; --! SQUID MUX feedback value in open loop: data read

         i_init_fbk_pixel_pos => init_fbk_pixel_pos(k), -- in     slv(c_MUX_FACT_S-1 downto 0)              ; --! Initialization feedback chain accumulators Pixel position
         i_init_fbk_acc       => init_fbk_acc(k)      , -- in     std_logic                                 ; --! Initialization feedback chain accumulators ('0' = Inactive, '1' = Active)

         i_sqm_data_err       => sqm_data_err(k)      , -- in     slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error
         i_sqm_data_err_frst  => sqm_data_err_frst(k) , -- in     std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  => sqm_data_err_last(k) , -- in     std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   => sqm_data_err_rdy(k)  , -- in     std_logic                                 ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_sqm_data_sc_msb    => sqm_data_sc_msb(k)   , -- out    slv(c_SC_DATA_SER_W_S-1 downto 0)         ; --! SQUID MUX Data science MSB
         o_sqm_data_sc_lsb    => sqm_data_sc_lsb(k)   , -- out    slv(c_SC_DATA_SER_W_S-1 downto 0)         ; --! SQUID MUX Data science LSB
         o_sqm_data_sc_first  => sqm_data_sc_first(k) , -- out    std_logic                                 ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   => sqm_data_sc_last(k)  , -- out    std_logic                                 ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    => sqm_data_sc_rdy(k)   , -- out    std_logic                                 ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_sqm_dta_pixel_pos  => sqm_dta_pixel_pos(k) , -- out    slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_cor    => sqm_dta_err_cor(k)   , -- out    slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)
         o_sqm_dta_err_cor_cs => sqm_dta_err_cor_cs(k)   -- out    std_logic                                   --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)
      );

      I_sqm_fbk_mgt: entity work.sqm_fbk_mgt port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge

         i_sqm_dta_pixel_pos  => sqm_dta_pixel_pos(k) , -- in     slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID MUX Data error corrected pixel position
         i_sqm_dta_err_cor    => sqm_dta_err_cor(k)   , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)
         i_sqm_dta_err_cor_cs => sqm_dta_err_cor_cs(k), -- in     std_logic                                 ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_smfb0          => mem_smfb0(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback value in open loop: memory inputs
         o_smfb0_data         => smfb0_data(k)        , -- out    slv(c_DFLD_SMFB0_PIX_S-1 downto 0)        ; --! SQUID MUX feedback value in open loop: data read

         i_smfmd              => smfmd(k)             , -- in     slv(c_DFLD_SMFMD_COL_S-1 downto 0)        ; --! SQUID MUX feedback mode
         i_smfbd              => smfbd(k)             , -- in     slv(c_DFLD_SMFBD_COL_S-1 downto 0)        ; --! SQUID MUX feedback delay
         i_mem_smfbm          => mem_smfbm(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback mode: memory inputs
         o_smfbm_data         => smfbm_data(k)        , -- out    slv(c_DFLD_SMFBM_PIX_S-1 downto 0)        ; --! SQUID MUX feedback mode: data read

         o_sqm_data_fbk       => sqm_data_fbk(k)      , -- out    slv( c_SQM_DATA_FBK_S-1 downto 0)         ; --! SQUID MUX Data feedback (signed)

         o_init_fbk_pixel_pos => init_fbk_pixel_pos(k), -- out    slv(c_MUX_FACT_S-1 downto 0)              ; --! Initialization feedback chain accumulators Pixel position
         o_init_fbk_acc       => init_fbk_acc(k)        -- out    std_logic                                   --! Initialization feedback chain accumulators ('0' = Inactive, '1' = Active)
      );

      I_sqm_dac_mgt: entity work.sqm_dac_mgt port map
      (  i_rst_sqm_adc_dac_pd => rst_sqm_adc_dac_pd   , -- in     std_logic                                 ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID MUX DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock
         i_clk_sqm_adc_dac_90 => clk_sqm_adc_dac_90   , -- in     std_logic                                 ; --! SQUID ADC/DAC internal 90 degrees shift

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_rs            => sync_rs(c_FPGA_POS_SQM_DAC(k)), -- in     std_logic                        ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sqm_data_fbk       => sqm_data_fbk(k)      , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data feedback
         i_plsss              => plsss(k)             , -- in     slv(c_DFLD_PLSSS_PLS_S  -1 downto 0)      ; --! SQUID MUX feedback pulse shaping set
         i_smfbd              => smfbd(k)             , -- in     slv(c_DFLD_SMFBD_COL_S  -1 downto 0)      ; --! SQUID MUX feedback delay

         i_mem_plssh          => mem_plssh(k)         , -- in     t_mem                                     ; --! SQUID MUX feedback pulse shaping coefficient: memory inputs
         o_plssh_data         => plssh_data(k)        , -- out    slv(c_DFLD_PLSSH_PLS_S-1 downto 0)        ; --! SQUID MUX feedback pulse shaping coefficient: data read

         o_sqm_dac_data       => o_sqm_dac_data(k)      -- out    slv(c_SQM_DAC_DATA_S-1 downto 0)            --! SQUID MUX DAC: Data
      );

      I_sqa_fbk_mgt: entity work.sqa_fbk_mgt port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge

         i_saofm              => saofm(k)             , -- in     slv(c_DFLD_SAOFM_COL_S-1 downto 0)        ; --! SQUID AMP offset mode
         i_saofc              => saofc(k)             , -- in     slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! SQUID AMP lockpoint coarse offset
         i_saomd              => saomd(k)             , -- in     slv(c_DFLD_SAOMD_COL_S-1 downto 0)        ; --! SQUID AMP offset MUX delay
         i_sqm_dta_err_cor    => sqm_dta_err_cor(k)   , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)

         i_mem_saoff          => mem_saoff(k)         , -- in     t_mem                                     ; --! SQUID AMP lockpoint fine offset: memory inputs
         o_saoff_data         => saoff_data(k)        , -- out    slv(c_DFLD_SAOFF_PIX_S  -1 downto 0)      ; --! SQUID AMP lockpoint fine offset: data read

         o_sqa_fbk_mux        => sqa_fbk_mux(k)       , -- out    slv(c_DFLD_SAOFF_PIX_S-1 downto 0)        ; --! SQUID AMP Feedback Multiplexer
         o_sqa_fbk_off        => sqa_fbk_off(k)         -- out    slv(c_DFLD_SAOFC_COL_S-1 downto 0)          --! SQUID AMP coarse offset
      );

      I_sqa_dac_mgt: entity work.sqa_dac_mgt port map
      (  i_rst_sqm_adc_dac_pd => rst_sqm_adc_dac_pd   , -- in     std_logic                                 ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID AMP DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => sync_rs(c_FPGA_POS_SQM_DAC(k)), -- in     std_logic                        ; --! Pixel sequence synchronization, synchronized on System Clock
         i_saofl              => saofl(k)             , -- in     slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! SQUID AMP offset DAC LSB
         i_sqa_fbk_mux        => sqa_fbk_mux(k)       , -- in     slv(c_DFLD_SAOFF_PIX_S-1 downto 0)        ; --! SQUID AMP Feedback Multiplexer
         i_sqa_fbk_off        => sqa_fbk_off(k)       , -- in     slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! SQUID AMP coarse offset
         i_saodd              => saodd(k)             , -- in     slv(c_DFLD_SAODD_COL_S-1 downto 0)        ; --! SQUID AMP offset DAC delay
         i_saomd              => saomd(k)             , -- in     slv(c_DFLD_SAOMD_COL_S-1 downto 0)        ; --! SQUID AMP offset MUX delay

         o_sqa_dac_mux        => o_sqa_dac_mux(k)     , -- out    slv(c_SQA_DAC_MUX_S -1 downto 0)          ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_data       => o_sqa_dac_data(k)    , -- out    std_logic                                 ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       => o_sqa_dac_sclk(k)    , -- out    std_logic                                 ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    => o_sqa_dac_snc_l_n(k) , -- out    std_logic                                 ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    => o_sqa_dac_snc_o_n(k)   -- out    std_logic                                   --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
      );

      I_sqm_spi_mgt: entity work.sqm_spi_mgt port map
      (  o_sqm_adc_spi_mosi   => b_sqm_adc_spi_sdio(k), -- out    std_logic                                 ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   => o_sqm_adc_spi_sclk(k), -- out    std_logic                                 ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   => o_sqm_adc_spi_cs_n(k)  -- out    std_logic                                   --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)
      );

      o_science_data(k) <= science_data_ser((k+1)*c_SC_DATA_SER_NB-1 downto k*c_SC_DATA_SER_NB);

   end generate G_column_mgt;

   o_sqa_dac_mx_en_n <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data outputs association
   -- ------------------------------------------------------------------------------------------------------
   o_clk_science_01     <= ck_science;
   o_clk_science_23     <= ck_science;

   o_science_ctrl_01    <= science_data_ser(4*c_SC_DATA_SER_NB);
   o_science_ctrl_23    <= science_data_ser(4*c_SC_DATA_SER_NB);

   o_science_data(o_science_data'high) <= (others => '0');

end architecture rtl;
