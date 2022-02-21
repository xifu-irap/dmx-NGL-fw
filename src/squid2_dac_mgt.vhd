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
--!   @file                   squid2_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid2 DAC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity squid2_dac_mgt is port
   (     i_rst_sys_sq2_dac    : in     std_logic                                                            ; --! Reset for SQUID2 DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_dac    : in     std_logic                                                            ; --! SQUID1 ADC/DAC internal Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock

         o_sq2_dac_mux        : out    std_logic_vector(c_SQ2_DAC_MUX_S -1 downto 0)                        ; --! SQUID2 DAC - Multiplexer
         o_sq2_dac_data       : out    std_logic                                                            ; --! SQUID2 DAC - Serial Data
         o_sq2_dac_sclk       : out    std_logic                                                            ; --! SQUID2 DAC - Serial Clock
         o_sq2_dac_snc_l_n    : out    std_logic                                                            ; --! SQUID2 DAC - Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sq2_dac_snc_o_n    : out    std_logic                                                              --! SQUID2 DAC - Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)

   );
end entity squid2_dac_mgt;

architecture RTL of squid2_dac_mgt is
constant c_SPI_SER_WD_S_V_S   : integer := log2_ceil(c_SQ2_SPI_SER_WD_S+1)                                  ; --! SQUID2 DAC SPI: Serial word size vector bus size
constant c_SQ2_SPI_SER_WD_S_V : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_SQ2_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S))       ; --! SQUID2 DAC SPI: Serial word size vector

signal   rst_sq2_dac          : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

signal   sq2_dac_mux          : std_logic_vector(c_SQ2_DAC_MUX_S-1 downto 0)                                ; --! SQUID2 DAC - Multiplexer
signal   sq2_dac_data         : std_logic                                                                   ; --! SQUID2 DAC - Serial Data
signal   sq2_dac_sclk         : std_logic                                                                   ; --! SQUID2 DAC - Serial Clock
signal   sq2_dac_sync_n       : std_logic                                                                   ; --! SQUID2 DAC - Frame Synchronization ('0' = Active, '1' = Inactive)

signal   sq2_spi_start        : std_logic                                                                   ; --! SQUID2 DAC SPI: Start transmit ('0' = Inactive, '1' = Active)
signal   sq2_spi_data_tx      : std_logic_vector(c_SQ2_SPI_SER_WD_S-1 downto 0)                             ; --! SQUID2 DAC SPI: Data to transmit (stall on MSB)
signal   sq2_spi_tx_busy_n    : std_logic                                                                   ; --! SQUID2 DAC SPI: Transmit link busy ('0' = Busy, '1' = Not Busy)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID2 DAC Clock generation
   --!     Necessity to generate local reset in order to reach expected frequency
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_sq2_dac: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RST_ADC_DAC_NB  , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '1'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst_sys_sq2_dac    , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => '0'                  , -- in     std_logic                                 ; --! Signal
         o_sig_r              => rst_sq2_dac            -- out    std_logic                                   --! Signal registered
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sync_r <= (others => c_I_SYNC_DEF);

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sync_r <= sync_r(sync_r'high-1 downto 0) & i_sync_rs;

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid 2 SPI master
   --    @Req : DRE-DMX-FW-REQ-0340
   --    @Req : DRE-DMX-FW-REQ-0350
   -- ------------------------------------------------------------------------------------------------------
   I_sq2_spi_master : entity work.spi_master generic map
   (     g_CPOL               => c_SQ2_SPI_CPOL       , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_SQ2_SPI_CPHA       , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => c_SQ2_SPI_SCLK_L     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => c_SQ2_SPI_SCLK_H     , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => 0                    , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_SQ2_SPI_SER_WD_S     -- integer                                            --! Data bus size
   ) port map
   (     i_rst                => rst_sq2_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_start              => sq2_spi_start        , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => c_SQ2_SPI_SER_WD_S_V , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => sq2_spi_data_tx      , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => sq2_spi_tx_busy_n    , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => open                 , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => open                 , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => '0'                  , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => sq2_dac_data         , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => sq2_dac_sclk         , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => sq2_dac_sync_n         -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   I_sq2_dac_data: entity work.signal_reg generic map
   (     g_SIG_FF_NB          =>  1                   , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '0'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => rst_sq2_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => sq2_dac_data         , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_dac_data         -- out    std_logic                                   --! Signal registered
   );

   I_sq2_dac_sclk: entity work.signal_reg generic map
   (     g_SIG_FF_NB          =>  1                   , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '0'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => rst_sq2_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => sq2_dac_sclk         , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_dac_sclk         -- out    std_logic                                   --! Signal registered
   );

   I_sq2_dac_snc_l_n: entity work.signal_reg generic map
   (     g_SIG_FF_NB          =>  1                   , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '1'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => rst_sq2_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => sq2_dac_sync_n       , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_dac_snc_l_n      -- out    std_logic                                   --! Signal registered
   );

   I_sq2_dac_snc_o_n: entity work.signal_reg generic map
   (     g_SIG_FF_NB          =>  1                   , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '1'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => rst_sq2_dac          , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => sq2_dac_sync_n       , -- in     std_logic                                 ; --! Signal
         o_sig_r              => o_sq2_dac_snc_o_n      -- out    std_logic                                   --! Signal registered
   );

   -- TODO
   sq2_spi_start     <= '1';
   sq2_spi_data_tx   <= x"256A";

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID2 DAC - Multiplexer
   -- ------------------------------------------------------------------------------------------------------
   o_sq2_dac_mux <= sq2_dac_mux;

   -- TODO
   P_todo : process (rst_sq2_dac, i_clk_sq1_adc_dac)
   begin

      if rst_sq2_dac = '1' then
         sq2_dac_mux <= (others => '0');

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sq2_dac_mux <= std_logic_vector(unsigned(sq2_dac_mux) + 1);

      end if;

   end process P_todo;

end architecture RTL;
