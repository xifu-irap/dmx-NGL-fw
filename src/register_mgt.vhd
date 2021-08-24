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
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity register_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock

         o_ep_cmd_sts_err_out : out    std_logic                                                            ; --! EP command: Status, error SPI data out of range
         o_ep_cmd_sts_err_nin : out    std_logic                                                            ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis : out    std_logic                                                            ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register

         i_ep_cmd_rx_wd_add   : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_noerr_rdy: in     std_logic                                                            ; --! EP command receipted with no address/length error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command to transmit: read register word
         o_cmd_ck_sq1_adc     : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC Clocks switch commands (for each column: '0' = Inactive, '1' = Active)
         o_cmd_ck_sq1_dac     : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID1 DAC Clocks switch commands (for each column: '0' = Inactive, '1' = Active)

   );
end entity register_mgt;

architecture RTL of register_mgt is
constant c_FW_VERSION_S       : integer   := c_EP_SPI_WD_S - c_BRD_MODEL_S - c_BRD_REF_S                    ; --! Firmware version bus size

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Register to transmit management
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_tx_wd_rd_rg : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_ep_cmd_tx_wd_rd_rg <= (others => c_EP_CMD_ERR_CLR);

      elsif rising_edge(i_clk) then
         case i_ep_cmd_rx_wd_add is

            -- @Req : REG_Version
            -- @Req : DRE-DMX-FW-REQ-0520
            -- @Req : DRE-DMX-FW-REQ-0530
            when c_EP_CMD_ADD_VERSION  =>
               o_ep_cmd_tx_wd_rd_rg <= std_logic_vector(to_unsigned(c_FW_VERSION, c_FW_VERSION_S)) & i_brd_model_rs & i_brd_ref_rs;

            -- @Req : REG_Status
            when others                =>
               o_ep_cmd_tx_wd_rd_rg <= i_ep_cmd_sts_rg;

           end case;

      end if;

   end process P_ep_cmd_tx_wd_rd_rg;

   -- TODO
   o_ep_cmd_sts_err_nin   <= '0';
   o_ep_cmd_sts_err_dis   <= '0';
   o_ep_cmd_sts_err_out   <= '0';
   o_cmd_ck_sq1_adc       <= (others => '1');
   o_cmd_ck_sq1_dac       <= (others => '1');

end architecture RTL;
