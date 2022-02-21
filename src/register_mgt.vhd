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
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity register_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_tm_mode_sync       : in     std_logic                                                            ; --! Telemetry mode synchronization

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock

         o_ep_cmd_sts_err_nin : out    std_logic                                                            ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis : out    std_logic                                                            ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register

         i_ep_cmd_rx_wd_add   : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy : in     std_logic                                                            ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command to transmit: read register word

         o_tm_mode            : out    t_rg_tm_mode(0 to c_NB_COL-1)                                        ; --! Telemetry mode
         o_tm_mode_dmp_cmp    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

         o_sq1_fb_mode        : out    t_rg_sq1fbmd(     0 to c_NB_COL-1)                                   ; --! Squid 1 Feedback mode (on/off)
         o_sq1_fb_pls_set     : out    t_rg_sq1fbmd_pls( 0 to c_NB_COL-1)                                   ; --! Squid 1 Feedback Pulse shaping set
         o_sq2_fb_mode        : out    t_rg_sq2fbmd(     0 to c_NB_COL-1)                                   ; --! Squid 2 Feedback mode

         o_mem_sq1_fb0        : out    t_mem_arr(c_NB_COL-1 downto 0)(
                                       add(    c_MEM_S1FB0_ADD_S-1 downto 0),
                                       data_w(c_DFLD_S1FB0_PIX_S-1 downto 0))                               ; --! Squid1 feedback value in open loop: memory inputs
         i_sq1_fb0_data       : in     t_mem_s1fb0_data(0 to c_NB_COL-1)                                    ; --! Squid1 feedback value in open loop: data read

         o_mem_sq1_fbm        : out    t_mem_arr(c_NB_COL-1 downto 0)(
                                       add(    c_MEM_S1FBM_ADD_S-1 downto 0),
                                       data_w(c_DFLD_S1FBM_PIX_S-1 downto 0))                               ; --! Squid1 feedback mode: memory inputs
         i_sq1_fbm_data       : in     t_mem_s1fbm_data(0 to c_NB_COL-1)                                    ; --! Squid1 feedback mode: data read

         o_mem_pls_shp        : out    t_mem_arr(c_NB_COL-1 downto 0)(
                                       add(      c_MEM_PLSSH_ADD_S-1 downto 0),
                                       data_w(c_DFLD_PLSSH_PLS_S-1 downto 0))                               ; --! Pulse shaping coef: memory inputs
         i_pls_shp_data       : in     t_mem_plssh_data(0 to c_NB_COL-1)                                      --! Pulse shaping coef: data read
   );
end entity register_mgt;

architecture RTL of register_mgt is
constant c_FW_VERSION_S       : integer   := c_EP_SPI_WD_S - c_BRD_MODEL_S - c_BRD_REF_S                    ; --! Firmware version bus size

signal   ep_cmd_rx_wd_add_r   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared, registered
signal   ep_cmd_rx_wd_data_r  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word, registered
signal   ep_cmd_rx_rw_r       : std_logic                                                                   ; --! EP command receipted: read/write bit, registered
signal   ep_cmd_rx_nerr_rdy_r : std_logic                                                                   ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
signal   ep_cmd_sts_rg_r      : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: Status register, registered

signal   tm_mode_dur          : std_logic_vector(c_DFLD_TM_MODE_DUR_S-1 downto 0)                           ; --! Telemetry mode, duration field
signal   tm_mode              : t_rg_tm_mode(0 to c_NB_COL-1)                                               ; --! Telemetry mode
signal   tm_mode_st_dump      : std_logic                                                                   ; --! Telemetry mode, status "Dump" ('0' = Inactive, '1' = Active)
signal   tm_mode_dmp_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)

signal   rg_sq1_fb_mode       : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP register: SQ1_FB_MODE
signal   rg_sq2_fb_mode       : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP register: SQ2_FB_MODE

signal   sq1_fb0_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid1 feedback value in open loop: chip select data read ('0'=Inactive, '1'=Active)
signal   sq1_fb0_data_mx      : std_logic_vector(c_DFLD_S1FB0_PIX_S-1 downto 0)                             ; --! Squid1 feedback value in open loop: data read multiplexed

signal   sq1_fbm_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid1 feedback mode: chip select data read ('0' = Inactive, '1' = Active)
signal   sq1_fbm_data_mx      : std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0)                             ; --! Squid1 feedback mode: data read multiplexed

signal   pls_shp_cs           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Pulse shaping coef: chip select data read ('0' = Inactive, '1' = Active)
signal   pls_shp_data_mx      : std_logic_vector(c_DFLD_PLSSH_PLS_S-1 downto 0)                             ; --! Pulse shaping coef: data read multiplexed

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
            if ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SQ1FBMD then
               rg_sq1_fb_mode       <= ep_cmd_rx_wd_data_r;

            end if;

            -- @Req : REG_SQ2_FB_MODE
            if ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SQ2FBMD then
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
            o_mem_sq1_fb0(k).cs <= '0';
            o_mem_sq1_fb0(k).pp <= '0';

            o_mem_sq1_fbm(k).cs <= '0';
            o_mem_sq1_fbm(k).pp <= '0';

            o_mem_pls_shp(k).cs <= '0';
            o_mem_pls_shp(k).pp <= '0';

         elsif rising_edge(i_clk) then

            -- @Req : REG_CY_SQ1_FB0
            -- @Req : DRE-DMX-FW-REQ-0200
            if ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_MEM_S1FB0_ADD_S) = c_EP_CMD_ADD_S1FB0(k)(ep_cmd_rx_wd_add_r'high downto c_MEM_S1FB0_ADD_S) then
               o_mem_sq1_fb0(k).cs <= ep_cmd_rx_nerr_rdy_r;

               if ep_cmd_rx_wd_add_r(c_MEM_S1FB0_ADD_S-1 downto 0) = std_logic_vector(to_unsigned(c_TAB_S1FB0_NW-1, c_MEM_S1FB0_ADD_S)) then
                  o_mem_sq1_fb0(k).pp <= ep_cmd_rx_nerr_rdy_r and not(ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);

               end if;

            end if;

            -- @Req : REG_CY_SQ1_FB_MODE
            -- @Req : DRE-DMX-FW-REQ-0210
            if ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_MEM_S1FBM_ADD_S) = c_EP_CMD_ADD_S1FBM(k)(ep_cmd_rx_wd_add_r'high downto c_MEM_S1FBM_ADD_S) then
               o_mem_sq1_fbm(k).cs <= ep_cmd_rx_nerr_rdy_r;

               if ep_cmd_rx_wd_add_r(c_MEM_S1FBM_ADD_S-1 downto 0) = std_logic_vector(to_unsigned(c_TAB_S1FBM_NW-1, c_MEM_S1FBM_ADD_S)) then
                  o_mem_sq1_fbm(k).pp <= ep_cmd_rx_nerr_rdy_r and not(ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);

               end if;

            end if;

            -- @Req : REG_CY_FB1_PULSE_SHAPING
            -- @Req : DRE-DMX-FW-REQ-0230
            if ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_MEM_PLSSH_ADD_S) = c_EP_CMD_ADD_PLSSH(k)(ep_cmd_rx_wd_add_r'high downto c_MEM_PLSSH_ADD_S) then
               o_mem_pls_shp(k).cs <= ep_cmd_rx_nerr_rdy_r;

               if ep_cmd_rx_wd_add_r(c_MEM_PLSSH_ADD_S-1 downto 0) = std_logic_vector(to_unsigned(c_NB_COL-1, log2_ceil(c_DAC_PLS_SHP_SET_NB)) & to_unsigned(c_TAB_PLSSH_NW-1, c_TAB_PLSSH_S)) then
                  o_mem_pls_shp(k).pp <= ep_cmd_rx_nerr_rdy_r and not(ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);

               end if;

            end if;

         end if;

      end process P_ep_cmd_wr_rg;

      o_mem_sq1_fb0(k).add    <= ep_cmd_rx_wd_add_r(o_mem_sq1_fb0(k).add'high downto 0);
      o_mem_sq1_fb0(k).we     <= not(ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);
      o_mem_sq1_fb0(k).data_w <= ep_cmd_rx_wd_data_r(o_mem_sq1_fb0(k).data_w'high downto 0);
      sq1_fb0_cs(k)           <= o_mem_sq1_fb0(k).cs and not(o_mem_sq1_fb0(k).we);

      o_mem_sq1_fbm(k).add    <= ep_cmd_rx_wd_add_r(o_mem_sq1_fbm(k).add'high downto 0);
      o_mem_sq1_fbm(k).we     <= not(ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);
      o_mem_sq1_fbm(k).data_w <= ep_cmd_rx_wd_data_r(o_mem_sq1_fbm(k).data_w'high downto 0);
      sq1_fbm_cs(k)           <= o_mem_sq1_fbm(k).cs and not(o_mem_sq1_fbm(k).we);

      o_mem_pls_shp(k).add    <= ep_cmd_rx_wd_add_r(o_mem_pls_shp(k).add'high downto 0);
      o_mem_pls_shp(k).we     <= not(ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);
      o_mem_pls_shp(k).data_w <= ep_cmd_rx_wd_data_r(o_mem_pls_shp(k).data_w'high downto 0);
      pls_shp_cs(k)           <= o_mem_pls_shp(k).cs and not(o_mem_pls_shp(k).we);

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   I_mem_data_rd_mux : entity work.mem_data_rd_mux port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_sq1_fb0_data       => i_sq1_fb0_data       , -- in     t_mem_s1fb0_data(0     to c_NB_COL-1)     ; --! Squid1 feedback value in open loop: data read
         i_sq1_fb0_cs         => sq1_fb0_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid1 feedback value in open loop: chip select data read ('0' = Inactive,'1'=Active)

         i_sq1_fbm_data       => i_sq1_fbm_data       , -- in     t_mem_s1fbm_data(0     to c_NB_COL-1)     ; --! Squid1 feedback mode: data read
         i_sq1_fbm_cs         => sq1_fbm_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Squid1 feedback mode: chip select data read ('0' = Inactive, '1' = Active)

         i_pls_shp_data       => i_pls_shp_data       , -- in     t_mem_plssh_data(0     to c_NB_COL-1)     ; --! Pulse shaping coef: data read
         i_pls_shp_cs         => pls_shp_cs           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Pulse shaping coef: chip select data read ('0' = Inactive, '1' = Active)

         o_sq1_fb0_data_mx    => sq1_fb0_data_mx      , -- out    slv(c_DFLD_S1FB0_PIX_S-1 downto 0)        ; --! Squid1 feedback value in open loop: data read multiplexed
         o_sq1_fbm_data_mx    => sq1_fbm_data_mx      , -- out    slv(c_DFLD_S1FBM_PIX_S-1 downto 0)        ; --! Squid1 feedback mode: data read multiplexed
         o_pls_shp_data_mx    => pls_shp_data_mx        -- out    slv(c_DFLD_PLSSH_PLS_S-1 downto 0)          --! Pulse shaping coef: data read multiplexed
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Register to transmit management
   --    @Req : DRE-DMX-FW-REQ-0510
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_tx_wd_rd_rg : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_ep_cmd_tx_wd_rd_rg <= (others => c_EP_CMD_ERR_CLR);

      elsif rising_edge(i_clk) then

         -- @Req : REG_TM_MODE
         if    ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_TM_MODE  then
            o_ep_cmd_tx_wd_rd_rg <= tm_mode(3) & tm_mode(2) & tm_mode(1) & tm_mode(0) & tm_mode_dur;

         -- @Req : REG_SQ1_FB_MODE
         elsif ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SQ1FBMD  then
            o_ep_cmd_tx_wd_rd_rg <= rg_sq1_fb_mode;

         -- @Req : REG_SQ2_FB_MODE
         elsif ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SQ2FBMD  then
            o_ep_cmd_tx_wd_rd_rg <= rg_sq2_fb_mode;

         -- @Req : REG_Version
         elsif ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_VERSION  then
            o_ep_cmd_tx_wd_rd_rg <= std_logic_vector(to_unsigned(c_FW_VERSION, c_FW_VERSION_S)) & i_brd_model_rs & i_brd_ref_rs;

            -- @Req : REG_CY_SQ1_FB0
            -- @Req : DRE-DMX-FW-REQ-0200
         elsif ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FB0(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
               ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FB0_ADD_S)      = c_EP_CMD_ADD_S1FB0(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FB0_ADD_S) then
            o_ep_cmd_tx_wd_rd_rg <= std_logic_vector(resize(unsigned(sq1_fb0_data_mx),  o_ep_cmd_tx_wd_rd_rg'length));

         -- @Req : REG_CY_SQ1_FB_MODE
         -- @Req : DRE-DMX-FW-REQ-0210
         elsif ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FBM(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
               ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FBM_ADD_S)      = c_EP_CMD_ADD_S1FBM(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_S1FBM_ADD_S) then
            o_ep_cmd_tx_wd_rd_rg <= std_logic_vector(resize(unsigned(sq1_fbm_data_mx),  o_ep_cmd_tx_wd_rd_rg'length));

         -- @Req : REG_CY_FB1_PULSE_SHAPING
         -- @Req : DRE-DMX-FW-REQ-0230
         elsif ep_cmd_rx_wd_add_r(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSH(0)(ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
               ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      = c_EP_CMD_ADD_PLSSH(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S) then
            o_ep_cmd_tx_wd_rd_rg <= std_logic_vector(resize(unsigned(pls_shp_data_mx),  o_ep_cmd_tx_wd_rd_rg'length));

         -- @Req : REG_Status
         else
            o_ep_cmd_tx_wd_rd_rg <= ep_cmd_sts_rg_r;

        end if;

      end if;

   end process P_ep_cmd_tx_wd_rd_rg;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: TM_MODE Register writing management
   --    @Req : DRE-DMX-FW-REQ-0580
   --    @Req : REG_TM_MODE
   -- ------------------------------------------------------------------------------------------------------
   I_rg_tm_mode_mgt: entity work.rg_tm_mode_mgt port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_tm_mode_sync       => i_tm_mode_sync       , -- in     std_logic                                 ; --! Telemetry mode synchronization
         i_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data_r  , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)
         o_tm_mode_dur        => tm_mode_dur          , -- out    slv(c_DFLD_TM_MODE_DUR_S-1 downto 0)      ; --! Telemetry mode, duration field
         o_tm_mode            => tm_mode              , -- out    t_rg_tm_mode(0 to c_NB_COL-1)             ; --! Telemetry mode
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
   G_sqx_fb_mode: for k in 0 to c_NB_COL-1 generate
   begin

      I_tm_mode_dmp_cmp: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '0'                    -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => tm_mode_dmp_cmp(k)   , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_tm_mode_dmp_cmp(k)   -- out    std_logic                                   --! Signal registered
      );

      G_sq1_fb_mode: for l in 0 to c_DFLD_SQ1FBMD_COL_S-1 generate
      begin

         I_sq1_fb_mode: entity work.signal_reg generic map
         (
         g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_EP_CMD_DEF_SQ1FBMD(4*k+l) -- std_logic                                   --! Signal registered default value at reset
         )  port map
         (
         i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => rg_sq1_fb_mode(4*k+l), -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq1_fb_mode(k)(l)    -- out    std_logic                                   --! Signal registered
         );

      end generate G_sq1_fb_mode;

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

      G_sq2_fb_mode: for l in 0 to c_DFLD_SQ2FBMD_COL_S-1 generate
      begin

         I_sq2_fb_mode: entity work.signal_reg generic map
         (
         g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_EP_CMD_DEF_SQ2FBMD(4*k+l) -- std_logic                                   --! Signal registered default value at reset
         )  port map
         (
         i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => rg_sq2_fb_mode(4*k+l), -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_fb_mode(k)(l)    -- out    std_logic                                   --! Signal registered
         );

      end generate G_sq2_fb_mode;

   end generate G_sqx_fb_mode;

   -- TODO
   o_ep_cmd_sts_err_nin   <= '0';

end architecture RTL;
