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
--!   @file                   ep_cmd.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command SPI interface and EP command status register management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity ep_cmd is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_ep_cmd_sts_err_add : in     std_logic                                                            ; --! EP command: Status, error invalid address
         i_ep_cmd_sts_err_nin : in     std_logic                                                            ; --! EP command: Status, error parameter to read not initialized yet
         i_ep_cmd_sts_err_dis : in     std_logic                                                            ; --! EP command: Status, error last SPI command discarded
         o_ep_cmd_sts_rg      : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register

         o_ep_cmd_rx_wd_add   : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         o_ep_cmd_rx_wd_data  : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         o_ep_cmd_rx_rw       : out    std_logic                                                            ; --! EP command receipted: read/write bit
         o_ep_cmd_rx_nerr_rdy : out    std_logic                                                            ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         i_ep_cmd_tx_wd_rd_rg : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command to transmit: read register word

         o_ep_spi_miso        : out    std_logic                                                            ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_mosi_rs     : in     std_logic                                                            ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
         i_ep_spi_sclk_rs     : in     std_logic                                                            ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
         i_ep_spi_cs_n_rs     : in     std_logic                                                              --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );
end entity ep_cmd;

architecture RTL of ep_cmd is
constant c_SPI_DATA_WD_LG_S   : integer := log2_ceil(c_EP_SPI_WD_S)                                         ; --! EP: SPI Receipted data word length minus 1 bus size
constant c_ADD_ERR_RDY_S      : integer := 6                                                                ; --! EP command receipted: errors ready after address rx bus size
constant c_OUT_ERR_RDY_FF_NB  : integer := 3                                                                ; --! Flip-Flop number for getting error out of range ready
constant c_EP_CMD_TX_DT_FF_NB : integer := 15                                                               ; --! Flip-Flop number for getting EP command data word to transmit
constant c_EP_SPI_WD_END_R_S  : integer := c_OUT_ERR_RDY_FF_NB + c_EP_CMD_TX_DT_FF_NB                       ; --! EP: SPI word end register bus size

signal   ep_spi_data_tx_wd    : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP: SPI Data word to transmit (stall on MSB)
signal   ep_spi_data_tx_wd_nb : std_logic_vector(c_EP_SPI_TX_WD_NB_S-1 downto 0)                            ; --! EP: SPI Data word to transmit number

signal   ep_spi_data_rx_wd    : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP: SPI Receipted data word (stall on LSB)
signal   ep_spi_data_rx_wd_nb : std_logic_vector(c_EP_SPI_RX_WD_NB_S-1 downto 0)                            ; --! EP: SPI Receipted data word number
signal   ep_spi_data_rx_wd_lg : std_logic_vector(c_SPI_DATA_WD_LG_S -1 downto 0)                            ; --! EP: SPI Receipted data word length minus 1
signal   ep_spi_data_rx_wd_rdy: std_logic                                                                   ; --! EP: SPI Receipted data word ready ('0' = Not ready, '1' = Ready)

signal   ep_spi_wd_end        : std_logic                                                                   ; --! EP: SPI word end ('0' = Not end, '1' = End)
signal   ep_spi_wd_end_r      : std_logic_vector(c_EP_SPI_WD_END_R_S-1 downto 0)                            ; --! EP: SPI word end register ('0' = Not end, '1' = End)

signal   ep_cmd_rx_wd_add     : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP command receipted: address word
signal   ep_cmd_rx_wd_add_norw: std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP command receipted: address word, read/write bit cleared
signal   ep_cmd_rx_wd_add_rdy : std_logic                                                                   ; --! EP command receipted: address word ready ('0' = Not ready, '1' = Ready)
signal   ep_cmd_rx_add_err_rdy: std_logic_vector(c_ADD_ERR_RDY_S    -1 downto 0)                            ; --! EP command receipted: errors ready after address rx ('0' = Not ready, '1' = Ready)
signal   ep_cmd_rx_wd_data    : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP command receipted: data word
signal   ep_cmd_rx_rw         : std_logic                                                                   ; --! EP command receipted: read/write bit

signal   ep_cmd_tx_wd_add     : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP command to transmit: address word
signal   ep_cmd_tx_wd_add_end : std_logic_vector(c_EP_SPI_WD_S      -2 downto 0)                            ; --! EP command to transmit: address word at spi end
signal   ep_cmd_tx_wd_data    : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP command to transmit: data word

signal   ep_cmd_sts_rg        : std_logic_vector(c_EP_SPI_WD_S      -1 downto 0)                            ; --! EP command: status register

signal   ep_cmd_sts_err_lgt   : std_logic                                                                   ; --! EP command: Status, error SPI command length not complete
signal   ep_cmd_sts_err_wrt   : std_logic                                                                   ; --! EP command: Status, error try to write in a read only register
signal   ep_cmd_sts_err_out   : std_logic                                                                   ; --! EP command: Status, error SPI data out of range

signal   ep_cmd_all_err_add   : std_logic                                                                   ; --! EP command: all errors detected at address word end grouped together
signal   ep_cmd_all_err_data  : std_logic                                                                   ; --! EP command: all errors detected at data word end grouped together
signal   ep_cmd_all_err_lg_grt: std_logic                                                                   ; --! EP command: all errors detected at data word end+spi length greater grouped together
signal   ep_cmd_all_err       : std_logic                                                                   ; --! EP command: all errors grouped together
signal   ep_cmd_err_add_wd_end: std_logic                                                                   ; --! EP command: Error(s) detected at address word end
signal   ep_cmd_err_spi_wd_end: std_logic                                                                   ; --! EP command: Error(s) detected at SPI word end

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP SPI slave
   -- ------------------------------------------------------------------------------------------------------
   I_spi_slave: entity work.spi_slave generic map
   (     g_CPOL               => c_EP_SPI_CPOL        , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_EP_SPI_CPHA        , -- std_logic                                        ; --! Clock phase
         g_DTA_TX_WD_S        => c_EP_SPI_WD_S        , -- integer                                          ; --! Data word to transmit bus size
         g_DTA_TX_WD_NB_S     => c_EP_SPI_TX_WD_NB_S  , -- integer                                          ; --! Data word to transmit number size
         g_DTA_RX_WD_S        => c_EP_SPI_WD_S        , -- integer                                          ; --! Receipted data word bus size
         g_DTA_RX_WD_NB_S     => c_EP_SPI_RX_WD_NB_S    -- integer                                            --! Receipted data word number size
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_data_tx_wd         => ep_spi_data_tx_wd    , -- in     slv(g_DTA_TX_WD_S   -1 downto 0)          ; --! Data word to transmit (stall on MSB)
         o_data_tx_wd_nb      => ep_spi_data_tx_wd_nb , -- out    slv(g_DTA_TX_WD_NB_S-1 downto 0)          ; --! Data word to transmit number

         o_data_rx_wd         => ep_spi_data_rx_wd    , -- out    slv(g_DTA_RX_WD_S   -1 downto 0)          ; --! Receipted data word (stall on LSB)
         o_data_rx_wd_nb      => ep_spi_data_rx_wd_nb , -- out    slv(g_DTA_RX_WD_NB_S-1 downto 0)          ; --! Receipted data word number
         o_data_rx_wd_lg      => ep_spi_data_rx_wd_lg , -- out    slv(log2_ceil(g_DTA_RX_WD_S)-1 downto 0)  ; --! Receipted data word length minus 1
         o_data_rx_wd_rdy     => ep_spi_data_rx_wd_rdy, -- out    std_logic                                 ; --! Receipted data word ready ('0' = Not ready, '1' = Ready)

         o_spi_wd_end         => ep_spi_wd_end        , -- out    std_logic                                 ; --! SPI word end ('0' = Not end, '1' = End)

         o_miso               => o_ep_spi_miso        , -- out    std_logic                                 ; --! SPI Master Input Slave Output
         i_mosi               => i_ep_spi_mosi_rs     , -- in     std_logic                                 ; --! SPI Master Output Slave Input
         i_sclk               => i_ep_spi_sclk_rs     , -- in     std_logic                                 ; --! SPI Serial Clock
         i_cs_n               => i_ep_spi_cs_n_rs       -- in     std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command receipt management
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_rx_wd : process (i_rst, i_clk)
   begin

      if i_rst = '1' then

         if c_EP_CMD_ADD_RW_POS = 0 then
            ep_cmd_rx_wd_add <= c_EP_CMD_ADD_STATUS(ep_cmd_rx_wd_add'high-1 downto 0) & '0';

         else
            ep_cmd_rx_wd_add <= '0' & c_EP_CMD_ADD_STATUS(ep_cmd_rx_wd_add'high-1 downto 0);

         end if;

         ep_cmd_rx_wd_add_rdy <= '0';
         ep_cmd_rx_add_err_rdy<= (others => '0');
         ep_cmd_rx_wd_data    <= (others => c_EP_CMD_ERR_CLR);
         ep_spi_wd_end_r      <= (others => '0');
         o_ep_cmd_rx_nerr_rdy <= '0';

      elsif rising_edge(i_clk) then
         if ep_spi_data_rx_wd_rdy = '1' and ep_spi_data_rx_wd_nb = std_logic_vector(to_unsigned(c_EP_CMD_WD_ADD_POS, ep_spi_data_rx_wd_nb'length)) then
            ep_cmd_rx_wd_add <= ep_spi_data_rx_wd;

         end if;

         if ep_spi_data_rx_wd_nb = std_logic_vector(to_unsigned(c_EP_CMD_WD_ADD_POS, ep_spi_data_rx_wd_nb'length)) then
            ep_cmd_rx_wd_add_rdy <= ep_spi_data_rx_wd_rdy;

         end if;

         ep_cmd_rx_add_err_rdy <= ep_cmd_rx_add_err_rdy(ep_cmd_rx_add_err_rdy'high-1 downto 0) & ep_cmd_rx_wd_add_rdy;

         if ep_spi_data_rx_wd_rdy = '1' and ep_spi_data_rx_wd_nb = std_logic_vector(to_unsigned(c_EP_CMD_WD_DATA_POS, ep_spi_data_rx_wd_nb'length)) then
            ep_cmd_rx_wd_data <= ep_spi_data_rx_wd;

         end if;

         ep_spi_wd_end_r      <= ep_spi_wd_end_r(ep_spi_wd_end_r'high-1 downto 0) & ep_spi_wd_end;
         o_ep_cmd_rx_nerr_rdy <= ep_spi_wd_end_r(c_OUT_ERR_RDY_FF_NB) and not(ep_cmd_all_err xor c_EP_CMD_ERR_CLR);

      end if;

   end process P_ep_cmd_rx_wd;

   -- Address Receipt: Read/Write LSB bit position
   G_add_rw_pos_equ_nul: if c_EP_CMD_ADD_RW_POS = 0 generate
      ep_cmd_rx_wd_add_norw <= '0' & ep_cmd_rx_wd_add(ep_cmd_rx_wd_add'high downto 1);
   end generate G_add_rw_pos_equ_nul;

   -- Address Receipt: Read/Write others bit position
   G_add_rw_pos_neq_nul: if c_EP_CMD_ADD_RW_POS /= 0 generate
      ep_cmd_rx_wd_add_norw <= '0' & ep_cmd_rx_wd_add(ep_cmd_rx_wd_add'high-1 downto 0);
   end generate G_add_rw_pos_neq_nul;

   ep_cmd_rx_rw <= ep_cmd_rx_wd_add(c_EP_CMD_ADD_RW_POS);

   o_ep_cmd_rx_wd_add   <= ep_cmd_rx_wd_add_norw;
   o_ep_cmd_rx_wd_data  <= ep_cmd_rx_wd_data;
   o_ep_cmd_rx_rw       <= ep_cmd_rx_rw;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command transmit management
   --    @Req : DRE-DMX-FW-REQ-0510
   -- ------------------------------------------------------------------------------------------------------
   -- Address Transmit: Read/Write LSB bit position
   G_add_tw_pos_equ_nul: if c_EP_CMD_ADD_RW_POS = 0 generate
      ep_cmd_tx_wd_add(0)                                <= c_EP_CMD_ADD_RW_R;
      ep_cmd_tx_wd_add(ep_cmd_tx_wd_add'high   downto 1) <= c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add'high-1 downto 0) when ep_cmd_rx_wd_add(c_EP_CMD_ADD_RW_POS) = c_EP_CMD_ADD_RW_W else
                                                            c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add'high-1 downto 0) when ep_cmd_all_err_data = c_EP_CMD_ERR_SET else
                                                            ep_cmd_rx_wd_add(   ep_cmd_tx_wd_add'high   downto 1);

      P_ep_cmd_tx_wd_adend : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            ep_cmd_tx_wd_add_end <= c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add_end'high downto 0);

         elsif rising_edge(i_clk) then
            if ep_spi_wd_end = '1' then
               ep_cmd_tx_wd_add_end <= ep_cmd_tx_wd_add(ep_cmd_tx_wd_add'high downto 1);

            end if;

         end if;

      end process P_ep_cmd_tx_wd_adend;

   end generate G_add_tw_pos_equ_nul;

   -- Address Transmit: Read/Write others bit position
   G_add_tw_pos_neq_nul: if c_EP_CMD_ADD_RW_POS /= 0 generate
      ep_cmd_tx_wd_add(ep_cmd_tx_wd_add'high)            <= c_EP_CMD_ADD_RW_R;
      ep_cmd_tx_wd_add(ep_cmd_tx_wd_add'high-1 downto 0) <= c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add'high-1 downto 0) when ep_cmd_rx_wd_add(c_EP_CMD_ADD_RW_POS) = c_EP_CMD_ADD_RW_W else
                                                            c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add'high-1 downto 0) when ep_cmd_all_err_data = c_EP_CMD_ERR_SET else
                                                            ep_cmd_rx_wd_add(   ep_cmd_tx_wd_add'high-1 downto 0);

      P_ep_cmd_tx_wd_adend : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            ep_cmd_tx_wd_add_end <= c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add_end'high downto 0);

         elsif rising_edge(i_clk) then
            if ep_spi_wd_end = '1' then
               ep_cmd_tx_wd_add_end <= ep_cmd_tx_wd_add(ep_cmd_tx_wd_add'high-1 downto 0);

            end if;

         end if;

      end process P_ep_cmd_tx_wd_adend;

   end generate G_add_tw_pos_neq_nul;

   P_ep_cmd_tx_wd : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ep_cmd_tx_wd_data <= (others => '0');

      elsif rising_edge(i_clk) then
         if ep_spi_wd_end_r(ep_spi_wd_end_r'high) = '1' then
            if ep_cmd_tx_wd_add_end = c_EP_CMD_ADD_STATUS(ep_cmd_tx_wd_add_end'high downto 0) then
               ep_cmd_tx_wd_data <= ep_cmd_sts_rg;

            else
               ep_cmd_tx_wd_data <= i_ep_cmd_tx_wd_rd_rg;

            end if;

         end if;

      end if;

   end process P_ep_cmd_tx_wd;

   ep_spi_data_tx_wd    <= ep_cmd_tx_wd_add when ep_spi_data_tx_wd_nb = std_logic_vector(to_unsigned(c_EP_CMD_WD_ADD_POS, ep_spi_data_tx_wd_nb'length)) else
                           ep_cmd_tx_wd_data;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error SPI command length not complete
   --    @Req : REG_EP_CMD_ERR_LGT
   -- ------------------------------------------------------------------------------------------------------
   ep_cmd_sts_err_lgt <= c_EP_CMD_ERR_CLR when (ep_spi_data_rx_wd_nb & ep_spi_data_rx_wd_lg)=std_logic_vector(to_unsigned(c_EP_CMD_S-1, ep_spi_data_rx_wd_nb'length+ep_spi_data_rx_wd_lg'length)) else
                         c_EP_CMD_ERR_SET;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error try to write in a read only register
   --    @Req : REG_EP_CMD_ERR_WRT
   -- ------------------------------------------------------------------------------------------------------
   I_sts_err_wrt_mgt: entity work.sts_err_wrt_mgt port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_add_norw => ep_cmd_rx_wd_add_norw, -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_sts_err_wrt => ep_cmd_sts_err_wrt     -- out    std_logic                                   --! EP command: Status, error try to write in a read only register
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error data out of range
   --    @Req : REG_EP_CMD_ERR_OUT
   -- ------------------------------------------------------------------------------------------------------
   I_sts_err_out_mgt: entity work.sts_err_out_mgt port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_add_norw => ep_cmd_rx_wd_add_norw, -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_out_rdy  => ep_spi_wd_end_r(0)   , -- in     std_logic                                 ; --! EP command receipted: error data out of range ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd_sts_err_out => ep_cmd_sts_err_out     -- out    std_logic                                   --! EP command: Status, error data out of range
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Global error management
   -- ------------------------------------------------------------------------------------------------------
   G_ep_cmd_err_clr_nul: if c_EP_CMD_ERR_CLR = '0' generate
      ep_cmd_all_err_add   <= i_ep_cmd_sts_err_add or ep_cmd_sts_err_wrt or i_ep_cmd_sts_err_nin or i_ep_cmd_sts_err_dis;
      ep_cmd_all_err_data  <= ep_cmd_sts_err_lgt   or ep_cmd_err_add_wd_end;
      ep_cmd_all_err       <= ep_cmd_sts_err_out   or ep_cmd_err_spi_wd_end;

   end generate G_ep_cmd_err_clr_nul;

   G_ep_cmd_err_clr_one: if c_EP_CMD_ERR_CLR /= '0' generate
      ep_cmd_all_err_add   <= i_ep_cmd_sts_err_add and ep_cmd_sts_err_wrt and i_ep_cmd_sts_err_nin and i_ep_cmd_sts_err_dis;
      ep_cmd_all_err_data  <= ep_cmd_sts_err_lgt   and ep_cmd_err_add_wd_end;
      ep_cmd_all_err       <= ep_cmd_sts_err_out   and ep_cmd_err_spi_wd_end;

   end generate G_ep_cmd_err_clr_one;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status register management
   --    @Req : REG_Status
   -- ------------------------------------------------------------------------------------------------------
   ep_cmd_sts_rg(c_EP_CMD_ERR_FST_POS-1 downto 0) <= (others => c_EP_CMD_ERR_CLR);

   P_ep_cmd_sts_rg : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ep_cmd_err_add_wd_end   <= c_EP_CMD_ERR_CLR;
         ep_cmd_err_spi_wd_end   <= c_EP_CMD_ERR_CLR;
         ep_cmd_sts_rg(ep_cmd_sts_rg'high downto c_EP_CMD_ERR_FST_POS) <= (others => c_EP_CMD_ERR_CLR);

      elsif rising_edge(i_clk) then
         if ep_cmd_rx_add_err_rdy(ep_cmd_rx_add_err_rdy'high) = '1' then
            ep_cmd_err_add_wd_end   <= ep_cmd_all_err_add;

            ep_cmd_sts_rg(c_EP_CMD_ERR_ADD_POS) <= i_ep_cmd_sts_err_add;
            ep_cmd_sts_rg(c_EP_CMD_ERR_WRT_POS) <= ep_cmd_sts_err_wrt;
            ep_cmd_sts_rg(c_EP_CMD_ERR_NIN_POS) <= i_ep_cmd_sts_err_nin;
            ep_cmd_sts_rg(c_EP_CMD_ERR_DIS_POS) <= i_ep_cmd_sts_err_dis;

         end if;

         if ep_spi_wd_end = '1' then
            ep_cmd_err_spi_wd_end <= ep_cmd_all_err_data;

            ep_cmd_sts_rg(c_EP_CMD_ERR_LGT_POS) <= ep_cmd_sts_err_lgt;

         end if;

         ep_cmd_sts_rg(c_EP_CMD_ERR_OUT_POS) <= ep_cmd_sts_err_out;

      end if;

   end process P_ep_cmd_sts_rg;

   o_ep_cmd_sts_rg <= ep_cmd_sts_rg;

end architecture RTL;
