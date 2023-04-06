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
--!   @file                   register_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Register management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity register_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock
         i_hk_err_nin         : in     std_logic                                                            ; --! Housekeeping Error parameter to read not initialized yet
         i_dlflg              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_DLFLG_COL_S-1 downto 0)            ; --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)

         o_ep_cmd_sts_err_add : out    std_logic                                                            ; --! EP command: Status, error invalid address
         o_ep_cmd_sts_err_nin : out    std_logic                                                            ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis : out    std_logic                                                            ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register

         i_ep_cmd_rx_wd_add   : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy : in     std_logic                                                            ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command to transmit: read register word

         i_aqmde_dmp_tx_end   : in     std_logic                                                            ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         o_aqmde              : out    std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         o_aqmde_dmp_cmp      : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

         i_tst_pat_end_pat    : in     std_logic                                                            ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         i_tst_pat_end_re     : in     std_logic                                                            ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         i_tst_pat_empty      : in     std_logic                                                            ; --! Test pattern empty ('0' = No, '1' = Yes)
         o_tsten_lop          : out    std_logic_vector(c_DFLD_TSTEN_LOP_S-1 downto 0)                      ; --! Test pattern enable, field Loop number
         o_tsten_inf          : out    std_logic                                                            ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
         o_tsten_ena          : out    std_logic                                                            ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

         o_smfmd              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)            ; --! SQUID MUX feedback mode
         o_saofm              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)            ; --! SQUID AMP offset mode
         o_bxlgt              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)            ; --! ADC sample number for averaging
         o_saofc              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)            ; --! SQUID AMP lockpoint coarse offset
         o_saofl              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)            ; --! SQUID AMP offset DAC LSB
         o_smfbd              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)            ; --! SQUID MUX feedback delay
         o_saodd              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAODD_COL_S-1 downto 0)            ; --! SQUID AMP offset DAC delay
         o_saomd              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)            ; --! SQUID AMP offset MUX delay
         o_smpdl              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMPDL_COL_S-1 downto 0)            ; --! ADC sample delay
         o_plsss              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSS_PLS_S-1 downto 0)            ; --! SQUID MUX feedback pulse shaping set
         o_rldel              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_RLDEL_COL_S-1 downto 0)            ; --! Relock delay
         o_rlthr              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_RLTHR_COL_S-1 downto 0)            ; --! Relock threshold

         o_mem_tstpt          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(c_MEM_TSTPT_ADD_S-1 downto 0),
                                       data_w(c_DFLD_TSTPT_S-1 downto 0))                                   ; --! Test pattern: memory inputs
         i_tstpt_data         : in     std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                          ; --! Test pattern: data read

         o_mem_hkeep_add      : out    std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0)                       ; --! Housekeeping: memory address
         i_hkeep_data         : in     std_logic_vector(c_DFLD_HKEEP_S-1 downto 0)                          ; --! Housekeeping: data read

         o_mem_parma          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_PARMA_ADD_S-1 downto 0),
                                       data_w(c_DFLD_PARMA_PIX_S-1 downto 0))                               ; --! Parameter a(p): memory inputs
         i_parma_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PARMA_PIX_S-1 downto 0)            ; --! Parameter a(p): data read

         o_mem_kiknm          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_KIKNM_ADD_S-1 downto 0),
                                       data_w(c_DFLD_KIKNM_PIX_S-1 downto 0))                               ; --! Parameter ki(p)*knorm(p): memory inputs
         i_kiknm_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_KIKNM_PIX_S-1 downto 0)            ; --! Parameter ki(p)*knorm(p): data read

         o_mem_knorm          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_KNORM_ADD_S-1 downto 0),
                                       data_w(c_DFLD_KNORM_PIX_S-1 downto 0))                               ; --! Parameter knorm(p): memory inputs
         i_knorm_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_KNORM_PIX_S-1 downto 0)            ; --! Parameter knorm(p): data read

         o_mem_smfb0          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_SMFB0_ADD_S-1 downto 0),
                                       data_w(c_DFLD_SMFB0_PIX_S-1 downto 0))                               ; --! SQUID MUX feedback value in open loop: memory inputs
         i_smfb0_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFB0_PIX_S-1 downto 0)            ; --! SQUID MUX feedback value in open loop: data read

         o_mem_smlkv          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_SMLKV_ADD_S-1 downto 0),
                                       data_w(c_DFLD_SMLKV_PIX_S-1 downto 0))                               ; --! Parameter elp(p): memory inputs
         i_smlkv_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMLKV_PIX_S-1 downto 0)            ; --! Parameter elp(p): data read

         o_mem_smfbm          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_SMFBM_ADD_S-1 downto 0),
                                       data_w(c_DFLD_SMFBM_PIX_S-1 downto 0))                               ; --! SQUID MUX feedback mode: memory inputs
         i_smfbm_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBM_PIX_S-1 downto 0)            ; --! SQUID MUX feedback mode: data read

         o_mem_saoff          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_SAOFF_ADD_S-1 downto 0),
                                       data_w(c_DFLD_SAOFF_PIX_S-1 downto 0))                               ; --! SQUID AMP lockpoint fine offset: memory inputs
         i_saoff_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFF_PIX_S-1 downto 0)            ; --! SQUID AMP lockpoint fine offset: data read

         o_mem_plssh          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(      c_MEM_PLSSH_ADD_S-1 downto 0),
                                       data_w(c_DFLD_PLSSH_PLS_S-1 downto 0))                               ; --! SQUID MUX feedback pulse shaping coefficient: memory inputs
         i_plssh_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSH_PLS_S-1 downto 0)            ; --! SQUID MUX feedback pulse shaping coefficient: data read

         o_mem_dlcnt          : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(      c_MEM_DLCNT_ADD_S-1 downto 0),
                                       data_w(c_DFLD_DLCNT_PIX_S-1 downto 0))                               ; --! Delock counter: memory inputs
         i_dlcnt_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_DLCNT_PIX_S-1 downto 0)              --! Delock counter: data read

   );
end entity register_mgt;

architecture RTL of register_mgt is
signal   col_nb               : std_logic_vector(log2_ceil(c_NB_COL)-1 downto 0)                            ; --! Column number
signal   ep_cmd_rx_wd_add_r   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared, registered
signal   ep_cmd_rx_wd_data_r  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word, registered
signal   ep_cmd_rx_rw_r       : std_logic                                                                   ; --! EP command receipted: read/write bit, registered
signal   ep_cmd_rx_nerr_rdy_r : std_logic                                                                   ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
signal   ep_cmd_sts_rg_r      : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: Status register, registered

signal   rg_aqmde_sav         : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! EP register: DATA_ACQ_MODE save previous mode
signal   rg_aqmde_dmp_cmp     : std_logic                                                                   ; --! EP register: DATA_ACQ_MODE, status "Dump" compared ('0' = Inactive, '1' = Active)

signal   tstpt_data_arr       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TSTPT_S-1 downto 0)                       ; --! Data read: TEST_PATTERN
signal   rg_tsten_lop         : std_logic_vector(c_DFLD_TSTEN_LOP_S-1 downto 0)                             ; --! Test pattern enable, field Loop number
signal   rg_tsten_inf         : std_logic                                                                   ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
signal   rg_tsten_ena         : std_logic                                                                   ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)
signal   rg_tsten             : std_logic_vector(    c_DFLD_TSTEN_S-1 downto 0)                             ; --! Test pattern enable

signal   rg_smfmd             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)                   ; --! EP register: SQ_MUX_FB_ON_OFF
signal   rg_saofm             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)                   ; --! EP register: SQ_AMP_OFFSET_MODE
signal   rg_bxlgt             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)                   ; --! EP register: BOXCAR_LENGTH
signal   rg_saofc             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)                   ; --! EP register: CY_AMP_SQ_OFFSET_COARSE
signal   rg_saofl             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFL_COL_S-1 downto 0)                   ; --! EP register: CY_AMP_SQ_OFFSET_LSB
signal   rg_smfbd             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)                   ; --! EP register: CY_MUX_SQ_FB_DELAY
signal   rg_saodd             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAODD_COL_S-1 downto 0)                   ; --! EP register: CY_AMP_SQ_OFFSET_DAC_DELAY
signal   rg_saomd             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)                   ; --! EP register: CY_AMP_SQ_OFFSET_MUX_DELAY
signal   rg_smpdl             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMPDL_COL_S-1 downto 0)                   ; --! EP register: CY_SAMPLING_DELAY
signal   rg_plsss             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSS_PLS_S-1 downto 0)                   ; --! EP register: CY_FB1_PULSE_SHAPING_SELECTION
signal   rg_rldel             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_RLDEL_COL_S-1 downto 0)                   ; --! EP register: CY_RELOCK_DELAY
signal   rg_rlthr             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_RLTHR_COL_S-1 downto 0)                   ; --! EP register: CY_RELOCK_THRESHOLD

signal   kiknm_add            : std_logic_vector(c_MEM_KIKNM_ADD_S-1 downto 0)                              ; --! Address memory: CY_KI_KNORM
signal   smlkv_add            : std_logic_vector(c_MEM_SMLKV_ADD_S-1 downto 0)                              ; --! Address memory: CY_MUX_SQ_LOCKPOINT_V

signal   tstpt_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): TEST_PATTERN
signal   parma_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_A
signal   kiknm_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_KI_KNORM
signal   knorm_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_KNORM
signal   smfb0_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_MUX_SQ_FB0
signal   smlkv_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_MUX_SQ_LOCKPOINT_V
signal   smfbm_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_MUX_SQ_FB_MODE
signal   saoff_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_AMP_SQ_OFFSET_FINE
signal   saofl_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_AMP_SQ_OFFSET_LSB
signal   saofc_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_AMP_SQ_OFFSET_COARSE
signal   smfbd_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_MUX_SQ_FB_DELAY
signal   saodd_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_AMP_SQ_OFFSET_DAC_DELAY
signal   saomd_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_AMP_SQ_OFFSET_MUX_DELAY
signal   smpdl_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_SAMPLING_DELAY
signal   plssh_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_FB1_PULSE_SHAPING
signal   plsss_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_FB1_PULSE_SHAPING_SELECTION
signal   rldel_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_RELOCK_DELAY
signal   rlthr_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_RELOCK_THRESHOLD
signal   dlcnt_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Chip select data read ('0'=Inactive, '1'=Active): CY_DELOCK_COUNTERS

signal   cs_rg                : std_logic_vector(c_EP_CMD_POS_LAST-1 downto 0)                              ; --! Chip selects register ('0' = Inactive, '1' = Active)
signal   cs_rg_r              : std_logic_vector(c_EP_CMD_REG_MX_STIN(0)-1 downto 0)                        ; --! Chip selects register registered

signal   mem_dlcnt_int        : t_mem_arr(0 to c_NB_COL-1)(
                                add(    c_MEM_DLCNT_ADD_S-1 downto 0),
                                data_w(c_DFLD_DLCNT_PIX_S-1 downto 0))                                      ; --! Delock counter: memory inputs internal

attribute syn_preserve        : boolean                                                                     ;
attribute syn_preserve          of o_aqmde_dmp_cmp   : signal is true                                       ;

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command register
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ep_cmd_rx_wd_add_r   <= (others => '0');
         ep_cmd_rx_wd_data_r  <= (others => '0');
         ep_cmd_rx_rw_r       <= '0';
         ep_cmd_rx_nerr_rdy_r <= '0';
         ep_cmd_sts_rg_r      <= (others => c_EP_CMD_ERR_CLR);

      elsif rising_edge(i_clk) then
         ep_cmd_rx_wd_add_r   <= i_ep_cmd_rx_wd_add;
         ep_cmd_rx_wd_data_r  <= i_ep_cmd_rx_wd_data;
         ep_cmd_rx_rw_r       <= i_ep_cmd_rx_rw;
         ep_cmd_rx_nerr_rdy_r <= i_ep_cmd_rx_nerr_rdy;
         ep_cmd_sts_rg_r      <= i_ep_cmd_sts_rg;

      end if;

   end process P_ep_cmd_r;

   col_nb <= ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSH downto c_EP_CMD_ADD_COLPOSL);

   -- ------------------------------------------------------------------------------------------------------
   --!   Chip selects register
   -- ------------------------------------------------------------------------------------------------------
   cs_rg(c_EP_CMD_POS_AQMDE)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_AQMDE  else '0';
   cs_rg(c_EP_CMD_POS_SMFMD)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SMFMD  else '0';
   cs_rg(c_EP_CMD_POS_SAOFM)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAOFM  else '0';
   cs_rg(c_EP_CMD_POS_TSTEN)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_TSTEN  else '0';
   cs_rg(c_EP_CMD_POS_BXLGT)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_BXLGT  else '0';
   cs_rg(c_EP_CMD_POS_DLFLG)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_DLFLG  else '0';
   cs_rg(c_EP_CMD_POS_STATUS) <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_STATUS else '0';
   cs_rg(c_EP_CMD_POS_FW_VER) <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_FW_VER else '0';
   cs_rg(c_EP_CMD_POS_HW_VER) <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_HW_VER else '0';

   cs_rg(c_EP_CMD_POS_TSTPT)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_MEM_TSTPT_ADD_S)      = c_EP_CMD_ADD_TSTPT(ep_cmd_rx_wd_add_r'high downto c_MEM_TSTPT_ADD_S)         and
       ep_cmd_rx_wd_add_r(   c_MEM_TSTPT_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_TSTPT_NW, c_MEM_TSTPT_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_HKEEP)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_MEM_HKEEP_ADD_S)      = c_EP_CMD_ADD_HKEEP(ep_cmd_rx_wd_add_r'high downto c_MEM_HKEEP_ADD_S)         and
       ep_cmd_rx_wd_add_r(   c_MEM_HKEEP_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_HKEEP_NW, c_MEM_HKEEP_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_PARMA)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PARMA(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PARMA_ADD_S)      = c_EP_CMD_ADD_PARMA(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PARMA_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_PARMA_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PARMA_NW, c_MEM_PARMA_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_KIKNM)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_KIKNM(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                     >= c_EP_CMD_ADD_KIKNM(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      < std_logic_vector(unsigned(c_EP_CMD_ADD_KIKNM(0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                               + to_unsigned(c_TAB_KIKNM_NW, c_EP_CMD_ADD_COLPOSL)))            else '0';
   cs_rg(c_EP_CMD_POS_KNORM)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_KNORM(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_KNORM_ADD_S)      = c_EP_CMD_ADD_KNORM(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_KNORM_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_KNORM_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_KNORM_NW, c_MEM_KNORM_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SMFB0)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFB0(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFB0_ADD_S)      = c_EP_CMD_ADD_SMFB0(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFB0_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_SMFB0_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFB0_NW, c_MEM_SMFB0_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SMLKV)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMLKV(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                     >= c_EP_CMD_ADD_SMLKV(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      < std_logic_vector(unsigned(c_EP_CMD_ADD_SMLKV(0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                               + to_unsigned(c_TAB_SMLKV_NW, c_EP_CMD_ADD_COLPOSL)))            else '0';
   cs_rg(c_EP_CMD_POS_SMFBM)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBM(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFBM_ADD_S)      = c_EP_CMD_ADD_SMFBM(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFBM_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_SMFBM_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFBM_NW, c_MEM_SMFBM_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SAOFF)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFF(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SAOFF_ADD_S)      = c_EP_CMD_ADD_SAOFF(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SAOFF_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_SAOFF_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SAOFF_NW, c_MEM_SAOFF_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SAOFC)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFC(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAOFC(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SAOFL)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFL(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAOFL(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SMFBD)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBD(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SMFBD(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SAODD)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAODD(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAODD(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SAOMD)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOMD(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAOMD(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SMPDL)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMPDL(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SMPDL(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_PLSSH)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSH(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      = c_EP_CMD_ADD_PLSSH(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      and
       ep_cmd_rx_wd_add_r(     c_TAB_PLSSH_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PLSSH_NW, c_TAB_PLSSH_S)))                else '0';

   cs_rg(c_EP_CMD_POS_PLSSS)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSS(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_PLSSS(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_RLDEL)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_RLDEL(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_RLDEL(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_RLTHR)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_RLTHR(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_RLTHR(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_DLCNT)  <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_DLCNT(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_DLCNT_ADD_S)      = c_EP_CMD_ADD_DLCNT(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_DLCNT_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_DLCNT_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_DLCNT_NW, c_MEM_DLCNT_ADD_S)))            else '0';

   P_cs_rg_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         cs_rg_r(c_EP_CMD_POS_LAST-1 downto 0) <= (others => '0');

      elsif rising_edge(i_clk) then
         cs_rg_r(c_EP_CMD_POS_LAST-1 downto 0) <= cs_rg;

      end if;

   end process P_cs_rg_r;

   cs_rg_r(c_EP_CMD_REG_MX_STIN(0)-1 downto c_EP_CMD_POS_LAST) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Register/Memory writing management
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_wr_rg : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_aqmde      <= c_DST_AQMDE_IDLE;
         rg_aqmde_sav <= c_DST_AQMDE_IDLE;
         rg_tsten_lop <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);
         rg_tsten_inf <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_INF_POS);
         rg_tsten_ena <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_ENA_POS);

      elsif rising_edge(i_clk) then

         -- @Req : REG_DATA_ACQ_MODE
         -- @Req : DRE-DMX-FW-REQ-0580
         if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and cs_rg_r(c_EP_CMD_POS_AQMDE) = '1' then
            o_aqmde <= ep_cmd_rx_wd_data_r(o_aqmde'high downto 0);

         elsif (o_aqmde = c_DST_AQMDE_TEST and i_tst_pat_end_re = '1') or (o_aqmde = c_DST_AQMDE_DUMP and i_aqmde_dmp_tx_end = '1') then
            o_aqmde <= rg_aqmde_sav;

         end if;

         if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W then

            if cs_rg_r(c_EP_CMD_POS_AQMDE) = '1' then
               if ep_cmd_rx_wd_data_r(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_TEST or
                 (ep_cmd_rx_wd_data_r(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_DUMP and o_aqmde = c_DST_AQMDE_TEST) then
                  rg_aqmde_sav <= c_DST_AQMDE_IDLE;

               else
                  rg_aqmde_sav <= o_aqmde;

               end if;

            end if;

         end if;

         -- @Req : REG_TEST_PATTERN_ENABLE
         if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and cs_rg_r(c_EP_CMD_POS_TSTEN) = '1' then
            if ep_cmd_rx_wd_data_r(c_DFLD_TSTEN_INF_POS) = '1' then
               rg_tsten_lop <= std_logic_vector(to_unsigned(0, rg_tsten_lop'length));

            else
               rg_tsten_lop <= ep_cmd_rx_wd_data_r(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);

            end if;

         elsif i_tst_pat_empty = '1' then
            rg_tsten_lop <= std_logic_vector(to_unsigned(0, rg_tsten_lop'length));

         elsif rg_tsten_lop /= std_logic_vector(to_unsigned(0, rg_tsten_lop'length)) and i_tst_pat_end_pat = '1' then
            rg_tsten_lop <= std_logic_vector(signed(rg_tsten_lop) - 1);

         end if;

         if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and cs_rg_r(c_EP_CMD_POS_TSTEN) = '1' then
            rg_tsten_inf <= ep_cmd_rx_wd_data_r(c_DFLD_TSTEN_INF_POS);

         elsif i_tst_pat_empty = '1' then
            rg_tsten_inf <= '0';

         end if;

         if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and cs_rg_r(c_EP_CMD_POS_TSTEN) = '1' then
            rg_tsten_ena <= ep_cmd_rx_wd_data_r(c_DFLD_TSTEN_ENA_POS);

         elsif (rg_tsten_lop = std_logic_vector(to_unsigned(0, rg_tsten_lop'length)) and rg_tsten_inf = '0') or i_tst_pat_empty = '1' then
            rg_tsten_ena <= '0';

         end if;

      end if;

   end process P_ep_cmd_wr_rg;

   rg_aqmde_dmp_cmp <= '1' when o_aqmde = c_DST_AQMDE_DUMP else '0';
   rg_tsten         <= rg_tsten_ena & rg_tsten_inf & rg_tsten_lop;

   G_column_mgt : for k in 0 to c_NB_COL-1 generate
   begin

      P_ep_cmd_wr_rg : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            rg_saofm(k) <= c_EP_CMD_DEF_SAOFM;
            rg_smfmd(k) <= c_EP_CMD_DEF_SMFMD;
            rg_bxlgt(k) <= c_EP_CMD_DEF_BXLGT;

            rg_saofc(k) <= c_EP_CMD_DEF_SAOFC;
            rg_saofl(k) <= c_EP_CMD_DEF_SAOFL;
            rg_smfbd(k) <= c_EP_CMD_DEF_SMFBD;
            rg_saodd(k) <= c_EP_CMD_DEF_SAODD;
            rg_saomd(k) <= c_EP_CMD_DEF_SAOMD;
            rg_smpdl(k) <= c_EP_CMD_DEF_SMPDL;
            rg_plsss(k) <= c_EP_CMD_DEF_PLSSS;
            rg_rldel(k) <= c_EP_CMD_DEF_RLDEL;
            rg_rlthr(k) <= c_EP_CMD_DEF_RLTHR;

         elsif rising_edge(i_clk) then

               -- @Req : REG_SQ_AMP_OFFSET_MODE
               -- @Req : DRE-DMX-FW-REQ-0330
               if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and cs_rg_r(c_EP_CMD_POS_SAOFM) = '1' then
                  rg_saofm(k) <= ep_cmd_rx_wd_data_r(c_NB_COL*k+c_DFLD_SAOFM_COL_S-1 downto c_NB_COL*k);

               elsif rg_saofm(k) = c_DST_SAOFM_TEST and i_tst_pat_end_re = '1' then
                  rg_saofm(k) <= c_DST_SAOFM_OFFSET;

               end if;

            if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W then

               -- @Req : REG_SQ_MUX_FB_ON_OFF
               if cs_rg_r(c_EP_CMD_POS_SMFMD) = '1' then
                  rg_smfmd(k) <= ep_cmd_rx_wd_data_r(c_NB_COL*k+c_DFLD_SMFMD_COL_S-1 downto c_NB_COL*k);

               end if;

               -- @Req : REG_BOXCAR_LENGTH
               -- @Req : DRE-DMX-FW-REQ-0145
               if cs_rg_r(c_EP_CMD_POS_BXLGT) = '1' then
                  rg_bxlgt(k) <= ep_cmd_rx_wd_data_r(c_NB_COL*k+c_DFLD_BXLGT_COL_S-1 downto c_NB_COL*k);

               end if;

               if ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSH downto c_EP_CMD_ADD_COLPOSL) = std_logic_vector(to_unsigned(k, log2_ceil(c_NB_COL))) then

                  -- @Req : REG_CY_AMP_SQ_OFFSET_COARSE
                  -- @Req : DRE-DMX-FW-REQ-0290
                  if cs_rg_r(c_EP_CMD_POS_SAOFC) = '1' then
                     rg_saofc(k) <= ep_cmd_rx_wd_data_r(c_DFLD_SAOFC_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_AMP_SQ_OFFSET_LSB
                  -- @Req : DRE-DMX-FW-REQ-0290
                  if cs_rg_r(c_EP_CMD_POS_SAOFL) = '1' then
                     rg_saofl(k) <= ep_cmd_rx_wd_data_r(c_DFLD_SAOFL_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_MUX_SQ_FB_DELAY
                  -- @Req : DRE-DMX-FW-REQ-0280
                  if cs_rg_r(c_EP_CMD_POS_SMFBD) = '1' then
                     rg_smfbd(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_SMFBD_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_AMP_SQ_OFFSET_DAC_DELAY
                  -- @Req : DRE-DMX-FW-REQ-0380
                  if cs_rg_r(c_EP_CMD_POS_SAODD) = '1' then
                     rg_saodd(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_SAODD_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_AMP_SQ_OFFSET_MUX_DELAY
                  if cs_rg_r(c_EP_CMD_POS_SAOMD) = '1' then
                     rg_saomd(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_SAOMD_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_SAMPLING_DELAY
                  -- @Req : DRE-DMX-FW-REQ-0150
                  if cs_rg_r(c_EP_CMD_POS_SMPDL) = '1' then
                     rg_smpdl(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_SMPDL_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_FB1_PULSE_SHAPING_SEL
                  if cs_rg_r(c_EP_CMD_POS_PLSSS) = '1' then
                     rg_plsss(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_PLSSS_PLS_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_RELOCK_DELAY
                  -- @Req : DRE-DMX-FW-REQ-0410
                  if cs_rg_r(c_EP_CMD_POS_RLDEL) = '1' then
                     rg_rldel(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_RLDEL_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_RELOCK_THRESHOLD
                  -- @Req : DRE-DMX-FW-REQ-0420
                  if cs_rg_r(c_EP_CMD_POS_RLTHR) = '1' then
                     rg_rlthr(k)  <= ep_cmd_rx_wd_data_r(c_DFLD_RLTHR_COL_S-1 downto 0);

                  end if;

               end if;

            end if;

         end if;

      end process P_ep_cmd_wr_rg;

      saofc_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAOFC(k) else '0';
      saofl_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAOFL(k) else '0';
      smfbd_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SMFBD(k) else '0';
      saodd_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAODD(k) else '0';
      saomd_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAOMD(k) else '0';
      smpdl_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SMPDL(k) else '0';
      plsss_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_PLSSS(k) else '0';
      rldel_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_RLDEL(k) else '0';
      rlthr_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_RLTHR(k) else '0';

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memories inputs generation
   -- ------------------------------------------------------------------------------------------------------
   -- @Req : REG_TEST_PATTERN
   -- @Req : DRE-DMX-FW-REQ-0440
   I_mem_tstpt: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_TSTPT_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_TSTPT_S       , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_TSTPT_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => (others => '0')      , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_TSTPT_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_TSTPT_S-1 downto 0),     -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_TSTPT), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_tstpt          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => tstpt_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   tstpt_data_arr(0) <= i_tstpt_data;

   G_col_mgt : for k in 1 to c_NB_COL-1 generate
   begin
      tstpt_data_arr(k) <= (others => '0');

   end generate G_col_mgt;

   -- @Req : REG_HKEEP
   o_mem_hkeep_add   <= ep_cmd_rx_wd_add_r(  c_MEM_HKEEP_ADD_S-1 downto 0);

   -- @Req : REG_CY_A
   -- @Req : DRE-DMX-FW-REQ-0180
   I_mem_parma: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_PARMA_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_PARMA_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_PARMA_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_PARMA_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_PARMA_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_PARMA), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_parma          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => parma_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   kiknm_add <= std_logic_vector(signed(ep_cmd_rx_wd_add_r(   kiknm_add'high downto 0)) -
                                 signed(c_EP_CMD_ADD_KIKNM(0)(kiknm_add'high downto 0)));

   -- @Req : REG_CY_KI_KNORM
   -- @Req : DRE-DMX-FW-REQ-0170
   I_mem_kiknm: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_KIKNM_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_KIKNM_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_KIKNM_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => kiknm_add            , -- in     slv g_MEM_ADD_S                           ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_KIKNM_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_KIKNM), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_kiknm          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => kiknm_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_KNORM
   -- @Req : DRE-DMX-FW-REQ-0185
   I_mem_knorm: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_KNORM_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_KNORM_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_KNORM_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_KNORM_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_KNORM_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_KNORM), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_knorm          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => knorm_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_MUX_SQ_FB0
   -- @Req : DRE-DMX-FW-REQ-0200
   I_mem_smfb0: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_SMFB0_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_SMFB0_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_SMFB0_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_SMFB0_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_SMFB0), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_smfb0          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => smfb0_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   smlkv_add <= std_logic_vector(signed(ep_cmd_rx_wd_add_r(   smlkv_add'high downto 0)) -
                                 signed(c_EP_CMD_ADD_SMLKV(0)(smlkv_add'high downto 0)));

   -- @Req : REG_CY_MUX_SQ_LOCKPOINT_V
   -- @Req : DRE-DMX-FW-REQ-0190
   I_mem_smlkv: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_SMLKV_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_SMLKV_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_SMLKV_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => smlkv_add            , -- in     slv g_MEM_ADD_S                           ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_SMLKV_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_SMLKV), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_smlkv          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => smlkv_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_MUX_SQ_FB_MODE
   -- @Req : DRE-DMX-FW-REQ-0210
   I_mem_smfbm: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_SMFBM_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_SMFBM_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_SMFBM_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_SMFBM_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_SMFBM_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_SMFBM), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_smfbm          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => smfbm_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_AMP_SQ_OFFSET_FINE
   -- @Req : DRE-DMX-FW-REQ-0300
   I_mem_saoff: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_SAOFF_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_SAOFF_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_SAOFF_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_SAOFF_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_SAOFF_PIX_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_SAOFF), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_saoff          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => saoff_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_FB1_PULSE_SHAPING
   -- @Req : DRE-DMX-FW-REQ-0230
   I_mem_plssh: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_PLSSH_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_PLSSH_PLS_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_MEM_PLSSH_ADD_END    -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(  c_MEM_PLSSH_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S  ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_PLSSH_PLS_S-1 downto 0), -- in slv g_MEM_DATA_S ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_PLSSH), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_plssh          , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => plssh_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_DELOCK_COUNTERS
   -- @Req : DRE-DMX-FW-REQ-0435
   I_mem_dlcnt: entity work.mem_in_gen generic map
   (     g_MEM_ADD_S          => c_MEM_DLCNT_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_DATA_S         => c_DFLD_DLCNT_PIX_S   , -- integer                                          ; --! Memory data size
         g_MEM_ADD_END        => c_TAB_DLCNT_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(c_MEM_DLCNT_ADD_S-1 downto 0), -- in slv g_MEM_ADD_S    ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => (others => '0')      , -- in     slv g_MEM_DATA_S                          ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_DLCNT), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => mem_dlcnt_int        , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => dlcnt_cs               -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   G_mem_dlcnt : for k in 0 to c_NB_COL-1 generate
   begin

      o_mem_dlcnt(k).add     <= mem_dlcnt_int(k).add;
      o_mem_dlcnt(k).we      <= mem_dlcnt_int(k).we;
      o_mem_dlcnt(k).cs      <= mem_dlcnt_int(k).cs;
      o_mem_dlcnt(k).data_w  <= (others => '0');
      o_mem_dlcnt(k).pp      <= c_MEM_STR_ADD_PP_DEF;

   end generate G_mem_dlcnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Register to transmit management
   --    @Req : DRE-DMX-FW-REQ-0510
   -- ------------------------------------------------------------------------------------------------------
   I_ep_cmd_tx_wd: entity work.ep_cmd_tx_wd port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_cs_rg              => cs_rg_r              , -- in     slv(c_EP_CMD_POS_NB-1 downto 0)           ; --! Chip selects register ('0' = Inactive, '1' = Active)

         i_brd_ref_rs         => i_brd_ref_rs         , -- in     slv(  c_BRD_REF_S-1 downto 0)             ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       => i_brd_model_rs       , -- in     slv(c_BRD_MODEL_S-1 downto 0)             ; --! Board model, synchronized on System Clock
         i_dlflg              => i_dlflg              , -- in     t_slv_arr c_NB_COL c_DFLD_DLFLG_COL_S     ; --! Delock flag

         i_rg_aqmde           => o_aqmde              , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! EP register: DATA_ACQ_MODE

         i_rg_smfmd           => rg_smfmd             , -- in     t_slv_arr c_NB_COL c_DFLD_SMFMD_COL_S     ; --! EP register: SQ_MUX_FB_ON_OFF
         i_rg_saofm           => rg_saofm             , -- in     t_slv_arr c_NB_COL c_DFLD_SAOFM_COL_S     ; --! EP register: SQ_AMP_OFFSET_MODE
         i_rg_tsten           => rg_tsten             , -- in     slv(c_DFLD_TSTEN_S-1 downto 0)            ; --! EP register: TEST_PATTERN_ENABLE
         i_rg_bxlgt           => rg_bxlgt             , -- in     t_slv_arr c_NB_COL c_DFLD_BXLGT_COL_S     ; --! EP register: BOXCAR_LENGTH
         i_ep_cmd_sts_rg_r    => ep_cmd_sts_rg_r      , -- in     slv(c_EP_SPI_WD_S-1 downto 0)             ; --! EP command: Status register, registered

         i_tstpt_data         => tstpt_data_arr       , -- in     t_slv_arr c_NB_COL c_DFLD_TSTPT_S         ; --! Data read: TEST_PATTERN
         i_tstpt_cs           => tstpt_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): TEST_PATTERN

         i_hkeep_data         => i_hkeep_data         , -- in     slv(c_DFLD_HKEEP_S-1 downto 0)            ; --! Data read: Housekeeping

         i_parma_data         => i_parma_data         , -- in     t_slv_arr c_NB_COL c_DFLD_PARMA_PIX_S     ; --! Data read: CY_A
         i_parma_cs           => parma_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_A

         i_kiknm_data         => i_kiknm_data         , -- in     t_slv_arr c_NB_COL c_DFLD_KIKNM_PIX_S     ; --! Data read: CY_KI_KNORM
         i_kiknm_cs           => kiknm_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_KI_KNORM

         i_knorm_data         => i_knorm_data         , -- in     t_slv_arr c_NB_COL c_DFLD_KNORM_PIX_S     ; --! Data read: CY_KNORM
         i_knorm_cs           => knorm_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_KNORM

         i_smfb0_data         => i_smfb0_data         , -- in     t_slv_arr c_NB_COL c_DFLD_SMFB0_PIX_S     ; --! Data read: CY_MUX_SQ_FB0
         i_smfb0_cs           => smfb0_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_FB0

         i_smlkv_data         => i_smlkv_data         , -- in     t_slv_arr c_NB_COL c_DFLD_SMLKV_PIX_S     ; --! Data read: CY_MUX_SQ_LOCKPOINT_V
         i_smlkv_cs           => smlkv_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_LOCKPOINT_V

         i_smfbm_data         => i_smfbm_data         , -- in     t_slv_arr c_NB_COL c_DFLD_SMFBM_PIX_S     ; --! Data read: CY_MUX_SQ_FB_MODE
         i_smfbm_cs           => smfbm_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_FB_MODE

         i_saoff_data         => i_saoff_data         , -- in     t_slv_arr c_NB_COL c_DFLD_SAOFF_PIX_S     ; --! Data read: CY_AMP_SQ_OFFSET_FINE
         i_saoff_cs           => saoff_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_FINE

         i_saofc_data         => rg_saofc             , -- in     t_slv_arr c_NB_COL c_DFLD_SAOFC_COL_S     ; --! Data read: CY_AMP_SQ_OFFSET_COARSE
         i_saofc_cs           => saofc_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_COARSE

         i_saofl_data         => rg_saofl             , -- in     t_slv_arr c_NB_COL c_DFLD_SAOFC_COL_S     ; --! Data read: CY_AMP_SQ_OFFSET_LSB
         i_saofl_cs           => saofl_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_LSB

         i_smfbd_data         => rg_smfbd             , -- in     t_slv_arr c_NB_COL c_DFLD_SMFBD_COL_S     ; --! Data read: CY_MUX_SQ_FB_DELAY
         i_smfbd_cs           => smfbd_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_FB_DELAY

         i_saodd_data         => rg_saodd             , -- in     t_slv_arr c_NB_COL c_DFLD_SAODD_COL_S     ; --! Data read: CY_AMP_SQ_OFFSET_DAC_DELAY
         i_saodd_cs           => saodd_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_DAC_DELAY

         i_saomd_data         => rg_saomd             , -- in     t_slv_arr c_NB_COL c_DFLD_SAOMD_COL_S     ; --! Data read: CY_AMP_SQ_OFFSET_MUX_DELAY
         i_saomd_cs           => saomd_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_MUX_DELAY

         i_smpdl_data         => rg_smpdl             , -- in     t_slv_arr c_NB_CO c_DFLD_SMPDL_COL_S      ; --! Data read: CY_SAMPLING_DELAY
         i_smpdl_cs           => smpdl_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive, '1' = Active): CY_SAMPLING_DELAY

         i_plssh_data         => i_plssh_data         , -- in     t_slv_arr c_NB_COL c_DFLD_PLSSH_PLS_S     ; --! Data read: CY_FB1_PULSE_SHAPING
         i_plssh_cs           => plssh_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_FB1_PULSE_SHAPING

         i_plsss_data         => rg_plsss             , -- in     t_slv_arr c_NB_COL c_DFLD_PLSSS_PLS_S     ; --! Data read: CY_FB1_PULSE_SHAPING_SELECTION
         i_plsss_cs           => plsss_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_FB1_PULSE_SHAPING_SELECTION

         i_rldel_data         => rg_rldel             , -- in     t_slv_arr c_NB_COL c_DFLD_RLDEL_COL_S     ; --! Data read: CY_RELOCK_DELAY
         i_rldel_cs           => rldel_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_RELOCK_DELAY

         i_rlthr_data         => rg_rlthr             , -- in     t_slv_arr c_NB_COL c_DFLD_RLTHR_COL_S     ; --! Data read: CY_RELOCK_THRESHOLD
         i_rlthr_cs           => rlthr_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_RELOCK_THRESHOLD

         i_dlcnt_data         => i_dlcnt_data         , -- in     t_slv_arr c_NB_COL c_DFLD_DLCNT_PIX_S     ; --! Data read: CY_DELOCK_COUNTERS
         i_dlcnt_cs           => dlcnt_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_DELOCK_COUNTERS

         o_ep_cmd_sts_err_add => o_ep_cmd_sts_err_add , -- out    std_logic                                 ; --! EP command: Status, error invalid address
         o_ep_cmd_tx_wd_rd_rg => o_ep_cmd_tx_wd_rd_rg   -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)  --! EP command to transmit: read register word
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error last SPI command discarded
   --    @Req : REG_EP_CMD_ERR_DIS
   -- ------------------------------------------------------------------------------------------------------
   I_sts_err_dis_mgt: entity work.sts_err_dis_mgt port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_aqmde_dmp_cmp      => rg_aqmde_dmp_cmp     , -- in     std_logic                                 ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_ep_cmd_rx_add_norw => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_sts_err_dis => o_ep_cmd_sts_err_dis   -- out    std_logic                                   --! EP command: Status, error last SPI command discarded
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  EP command: Status, error parameter to read not initialized yet
   --    @Req : REG_EP_CMD_ERR_IN
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_nin : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_ep_cmd_sts_err_nin <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if cs_rg(c_EP_CMD_POS_HKEEP) = '1' and i_hk_err_nin = c_EP_CMD_ERR_SET then
            o_ep_cmd_sts_err_nin <= c_EP_CMD_ERR_SET;

         else
            o_ep_cmd_sts_err_nin <= c_EP_CMD_ERR_CLR;

         end if;

      end if;

   end process P_ep_cmd_sts_err_nin;

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs association
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : DRE-DMX-FW-REQ-0330
   -- ------------------------------------------------------------------------------------------------------
   P_out: process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_aqmde_dmp_cmp <= (others => '0');
         o_tsten_lop     <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);
         o_tsten_inf     <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_INF_POS);
         o_tsten_ena     <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_ENA_POS);

         o_smfmd <= (others => c_EP_CMD_DEF_SMFMD);
         o_saofm <= (others => c_EP_CMD_DEF_SAOFM);
         o_bxlgt <= (others => c_EP_CMD_DEF_BXLGT);
         o_saofc <= (others => c_EP_CMD_DEF_SAOFC);
         o_saofl <= (others => c_EP_CMD_DEF_SAOFL);
         o_smfbd <= (others => c_EP_CMD_DEF_SMFBD);
         o_saodd <= (others => c_EP_CMD_DEF_SAODD);
         o_saomd <= (others => c_EP_CMD_DEF_SAOMD);
         o_smpdl <= (others => c_EP_CMD_DEF_SMPDL);
         o_plsss <= (others => c_EP_CMD_DEF_PLSSS);
         o_rldel <= (others => c_EP_CMD_DEF_RLDEL);
         o_rlthr <= (others => c_EP_CMD_DEF_RLTHR);

      elsif rising_edge(i_clk) then
         o_aqmde_dmp_cmp <= (others => rg_aqmde_dmp_cmp);
         o_tsten_lop     <= rg_tsten_lop;
         o_tsten_inf     <= rg_tsten_inf;
         o_tsten_ena     <= rg_tsten_ena;

         o_smfmd <= rg_smfmd;
         o_saofm <= rg_saofm;
         o_bxlgt <= rg_bxlgt;
         o_saofc <= rg_saofc;
         o_saofl <= rg_saofl;
         o_smfbd <= rg_smfbd;
         o_saodd <= rg_saodd;
         o_saomd <= rg_saomd;
         o_smpdl <= rg_smpdl;
         o_plsss <= rg_plsss;
         o_rldel <= rg_rldel;
         o_rlthr <= rg_rlthr;

      end if;

   end process P_out;

end architecture RTL;
