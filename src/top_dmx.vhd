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
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity top_dmx is port
   (     i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         o_clk_sq1_adc        : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC: Clock
         o_clk_sq1_dac        : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 DAC: Clock
         o_clk_science_01     : out    std_logic                                                            ; --! Science Data: Clock channel 0/1
         o_clk_science_23     : out    std_logic                                                            ; --! Science Data: Clock channel 2/3

         i_brd_ref            : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         i_brd_model          : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_sq1_adc_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_SQ1_ADC_DATA_S-1 downto 0)              ; --! SQUID1 ADC: Data
         i_sq1_adc_oor        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC: Out of range ('0' = No, '1' = under/over range)
         o_sq1_dac_data       : out    t_slv_arr(0 to c_NB_COL-1)(c_SQ1_DAC_DATA_S-1 downto 0)              ; --! SQUID1 DAC: Data

         o_science_ctrl_01    : out    std_logic                                                            ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    : out    std_logic                                                            ; --! Science Data: Control channel 2/3
         o_science_data       : out    t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB-1 downto 0)              ; --! Science Data: Serial Data

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

         b_sq1_adc_spi_sdio   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC: SPI Serial Data In Out
         o_sq1_adc_spi_sclk   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sq1_adc_spi_cs_n   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sq1_adc_pwdn       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sq1_dac_sleep      : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 DAC: Sleep ('0' = Inactive, '1' = Active)

         o_sq2_dac_data       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID2 DAC: Serial Data
         o_sq2_dac_sclk       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID2 DAC: Serial Clock
         o_sq2_dac_snc_l_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID2 DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sq2_dac_snc_o_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID2 DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_sq2_dac_mux        : out    t_slv_arr(0 to c_NB_COL-1)(c_SQ2_DAC_MUX_S downto 1)                 ; --! SQUID2 DAC: Multiplexer
         o_sq2_dac_mx_en_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID2 DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)
    );
end entity top_dmx;

architecture RTL of top_dmx is
signal   arst                 : std_logic                                                                   ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   rst_sys_sq1_adc      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Reset for SQUID1 ADC, de-assertion on system clock ('0' = Inactive, '1' = Active)
signal   rst_sys_sq1_dac      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Reset for SQUID1 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
signal   rst_sys_sq2_dac      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Reset for SQUID2 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)

signal   clk                  : std_logic                                                                   ; --! System Clock
signal   clk_sq1_adc_dac      : std_logic                                                                   ; --! SQUID1 ADC/DAC internal Clock
signal   clk_90               : std_logic                                                                   ; --! System Clock 90 degrees shift
signal   clk_sq1_adc_dac_90   : std_logic                                                                   ; --! SQUID1 ADC/DAC internal 90 degrees shift

signal   brd_ref_rs           : std_logic_vector(  c_BRD_REF_S-1 downto 0)                                  ; --! Board reference, synchronized on System Clock
signal   brd_model_rs         : std_logic_vector(c_BRD_MODEL_S-1 downto 0)                                  ; --! Board model, synchronized on System Clock
signal   sync_rs              : std_logic                                                                   ; --! Pixel sequence synchronization, synchronized on System Clock
signal   sync_sq1_adc_rs      : std_logic_vector(     c_NB_COL-1 downto 0)                                  ; --! Pixel sequence synchronization for squid1 ADC, synchronized on System Clock
signal   sync_sq1_dac_rs      : std_logic_vector(     c_NB_COL-1 downto 0)                                  ; --! Pixel sequence synchronization for squid1 DAC, synchronized on System Clock
signal   sync_sq2_dac_rs      : std_logic_vector(     c_NB_COL-1 downto 0)                                  ; --! Pixel sequence synchronization for squid2 DAC, synchronized on System Clock

signal   hk1_spi_miso_rs      : std_logic                                                                   ; --! HouseKeeping 1: SPI Master Input Slave Output, synchronized on System Clock
signal   ep_spi_mosi_rs       : std_logic                                                                   ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
signal   ep_spi_sclk_rs       : std_logic                                                                   ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
signal   ep_spi_cs_n_rs       : std_logic                                                                   ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock

signal   sync_re              : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge

signal   cmd_ck_s1_adc_ena    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
signal   cmd_ck_s1_adc_dis    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
signal   cmd_ck_s1_dac_ena    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
signal   cmd_ck_s1_dac_dis    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

signal   sq1_mem_dump_add     : std_logic_vector( c_MEM_DUMP_ADD_S-1 downto 0)                              ; --! SQUID1 Memory Dump: address
signal   sq1_mem_dump_data    : t_slv_arr(0 to c_NB_COL-1)(c_SQ1_ADC_DATA_S+1 downto 0)                     ; --! SQUID1 Memory Dump: data
signal   sq1_mem_dump_bsy     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

signal   sq1_data_err         : t_slv_arr(0 to c_NB_COL-1)(c_SQ1_DATA_ERR_S-1 downto 0)                     ; --! SQUID1 Data error (signed)

signal   s1_dta_pixel_pos     : t_slv_arr(0 to c_NB_COL-1)(c_MUX_FACT_S-1     downto 0)                     ; --! SQUID1 Data error corrected pixel position
signal   s1_dta_err_cor       : t_slv_arr(0 to c_NB_COL-1)(c_SQ1_DATA_FBK_S-1 downto 0)                     ; --! SQUID1 Data error corrected (signed)
signal   s1_dta_err_cor_cs    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data error corrected chip select ('0' = Inactive, '1' = Active)

signal   sq1_data_sc_msb      : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)                    ; --! SQUID1 Data science MSB
signal   sq1_data_sc_lsb      : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)                    ; --! SQUID1 Data science LSB
signal   sq1_data_sc_first    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science first pixel ('0' = No, '1' = Yes)
signal   sq1_data_sc_last     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science last pixel ('0' = No, '1' = Yes)
signal   sq1_data_sc_rdy      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science ready ('0' = Not ready, '1' = Ready)

signal   sq1_data_fbk         : t_slv_arr(0 to c_NB_COL-1)(c_SQ1_DATA_FBK_S-1 downto 0)                     ; --! SQUID1 Data feedback (signed)
signal   sq2_fbk_mux          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2LKP_PIX_S-1 downto 0)                   ; --! Squid2 Feedback Multiplexer
signal   sq2_fbk_off          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S-1 downto 0)                   ; --! Squid2 Feedback offset

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

signal   tm_mode_dmp_tx_end   : std_logic                                                                   ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
signal   tm_mode_tst_tx_end   : std_logic                                                                   ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)
signal   tm_mode              : std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0)                               ; --! Telemetry mode
signal   tm_mode_dmp_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

signal   sq1_fb_mode          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ1FBMD_COL_S-1 downto 0)                 ; --! Squid 1 Feedback mode (on/off)
signal   sq1_fb_pls_set       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ1FBMD_PLS_S-1 downto 0)                 ; --! Squid 1 Feedback Pulse shaping set
signal   sq2_fb_mode          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ2FBMD_COL_S-1 downto 0)                 ; --! Squid 2 Feedback mode
signal   sq2_dac_lsb          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S  -1 downto 0)                 ; --! Squid 2 DAC LSB
signal   sq2_lkp_off          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S  -1 downto 0)                 ; --! Squid 2 Feedback lockpoint offset
signal   sq1_fb_del           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FBD_COL_S  -1 downto 0)                 ; --! Squid 1 Feedback delay
signal   sq_off_dac_del       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2DCD_COL_S  -1 downto 0)                 ; --! Squid offset DAC delay
signal   sq_off_mux_del       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2MXD_COL_S  -1 downto 0)                 ; --! Squid offset MUX delay

signal   mem_sq1_fb0          : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_S1FB0_ADD_S-1 downto 0),
                                data_w(c_DFLD_S1FB0_PIX_S-1 downto 0))                                      ; --! Squid1 feedback value in open loop: memory inputs
signal   sq1_fb0_data         : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FB0_PIX_S-1 downto 0)                   ; --! Squid1 feedback value in open loop: data read

signal   mem_sq1_fbm          : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_S1FBM_ADD_S-1 downto 0),
                                data_w(c_DFLD_S1FBM_PIX_S-1 downto 0))                                      ; --! Squid1 feedback mode: memory inputs
signal   sq1_fbm_data         : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FBM_PIX_S-1 downto 0)                   ; --! Squid1 feedback mode: data read

signal   mem_sq2_lkp          : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_S2LKP_ADD_S-1 downto 0),
                                data_w(c_DFLD_S2LKP_PIX_S-1 downto 0))                                      ; --! Squid2 feedback lockpoint: memory inputs
signal   sq2_lkp_data         : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2LKP_PIX_S-1 downto 0)                   ; --! Squid2 feedback lockpoint: data read

signal   mem_pls_shp          : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_PLSSH_ADD_S-1 downto 0),
                                data_w(c_DFLD_PLSSH_PLS_S-1 downto 0))                                      ; --! Pulse shaping coef: memory inputs
signal   pls_shp_data         : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSH_PLS_S-1 downto 0)                   ; --! Pulse shaping coef: data read

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Manage the internal reset and generate the clocks
   -- ------------------------------------------------------------------------------------------------------
   arst <= not(i_arst_n);

   I_rst_clk_mgt: entity work.rst_clk_mgt port map
   (     i_arst               => arst                 , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock

         i_cmd_ck_s1_adc_ena  => cmd_ck_s1_adc_ena    , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_s1_adc_dis  => cmd_ck_s1_adc_dis    , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         i_cmd_ck_s1_dac_ena  => cmd_ck_s1_dac_ena    , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_s1_dac_dis  => cmd_ck_s1_dac_dis    , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         o_rst                => rst                  , -- out    std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         o_rst_sys_sq1_adc    => rst_sys_sq1_adc      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Reset for SQUID1 ADC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         o_rst_sys_sq1_dac    => rst_sys_sq1_dac      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Reset for SQUID1 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         o_rst_sys_sq2_dac    => rst_sys_sq2_dac      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Reset for SQUID2 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)

         o_clk                => clk                  , -- out    std_logic                                 ; --! System Clock
         o_clk_sq1_adc_dac    => clk_sq1_adc_dac      , -- out    std_logic                                 ; --! SQUID1 ADC/DAC internal Clock

         o_ck_sq1_adc         => o_clk_sq1_adc        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Image Clocks
         o_ck_sq1_dac         => o_clk_sq1_dac        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Image Clocks
         o_ck_science         => ck_science           , -- out    std_logic                                 ; --! Science Data Image Clock

         o_clk_90             => clk_90               , -- out    std_logic                                 ; --! System Clock 90 degrees shift
         o_clk_sq1_adc_dac_90 => clk_sq1_adc_dac_90   , -- out    std_logic                                 ; --! SQUID1 ADC/DAC internal 90 degrees shift

         o_sq1_adc_pwdn       => o_sq1_adc_pwdn        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sq1_dac_sleep      => o_sq1_dac_sleep         -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID1 DAC: Sleep ('0' = Inactive, '1' = Active)
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
         o_sync_rs            => sync_rs              , -- out    std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         o_sync_sq1_adc_rs    => sync_sq1_adc_rs      , -- out    std_logic_vector(     c_NB_COL-1 downto 0); --! Pixel sequence synchronization for squid1 ADC, synchronized on System Clock
         o_sync_sq1_dac_rs    => sync_sq1_dac_rs      , -- out    std_logic_vector(     c_NB_COL-1 downto 0); --! Pixel sequence synchronization for squid1 DAC, synchronized on System Clock
         o_sync_sq2_dac_rs    => sync_sq2_dac_rs      , -- out    std_logic_vector(     c_NB_COL-1 downto 0); --! Pixel sequence synchronization for squid2 DAC, synchronized on System Clock

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

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge
         i_tm_mode            => tm_mode              , -- in     slv(c_DFLD_TM_MODE_S-1 downto 0)          ; --! Telemetry mode

         i_sq1_data_sc_msb    => sq1_data_sc_msb      , -- in     t_slv_arr c_NB_COL c_SC_DATA_SER_W_S      ; --! SQUID1 Data science MSB
         i_sq1_data_sc_lsb    => sq1_data_sc_lsb      , -- in     t_slv_arr c_NB_COL c_SC_DATA_SER_W_S      ; --! SQUID1 Data science LSB
         i_sq1_data_sc_first  => sq1_data_sc_first(0) , -- in     std_logic                                 ; --! SQUID1 Data science first pixel ('0' = No, '1' = Yes)
         i_sq1_data_sc_last   => sq1_data_sc_last(0)  , -- in     std_logic                                 ; --! SQUID1 Data science last pixel ('0' = No, '1' = Yes)
         i_sq1_data_sc_rdy    => sq1_data_sc_rdy      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 Data science ready ('0' = Not ready, '1' = Ready)

         i_sq1_mem_dump_bsy   => sq1_mem_dump_bsy(0)  , -- in     std_logic                                 ; --! SQUID1 Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)
         o_sq1_mem_dump_add   => sq1_mem_dump_add     , -- out    slv(c_MEM_DUMP_ADD_S-1 downto 0)          ; --! SQUID1 Memory Dump: address
         i_sq1_mem_dump_data  => sq1_mem_dump_data    , -- in     t_slv_arr c_NB_COL c_SQ1_ADC_DATA_S+1     ; --! SQUID1 Memory Dump: data

         o_tm_mode_dmp_tx_end => tm_mode_dmp_tx_end   , -- out    std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         o_tm_mode_tst_tx_end => tm_mode_tst_tx_end   , -- out    std_logic                                 ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)

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

         i_tm_mode_dmp_tx_end => tm_mode_dmp_tx_end   , -- in     std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         i_tm_mode_tst_tx_end => tm_mode_tst_tx_end   , -- in     std_logic                                 ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)
         o_tm_mode            => tm_mode              , -- out    slv(c_DFLD_TM_MODE_S-1 downto 0)          ; --! Telemetry mode
         o_tm_mode_dmp_cmp    => tm_mode_dmp_cmp      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

         o_sq1_fb_mode        => sq1_fb_mode          , -- out    t_slv_arr c_NB_COL c_DFLD_SQ1FBMD_COL_S   ; --! Squid 1 Feedback mode (on/off)
         o_sq1_fb_pls_set     => sq1_fb_pls_set       , -- out    t_slv_arr c_NB_COL c_DFLD_SQ1FBMD_PLS_S   ; --! Squid 1 Feedback Pulse shaping set
         o_sq2_fb_mode        => sq2_fb_mode          , -- out    t_slv_arr c_NB_COL c_DFLD_SQ2FBMD_COL_S   ; --! Squid 2 Feedback mode
         o_sq2_dac_lsb        => sq2_dac_lsb          , -- out    t_slv_arr c_NB_COL c_DFLD_S2OFF_COL_S     ; --! Squid 2 DAC LSB
         o_sq2_lkp_off        => sq2_lkp_off          , -- out    t_slv_arr c_NB_COL c_DFLD_S2OFF_COL_S     ; --! Squid 2 Feedback lockpoint offset
         o_sq1_fb_del         => sq1_fb_del           , -- out    t_slv_arr c_NB_COL c_DFLD_S1FBD_COL_S     ; --! Squid 1 Feedback delay
         o_sq_off_dac_del     => sq_off_dac_del       , -- out    t_slv_arr c_NB_COL c_DFLD_S2DCD_COL_S     ; --! Squid offset DAC delay
         o_sq_off_mux_del     => sq_off_mux_del       , -- out    t_slv_arr c_NB_COL c_DFLD_S2MXD_COL_S     ; --! Squid offset MUX delay

         o_mem_sq1_fb0        => mem_sq1_fb0          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Squid1 feedback value in open loop: memory inputs
         i_sq1_fb0_data       => sq1_fb0_data         , -- in     t_slv_arr c_NB_COL c_DFLD_S1FB0_PIX_S     ; --! Squid1 feedback value in open loop: data read

         o_mem_sq1_fbm        => mem_sq1_fbm          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Squid1 feedback mode: memory inputs
         i_sq1_fbm_data       => sq1_fbm_data         , -- in     t_slv_arr c_NB_COL c_DFLD_S1FBM_PIX_S     ; --! Squid1 feedback mode: data read

         o_mem_sq2_lkp        => mem_sq2_lkp          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Squid2 feedback lockpoint: memory inputs
         i_sq2_lkp_data       => sq2_lkp_data         , -- in     t_slv_arr c_NB_COL c_DFLD_S2LKP_PIX_S     ; --! Squid2 feedback lockpoint: data read

         o_mem_pls_shp        => mem_pls_shp          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Pulse shaping coef: memory inputs
         i_pls_shp_data       => pls_shp_data           -- in     t_slv_arr c_NB_COL c_DFLD_PLSSH_PLS_S       --! Pulse shaping coef: data read
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
         i_sync_rs            => sync_rs              , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_tm_mode            => tm_mode              , -- in     slv(c_DFLD_TM_MODE_S-1 downto 0)          ; --! Telemetry mode
         i_sq1_fb_mode        => sq1_fb_mode          , -- in     t_slv_arr c_NB_COL c_DFLD_SQ1FBMD_COL_S   ; --! Squid 1 Feedback mode (on/off)
         o_sync_re            => sync_re              , -- out    std_logic                                 ; --! Pixel sequence synchronization, rising edge
         o_cmd_ck_s1_adc_ena  => cmd_ck_s1_adc_ena    , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_s1_adc_dis  => cmd_ck_s1_adc_dis    , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
         o_cmd_ck_s1_dac_ena  => cmd_ck_s1_dac_ena    , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_s1_dac_dis  => cmd_ck_s1_dac_dis      -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID1 DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)
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
      (  i_rst_sys_sq1_adc    => rst_sys_sq1_adc(k)   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Reset for SQUID1 ADC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_dac    => clk_sq1_adc_dac      , -- in     std_logic                                 ; --! SQUID1 ADC/DAC internal Clock

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => sync_sq1_adc_rs(k)   , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_tm_mode_dmp_cmp    => tm_mode_dmp_cmp(k)   , -- out    std_logic                                 ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_sq1_adc_data       => i_sq1_adc_data(k)    , -- in     slv(c_SQ1_ADC_DATA_S-1 downto 0)          ; --! SQUID1 ADC: Data, no rsync
         i_sq1_adc_oor        => i_sq1_adc_oor(k)     , -- in     std_logic                                 ; --! SQUID1 ADC: Out of range, no rsync ('0'= No, '1'= under/over range)

         i_sq1_mem_dump_add   => sq1_mem_dump_add     , -- in     slv(c_MEM_DUMP_ADD_S-1 downto 0)          ; --! SQUID1 Memory Dump: address
         o_sq1_mem_dump_data  => sq1_mem_dump_data(k) , -- out    slv(c_SQ1_ADC_DATA_S+1 downto 0)          ; --! SQUID1 Memory Dump: data
         o_sq1_mem_dump_bsy   => sq1_mem_dump_bsy(k)  , -- out    std_logic                                 ; --! SQUID1 Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

         o_sq1_data_err       => sq1_data_err(k)        -- out    slv(c_SQ1_DATA_ERR_S-1 downto 0)          ; --! SQUID1 Data error
      );

      I_squid_data_proc: entity work.squid_data_proc port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sq1_data_err       => sq1_data_err(k)      , -- in     slv(c_SQ1_DATA_ERR_S-1 downto 0)          ; --! SQUID1 Data error

         o_sq1_data_sc_msb    => sq1_data_sc_msb(k)   , -- out    slv(c_SC_DATA_SER_W_S-1 downto 0)         ; --! SQUID1 Data science MSB
         o_sq1_data_sc_lsb    => sq1_data_sc_lsb(k)   , -- out    slv(c_SC_DATA_SER_W_S-1 downto 0)         ; --! SQUID1 Data science LSB
         o_sq1_data_sc_first  => sq1_data_sc_first(k) , -- out    std_logic                                 ; --! SQUID1 Data science first pixel ('0' = No, '1' = Yes)
         o_sq1_data_sc_last   => sq1_data_sc_last(k)  , -- out    std_logic                                 ; --! SQUID1 Data science last pixel ('0' = No, '1' = Yes)
         o_sq1_data_sc_rdy    => sq1_data_sc_rdy(k)   , -- out    std_logic                                 ; --! SQUID1 Data science ready ('0' = Not ready, '1' = Ready)

         o_s1_dta_pixel_pos   => s1_dta_pixel_pos(k)  , -- out    slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID1 Data error corrected pixel position
         o_s1_dta_err_cor     => s1_dta_err_cor(k)    , -- out    slv(c_SQ1_DATA_FBK_S-1 downto 0)          ; --! SQUID1 Data error corrected (signed)
         o_s1_dta_err_cor_cs  => s1_dta_err_cor_cs(k)   -- out    std_logic                                   --! SQUID1 Data error corrected chip select ('0' = Inactive, '1' = Active)
      );

      I_squid1_fbk_mgt: entity work.squid1_fbk_mgt port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge

         i_s1_dta_pixel_pos   => s1_dta_pixel_pos(k)  , -- in     slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID1 Data error corrected pixel position
         i_s1_dta_err_cor     => s1_dta_err_cor(k)    , -- in     slv(c_SQ1_DATA_FBK_S-1 downto 0)          ; --! SQUID1 Data error corrected (signed)
         i_s1_dta_err_cor_cs  => s1_dta_err_cor_cs(k) , -- in     std_logic                                 ; --! SQUID1 Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_sq1_fb0        => mem_sq1_fb0(k)       , -- in     t_mem                                     ; --! Squid1 feedback value in open loop: memory inputs
         o_sq1_fb0_data       => sq1_fb0_data(k)      , -- out    slv(c_DFLD_S1FB0_PIX_S-1 downto 0)        ; --! Squid1 feedback value in open loop: data read

         i_sq1_fb_mode        => sq1_fb_mode(k)       , -- in     slv(c_DFLD_SQ1FBMD_COL_S-1 downto 0)      ; --! Squid1 Feedback mode (on/off)
         i_sq1_fb_del         => sq1_fb_del(k)        , -- in     slv(c_DFLD_S1FBD_COL_S  -1 downto 0)      ; --! Squid1 Feedback delay
         i_mem_sq1_fbm        => mem_sq1_fbm(k)       , -- in     t_mem                                     ; --! Squid1 feedback mode: memory inputs
         o_sq1_fbm_data       => sq1_fbm_data(k)      , -- out    slv(c_DFLD_S1FBM_PIX_S-1 downto 0)        ; --! Squid1 feedback mode: data read

         o_sq1_data_fbk       => sq1_data_fbk(k)        -- out    slv( c_SQ1_DATA_FBK_S-1 downto 0)           --! SQUID1 Data feedback (signed)
      );

      I_squid1_dac_mgt: entity work.squid1_dac_mgt port map
      (  i_rst_sys_sq1_dac    => rst_sys_sq1_dac(k)   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Reset for SQUID1 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_dac    => clk_sq1_adc_dac      , -- in     std_logic                                 ; --! SQUID1 ADC/DAC internal Clock
         i_clk_sq1_adc_dac_90 => clk_sq1_adc_dac_90   , -- in     std_logic                                 ; --! SQUID1 ADC/DAC internal 90 degrees shift

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_rs            => sync_sq1_dac_rs(k)   , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sq1_data_fbk       => sq1_data_fbk(k)      , -- in     slv(c_SQ1_DATA_FBK_S-1 downto 0)          ; --! SQUID 1 Data feedback
         i_sq1_fb_pls_set     => sq1_fb_pls_set(k)    , -- in     slv(c_DFLD_SQ1FBMD_PLS_S-1 downto 0)      ; --! Squid 1 Feedback Pulse shaping set
         i_sq1_fb_del         => sq1_fb_del(k)        , -- in     slv(c_DFLD_S1FBD_COL_S  -1 downto 0)      ; --! Squid 1 Feedback delay

         i_mem_pls_shp        => mem_pls_shp(k)       , -- in     t_mem                                     ; --! Pulse shaping coef: memory inputs
         o_pls_shp_data       => pls_shp_data(k)      , -- out    slv(c_DFLD_PLSSH_PLS_S-1 downto 0)        ; --! Pulse shaping coef: data read

         o_sq1_dac_data       => o_sq1_dac_data(k)      -- out    slv(c_SQ1_DAC_DATA_S-1 downto 0)            --! SQUID1 DAC: Data
      );

      I_squid2_fbk_mgt: entity work.squid2_fbk_mgt port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge

         i_sq2_fb_mode        => sq2_fb_mode(k)       , -- in     slv(c_DFLD_SQ2FBMD_COL_S-1 downto 0)      ; --! Squid 2 Feedback mode
         i_sq2_lkp_off        => sq2_lkp_off(k)       , -- in     slv(c_DFLD_S2OFF_COL_S-1 downto 0)        ; --! Squid 2 Feedback lockpoint offset
         i_sq_off_mux_del     => sq_off_mux_del(k)    , -- in     slv(c_DFLD_S2MXD_COL_S-1 downto 0)        ; --! Squid offset MUX delay
         i_s1_dta_err_cor     => s1_dta_err_cor(k)    , -- in     slv(c_SQ1_DATA_FBK_S-1 downto 0)          ; --! SQUID1 Data error corrected (signed)

         i_mem_sq2_lkp        => mem_sq2_lkp(k)       , -- in     t_mem                                     ; --! Squid2 feedback lockpoint: memory inputs
         o_sq2_lkp_data       => sq2_lkp_data(k)      , -- out    slv(c_DFLD_S2LKP_PIX_S  -1 downto 0)      ; --! Squid2 feedback lockpoint: data read

         o_sq2_fbk_mux        => sq2_fbk_mux(k)       , -- out    slv(c_DFLD_S2LKP_PIX_S-1 downto 0)        ; --! Squid2 Feedback Multiplexer
         o_sq2_fbk_off        => sq2_fbk_off(k)         -- out    slv(c_DFLD_S2OFF_COL_S-1 downto 0)          --! Squid2 Feedback offset
      );

      I_squid2_dac_mgt: entity work.squid2_dac_mgt port map
      (  i_rst_sys_sq2_dac    => rst_sys_sq2_dac(k)   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Reset for SQUID2 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_dac    => clk_sq1_adc_dac      , -- in     std_logic                                 ; --! SQUID1 ADC/DAC internal Clock

         i_sync_rs            => sync_sq2_dac_rs(k)   , -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sq2_dac_lsb        => sq2_dac_lsb(k)       , -- in     slv(c_DFLD_S2OFF_COL_S-1 downto 0)        ; --! Squid 2 DAC LSB
         i_sq2_fbk_mux        => sq2_fbk_mux(k)       , -- in     slv(c_DFLD_S2LKP_PIX_S-1 downto 0)        ; --! Squid2 Feedback Multiplexer
         i_sq2_fbk_off        => sq2_fbk_off(k)       , -- in     slv(c_DFLD_S2OFF_COL_S-1 downto 0)        ; --! Squid2 Feedback offset
         i_sq_off_dac_del     => sq_off_dac_del(k)    , -- in     slv(c_DFLD_S2DCD_COL_S-1 downto 0)        ; --! Squid offset DAC delay
         i_sq_off_mux_del     => sq_off_mux_del(k)    , -- in     slv(c_DFLD_S2MXD_COL_S-1 downto 0)        ; --! Squid offset MUX delay

         o_sq2_dac_mux        => o_sq2_dac_mux(k)     , -- out    slv(c_SQ2_DAC_MUX_S -1 downto 0)          ; --! SQUID2 DAC: Multiplexer
         o_sq2_dac_data       => o_sq2_dac_data(k)    , -- out    std_logic                                 ; --! SQUID2 DAC: Serial Data
         o_sq2_dac_sclk       => o_sq2_dac_sclk(k)    , -- out    std_logic                                 ; --! SQUID2 DAC: Serial Clock
         o_sq2_dac_snc_l_n    => o_sq2_dac_snc_l_n(k) , -- out    std_logic                                 ; --! SQUID2 DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sq2_dac_snc_o_n    => o_sq2_dac_snc_o_n(k)   -- out    std_logic                                   --! SQUID2 DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
      );

      I_squid1_spi_mgt: entity work.squid1_spi_mgt port map
      (  o_sq1_adc_spi_mosi   => b_sq1_adc_spi_sdio(k), -- out    std_logic                                 ; --! SQUID1 ADC: SPI Serial Data In Out
         o_sq1_adc_spi_sclk   => o_sq1_adc_spi_sclk(k), -- out    std_logic                                 ; --! SQUID1 ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sq1_adc_spi_cs_n   => o_sq1_adc_spi_cs_n(k)  -- out    std_logic                                   --! SQUID1 ADC: SPI Chip Select ('0' = Active, '1' = Inactive)
      );

      o_science_data(k) <= science_data_ser((k+1)*c_SC_DATA_SER_NB-1 downto k*c_SC_DATA_SER_NB);

   end generate G_column_mgt;

   o_sq2_dac_mx_en_n <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data outputs association
   -- ------------------------------------------------------------------------------------------------------
   o_clk_science_01     <= ck_science;
   o_clk_science_23     <= ck_science;

   o_science_ctrl_01    <= science_data_ser(4*c_SC_DATA_SER_NB);
   o_science_ctrl_23    <= science_data_ser(4*c_SC_DATA_SER_NB);

end architecture rtl;
