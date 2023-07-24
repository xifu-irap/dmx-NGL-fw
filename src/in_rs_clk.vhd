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
--!   @file                   in_rs_clk.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Data resynchronization on System Clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

entity in_rs_clk is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_brd_ref            : in     std_logic_vector(     c_BRD_REF_S-1 downto 0)                        ; --! Board reference
         i_brd_model          : in     std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                        ; --! Board model
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_ras_data_valid     : in     std_logic                                                            ; --! RAS Data valid ('0' = No, '1' = Yes)

         i_hk_spi_miso        : in     std_logic                                                            ; --! HouseKeeping: SPI Master Input Slave Output

         i_ep_spi_mosi        : in     std_logic                                                            ; --! EP: SPI Master Input Slave Output (MSB first)
         i_ep_spi_sclk        : in     std_logic                                                            ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        : in     std_logic                                                            ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_brd_ref_rs         : out    std_logic_vector(     c_BRD_REF_S-1 downto 0)                        ; --! Board reference, synchronized on System Clock
         o_brd_model_rs       : out    std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                        ; --! Board model, synchronized on System Clock
         o_sync_rs            : out    std_logic_vector(        c_NB_COL   downto 0)                        ; --! Pixel sequence synchronization, synchronized on System Clock
         o_ras_data_valid_rs  : out    std_logic                                                            ; --! RAS Data valid, synchronized on System Clock ('0' = No, '1' = Yes)

         o_hk_spi_miso_rs     : out    std_logic                                                            ; --! HouseKeeping: SPI Master Input Slave Output, synchronized on System Clock

         o_ep_spi_mosi_rs     : out    std_logic                                                            ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
         o_ep_spi_sclk_rs     : out    std_logic                                                            ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
         o_ep_spi_cs_n_rs     : out    std_logic                                                              --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );
end entity in_rs_clk;

architecture RTL of in_rs_clk is
signal   inhib_fst_per        : std_logic_vector(1 downto 0)                                                ; --! Inhibit first periods after reset de-assertion

signal   brd_ref_r            : t_slv_arr(0 to c_FF_RSYNC_NB-1)(  c_BRD_REF_S-1 downto 0)                   ; --! Board reference register
signal   brd_model_r          : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_BRD_MODEL_S-1 downto 0)                   ; --! Board model register
signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   ras_data_valid_r     : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! RAS Data valid register ('0' = No, '1' = Yes)

signal   hk_spi_miso_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! HouseKeeping: SPI Master Input Slave Output register

signal   ep_spi_mosi_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP: SPI Master Input Slave Output register (MSB first)
signal   ep_spi_sclk_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP: SPI Serial Clock register (CPOL = '0', CPHA = '0')
signal   ep_spi_cs_n_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP: SPI Chip Select register ('0' = Active, '1' = Inactive)

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of o_sync_rs           : signal is true                                     ; --! Disabling signal optimization: o_sync_rs

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         inhib_fst_per        <= (others => c_LOW_LEV);

         brd_ref_r            <= (others => c_ZERO(brd_ref_r(brd_ref_r'low)'range));
         brd_model_r          <= (others => c_ZERO(brd_model_r(brd_model_r'low)'range));
         hk_spi_miso_r        <= (others => c_LOW_LEV);

         if c_PAD_REG_SET_AUTH = c_LOW_LEV then
            sync_r         <= (sync_r'low        => c_LOW_LEV, others => c_I_SYNC_DEF);
            ep_spi_sclk_r  <= (ep_spi_sclk_r'low => c_LOW_LEV, others => c_I_SPI_SCLK_DEF);
            ep_spi_cs_n_r  <= (ep_spi_cs_n_r'low => c_LOW_LEV, others => c_I_SPI_CS_N_DEF);

         else
            sync_r         <= (others => c_I_SYNC_DEF);
            ep_spi_sclk_r  <= (others => c_I_SPI_SCLK_DEF);
            ep_spi_cs_n_r  <= (others => c_I_SPI_CS_N_DEF);

         end if;

         ep_spi_mosi_r     <= (others => c_LOW_LEV);
         o_sync_rs         <= (others => c_LOW_LEV);
         ras_data_valid_r  <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         inhib_fst_per     <= inhib_fst_per(inhib_fst_per'high-1 downto 0) & c_HGH_LEV;

         brd_ref_r         <= i_brd_ref   & brd_ref_r(  0 to brd_ref_r'high-1);
         brd_model_r       <= i_brd_model & brd_model_r(0 to brd_model_r'high-1);
         hk_spi_miso_r     <= hk_spi_miso_r(hk_spi_miso_r'high-1 downto 0) & i_hk_spi_miso;

         sync_r            <= sync_r(              sync_r'high-1 downto 0) & i_sync;
         ep_spi_sclk_r     <= ep_spi_sclk_r(ep_spi_sclk_r'high-1 downto 0) & i_ep_spi_sclk;
         ep_spi_cs_n_r     <= ep_spi_cs_n_r(ep_spi_cs_n_r'high-1 downto 0) & i_ep_spi_cs_n;
         ep_spi_mosi_r     <= ep_spi_mosi_r(ep_spi_mosi_r'high-1 downto 0) & i_ep_spi_mosi;

         o_sync_rs         <= (others => ((inhib_fst_per(inhib_fst_per'high) and sync_r(sync_r'high)) or (not(inhib_fst_per(inhib_fst_per'high)) and c_I_SYNC_DEF)));
         ras_data_valid_r  <= ras_data_valid_r(ras_data_valid_r'high-1 downto 0) & i_ras_data_valid;

      end if;

   end process P_rsync;

   o_brd_ref_rs            <= brd_ref_r(brd_ref_r'high);
   o_brd_model_rs          <= brd_model_r(brd_model_r'high);
   o_hk_spi_miso_rs        <= hk_spi_miso_r(hk_spi_miso_r'high);
   o_ras_data_valid_rs     <= ras_data_valid_r(ras_data_valid_r'high);
   o_ep_spi_mosi_rs        <= ep_spi_mosi_r(ep_spi_mosi_r'high);

   G_pad_reg_set_auth_0: if c_PAD_REG_SET_AUTH = c_LOW_LEV generate
      o_ep_spi_sclk_rs     <= (inhib_fst_per(inhib_fst_per'high) and ep_spi_sclk_r(ep_spi_sclk_r'high))   or (not(inhib_fst_per(inhib_fst_per'high)) and c_I_SPI_SCLK_DEF);
      o_ep_spi_cs_n_rs     <= (inhib_fst_per(inhib_fst_per'high) and ep_spi_cs_n_r(ep_spi_cs_n_r'high))   or (not(inhib_fst_per(inhib_fst_per'high)) and c_I_SPI_CS_N_DEF);

   end generate G_pad_reg_set_auth_0;

   G_pad_reg_set_auth_1: if c_PAD_REG_SET_AUTH = c_HGH_LEV generate
      o_ep_spi_sclk_rs     <= ep_spi_sclk_r(ep_spi_sclk_r'high);
      o_ep_spi_cs_n_rs     <= ep_spi_cs_n_r(ep_spi_cs_n_r'high);

   end generate G_pad_reg_set_auth_1;

end architecture RTL;
