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
--!   @file                   multiplexer.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Multiplexer with one pipe out. Return 0 if no chip select is activated. Multiplexed data conflict if more one chip select is activated.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;

entity multiplexer is generic
   (     g_DATA_S             : integer                                                                     ; --! Data bus size
         g_NB                 : integer                                                                       --! Data bus number
   ); port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_data               : in     t_slv_arr(g_NB-1 downto 0)(g_DATA_S-1 downto 0)                      ; --! Data buses
         i_cs                 : in     std_logic_vector(g_NB-1 downto 0)                                    ; --! Chip selects ('0' = Inactive, '1' = Active)

         o_data_mux           : out    std_logic_vector(g_DATA_S-1 downto 0)                                ; --! Multiplexed data
         o_cs_or              : out    std_logic                                                              --! Chip selects "or-ed"

   );
end entity multiplexer;

architecture RTL of multiplexer is
signal   cs_or                : std_logic_vector(g_NB-1 downto 0)                                           ; --! Chip selects "or-ed"
signal   data_cmp             : t_slv_arr(g_NB-1 downto 0)(g_DATA_S-1 downto 0)                             ; --! Data compared
signal   data_or              : t_slv_arr(g_NB-1 downto 0)(g_DATA_S-1 downto 0)                             ; --! Data "or-ed"

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   "Or-ed" bus initialization
   -- ------------------------------------------------------------------------------------------------------
   cs_or(0)    <= i_cs(0);
   data_or(0)  <= data_cmp(0);

   -- ------------------------------------------------------------------------------------------------------
   --!   "Or-ed" bus management
   -- ------------------------------------------------------------------------------------------------------
   G_data_bus_nb: for k in 0 to g_NB-1 generate
   begin

      data_cmp(k) <= i_data(k) when i_cs(k) = '1' else (others => '0');

      G_k_not0: if k /= 0 generate

         cs_or(k)    <= i_cs(k)     or cs_or(k-1);
         data_or(k)  <= data_cmp(k) or data_or(k-1);

      end generate;

   end generate G_data_bus_nb;

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs management
   -- ------------------------------------------------------------------------------------------------------
   P_output_mgt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_data_mux  <= (others => '0');
         o_cs_or     <= '0';

      elsif rising_edge(i_clk) then
         o_data_mux  <= data_or(data_or'high);
         o_cs_or     <= cs_or(cs_or'high);

      end if;

   end process P_output_mgt;

end architecture RTL;
