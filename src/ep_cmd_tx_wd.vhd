-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmux-ngl-fw is free software: you can redistribute it and/or modify
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
--!   @file                   ep_cmd_tx_wd.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command transmit word management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity ep_cmd_tx_wd is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_cs_rg              : in     std_logic_vector(c_EP_CMD_REG_MX_STIN(0)-1 downto 0)                 ; --! Chip selects register ('0' = Inactive, '1' = Active)

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock

         i_rg_aqmde           : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! EP register: DATA_ACQ_MODE

         i_rg_smfmd           : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)            ; --! EP register: SQ_MUX_FB_ON_OFF
         i_rg_saofm           : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)            ; --! EP register: SQ_AMP_OFFSET_MODE
         i_rg_bxlgt           : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)            ; --! EP register: BOXCAR_LENGTH
         i_ep_cmd_sts_rg_r    : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register, registered

         i_smfb0_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFB0_PIX_S-1 downto 0)            ; --! Data read: CY_MUX_SQ_FB0
         i_smfb0_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_FB0

         i_smfbm_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBM_PIX_S-1 downto 0)            ; --! Data read: CY_MUX_SQ_FB_MODE
         i_smfbm_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_FB_MODE

         i_saoff_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFF_PIX_S-1 downto 0)            ; --! Data read: CY_AMP_SQ_OFFSET_FINE
         i_saoff_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_FINE

         i_saofc_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)            ; --! Data read: CY_AMP_SQ_OFFSET_COARSE
         i_saofc_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_COARSE

         i_saofl_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)            ; --! Data read: CY_AMP_SQ_OFFSET_LSB
         i_saofl_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_LSB

         i_smfbd_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)            ; --! Data read: CY_MUX_SQ_FB_DELAY
         i_smfbd_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_MUX_SQ_FB_DELAY

         i_saodd_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAODD_COL_S-1 downto 0)            ; --! Data read: CY_AMP_SQ_OFFSET_DAC_DELAY
         i_saodd_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_AMP_SQ_OFFSET_DAC_DELAY

         i_saomd_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)            ; --! Data read: CY_AMP_SQ_OFFSET_MUX_DELAY
         i_saomd_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive, '1' = Active): CY_AMP_SQ_OFFSET_MUX_DELAY

         i_smpdl_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMPDL_COL_S-1 downto 0)            ; --! Data read: CY_SAMPLING_DELAY
         i_smpdl_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive, '1' = Active): CY_SAMPLING_DELAY

         i_plssh_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSH_PLS_S-1 downto 0)            ; --! Data read: CY_FB1_PULSE_SHAPING
         i_plssh_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_FB1_PULSE_SHAPING

         i_plsss_data         : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSS_PLS_S-1 downto 0)            ; --! Data read: CY_FB1_PULSE_SHAPING_SELECTION
         i_plsss_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Chip select data read ('0' = Inactive,'1'=Active): CY_FB1_PULSE_SHAPING_SELECTION

         o_ep_cmd_sts_err_add : out    std_logic                                                            ; --! EP command: Status, error invalid address
         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --! EP command to transmit: read register word

   );
end entity ep_cmd_tx_wd;

architecture RTL of ep_cmd_tx_wd is

   function mux_stage_offset (
         k : integer                                                                                          -- Index
   ) return integer is
   begin

      if k = 0 then
         return 0;

      else
         return c_EP_CMD_REG_MX_STIN(k-1);

      end if;

   end function;

signal   smfb0_data_mux       : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! Data read multiplexer: CY_MUX_SQ_FB0
signal   smfbm_data_mux       : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                             ; --! Data read multiplexer: CY_MUX_SQ_FB_MODE
signal   saoff_data_mux       : std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                             ; --! Data read multiplexer: CY_AMP_SQ_OFFSET_FINE
signal   saofc_data_mux       : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! Data read multiplexer: CY_AMP_SQ_OFFSET_COARSE
signal   saofl_data_mux       : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! Data read multiplexer: CY_AMP_SQ_OFFSET_LSB
signal   smfbd_data_mux       : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)                             ; --! Data read multiplexer: CY_MUX_SQ_FB_DELAY
signal   saodd_data_mux       : std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0)                             ; --! Data read multiplexer: CY_AMP_SQ_OFFSET_DAC_DELAY
signal   saomd_data_mux       : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                             ; --! Data read multiplexer: CY_AMP_SQ_OFFSET_MUX_DELAY
signal   smpdl_data_mux       : std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0)                             ; --! Data read multiplexer: CY_MUX_SQ_FB_DELAY
signal   plssh_data_mux       : std_logic_vector(c_DFLD_PLSSH_PLS_S-1 downto 0)                             ; --! Data read multiplexer: CY_FB1_PULSE_SHAPING
signal   plsss_data_mux       : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0)                             ; --! Data read multiplexer: CY_FB1_PULSE_SHAPING_SELECTION

signal   data_rg_rd           : t_slv_arr(0 to c_EP_CMD_REG_MX_STIN(c_EP_CMD_REG_MX_STIN'high)-1)
                                         (c_EP_SPI_WD_S-1 downto 0)                                         ; --! Data register read
signal   cs_rg                : std_logic_vector(c_EP_CMD_REG_MX_STIN(c_EP_CMD_REG_MX_STIN'high)-1 downto 0); --! Chip select register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Column Memory Data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   I_smfb0_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_smfb0_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_smfb0_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => smfb0_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_smfbm_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SMFBM_PIX_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_smfbm_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_smfbm_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => smfbm_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_saoff_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SAOFF_PIX_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_saoff_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_saoff_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => saoff_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_saofc_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SAOFC_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_saofc_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_saofc_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => saofc_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_saofl_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SAOFL_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_saofl_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_saofl_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => saofl_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_smfbd_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SMFBD_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_smfbd_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_smfbd_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => smfbd_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_saodd_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SAODD_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_saodd_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_saodd_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => saodd_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_saomd_data_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SAOMD_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_saomd_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_saomd_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => saomd_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_smpld_data_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_SMPDL_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_smpdl_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_smpdl_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => smpdl_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_plssh_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_PLSSH_PLS_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_plssh_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_plssh_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => plssh_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_shp_set_data_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_PLSSS_PLS_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_plsss_data         , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_plsss_cs           , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => plsss_data_mux         -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Data register read
   -- ------------------------------------------------------------------------------------------------------
   -- @Req : REG_DATA_ACQ_MODE
   -- @Req : DRE-DMX-FW-REQ-0580
   data_rg_rd(c_EP_CMD_POS_AQMDE) <= std_logic_vector(resize(unsigned(i_rg_aqmde),  c_EP_SPI_WD_S));

   -- @Req : REG_SQ_MUX_FB_ON_OFF
   data_rg_rd(c_EP_CMD_POS_SMFMD) <= std_logic_vector(resize(unsigned(i_rg_smfmd(3)), c_EP_SPI_WD_S/4) & resize(unsigned(i_rg_smfmd(2)), c_EP_SPI_WD_S/4) &
                                                      resize(unsigned(i_rg_smfmd(1)), c_EP_SPI_WD_S/4) & resize(unsigned(i_rg_smfmd(0)), c_EP_SPI_WD_S/4));
   -- @Req : REG_SQ_AMP_OFFSET_MODE
   -- @Req : DRE-DMX-FW-REQ-0330
   data_rg_rd(c_EP_CMD_POS_SAOFM) <= std_logic_vector(resize(unsigned(i_rg_saofm(3)), c_EP_SPI_WD_S/4) & resize(unsigned(i_rg_saofm(2)), c_EP_SPI_WD_S/4) &
                                                      resize(unsigned(i_rg_saofm(1)), c_EP_SPI_WD_S/4) & resize(unsigned(i_rg_saofm(0)), c_EP_SPI_WD_S/4));
   -- @Req : REG_BOXCAR_LENGTH
   -- @Req : DRE-DMX-FW-REQ-0145
   data_rg_rd(c_EP_CMD_POS_BXLGT) <= std_logic_vector(resize(unsigned(i_rg_bxlgt(3)), c_EP_SPI_WD_S/4) & resize(unsigned(i_rg_bxlgt(2)), c_EP_SPI_WD_S/4) &
                                                      resize(unsigned(i_rg_bxlgt(1)), c_EP_SPI_WD_S/4) & resize(unsigned(i_rg_bxlgt(0)), c_EP_SPI_WD_S/4));
   -- @Req : REG_Status
   data_rg_rd(c_EP_CMD_POS_STATUS)<= i_ep_cmd_sts_rg_r;

   -- @Req : REG_FW_Version
   -- @Req : DRE-DMX-FW-REQ-0520
   data_rg_rd(c_EP_CMD_POS_FW_VER)<= std_logic_vector(to_unsigned(c_FW_VERSION, c_EP_SPI_WD_S));

   -- @Req : REG_HW_Version
   -- @Req : DRE-DMX-FW-REQ-0530
   data_rg_rd(c_EP_CMD_POS_HW_VER)<= std_logic_vector(resize(unsigned(i_brd_model_rs), c_EP_SPI_WD_S/2)) & std_logic_vector(resize(unsigned(i_brd_ref_rs), c_EP_SPI_WD_S/2));

   -- @Req : REG_CY_MUX_SQ_FB0
   -- @Req : DRE-DMX-FW-REQ-0200
   data_rg_rd(c_EP_CMD_POS_SMFB0) <= std_logic_vector(resize(unsigned(smfb0_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_FB_MODE
   -- @Req : DRE-DMX-FW-REQ-0210
   data_rg_rd(c_EP_CMD_POS_SMFBM) <= std_logic_vector(resize(unsigned(smfbm_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_FINE
   -- @Req : DRE-DMX-FW-REQ-0300
   data_rg_rd(c_EP_CMD_POS_SAOFF) <= std_logic_vector(resize(unsigned(saoff_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_COARSE
   -- @Req : DRE-DMX-FW-REQ-0290
   data_rg_rd(c_EP_CMD_POS_SAOFC) <= std_logic_vector(resize(unsigned(saofc_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_LSB
   -- @Req : DRE-DMX-FW-REQ-0290
   data_rg_rd(c_EP_CMD_POS_SAOFL) <= std_logic_vector(resize(unsigned(saofl_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_FB_DELAY
   -- @Req : DRE-DMX-FW-REQ-0280
   data_rg_rd(c_EP_CMD_POS_SMFBD) <= std_logic_vector(resize(unsigned(smfbd_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_DAC_DELAY
   -- @Req : DRE-DMX-FW-REQ-0380
   data_rg_rd(c_EP_CMD_POS_SAODD) <= std_logic_vector(resize(unsigned(saodd_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_MUX_DELAY
   data_rg_rd(c_EP_CMD_POS_SAOMD) <= std_logic_vector(resize(unsigned(saomd_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_SAMPLING_DELAY
   -- @Req : DRE-DMX-FW-REQ-0150
   data_rg_rd(c_EP_CMD_POS_SMPDL) <= std_logic_vector(resize(unsigned(smpdl_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_FB1_PULSE_SHAPING
   -- @Req : DRE-DMX-FW-REQ-0230
   data_rg_rd(c_EP_CMD_POS_PLSSH) <= std_logic_vector(resize(unsigned(plssh_data_mux),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_FB1_PULSE_SHAPING_SEL
   data_rg_rd(c_EP_CMD_POS_PLSSS) <= std_logic_vector(resize(unsigned(plsss_data_mux), c_EP_SPI_WD_S));

   data_rg_rd(c_EP_CMD_POS_LAST to c_EP_CMD_REG_MX_STIN(0)-1) <= (others => (others => '0'));

   cs_rg(c_EP_CMD_REG_MX_STIN(0)-1 downto 0) <= i_cs_rg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   G_mux_stage: for k in 0 to c_EP_CMD_REG_MX_STNB-1 generate
   begin

      G_mux_nb: for l in 0 to c_EP_CMD_REG_MX_STIN(k+1) - c_EP_CMD_REG_MX_STIN(k) - 1 generate
      begin

         I_multiplexer: entity work.multiplexer generic map
         (  g_DATA_S          => c_EP_SPI_WD_S        , -- integer                                          ; --! Data bus size
            g_NB              => c_EP_CMD_REG_MX_INNB(k)-- integer                                            --! Data bus number
         ) port map
         (  i_rst             => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
            i_clk             => i_clk                , -- in     std_logic                                 ; --! System Clock
            i_data            => data_rg_rd(l   * c_EP_CMD_REG_MX_INNB(k) + mux_stage_offset(k)
                                        to (l+1)* c_EP_CMD_REG_MX_INNB(k) + mux_stage_offset(k)-1)          , --! Data buses
            i_cs              => cs_rg(    (l+1)* c_EP_CMD_REG_MX_INNB(k) + mux_stage_offset(k)-1
                                    downto  l   * c_EP_CMD_REG_MX_INNB(k) + mux_stage_offset(k))            , --! Chip selects ('0' = Inactive, '1' = Active)
            o_data_mux        => data_rg_rd(c_EP_CMD_REG_MX_STIN(k)+l), -- out    slv(g_DATA_S-1 downto 0)  ; --! Multiplexed data
            o_cs_or           => cs_rg(     c_EP_CMD_REG_MX_STIN(k)+l)  -- out    std_logic                   --! Chip selects "or-ed"
         );

      end generate G_mux_nb;

   end generate G_mux_stage;

   o_ep_cmd_tx_wd_rd_rg <= data_rg_rd(data_rg_rd'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error invalid address
   --    @Req : REG_EP_CMD_ERR_ADD
   -- ------------------------------------------------------------------------------------------------------
   o_ep_cmd_sts_err_add <= cs_rg(cs_rg'high) xor c_EP_CMD_ERR_SET;

end architecture RTL;
