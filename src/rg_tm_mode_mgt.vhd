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
--!   @file                   rg_tm_mode_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Register TM_MODE management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity rg_tm_mode_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_tm_mode_sync       : in     std_logic                                                            ; --! Telemetry mode synchronization

         i_cs_rg_tm_mode      : in     std_logic                                                            ; --! Chip selects register TM_MODE
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy : in     std_logic                                                            ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_tm_mode_dur        : out    std_logic_vector(c_DFLD_TM_MODE_DUR_S-1 downto 0)                    ; --! Telemetry mode, duration field
         o_tm_mode            : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)          ; --! Telemetry mode

         o_tm_mode_dmp_cmp    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         o_tm_mode_st_dump    : out    std_logic                                                              --! Telemetry mode, status "Dump" ('0' = Inactive, '1' = Active)
   );
end entity rg_tm_mode_mgt;

architecture RTL of rg_tm_mode_mgt is
signal   rg_tm_mode_req_new   : std_logic                                                                   ; --! EP register: Telemetry mode requested new command ('0' = Inactive, '1' = Active)

signal   rg_tm_mode_req       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)                 ; --! EP register: Telemetry mode requested
signal   rg_tm_mode_req_dump  : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)                 ; --! EP register: Telemetry mode, status "Dump" requested
signal   rg_tm_mode           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)                 ; --! EP register: Telemetry mode
signal   rg_tm_mode_sav       : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_TM_MODE_COL_S-1 downto 0)                 ; --! EP register: Telemetry mode save

signal   rg_tm_mode_dur_req   : std_logic_vector(c_DFLD_TM_MODE_DUR_S downto 0)                             ; --! EP register: Telemetry mode duration requested
signal   rg_tm_mode_dur       : std_logic_vector(c_DFLD_TM_MODE_DUR_S downto 0)                             ; --! EP register: Telemetry mode duration

signal   tm_mode_dmp_req_and  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode requested, status "Dump" column select "and-ed"
signal   tm_mode_dmp_req_cmp  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode requested, status "Dump" compared
signal   tm_mode_dmp_req_or   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode requested, status "Dump" column select "or-ed"

signal   tm_mode_dmp_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared
signal   tm_mode_dmp_or       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" column select "or-ed"

signal   tm_mode_tst_req_cmp  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode requested, status "Test pattern" compared
signal   tm_mode_tst_req_or   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode requested, status "Test pattern" column select "or-ed"

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Telemetry mode, status "Dump" and "Test pattern"
   -- ------------------------------------------------------------------------------------------------------
   tm_mode_dmp_req_and(0) <= '1';
   tm_mode_dmp_req_or(0)  <= tm_mode_dmp_req_cmp(0);
   tm_mode_dmp_or(0)      <= tm_mode_dmp_cmp(0);
   tm_mode_tst_req_or(0)  <= tm_mode_tst_req_cmp(0);

   G_tm_mode_st_dump : for k in 0 to c_NB_COL-1 generate
   begin

      G_tm_mode_st_dump_k0: if k /= 0 generate
         tm_mode_dmp_req_and(k) <= not(tm_mode_dmp_req_cmp(k-1)) and tm_mode_dmp_req_and(k-1);
         tm_mode_dmp_req_or(k)  <= tm_mode_dmp_req_cmp(k) or tm_mode_dmp_req_or(k-1);
         tm_mode_dmp_or(k)      <= tm_mode_dmp_cmp(k) or tm_mode_dmp_or(k-1);
         tm_mode_tst_req_or(k)  <= tm_mode_tst_req_cmp(k) or tm_mode_tst_req_or(k-1);

      end generate;

      tm_mode_dmp_req_cmp(k)  <= '1' when rg_tm_mode_req(k) = c_DST_TM_MODE_DUMP else '0';
      tm_mode_dmp_cmp(k)      <= '1' when rg_tm_mode(k)     = c_DST_TM_MODE_DUMP else '0';
      tm_mode_tst_req_cmp(k)  <= '1' when rg_tm_mode_req(k) = c_DST_TM_MODE_TEST else '0';

      rg_tm_mode_req_dump(k)  <= c_DST_TM_MODE_DUMP when (tm_mode_dmp_req_cmp(k) and tm_mode_dmp_req_and(k)) = '1' else c_DST_TM_MODE_IDLE;

   end generate G_tm_mode_st_dump;

   o_tm_mode_st_dump    <= tm_mode_dmp_req_or(tm_mode_dmp_req_or'high) or tm_mode_dmp_or(tm_mode_dmp_or'high);
   o_tm_mode_dmp_cmp    <= tm_mode_dmp_cmp;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP register: Telemetry mode save and duration request
   -- ------------------------------------------------------------------------------------------------------
   P_rg_tm_mode_sav_dur : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         rg_tm_mode_dur_req   <= std_logic_vector(to_signed(c_EP_CMD_DEF_TMDE_DR-2, rg_tm_mode_dur_req'length));
         rg_tm_mode_sav       <= (others => c_EP_CMD_DEF_TM_MODE);

      elsif rising_edge(i_clk) then

         -- Case new EP command to write (TM_MODE Duration requested, save current column telemetry modes)
         if i_ep_cmd_rx_nerr_rdy = '1' and i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_W and i_cs_rg_tm_mode = '1' then
            rg_tm_mode_dur_req   <= std_logic_vector(resize(unsigned(i_ep_cmd_rx_wd_data(c_DFLD_TM_MODE_DUR_S-1 downto 0)), rg_tm_mode_dur'length) - 2);
            rg_tm_mode_sav       <= rg_tm_mode;

         end if;

      end if;

   end process P_rg_tm_mode_sav_dur;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP register: Telemetry mode requested new command
   -- ------------------------------------------------------------------------------------------------------
   P_rg_tm_mode_req_new : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         rg_tm_mode_req_new <= '0';

      elsif rising_edge(i_clk) then

         if i_ep_cmd_rx_nerr_rdy = '1' and i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_W and i_cs_rg_tm_mode = '1' then
            rg_tm_mode_req_new <= '1';

         elsif i_tm_mode_sync = '1' then
            rg_tm_mode_req_new <= '0';

         end if;

      end if;

   end process P_rg_tm_mode_req_new;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP register: Telemetry mode requested
   -- ------------------------------------------------------------------------------------------------------
   G_rg_tm_mode_req : for k in 0 to c_NB_COL-1 generate
   begin

      P_rg_tm_mode_req : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            rg_tm_mode_req(k)    <= c_EP_CMD_DEF_TM_MODE;

         elsif rising_edge(i_clk) then

            -- Case new EP command to write
            if i_ep_cmd_rx_nerr_rdy = '1' and i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_W and i_cs_rg_tm_mode = '1' then
               rg_tm_mode_req(k)    <= i_ep_cmd_rx_wd_data((k+1)*c_DFLD_TM_MODE_COL_S + c_DFLD_TM_MODE_DUR_S-1 downto k*c_DFLD_TM_MODE_COL_S + c_DFLD_TM_MODE_DUR_S);

            -- Case new Pixel sequence start, end of duration detected or Telemetry mode requested new command
            --   Channel telemetry mode "Dump" activated (only one activated dump mode among c_NB_COL columns, priority from the first column to the last one)
            elsif (i_tm_mode_sync and (rg_tm_mode_dur(rg_tm_mode_dur'high) or rg_tm_mode_req_new) and tm_mode_dmp_req_cmp(k) and tm_mode_dmp_req_and(k)) = '1' then

               -- Load column Telemetry mode requested in Idle if the last mode before "Dump" activation was "Test Pattern"
               if rg_tm_mode_sav(k) = c_DST_TM_MODE_TEST then
                  rg_tm_mode_req(k) <= c_DST_TM_MODE_IDLE;

               -- Else load column Telemetry mode requested in the last mode before "Dump" activation
               else
                  rg_tm_mode_req(k) <= rg_tm_mode_sav(k);

               end if;

            elsif (i_tm_mode_sync and (rg_tm_mode_dur(rg_tm_mode_dur'high) or rg_tm_mode_req_new) and not(tm_mode_dmp_req_or(tm_mode_dmp_req_or'high)) and tm_mode_tst_req_or(tm_mode_tst_req_or'high)) = '1' then
               rg_tm_mode_req(k) <= c_DST_TM_MODE_IDLE;

            end if;
         end if;

      end process P_rg_tm_mode_req;

   end generate G_rg_tm_mode_req;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP register: Telemetry mode
   -- ------------------------------------------------------------------------------------------------------
   G_rg_tm_mode : for k in 0 to c_NB_COL-1 generate
   begin

      P_rg_tm_mode : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            rg_tm_mode(k)        <= c_EP_CMD_DEF_TM_MODE;

         elsif rising_edge(i_clk) then

            -- Case new Pixel sequence start, end of duration detected or Telemetry mode requested new command, a "Dump" telemetry mode activated on one or more columns,
            --  load telemetry mode requested (only one activated dump mode among c_NB_COL columns, priority from the first column to the last one)
            if (i_tm_mode_sync and (rg_tm_mode_dur(rg_tm_mode_dur'high) or rg_tm_mode_req_new) and tm_mode_dmp_req_or(tm_mode_dmp_req_or'high)) = '1' then
               rg_tm_mode(k) <= rg_tm_mode_req_dump(k);

            --  Case new Pixel sequence start, end of duration detected, no more "Dump" telemetry mode activated but one "Dump" mode currently activated
            --   load telemetry mode requested
            elsif (i_tm_mode_sync and rg_tm_mode_dur(rg_tm_mode_dur'high) and tm_mode_dmp_or(tm_mode_dmp_or'high)) = '1' then
               rg_tm_mode(k) <= rg_tm_mode_req(k);

            -- Case new Pixel sequence start, end of duration detected, a "Test Pattern" telemetry mode activated on corresponding column,
            --  "Duration" different to infinity value change telemetry mode to Idle
            elsif (i_tm_mode_sync and rg_tm_mode_dur(rg_tm_mode_dur'high) and rg_tm_mode_dur(rg_tm_mode_dur'low)) = '1' and rg_tm_mode(k) = c_DST_TM_MODE_TEST then
               rg_tm_mode(k) <= c_DST_TM_MODE_IDLE;

            -- Case new Pixel sequence start, telemetry mode requested new command, load telemetry mode requested
            elsif (i_tm_mode_sync and rg_tm_mode_req_new) = '1' then
               rg_tm_mode(k) <= rg_tm_mode_req(k);

            end if;

         end if;

      end process P_rg_tm_mode;

   end generate G_rg_tm_mode;

   o_tm_mode   <= rg_tm_mode;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP register: Telemetry mode duration
   -- ------------------------------------------------------------------------------------------------------
   P_rg_tm_mode_dur : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         rg_tm_mode_dur       <= std_logic_vector(to_signed(c_EP_CMD_DEF_TMDE_DR-2, rg_tm_mode_dur'length));

      elsif rising_edge(i_clk) then

         -- Case new Pixel sequence start, end of duration detected or Telemetry mode requested new command, a "Dump" telemetry mode activated on one or more columns,
         --  load telemetry mode duration to Dump mode duration value
         if (i_tm_mode_sync and (rg_tm_mode_dur(rg_tm_mode_dur'high) or rg_tm_mode_req_new) and tm_mode_dmp_req_or(tm_mode_dmp_req_or'high)) = '1' then
            rg_tm_mode_dur <= std_logic_vector(to_signed(c_D_TM_MODE_DUR_DUMP-2, rg_tm_mode_dur'length));

         -- Case new Pixel sequence start, telemetry mode requested new command,
         --  a "Test Pattern" telemetry mode requested activated on one or more columns, load telemetry mode duration requested
         elsif (i_tm_mode_sync and (rg_tm_mode_dur(rg_tm_mode_dur'high) or rg_tm_mode_req_new) and tm_mode_tst_req_or(tm_mode_tst_req_or'high)) = '1' then
            rg_tm_mode_dur <= rg_tm_mode_dur_req;

         -- Case new Pixel sequence start, telemetry mode requested new command,
         --  "Test Pattern" telemetry mode requested not activated on one or more columns, load telemetry mode duration to infinity value
         elsif (i_tm_mode_sync and rg_tm_mode_req_new and not(tm_mode_tst_req_or(tm_mode_tst_req_or'high))) = '1' then
            rg_tm_mode_dur <= std_logic_vector(to_signed(c_D_TM_MODE_DUR_INF-2, rg_tm_mode_dur'length));

         -- Case new Pixel sequence start, end of duration detected, load telemetry mode duration to infinity value
         elsif (i_tm_mode_sync and rg_tm_mode_dur(rg_tm_mode_dur'high)) = '1' then
            rg_tm_mode_dur <= std_logic_vector(to_signed(c_D_TM_MODE_DUR_INF-2, rg_tm_mode_dur'length));

         -- Case new Pixel sequence start, end of duration not reached
         elsif (i_tm_mode_sync and not(rg_tm_mode_dur(rg_tm_mode_dur'high))) = '1' then
            rg_tm_mode_dur <= std_logic_vector(signed(rg_tm_mode_dur) - 1);

         end if;

      end if;

   end process P_rg_tm_mode_dur;

   o_tm_mode_dur  <= std_logic_vector(signed(rg_tm_mode_dur(o_tm_mode_dur'high downto 0))+2);

end architecture RTL;
