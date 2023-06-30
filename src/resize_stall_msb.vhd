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
--!   @file                   resize_stall_msb.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                return resized data stalled on Mean Significant Bit
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

entity resize_stall_msb is generic (
         g_DATA_S             : integer                                                                     ; --! Data input bus size
         g_DATA_STALL_MSB_S   : integer                                                                       --! Data stalled on Mean Significant Bit bus size
   ); port (
         i_data               : in     std_logic_vector(          g_DATA_S-1 downto 0)                      ; --! Data
         o_data_stall_msb     : out    std_logic_vector(g_DATA_STALL_MSB_S-1 downto 0)                        --! Data stalled on Mean Significant Bit
   );
end entity resize_stall_msb;

architecture RTL of resize_stall_msb is
begin

   G_dta_stall_msb_s : for k in 0 to o_data_stall_msb'high generate
   begin

      G_data_stall_msb_lss : if k <= g_DATA_S-1 generate
         o_data_stall_msb(o_data_stall_msb'high - k) <= i_data(i_data'high - k);

      else generate
         o_data_stall_msb(o_data_stall_msb'high - k) <= '0';

      end generate G_data_stall_msb_lss;

   end generate G_dta_stall_msb_s;

end architecture RTL;
