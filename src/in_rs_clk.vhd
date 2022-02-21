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
use     work.pkg_project.all;

entity in_rs_clk is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_brd_ref            : in     std_logic_vector(     c_BRD_REF_S-1 downto 0)                        ; --! Board reference
         i_brd_model          : in     std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                        ; --! Board model
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_hk1_spi_miso       : in     std_logic                                                            ; --! HouseKeeping 1 - SPI Master Input Slave Output

         i_ep_spi_mosi        : in     std_logic                                                            ; --! EP - SPI Master Input Slave Output (MSB first)
         i_ep_spi_sclk        : in     std_logic                                                            ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         i_ep_spi_cs_n        : in     std_logic                                                            ; --! EP - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_brd_ref_rs         : out    std_logic_vector(     c_BRD_REF_S-1 downto 0)                        ; --! Board reference, synchronized on System Clock
         o_brd_model_rs       : out    std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                        ; --! Board model, synchronized on System Clock
         o_sync_rs            : out    std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         o_sync_sq1_adc_rs    : out    std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! Pixel sequence synchronization for squid1 ADC, synchronized on System Clock
         o_sync_sq1_dac_rs    : out    std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! Pixel sequence synchronization for squid1 DAC, synchronized on System Clock
         o_sync_sq2_dac_rs    : out    std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! Pixel sequence synchronization for squid2 DAC, synchronized on System Clock

         o_hk1_spi_miso_rs    : out    std_logic                                                            ; --! HouseKeeping 1 - SPI Master Input Slave Output, synchronized on System Clock

         o_ep_spi_mosi_rs     : out    std_logic                                                            ; --! EP - SPI Master Input Slave Output (MSB first), synchronized on System Clock
         o_ep_spi_sclk_rs     : out    std_logic                                                            ; --! EP - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’), synchronized on System Clock
         o_ep_spi_cs_n_rs     : out    std_logic                                                              --! EP - SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );
end entity in_rs_clk;

architecture RTL of in_rs_clk is
signal   sync_r               : std_logic                                                                   ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel sequence synchronization, synchronized on System Clock
   -- ------------------------------------------------------------------------------------------------------
   I_sync_r: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RSYNC_NB-1      , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SYNC_DEF           -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_sync               , -- in     std_logic                                 ; --! Signal
         o_sig_r              => sync_r                 -- out    std_logic                                   --! Signal registered
   );

   I_sync_rs: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SYNC_DEF           -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => sync_r               , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sync_rs              -- out    std_logic                                   --! Signal registered
   );

   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      I_sync_sq1_adc_rs: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SYNC_DEF           -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => sync_r               , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sync_sq1_adc_rs(k)   -- out    std_logic                                   --! Signal registered
      );

      I_sync_sq1_dac_rs: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SYNC_DEF           -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => sync_r               , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sync_sq1_dac_rs(k)   -- out    std_logic                                   --! Signal registered
      );

      I_sync_sq2_dac_rs: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => 1                    , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SYNC_DEF           -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => sync_r               , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sync_sq2_dac_rs(k)   -- out    std_logic                                   --! Signal registered
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Others signals synchronized on System Clock
   -- ------------------------------------------------------------------------------------------------------
   G_brd_ref: for k in i_brd_ref'range generate
   begin

      I_brd_ref_rs: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => c_FF_RSYNC_NB        , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '0'                    -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_brd_ref(k)         , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_brd_ref_rs(k)        -- out    std_logic                                   --! Signal registered
      );

   end generate G_brd_ref;

   G_brd_model: for k in i_brd_model'range generate
   begin

      I_brd_model_rs: entity work.signal_reg generic map
      (  g_SIG_FF_NB          => c_FF_RSYNC_NB        , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '0'                    -- std_logic                                          --! Signal registered default value at reset
      )  port map
      (  i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_brd_model(k)       , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_brd_model_rs(k)      -- out    std_logic                                   --! Signal registered
      );

   end generate G_brd_model;

   I_hk1_spi_miso_rs: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RSYNC_NB        , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SPI_DATA_DEF       -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_hk1_spi_miso       , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_hk1_spi_miso_rs      -- out    std_logic                                   --! Signal registered
   );

   I_ep_spi_mosi_rs: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RSYNC_NB        , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SPI_DATA_DEF       -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_ep_spi_mosi        , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_ep_spi_mosi_rs       -- out    std_logic                                   --! Signal registered
   );

   I_ep_spi_sclk_rs: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RSYNC_NB        , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SPI_SCLK_DEF       -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_ep_spi_sclk        , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_ep_spi_sclk_rs       -- out    std_logic                                   --! Signal registered
   );

   I_ep_spi_cs_n_rs: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RSYNC_NB        , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => c_I_SPI_CS_N_DEF       -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk                , -- in     std_logic                                 ; --! Clock

         i_sig                => i_ep_spi_cs_n        , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_ep_spi_cs_n_rs       -- out    std_logic                                   --! Signal registered
   );

end architecture rtl;
