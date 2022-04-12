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

         i_tm_mode_dur        : in     std_logic_vector(c_DFLD_TM_MODE_DUR_S-1 downto 0)                    ; --! Telemetry mode, duration field
         i_tm_mode            : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)          ; --! Telemetry mode

         i_rg_sq1_fb_mode     : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP register: SQ1_FB_MODE
         i_rg_sq2_fb_mode     : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP register: SQ2_FB_MODE
         i_ep_cmd_sts_rg_r    : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register, registered

         i_sq1_fb0_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FB0_PIX_S-1 downto 0)            ; --! Squid1 feedback value in open loop: data read
         i_sq1_fb0_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid1 feedback value in open loop: chip select data read ('0' = Inactive,'1'=Active)

         i_sq1_fbm_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FBM_PIX_S-1 downto 0)            ; --! Squid1 feedback mode: data read
         i_sq1_fbm_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid1 feedback mode: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_lkp_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2LKP_PIX_S-1 downto 0)            ; --! Squid2 feedback lockpoint: data read
         i_sq2_lkp_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid2 feedback lockpoint: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_dac_lsb_data   : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S-1 downto 0)            ; --! Squid2 DAC LSB: data read
         i_sq2_dac_lsb_cs     : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid2 DAC LSB: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_lkp_off_data   : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S-1 downto 0)            ; --! Squid2 feedback lockpoint offset: data read
         i_sq2_lkp_off_cs     : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid2 feedback lockpoint offset: chip select data read ('0' = Inactive,'1' = Active)

         i_pls_shp_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSH_PLS_S-1 downto 0)            ; --! Pulse shaping coef: data read
         i_pls_shp_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Pulse shaping coef: chip select data read ('0' = Inactive, '1' = Active)

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

constant c_FW_VERSION_S       : integer   := c_EP_SPI_WD_S - c_BRD_MODEL_S - c_BRD_REF_S                    ; --! Firmware version bus size

signal   sq1_fb0_data_mx      : std_logic_vector(c_DFLD_S1FB0_PIX_S-1 downto 0)                             ; --! Squid1 feedback value in open loop: data read compared
signal   sq1_fbm_data_mx      : std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0)                             ; --! Squid1 feedback mode: data read compared
signal   sq2_lkp_data_mx      : std_logic_vector(c_DFLD_S2LKP_PIX_S-1 downto 0)                             ; --! Squid2 feedback lockpoint: data read compared
signal   sq2_dac_lsb_data_mx  : std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                             ; --! Squid2 DAC LSB: data read compared
signal   sq2_lkp_off_data_mx  : std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                             ; --! Squid2 feedback lockpoint offset: data read compared
signal   pls_shp_data_mx      : std_logic_vector(c_DFLD_PLSSH_PLS_S-1 downto 0)                             ; --! Pulse shaping coef: data read compared

signal   data_rg_rd           : t_slv_arr(0 to c_EP_CMD_REG_MX_STIN(c_EP_CMD_REG_MX_STIN'high)-1)
                                         (c_EP_SPI_WD_S-1 downto 0)                                         ; --! Data register read
signal   cs_rg                : std_logic_vector(c_EP_CMD_REG_MX_STIN(c_EP_CMD_REG_MX_STIN'high)-1 downto 0); --! Chip select register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Column Memory Data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   I_sq1_fb0_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_S1FB0_PIX_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_sq1_fb0_data       , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_sq1_fb0_cs         , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => sq1_fb0_data_mx        -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_sq1_fbm_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_S1FBM_PIX_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_sq1_fbm_data       , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_sq1_fbm_cs         , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => sq1_fbm_data_mx        -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_sq2_lkp_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_S2LKP_PIX_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_sq2_lkp_data       , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_sq2_lkp_cs         , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => sq2_lkp_data_mx        -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_sq2_dac_lsb_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_S2LSB_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_sq2_dac_lsb_data   , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_sq2_dac_lsb_cs     , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => sq2_dac_lsb_data_mx    -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_sq2_lkp_off_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_S2OFF_COL_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_sq2_lkp_off_data   , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_sq2_lkp_off_cs     , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => sq2_lkp_off_data_mx    -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   I_pls_shp_mux : entity work.mem_data_rd_mux generic map
   (     g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_DFLD_PLSSH_PLS_S   , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_pls_shp_data       , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_pls_shp_cs         , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => pls_shp_data_mx        -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Multiplexed data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Data register read
   -- ------------------------------------------------------------------------------------------------------
   -- @Req : REG_TM_MODE
   data_rg_rd(c_EP_CMD_POS_TM_MODE) <= i_tm_mode(3) & i_tm_mode(2) & i_tm_mode(1) & i_tm_mode(0) & i_tm_mode_dur;

   -- @Req : REG_SQ1_FB_MODE
   data_rg_rd(c_EP_CMD_POS_SQ1FBMD) <= i_rg_sq1_fb_mode;

   -- @Req : REG_SQ2_FB_MODE
   data_rg_rd(c_EP_CMD_POS_SQ2FBMD) <= i_rg_sq2_fb_mode;

   -- @Req : REG_Status
   data_rg_rd(c_EP_CMD_POS_STATUS)  <= i_ep_cmd_sts_rg_r;

   -- @Req : REG_Version
   data_rg_rd(c_EP_CMD_POS_VERSION) <= std_logic_vector(to_unsigned(c_FW_VERSION, c_FW_VERSION_S)) & i_brd_model_rs & i_brd_ref_rs;

   -- @Req : REG_CY_SQ1_FB0
   -- @Req : DRE-DMX-FW-REQ-0200
   data_rg_rd(c_EP_CMD_POS_S1FB0)   <= std_logic_vector(resize(unsigned(sq1_fb0_data_mx),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_SQ1_FB_MODE
   -- @Req : DRE-DMX-FW-REQ-0210
   data_rg_rd(c_EP_CMD_POS_S1FBM)   <= std_logic_vector(resize(unsigned(sq1_fbm_data_mx),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_SQ2_PXL_LOCKPOINT
   -- @Req : DRE-DMX-FW-REQ-0300
   data_rg_rd(c_EP_CMD_POS_S2LKP)   <= std_logic_vector(resize(unsigned(sq2_lkp_data_mx),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_SQ2_PXL_DAC_LSB
   -- @Req : DRE-DMX-FW-REQ-0290
   data_rg_rd(c_EP_CMD_POS_S2LSB)   <= std_logic_vector(resize(unsigned(sq2_dac_lsb_data_mx),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_SQ2_PXL_LOCKPOINT_OFFSET
   -- @Req : DRE-DMX-FW-REQ-0290
   data_rg_rd(c_EP_CMD_POS_S2OFF)   <= std_logic_vector(resize(unsigned(sq2_lkp_off_data_mx),  c_EP_SPI_WD_S));

   -- @Req : REG_CY_FB1_PULSE_SHAPING
   -- @Req : DRE-DMX-FW-REQ-0230
   data_rg_rd(c_EP_CMD_POS_PLSSH)   <= std_logic_vector(resize(unsigned(pls_shp_data_mx),  c_EP_SPI_WD_S));

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
