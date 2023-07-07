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
--!   @file                   hk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Housekeeping management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity hk_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_mem_hkeep_add      : in     std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0)                       ; --! Housekeeping: memory address
         o_hkeep_data         : out    std_logic_vector(c_DFLD_HKEEP_S-1 downto 0)                          ; --! Housekeeping: data read
         o_hk_err_nin         : out    std_logic                                                            ; --! Housekeeping: Error parameter to read not initialized yet

         i_hk_spi_miso_rs     : in     std_logic                                                            ; --! HouseKeeping: SPI Master Input Slave Output
         o_hk_spi_mosi        : out    std_logic                                                            ; --! HouseKeeping: SPI Master Output Slave Input
         o_hk_spi_sclk        : out    std_logic                                                            ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         o_hk_spi_cs_n        : out    std_logic                                                            ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk_mux             : out    std_logic_vector(      c_HK_MUX_S-1 downto 0)                        ; --! HouseKeeping: Multiplexer
         o_hk_mux_ena_n       : out    std_logic                                                              --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

   );
end entity hk_mgt;

architecture RTL of hk_mgt is
constant c_HK_SPI_SER_WD_S_V_S: integer := log2_ceil(c_HK_SPI_SER_WD_S+1)                                   ; --! HK SPI: Serial word size vector bus size
constant c_HK_SPI_SER_WD_S_V  : std_logic_vector(c_HK_SPI_SER_WD_S_V_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_HK_SPI_SER_WD_S, c_HK_SPI_SER_WD_S_V_S))     ; --! HK SPI: Serial word size vector
constant c_HK_MUX_NPER_DEL    : integer := c_HK_SPI_SCLK_NB_ACQ * (c_HK_SPI_SCLK_L + c_HK_SPI_SCLK_H)       ; --! HK Multiplexer: Clock period number to delay

signal   mem_hkeep            : t_slv_arr(0 to 2**c_MEM_HKEEP_ADD_S-1)(c_DFLD_HKEEP_S-1 downto 0)           ; --! Memory data storage Housekeeping
signal   mem_hkeep_add_prm    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0)                              ; --! Memory Housekeeping, getting parameter side: address

signal   hk_pos               : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0)                              ; --! HK position

signal   hk_spi_data_tx       : std_logic_vector(c_HK_SPI_SER_WD_S-1 downto 0)                              ; --! HK SPI: Data to transmit (stall on MSB)
signal   hk_spi_tx_busy_n     : std_logic                                                                   ; --! HK SPI: Transmit link busy ('0' = Busy, '1' = Not Busy)
signal   hk_spi_tx_busy_n_r   : std_logic                                                                   ; --! HK SPI: Transmit link busy register ('0' = Busy, '1' = Not Busy)
signal   hk_spi_tx_busy_n_fe  : std_logic                                                                   ; --! HK SPI: Transmit link busy falling edge detect
signal   hk_spi_tx_bsy_n_fe_r : std_logic_vector(c_HK_MUX_NPER_DEL-1 downto 0)                              ; --! HK SPI: Transmit link busy falling edge detect register
signal   hk_spi_data_rx       : std_logic_vector(c_HK_SPI_SER_WD_S-1 downto 0)                              ; --! HK SPI: Receipted data (stall on LSB)
signal   hk_spi_data_rx_rdy   : std_logic                                                                   ; --! HK SPI: Receipted data ready ('0' = Not ready, '1' = Ready)

signal   hk_spi_mosi          : std_logic                                                                   ; --! HouseKeeping: SPI Master Output Slave Input
signal   hk_spi_sclk          : std_logic                                                                   ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
signal   hk_spi_cs_n          : std_logic                                                                   ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)

signal   err_nin_rmv_ena      : std_logic_vector(1 downto 0)                                                ; --! Error parameter to read not initialized yet, Remove Enable ('0'=Inactive, '1'=Active)
signal   err_nin_flg          : t_slv_arr(0 to c_ERR_NIN_MX_STIN(c_ERR_NIN_MX_STIN'high)-1)(0 downto 0)     ; --! Error parameter to read not initialized yet, Flags
signal   err_nin_cs           : std_logic_vector(c_ERR_NIN_MX_STIN(c_ERR_NIN_MX_STIN'high)-1  downto 0)     ; --! Error parameter to read not initialized yet, Chip Select   ('0'=Inactive, '1'=Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   HK position
   --    @Req : DRE-DMX-FW-REQ-0540
   --    @Req : DRE-DMX-FW-REQ-0570
   -- ------------------------------------------------------------------------------------------------------
   P_hk_pos : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         hk_pos  <= (others => '0');

      elsif rising_edge(i_clk) then
         if hk_spi_tx_busy_n = '1' then

            if hk_pos = std_logic_vector(to_unsigned(c_HK_NW-1, hk_pos'length)) then
               hk_pos   <= (others => '0');

            else
               hk_pos   <= std_logic_vector(unsigned(hk_pos) + 1);

            end if;

         end if;

      end if;

   end process P_hk_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   HK SPI: Transmit link busy falling edge detect
   -- ------------------------------------------------------------------------------------------------------
   P_hk_spi_tx_bsy_n_fe : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         hk_spi_tx_busy_n_r   <= '1';
         hk_spi_tx_busy_n_fe  <= '0';
         hk_spi_tx_bsy_n_fe_r <= (others => '0');

      elsif rising_edge(i_clk) then
         hk_spi_tx_busy_n_r   <= hk_spi_tx_busy_n;
         hk_spi_tx_busy_n_fe  <= hk_spi_tx_busy_n_r and not(hk_spi_tx_busy_n);
         hk_spi_tx_bsy_n_fe_r <= hk_spi_tx_bsy_n_fe_r(hk_spi_tx_bsy_n_fe_r'high-1 downto 0) & hk_spi_tx_busy_n_fe;

      end if;

   end process P_hk_spi_tx_bsy_n_fe;

   -- ------------------------------------------------------------------------------------------------------
   --!   HK SPI master
   --    @Req : DRE-DMX-FW-REQ-0540
   --    @Req : DRE-DMX-FW-REQ-0550
   --    @Req : DRE-DMX-FW-REQ-0570
   -- ------------------------------------------------------------------------------------------------------
   hk_spi_data_tx(hk_spi_data_tx'high    downto c_HK_SPI_ADD_POS_LSB) <= std_logic_vector(resize(unsigned(c_HK_ADC_SEQ(to_integer(unsigned(hk_pos)))), hk_spi_data_tx'length - c_HK_SPI_ADD_POS_LSB));
   hk_spi_data_tx(c_HK_SPI_ADD_POS_LSB-1 downto 0)                    <= (others => '0');

   I_hk_spi_master : entity work.spi_master generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_CPOL               => c_HK_SPI_CPOL        , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_HK_SPI_CPHA        , -- std_logic                                        ; --! Clock phase
         g_N_CLK_PER_SCLK_L   => c_HK_SPI_SCLK_L      , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock low  level
         g_N_CLK_PER_SCLK_H   => c_HK_SPI_SCLK_H      , -- integer                                          ; --! Number of clock period for elaborating SPI Serial Clock high level
         g_N_CLK_PER_MISO_DEL => c_FF_RSYNC_NB        , -- integer                                          ; --! Number of clock period for miso signal delay from spi pin input to spi master input
         g_DATA_S             => c_HK_SPI_SER_WD_S      -- integer                                            --! Data bus size
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_start              => '1'                  , -- in     std_logic                                 ; --! Start transmit ('0' = Inactive, '1' = Active)
         i_ser_wd_s           => c_HK_SPI_SER_WD_S_V  , -- in     slv(log2_ceil(g_DATA_S+1)-1 downto 0)     ; --! Serial word size
         i_data_tx            => hk_spi_data_tx       , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data to transmit (stall on MSB)
         o_tx_busy_n          => hk_spi_tx_busy_n     , -- out    std_logic                                 ; --! Transmit link busy ('0' = Busy, '1' = Not Busy)

         o_data_rx            => hk_spi_data_rx       , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Receipted data (stall on LSB)
         o_data_rx_rdy        => hk_spi_data_rx_rdy   , -- out    std_logic                                 ; --! Receipted data ready ('0' = Not ready, '1' = Ready)

         i_miso               => i_hk_spi_miso_rs     , -- in     std_logic                                 ; --! SPI Master Input Slave Output
         o_mosi               => hk_spi_mosi          , -- out    std_logic                                 ; --! SPI Master Output Slave Input
         o_sclk               => hk_spi_sclk          , -- out    std_logic                                 ; --! SPI Serial Clock
         o_cs_n               => hk_spi_cs_n            -- out    std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   --! HouseKeeping: SPI master
   P_hk_spi_master : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_hk_spi_mosi <= '0';
         o_hk_spi_sclk <= c_PAD_REG_SET_AUTH and c_HK_SPI_CPOL;
         o_hk_spi_cs_n <= c_PAD_REG_SET_AUTH;

      elsif rising_edge(i_clk) then
         o_hk_spi_mosi <= hk_spi_mosi;
         o_hk_spi_sclk <= hk_spi_sclk;
         o_hk_spi_cs_n <= hk_spi_cs_n;

      end if;

   end process P_hk_spi_master;

   -- ------------------------------------------------------------------------------------------------------
   --!   HK Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0560
   -- ------------------------------------------------------------------------------------------------------
   P_hk_mux : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_hk_mux  <= (others => '0');

      elsif rising_edge(i_clk) then
         if hk_spi_tx_bsy_n_fe_r(hk_spi_tx_bsy_n_fe_r'high) = '1' then
            o_hk_mux            <= c_HK_MUX_SEQ(to_integer(unsigned(hk_pos)));

         end if;

      end if;

   end process P_hk_mux;

   o_hk_mux_ena_n      <= '0';

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory data storage Housekeeping
   --    @Req : REG_HKEEP
   --    @Req : DRE-DMX-FW-REQ-0540
   -- ------------------------------------------------------------------------------------------------------
   mem_hkeep_add_prm <= std_logic_vector(unsigned(c_HK_ADD_SEQ(to_integer(unsigned(hk_pos)))));

   --! Memory housekeeping: data write
   P_mem_hkeep_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if hk_spi_data_rx_rdy = '1' then
            mem_hkeep(to_integer(unsigned(mem_hkeep_add_prm))) <= hk_spi_data_rx(c_DFLD_HKEEP_S-1 downto 0);

         end if;
      end if;

   end process P_mem_hkeep_wr;

   --! Memory housekeeping: data read
   P_mem_hkeep_rd : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_hkeep_data <= (others => '0');

      elsif rising_edge(i_clk) then
         o_hkeep_data <= mem_hkeep(to_integer(unsigned(i_mem_hkeep_add)));

      end if;

   end process P_mem_hkeep_rd;

   -- ------------------------------------------------------------------------------------------------------
   --!  Error parameter to read not initialized yet, Remove Enable
   -- ------------------------------------------------------------------------------------------------------
   P_err_nin_rmv_ena : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         err_nin_rmv_ena <= (others => '0');

      elsif rising_edge(i_clk) then
         if hk_spi_data_rx_rdy = '1' then
            err_nin_rmv_ena <=  err_nin_rmv_ena(err_nin_rmv_ena'high-1 downto 0) & '1';

         end if;

      end if;

   end process P_err_nin_rmv_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!  EP command: Status, error parameter to read not initialized yet
   --    @Req : REG_EP_CMD_ERR_IN
   -- ------------------------------------------------------------------------------------------------------
   G_err_nin: for k in 0 to c_HK_NW-1 generate
   begin

      --! Error parameter to read not initialized yet, Flags
      P_err_nin_flg : process (i_rst, i_clk)
      begin

         if i_rst = c_RST_LEV_ACT then
            err_nin_flg(k)(err_nin_flg(err_nin_flg'low)'low) <= c_EP_CMD_ERR_SET;

         elsif rising_edge(i_clk) then
            if (err_nin_rmv_ena(err_nin_rmv_ena'high) = '1') and (mem_hkeep_add_prm = std_logic_vector(to_unsigned(k, mem_hkeep_add_prm'length))) then
               err_nin_flg(k)(err_nin_flg(err_nin_flg'low)'low) <=  c_EP_CMD_ERR_CLR;

            end if;

         end if;

      end process P_err_nin_flg;

      err_nin_cs(k) <= '1' when i_mem_hkeep_add = std_logic_vector(to_unsigned(k, i_mem_hkeep_add'length)) else '0';

   end generate G_err_nin;

   err_nin_flg(c_HK_NW to c_ERR_NIN_MX_STIN(1)-1)     <= (others => (others => c_EP_CMD_ERR_CLR));
   err_nin_cs( c_ERR_NIN_MX_STIN(1)-1 downto c_HK_NW) <= (others => '0');

   G_mux_stage: for k in 0 to c_ERR_NIN_MX_STNB-1 generate
   begin

      G_mux_nb: for l in 0 to c_ERR_NIN_MX_STIN(k+2) - c_ERR_NIN_MX_STIN(k+1) - 1 generate
      begin

         I_multiplexer: entity work.multiplexer generic map (
            g_DATA_S          => 1                    , -- integer                                          ; --! Data bus size
            g_NB              => c_ERR_NIN_MX_INNB(k)   -- integer                                            --! Data bus number
         ) port map (
            i_rst             => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
            i_clk             => i_clk                , -- in     std_logic                                 ; --! System Clock
            i_data            => err_nin_flg(
                                 l   *c_ERR_NIN_MX_INNB(k) + c_ERR_NIN_MX_STIN(k) to
                                (l+1)*c_ERR_NIN_MX_INNB(k) + c_ERR_NIN_MX_STIN(k)-1)                        , --! Data buses
            i_cs              => err_nin_cs(
                                (l+1)*c_ERR_NIN_MX_INNB(k) + c_ERR_NIN_MX_STIN(k)-1 downto
                                 l   *c_ERR_NIN_MX_INNB(k) + c_ERR_NIN_MX_STIN(k))                          , --! Chip selects ('0' = Inactive, '1' = Active)
            o_data_mux        => err_nin_flg(c_ERR_NIN_MX_STIN(k+1)+l), -- out    slv(g_DATA_S-1 downto 0)  ; --! Multiplexed data
            o_cs_or           => err_nin_cs( c_ERR_NIN_MX_STIN(k+1)+l)  -- out    std_logic                   --! Chip selects "or-ed"
         );

      end generate G_mux_nb;

   end generate G_mux_stage;

   o_hk_err_nin <= err_nin_flg(err_nin_flg'high)(err_nin_flg(err_nin_flg'low)'low);

end architecture RTL;
