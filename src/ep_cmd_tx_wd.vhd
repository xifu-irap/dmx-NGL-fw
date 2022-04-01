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

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity ep_cmd_tx_wd is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_data_rg_rd         : in     t_slv_arr(c_EP_CMD_POS_NB-1 downto 0)(c_EP_SPI_WD_S-1 downto 0)      ; --! Data registers read
         i_cs_rg              : in     std_logic_vector(c_EP_CMD_POS_NB-1 downto 0)                         ; --! Chip selects register ('0' = Inactive, '1' = Active)

         o_ep_cmd_sts_err_add : out    std_logic                                                            ; --! EP command: Status, error invalid address
         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --! EP command to transmit: read register word

   );
end entity ep_cmd_tx_wd;

architecture RTL of ep_cmd_tx_wd is
constant c_NB_MUX_FIRST_LAY   : integer   := div_ceil(c_EP_CMD_POS_NB, c_EP_CMD_REG_NB_MUX)                 ; --! Multiplexer number for the first layer

signal   data_mux_first_lay   : t_slv_arr(c_NB_MUX_FIRST_LAY-1 downto 0)(c_EP_SPI_WD_S-1 downto 0)          ; --! Multiplexed data first layer
signal   cs_or_first_lay      : std_logic_vector(c_NB_MUX_FIRST_LAY-1 downto 0)                             ; --! Chip selects "or-ed"

signal   ep_cmd_sts_err_add   : std_logic                                                                   ; --! EP command: Status, error invalid address

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Data multiplexer
   -- ------------------------------------------------------------------------------------------------------
   G_data_bus_nb: for k in 0 to c_NB_MUX_FIRST_LAY-1 generate
   begin

      I_mux_first_lay: entity work.multiplexer generic map
      (  g_DATA_S             => c_EP_SPI_WD_S        , -- integer                                          ; --! Data bus size
         g_NB                 => c_EP_CMD_REG_NB_MUX    -- integer                                            --! Data bus number
      ) port map
      (  i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_data_rg_rd((k+1)*c_EP_CMD_REG_NB_MUX-1 downto k*c_EP_CMD_REG_NB_MUX)     , --! Data buses
         i_cs                 => i_cs_rg(     (k+1)*c_EP_CMD_REG_NB_MUX-1 downto k*c_EP_CMD_REG_NB_MUX)     , --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => data_mux_first_lay(k), -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Multiplexed data
         o_cs_or              => cs_or_first_lay(k)     -- out    std_logic                                   --! Chip selects "or-ed"
      );

   end generate G_data_bus_nb;

   I_mux_last_lay: entity work.multiplexer generic map
   (     g_DATA_S             => c_EP_SPI_WD_S        , -- integer                                          ; --! Data bus size
         g_NB                 => c_NB_MUX_FIRST_LAY     -- integer                                            --! Data bus number
   ) port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => data_mux_first_lay   , -- in     t_slv_arr                                 ; --! Data buses
         i_cs                 => cs_or_first_lay      , -- in     slv                                       ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => o_ep_cmd_tx_wd_rd_rg , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Multiplexed data
         o_cs_or              => ep_cmd_sts_err_add     -- out    std_logic                                   --! Chip selects "or-ed"
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error invalid address
   --    @Req : REG_EP_CMD_ERR_ADD
   -- ------------------------------------------------------------------------------------------------------
   o_ep_cmd_sts_err_add <= ep_cmd_sts_err_add xor c_EP_CMD_ERR_SET;

end architecture RTL;
