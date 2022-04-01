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
--!   @file                   mem_data_rd_mux.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Memory data read multiplexer
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity mem_data_rd_mux is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sq1_fb0_data       : in     t_mem_s1fb0_data(0     to c_NB_COL-1)                                ; --! Squid1 feedback value in open loop: data read
         i_sq1_fb0_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid1 feedback value in open loop: chip select data read ('0' = Inactive,'1'=Active)

         i_sq1_fbm_data       : in     t_mem_s1fbm_data(0     to c_NB_COL-1)                                ; --! Squid1 feedback mode: data read
         i_sq1_fbm_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid1 feedback mode: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_lkp_data       : in     t_mem_s2lkp_data(0     to c_NB_COL-1)                                ; --! Squid2 feedback lockpoint: data read
         i_sq2_lkp_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid2 feedback lockpoint: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_dac_lsb_data   : in     t_rg_sq2lkp(     0     to c_NB_COL-1)                                ; --! Squid2 DAC LSB: data read
         i_sq2_dac_lsb_cs     : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid2 DAC LSB: chip select data read ('0' = Inactive, '1' = Active)

         i_sq2_lkp_off_data   : in     t_rg_sq2lkp(     0     to c_NB_COL-1)                                ; --! Squid2 feedback lockpoint offset: data read
         i_sq2_lkp_off_cs     : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Squid2 feedback lockpoint offset: chip select data read ('0' = Inactive,'1' = Active)

         i_pls_shp_data       : in     t_mem_plssh_data(0     to c_NB_COL-1)                                ; --! Pulse shaping coef: data read
         i_pls_shp_cs         : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Pulse shaping coef: chip select data read ('0' = Inactive, '1' = Active)

         o_sq1_fb0_data_mx    : out    std_logic_vector(c_DFLD_S1FB0_PIX_S-1 downto 0)                      ; --! Squid1 feedback value in open loop: data read multiplexed
         o_sq1_fbm_data_mx    : out    std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0)                      ; --! Squid1 feedback mode: data read multiplexed
         o_sq2_lkp_data_mx    : out    std_logic_vector(c_DFLD_S2LKP_PIX_S-1 downto 0)                      ; --! Squid2 feedback lockpoint: data read multiplexed
         o_sq2_dac_lsb_dta_mx : out    std_logic_vector(c_DFLD_S2LSB_COL_S-1 downto 0)                      ; --! Squid2 DAC LSB: data read multiplexed
         o_sq2_lkp_off_dta_mx : out    std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                      ; --! Squid2 feedback lockpoint offset: data read multiplexed
         o_pls_shp_data_mx    : out    std_logic_vector(c_DFLD_PLSSH_PLS_S-1 downto 0)                        --! Pulse shaping coef: data read multiplexed

   );
end entity mem_data_rd_mux;

architecture RTL of mem_data_rd_mux is
type     t_cs_v                is array (natural range <>) of std_logic_vector(c_NB_COL-1  downto 0)        ; --! Chip select vector type

signal   sq1_fb0_cs_r         : t_cs_v(0 to c_MEM_RD_DATA_NPER)                                             ; --! Squid1 feedback value in open loop: chip select data read register
signal   sq1_fb0_cs_msb_or    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid1 feedback value in open loop: chip select data read msb "or-ed"
signal   sq1_fb0_data_cmp     : t_mem_s1fb0_data(0 to c_NB_COL-1)                                           ; --! Squid1 feedback value in open loop: data read compared
signal   sq1_fb0_data_or      : t_mem_s1fb0_data(0 to c_NB_COL-1)                                           ; --! Squid1 feedback value in open loop: data read "or-ed"

signal   sq1_fbm_cs_r         : t_cs_v(0 to c_MEM_RD_DATA_NPER)                                             ; --! Squid1 feedback mode: chip select data read register
signal   sq1_fbm_cs_msb_or    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid1 feedback mode: chip select data read msb "or-ed"
signal   sq1_fbm_data_cmp     : t_mem_s1fbm_data(0 to c_NB_COL-1)                                           ; --! Squid1 feedback mode: data read compared
signal   sq1_fbm_data_or      : t_mem_s1fbm_data(0 to c_NB_COL-1)                                           ; --! Squid1 feedback mode: data read "or-ed"

signal   sq2_lkp_cs_r         : t_cs_v(0 to c_MEM_RD_DATA_NPER)                                             ; --! Squid2 feedback lockpoint: chip select data read register
signal   sq2_lkp_cs_msb_or    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid2 feedback lockpoint: chip select data read msb "or-ed"
signal   sq2_lkp_data_cmp     : t_mem_s2lkp_data(0 to c_NB_COL-1)                                           ; --! Squid2 feedback lockpoint: data read compared
signal   sq2_lkp_data_or      : t_mem_s2lkp_data(0 to c_NB_COL-1)                                           ; --! Squid2 feedback lockpoint: data read "or-ed"

signal   sq2_dac_lsb_cs_r     : t_cs_v(0 to c_MEM_RD_DATA_NPER)                                             ; --! Squid2 DAC LSB: chip select data read register
signal   sq2_dac_lsb_cs_msb_or: std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid2 DAC LSB: chip select data read msb "or-ed"
signal   sq2_dac_lsb_data_cmp : t_rg_sq2lkp(0 to c_NB_COL-1)                                                ; --! Squid2 DAC LSB: data read compared
signal   sq2_dac_lsb_data_or  : t_rg_sq2lkp(0 to c_NB_COL-1)                                                ; --! Squid2 DAC LSB: data read "or-ed"

signal   sq2_lkp_off_cs_r     : t_cs_v(0 to c_MEM_RD_DATA_NPER)                                             ; --! Squid2 feedback lockpoint offset: chip select data read register
signal   sq2_lkp_off_cs_msb_or: std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Squid2 feedback lockpoint offset: chip select data read msb "or-ed"
signal   sq2_lkp_off_data_cmp : t_rg_sq2lkp(0 to c_NB_COL-1)                                                ; --! Squid2 feedback lockpoint offset: data read compared
signal   sq2_lkp_off_data_or  : t_rg_sq2lkp(0 to c_NB_COL-1)                                                ; --! Squid2 feedback lockpoint offset: data read "or-ed"

signal   pls_shp_cs_r         : t_cs_v(0 to c_MEM_RD_DATA_NPER)                                             ; --! Pulse shaping coef: chip select data read register
signal   pls_shp_cs_msb_or    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Pulse shaping coef: chip select data read msb "or-ed"
signal   pls_shp_data_cmp     : t_mem_plssh_data(0 to c_NB_COL-1)                                           ; --! Pulse shaping coef: data read compared
signal   pls_shp_data_or      : t_mem_plssh_data(0 to c_NB_COL-1)                                           ; --! Pulse shaping coef: data read "or-ed"

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Memories chip select registered
   -- ------------------------------------------------------------------------------------------------------
   P_cs_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sq1_fb0_cs_r      <= (others => (others => '0'));
         sq1_fbm_cs_r      <= (others => (others => '0'));
         sq2_lkp_cs_r      <= (others => (others => '0'));
         sq2_dac_lsb_cs_r  <= (others => (others => '0'));
         sq2_lkp_off_cs_r  <= (others => (others => '0'));
         pls_shp_cs_r      <= (others => (others => '0'));

      elsif rising_edge(i_clk) then
         sq1_fb0_cs_r      <= i_sq1_fb0_cs      & sq1_fb0_cs_r(    0 to sq1_fb0_cs_r'high-1);
         sq1_fbm_cs_r      <= i_sq1_fbm_cs      & sq1_fbm_cs_r(    0 to sq1_fbm_cs_r'high-1);
         sq2_lkp_cs_r      <= i_sq2_lkp_cs      & sq2_lkp_cs_r(    0 to sq2_lkp_cs_r'high-1);
         sq2_dac_lsb_cs_r  <= i_sq2_dac_lsb_cs  & sq2_dac_lsb_cs_r(0 to sq2_dac_lsb_cs_r'high-1);
         sq2_lkp_off_cs_r  <= i_sq2_lkp_off_cs  & sq2_lkp_off_cs_r(0 to sq2_lkp_off_cs_r'high-1);
         pls_shp_cs_r      <= i_pls_shp_cs      & pls_shp_cs_r(    0 to pls_shp_cs_r'high-1);

      end if;

   end process P_cs_r;


   -- ------------------------------------------------------------------------------------------------------
   --!   Chip select data read msb "or-ed" first seed
   -- ------------------------------------------------------------------------------------------------------
   sq1_fb0_cs_msb_or(0)       <= sq1_fb0_cs_r(sq1_fb0_cs_r'high)(0);
   sq1_fbm_cs_msb_or(0)       <= sq1_fbm_cs_r(sq1_fbm_cs_r'high)(0);
   sq2_lkp_cs_msb_or(0)       <= sq2_lkp_cs_r(sq2_lkp_cs_r'high)(0);
   sq2_dac_lsb_cs_msb_or(0)   <= sq2_dac_lsb_cs_r(sq2_dac_lsb_cs_r'high)(0);
   sq2_lkp_off_cs_msb_or(0)   <= sq2_lkp_off_cs_r(sq2_lkp_off_cs_r'high)(0);
   pls_shp_cs_msb_or(0)       <= pls_shp_cs_r(pls_shp_cs_r'high)(0);

   -- ------------------------------------------------------------------------------------------------------
   --!   Data read "or-ed" first seed
   -- ------------------------------------------------------------------------------------------------------
   sq1_fb0_data_or(0)      <= sq1_fb0_data_cmp(0);
   sq1_fbm_data_or(0)      <= sq1_fbm_data_cmp(0);
   sq2_lkp_data_or(0)      <= sq2_lkp_data_cmp(0);
   sq2_dac_lsb_data_or(0)  <= sq2_dac_lsb_data_cmp(0);
   sq2_lkp_off_data_or(0)  <= sq2_lkp_off_data_cmp(0);
   pls_shp_data_or(0)      <= pls_shp_data_cmp(0);

   -- ------------------------------------------------------------------------------------------------------
   --!   Columns management
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      G_col_k0: if k /= 0 generate
         -- ------------------------------------------------------------------------------------------------------
         --!   Chip select data read msb "or-ed" first seed
         -- ------------------------------------------------------------------------------------------------------
         sq1_fb0_cs_msb_or(k)       <= sq1_fb0_cs_r(   sq1_fb0_cs_r'high)(k)      or sq1_fb0_cs_msb_or(k-1);
         sq1_fbm_cs_msb_or(k)       <= sq1_fbm_cs_r(   sq1_fbm_cs_r'high)(k)      or sq1_fbm_cs_msb_or(k-1);
         sq2_lkp_cs_msb_or(k)       <= sq2_lkp_cs_r(   sq2_lkp_cs_r'high)(k)      or sq2_lkp_cs_msb_or(k-1);
         sq2_dac_lsb_cs_msb_or(k)   <= sq2_dac_lsb_cs_r(sq2_dac_lsb_cs_r'high)(k) or sq2_dac_lsb_cs_msb_or(k-1);
         sq2_lkp_off_cs_msb_or(k)   <= sq2_lkp_off_cs_r(sq2_lkp_off_cs_r'high)(k) or sq2_lkp_off_cs_msb_or(k-1);
         pls_shp_cs_msb_or(k)       <= pls_shp_cs_r(    pls_shp_cs_r'high)(k)     or pls_shp_cs_msb_or(k-1);

         -- ------------------------------------------------------------------------------------------------------
         --!   Data read "or-ed"
         -- ------------------------------------------------------------------------------------------------------
         sq1_fb0_data_or(k)      <= sq1_fb0_data_cmp(k)     or sq1_fb0_data_or(k-1);
         sq1_fbm_data_or(k)      <= sq1_fbm_data_cmp(k)     or sq1_fbm_data_or(k-1);
         sq2_lkp_data_or(k)      <= sq2_lkp_data_cmp(k)     or sq2_lkp_data_or(k-1);
         sq2_dac_lsb_data_or(k)  <= sq2_dac_lsb_data_cmp(k) or sq2_dac_lsb_data_or(k-1);
         sq2_lkp_off_data_or(k)  <= sq2_lkp_off_data_cmp(k) or sq2_lkp_off_data_or(k-1);
         pls_shp_data_or(k)      <= pls_shp_data_cmp(k)     or pls_shp_data_or(k-1);

      end generate;

      -- ------------------------------------------------------------------------------------------------------
      --!   Data read compared
      -- ------------------------------------------------------------------------------------------------------
      P_data_cmp_r : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sq1_fb0_data_cmp(k)     <= (others => '0');
            sq1_fbm_data_cmp(k)     <= (others => '0');
            sq2_lkp_data_cmp(k)     <= (others => '0');
            sq2_dac_lsb_data_cmp(k) <= (others => '0');
            sq2_lkp_off_data_cmp(k) <= (others => '0');
            pls_shp_data_cmp(k)     <= (others => '0');

         elsif rising_edge(i_clk) then
            if    sq1_fb0_cs_r(sq1_fb0_cs_r'high)(k) = '1' then
               sq1_fb0_data_cmp(k)  <= i_sq1_fb0_data(k);

            elsif sq1_fb0_cs_msb_or(sq1_fb0_cs_msb_or'high) = '1' then
               sq1_fb0_data_cmp(k)  <= (others => '0');

            end if;

            if    sq1_fbm_cs_r(sq1_fbm_cs_r'high)(k) = '1' then
               sq1_fbm_data_cmp(k)  <= i_sq1_fbm_data(k);

            elsif sq1_fbm_cs_msb_or(sq1_fbm_cs_msb_or'high) = '1' then
               sq1_fbm_data_cmp(k)  <= (others => '0');

            end if;

            if    sq2_lkp_cs_r(sq2_lkp_cs_r'high)(k) = '1' then
               sq2_lkp_data_cmp(k)  <= i_sq2_lkp_data(k);

            elsif sq2_lkp_cs_msb_or(sq2_lkp_cs_msb_or'high) = '1' then
               sq2_lkp_data_cmp(k)  <= (others => '0');

            end if;

            if    sq2_dac_lsb_cs_r(sq2_dac_lsb_cs_r'high)(k) = '1' then
               sq2_dac_lsb_data_cmp(k)  <= i_sq2_dac_lsb_data(k);

            elsif sq2_dac_lsb_cs_msb_or(sq2_dac_lsb_cs_msb_or'high) = '1' then
               sq2_dac_lsb_data_cmp(k)  <= (others => '0');

            end if;

            if    sq2_lkp_off_cs_r(sq2_lkp_off_cs_r'high)(k) = '1' then
               sq2_lkp_off_data_cmp(k)  <= i_sq2_lkp_off_data(k);

            elsif sq2_lkp_off_cs_msb_or(sq2_lkp_off_cs_msb_or'high) = '1' then
               sq2_lkp_off_data_cmp(k)  <= (others => '0');

            end if;

            if    pls_shp_cs_r(pls_shp_cs_r'high)(k) = '1' then
               pls_shp_data_cmp(k)  <= i_pls_shp_data(k);

            elsif pls_shp_cs_msb_or(pls_shp_cs_msb_or'high) = '1' then
               pls_shp_data_cmp(k)  <= (others => '0');

            end if;

         end if;

      end process P_data_cmp_r;

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data read multiplexed
   -- ------------------------------------------------------------------------------------------------------
   P_data_mx : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sq1_fb0_data_mx    <= (others => '0');
         o_sq1_fbm_data_mx    <= (others => '0');
         o_sq2_lkp_data_mx    <= (others => '0');
         o_sq2_dac_lsb_dta_mx <= (others => '0');
         o_sq2_lkp_off_dta_mx <= (others => '0');
         o_pls_shp_data_mx    <= (others => '0');

      elsif rising_edge(i_clk) then
         o_sq1_fb0_data_mx    <= sq1_fb0_data_or(sq1_fb0_data_or'high);
         o_sq1_fbm_data_mx    <= sq1_fbm_data_or(sq1_fbm_data_or'high);
         o_sq2_lkp_data_mx    <= sq2_lkp_data_or(sq2_lkp_data_or'high);
         o_sq2_dac_lsb_dta_mx <= sq2_dac_lsb_data_or(sq2_dac_lsb_data_or'high);
         o_sq2_lkp_off_dta_mx <= sq2_lkp_off_data_or(sq2_lkp_off_data_or'high);
         o_pls_shp_data_mx    <= pls_shp_data_or(pls_shp_data_or'high);

      end if;

   end process P_data_mx;

end architecture RTL;
