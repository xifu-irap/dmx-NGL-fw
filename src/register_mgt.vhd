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

         i_tm_mode_sync       : in     std_logic                                                            ; --! Telemetry mode synchronization

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock

         o_ep_cmd_sts_err_add : out    std_logic                                                            ; --! EP command: Status, error invalid address
         o_ep_cmd_sts_err_nin : out    std_logic                                                            ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis : out    std_logic                                                            ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register

         i_ep_cmd_rx_wd_add   : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy : in     std_logic                                                            ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command to transmit: read register word

         o_tm_mode            : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)          ; --! Telemetry mode
         o_tm_mode_dmp_cmp    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

         o_sq1_fb_mode        : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ1FBMD_COL_S-1 downto 0)          ; --! Squid 1 Feedback mode (on/off)
         o_sq1_fb_pls_set     : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ1FBMD_PLS_S-1 downto 0)          ; --! Squid 1 Feedback Pulse shaping set
         o_sq2_fb_mode        : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ2FBMD_COL_S-1 downto 0)          ; --! Squid 2 Feedback mode
         o_sq2_dac_lsb        : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S  -1 downto 0)          ; --! Squid 2 DAC LSB
         o_sq2_lkp_off        : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S  -1 downto 0)          ; --! Squid 2 Feedback lockpoint offset

         o_mem_sq1_fb0        : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_S1FB0_ADD_S-1 downto 0),
                                       data_w(c_DFLD_S1FB0_PIX_S-1 downto 0))                               ; --! Squid1 feedback value in open loop: memory inputs
         i_sq1_fb0_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FB0_PIX_S-1 downto 0)            ; --! Squid1 feedback value in open loop: data read

         o_mem_sq1_fbm        : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_S1FBM_ADD_S-1 downto 0),
                                       data_w(c_DFLD_S1FBM_PIX_S-1 downto 0))                               ; --! Squid1 feedback mode: memory inputs
         i_sq1_fbm_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S1FBM_PIX_S-1 downto 0)            ; --! Squid1 feedback mode: data read

         o_mem_sq2_lkp        : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(    c_MEM_S2LKP_ADD_S-1 downto 0),
                                       data_w(c_DFLD_S2LKP_PIX_S-1 downto 0))                               ; --! Squid2 feedback lockpoint: memory inputs
         i_sq2_lkp_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2LKP_PIX_S-1 downto 0)            ; --! Squid2 feedback lockpoint: data read

         o_mem_pls_shp        : out    t_mem_arr(0 to c_NB_COL-1)(
                                       add(      c_MEM_PLSSH_ADD_S-1 downto 0),
                                       data_w(c_DFLD_PLSSH_PLS_S-1 downto 0))                               ; --! Pulse shaping coef: memory inputs
         i_pls_shp_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_PLSSH_PLS_S-1 downto 0)              --! Pulse shaping coef: data read
   );
end entity register_mgt;

architecture RTL of register_mgt is
signal   ep_cmd_rx_wd_add_r   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared, registered
signal   ep_cmd_rx_wd_data_r  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word, registered
signal   ep_cmd_rx_rw_r       : std_logic                                                                   ; --! EP command receipted: read/write bit, registered
signal   ep_cmd_rx_nerr_rdy_r : std_logic                                                                   ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
signal   ep_cmd_sts_rg_r      : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: Status register, registered

signal   tm_mode_dur          : std_logic_vector(c_DFLD_TM_MODE_DUR_S-1 downto 0)                           ; --! Telemetry mode, duration field
signal   tm_mode              : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)                 ; --! Telemetry mode
signal   tm_mode_st_dump      : std_logic                                                                   ; --! Telemetry mode, status "Dump" ('0' = Inactive, '1' = Active)
signal   tm_mode_dmp_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

signal   rg_sq1_fb_mode       : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP register: SQ1_FB_MODE
signal   rg_sq2_fb_mode       : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP register: SQ2_FB_MODE
signal   rg_sq2_dac_lsb       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S-1 downto 0)                   ; --! EP register: CY_SQ2_PXL_DAC_LSB
signal   rg_sq2_lkp_off       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_S2OFF_COL_S-1 downto 0)                   ; --! EP register: CY_SQ2_PXL_LOCKPOINT_OFFSET

signal   sq1_fb0_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid1 feedback value in open loop: chip select data read ('0'=Inactive, '1'=Active)
signal   sq1_fbm_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid1 feedback mode: chip select data read ('0' = Inactive, '1' = Active)
signal   sq2_lkp_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid2 feedback lockpoint: chip select data read ('0' = Inactive, '1' = Active)
signal   sq2_dac_lsb_cs       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid2 DAC LSB: chip select data read ('0' = Inactive, '1' = Active)
signal   sq2_lkp_off_cs       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid2 feedback lockpoint offset: chip select data read ('0' = Inactive,'1' = Active)
signal   pls_shp_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Pulse shaping coef: chip select data read ('0' = Inactive, '1' = Active)

signal   cs_rg                : std_logic_vector(c_EP_CMD_POS_LAST-1 downto 0)                              ; --! Chip selects register ('0' = Inactive, '1' = Active)
signal   cs_rg_r              : std_logic_vector(c_EP_CMD_REG_MX_STIN(0)-1 downto 0)                        ; --! Chip selects register registered

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
         ep_cmd_sts_rg_r      <= (others => '0');

      elsif rising_edge(i_clk) then
         ep_cmd_rx_wd_add_r   <= i_ep_cmd_rx_wd_add;
         ep_cmd_rx_wd_data_r  <= i_ep_cmd_rx_wd_data;
         ep_cmd_rx_rw_r       <= i_ep_cmd_rx_rw;
         ep_cmd_rx_nerr_rdy_r <= i_ep_cmd_rx_nerr_rdy;
         ep_cmd_sts_rg_r      <= i_ep_cmd_sts_rg;

      end if;

   end process P_ep_cmd_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Chip selects register
   -- ------------------------------------------------------------------------------------------------------
   cs_rg(c_EP_CMD_POS_TM_MODE)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_TM_MODE else '0';
   cs_rg(c_EP_CMD_POS_SQ1FBMD)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SQ1FBMD else '0';
   cs_rg(c_EP_CMD_POS_SQ2FBMD)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SQ2FBMD else '0';
   cs_rg(c_EP_CMD_POS_STATUS)   <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_STATUS  else '0';
   cs_rg(c_EP_CMD_POS_VERSION)  <= '1' when  ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_VERSION else '0';

   cs_rg(c_EP_CMD_POS_S1FB0)    <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FB0(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FB0_ADD_S)      = c_EP_CMD_ADD_S1FB0(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FB0_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_S1FB0_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S1FB0_NW, c_MEM_S1FB0_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_S1FBM)    <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FBM(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FBM_ADD_S)      = c_EP_CMD_ADD_S1FBM(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FBM_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_S1FBM_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S1FBM_NW, c_MEM_S1FBM_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_S2LKP)    <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S2LKP(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S2LKP_ADD_S)      = c_EP_CMD_ADD_S2LKP(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S2LKP_ADD_S)      and
       ep_cmd_rx_wd_add_r(   c_MEM_S2LKP_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S2LKP_NW, c_MEM_S2LKP_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_S2LSB)    <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S2LSB(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_S2LSB(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_S2OFF)    <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S2OFF(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_S2OFF(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_PLSSH)    <= '1' when
      (ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSH(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      = c_EP_CMD_ADD_PLSSH(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      and
       ep_cmd_rx_wd_add_r(     c_TAB_PLSSH_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PLSSH_NW, c_TAB_PLSSH_S)))                else '0';

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
         rg_sq1_fb_mode       <= c_EP_CMD_DEF_SQ1FBMD;
         rg_sq2_fb_mode       <= c_EP_CMD_DEF_SQ2FBMD;

      elsif rising_edge(i_clk) then
         if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W then

            -- @Req : REG_SQ1_FB_MODE
            if cs_rg_r(c_EP_CMD_POS_SQ1FBMD) = '1' then
               rg_sq1_fb_mode       <= ep_cmd_rx_wd_data_r;

            end if;

            -- @Req : REG_SQ2_FB_MODE
            if cs_rg_r(c_EP_CMD_POS_SQ2FBMD) = '1' then
               rg_sq2_fb_mode       <= ep_cmd_rx_wd_data_r;

            end if;

         end if;

      end if;

   end process P_ep_cmd_wr_rg;

   G_column_mgt : for k in 0 to c_NB_COL-1 generate
   begin

      P_ep_cmd_wr_rg : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            rg_sq2_dac_lsb(k)   <= (others => '0');
            rg_sq2_lkp_off(k)   <= (others => '0');

         elsif rising_edge(i_clk) then
            if ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSH downto c_EP_CMD_ADD_COLPOSL) = std_logic_vector(to_unsigned(k, log2_ceil(c_NB_COL))) then

               if ep_cmd_rx_nerr_rdy_r = '1' and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W then

                  -- @Req : REG_CY_SQ2_PXL_DAC_LSB
                  -- @Req : DRE-DMX-FW-REQ-0290
                  if cs_rg_r(c_EP_CMD_POS_S2LSB) = '1' then
                     rg_sq2_dac_lsb(k) <= ep_cmd_rx_wd_data_r(c_DFLD_S2LSB_COL_S-1 downto 0);

                  end if;

                  -- @Req : REG_CY_SQ2_PXL_LOCKPOINT_OFFSET
                  -- @Req : DRE-DMX-FW-REQ-0290
                  if cs_rg_r(c_EP_CMD_POS_S2OFF) = '1' then
                     rg_sq2_lkp_off(k) <= ep_cmd_rx_wd_data_r(c_DFLD_S2OFF_COL_S-1 downto 0);

                  end if;

               end if;

            end if;

         end if;

      end process P_ep_cmd_wr_rg;

      sq2_dac_lsb_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_S2LSB(k) else '0';
      sq2_lkp_off_cs(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_S2OFF(k) else '0';

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memories inputs generation
   -- ------------------------------------------------------------------------------------------------------
   -- @Req : REG_CY_SQ1_FB0
   -- @Req : DRE-DMX-FW-REQ-0200
   I_mem_sq1_fb0: entity work.mem_in_gen generic map
   (     c_MEM_ADD_S          => c_MEM_S1FB0_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_ADD_END        => c_TAB_S1FB0_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r  , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_S1FB0), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_sq1_fb0        , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => sq1_fb0_cs             -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_SQ1_FB_MODE
   -- @Req : DRE-DMX-FW-REQ-0210
   I_mem_sq1_fbm: entity work.mem_in_gen generic map
   (     c_MEM_ADD_S          => c_MEM_S1FBM_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_ADD_END        => c_TAB_S1FBM_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r  , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_S1FBM), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_sq1_fbm        , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => sq1_fbm_cs             -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_SQ2_PXL_LOCKPOINT
   -- @Req : DRE-DMX-FW-REQ-0300
   I_mem_sq2_lkp: entity work.mem_in_gen generic map
   (     c_MEM_ADD_S          => c_MEM_S2LKP_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_ADD_END        => c_TAB_S2LKP_NW-1       -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r  , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_S2LKP), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_sq2_lkp        , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => sq2_lkp_cs             -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

   -- @Req : REG_CY_FB1_PULSE_SHAPING
   -- @Req : DRE-DMX-FW-REQ-0230
   I_mem_pls_shp: entity work.mem_in_gen generic map
   (     c_MEM_ADD_S          => c_MEM_PLSSH_ADD_S    , -- integer                                          ; --! Memory address size
         g_MEM_ADD_END        => c_MEM_PLSSH_ADD_END    -- integer                                            --! Memory address end
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r  , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_CMD_POS_PLSSH), --  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             => o_mem_pls_shp        , -- out    t_mem_arr(0 to c_NB_COL-1)                ; --! Memory inputs
         o_cs_data_rd         => pls_shp_cs             -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
   );

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

         i_tm_mode_dur        => tm_mode_dur          , -- in     slv(c_DFLD_TM_MODE_DUR_S-1 downto 0)      ; --! Telemetry mode, duration field
         i_tm_mode            => tm_mode              , -- in     t_slv_arr c_NB_COL c_DFLD_TM_MODE_COL_S   ; --! Telemetry mode

         i_rg_sq1_fb_mode     => rg_sq1_fb_mode       , -- in     slv(c_EP_SPI_WD_S-1 downto 0)             ; --! EP register: SQ1_FB_MODE
         i_rg_sq2_fb_mode     => rg_sq2_fb_mode       , -- in     slv(c_EP_SPI_WD_S-1 downto 0)             ; --! EP register: SQ2_FB_MODE
         i_ep_cmd_sts_rg_r    => ep_cmd_sts_rg_r      , -- in     slv(c_EP_SPI_WD_S-1 downto 0)             ; --! EP command: Status register, registered

         i_sq1_fb0_data       => i_sq1_fb0_data       , -- in     t_slv_arr c_NB_COL c_DFLD_S1FB0_PIX_S     ; --! Squid1 feedback value in open loop: data read
         i_sq1_fb0_cs         => sq1_fb0_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid1 feedback value in open loop: chip select data read ('0' = Inactive,'1'=Active)

         i_sq1_fbm_data       => i_sq1_fbm_data       , -- in     t_slv_arr c_NB_COL c_DFLD_S1FBM_PIX_S     ; --! Squid1 feedback mode: data read
         i_sq1_fbm_cs         => sq1_fbm_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid1 feedback mode: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_lkp_data       => i_sq2_lkp_data       , -- in     t_slv_arr c_NB_COL c_DFLD_S2LKP_PIX_S     ; --! Squid2 feedback lockpoint: data read
         i_sq2_lkp_cs         => sq2_lkp_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid2 feedback lockpoint: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_dac_lsb_data   => rg_sq2_dac_lsb       , -- in     t_slv_arr c_NB_COL c_DFLD_S2OFF_COL_S     ; --! Squid2 DAC LSB: data read
         i_sq2_dac_lsb_cs     => sq2_dac_lsb_cs       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid2 DAC LSB: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_lkp_off_data   => rg_sq2_lkp_off       , -- in     t_slv_arr c_NB_COL c_DFLD_S2OFF_COL_S     ; --! Squid2 feedback lockpoint offset: data read
         i_sq2_lkp_off_cs     => sq2_lkp_off_cs       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid2 feedback lockpoint offset: chip select data read ('0' = Inactive,'1' = Active)

         i_pls_shp_data       => i_pls_shp_data       , -- in     t_slv_arr c_NB_COL c_DFLD_PLSSH_PLS_S     ; --! Pulse shaping coef: data read
         i_pls_shp_cs         => pls_shp_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Pulse shaping coef: chip select data read ('0' = Inactive, '1' = Active)

         o_ep_cmd_sts_err_add => o_ep_cmd_sts_err_add , -- out    std_logic                                 ; --! EP command: Status, error invalid address
         o_ep_cmd_tx_wd_rd_rg => o_ep_cmd_tx_wd_rd_rg   -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)  --! EP command to transmit: read register word
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: TM_MODE Register writing management
   --    @Req : DRE-DMX-FW-REQ-0580
   --    @Req : REG_TM_MODE
   -- ------------------------------------------------------------------------------------------------------
   I_rg_tm_mode_mgt: entity work.rg_tm_mode_mgt port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_tm_mode_sync       => i_tm_mode_sync       , -- in     std_logic                                 ; --! Telemetry mode synchronization
         i_cs_rg_tm_mode      => cs_rg_r(c_EP_CMD_POS_TM_MODE),--in std_logic                                 ; --! Chip selects register TM_MODE
         i_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data_r  , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)
         o_tm_mode_dur        => tm_mode_dur          , -- out    slv(c_DFLD_TM_MODE_DUR_S-1 downto 0)      ; --! Telemetry mode, duration field
         o_tm_mode            => tm_mode              , -- out    t_slv_arr c_NB_COL c_DFLD_TM_MODE_COL_S   ; --! Telemetry mode
         o_tm_mode_dmp_cmp    => tm_mode_dmp_cmp      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         o_tm_mode_st_dump    => tm_mode_st_dump        -- out    std_logic                                   --! Telemetry mode, status "Dump" ('0' = Inactive, '1' = Active)
   );

   o_tm_mode      <= tm_mode;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error last SPI command discarded
   --    @Req : REG_EP_CMD_ERR_DIS
   -- ------------------------------------------------------------------------------------------------------
   I_sts_err_dis_mgt: entity work.sts_err_dis_mgt port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_tm_mode_st_dump    => tm_mode_st_dump      , -- in     std_logic                                 ; --! Telemetry mode, status "Dump" ('0' = Inactive, '1' = Active)
         i_ep_cmd_rx_add_norw => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_sts_err_dis => o_ep_cmd_sts_err_dis   -- out    std_logic                                   --! EP command: Status, error last SPI command discarded
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs association
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : DRE-DMX-FW-REQ-0330
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt_out: for k in 0 to c_NB_COL-1 generate
   begin

      P_out: process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            o_sq1_fb_mode(k) <= c_EP_CMD_DEF_SQ1FBMD(4*k + c_DFLD_SQ1FBMD_COL_S-1 downto 4*k);
            o_sq2_fb_mode(k) <= c_EP_CMD_DEF_SQ2FBMD(4*k + c_DFLD_SQ2FBMD_COL_S-1 downto 4*k);

         elsif rising_edge(i_clk) then
            o_sq1_fb_mode(k) <= rg_sq1_fb_mode(4*k + c_DFLD_SQ1FBMD_COL_S-1 downto 4*k);
            o_sq2_fb_mode(k) <= rg_sq2_fb_mode(4*k + c_DFLD_SQ2FBMD_COL_S-1 downto 4*k);

         end if;

      end process P_out;

      I_tm_mode_dmp_cmp: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '0'                    -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => tm_mode_dmp_cmp(k)   , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_tm_mode_dmp_cmp(k)   -- out    std_logic                                   --! Signal registered
      );

      G_sq1_fb_pls_set: for l in 0 to c_DFLD_SQ1FBMD_PLS_S-1 generate
      begin

         I_sq1_fb_pls_set: entity work.signal_reg generic map
         (
         g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_EP_CMD_DEF_SQ1FBMD(4*k+l+2) -- std_logic                                   --! Signal registered default value at reset
         )  port map
         (
         i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => rg_sq1_fb_mode(4*k+l+2),-- in    std_logic                                 ; --! Signal
         o_sig_r              => o_sq1_fb_pls_set(k)(l) -- out    std_logic                                   --! Signal registered
         );

      end generate G_sq1_fb_pls_set;

      G_sq2_dac_lsb: for l in 0 to c_DFLD_S2LSB_COL_S-1 generate
      begin

         I_sq2_dac_lsb: entity work.signal_reg generic map
         (
         g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_EP_CMD_DEF_S2LSB(l)  -- std_logic                                          --! Signal registered default value at reset
         )  port map
         (
         i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => rg_sq2_dac_lsb(k)(l) , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_dac_lsb(k)(l)    -- out    std_logic                                   --! Signal registered
         );

      end generate G_sq2_dac_lsb;

      G_sq2_lkp_off: for l in 0 to c_DFLD_S2OFF_COL_S-1 generate
      begin

         I_sq2_lkp_off: entity work.signal_reg generic map
         (
         g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_EP_CMD_DEF_S2OFF(l)  -- std_logic                                          --! Signal registered default value at reset
         )  port map
         (
         i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => rg_sq2_lkp_off(k)(l) , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_lkp_off(k)(l)    -- out    std_logic                                   --! Signal registered
         );

      end generate G_sq2_lkp_off;

   end generate G_column_mgt_out;

   -- TODO
   o_ep_cmd_sts_err_nin   <= '0';

end architecture RTL;
