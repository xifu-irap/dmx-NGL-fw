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
use     work.pkg_type.all;

entity mem_data_rd_mux is generic (
         g_MEM_RD_DATA_NPER   : integer                                                                     ; --! Clock period number for accessing memory data output
         g_DATA_S             : integer                                                                     ; --! Data bus size
         g_NB                 : integer                                                                       --! Data bus number
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_data               : in     t_slv_arr(0 to g_NB-1)(g_DATA_S-1 downto 0)                          ; --! Data buses
         i_cs                 : in     std_logic_vector(g_NB-1 downto 0)                                    ; --! Chip selects ('0' = Inactive, '1' = Active)

         o_data_mux           : out    std_logic_vector(g_DATA_S-1 downto 0)                                  --! Multiplexed data

   );
end entity mem_data_rd_mux;

architecture RTL of mem_data_rd_mux is
signal   cs_r                 : t_slv_arr(0 to g_MEM_RD_DATA_NPER)(g_NB-1 downto 0)                         ; --! Chip select data read register
signal   cs_or                : std_logic                                                                   ; --! Chip select data read "or-ed"
signal   data_mx              : std_logic_vector(g_DATA_S-1 downto 0)                                       ; --! Data read multiplexed

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Memories chip select registered
   -- ------------------------------------------------------------------------------------------------------
   P_cs_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         cs_r  <= (others => (others => '0'));

      elsif rising_edge(i_clk) then
         cs_r  <= i_cs & cs_r(0 to cs_r'high-1);

      end if;

   end process P_cs_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Multiplexer
   -- ------------------------------------------------------------------------------------------------------
   I_data_mux : entity work.multiplexer generic map (
         g_DATA_S             => g_DATA_S             , -- integer                                          ; --! Data bus size
         g_NB                 => g_NB                   -- integer                                            --! Data bus number
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => i_data               , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => cs_r(cs_r'high)      , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => data_mx              , -- out    std_logic_vector(g_DATA_S-1 downto 0)     ; --! Multiplexed data
         o_cs_or              => cs_or                  -- out    std_logic                                   --! Chip selects "or-ed"
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Data read multiplexed
   -- ------------------------------------------------------------------------------------------------------
   P_data_mx : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_data_mux  <= (others => '0');

      elsif rising_edge(i_clk) then
         if cs_or = '1' then
            o_data_mux    <= data_mx;
         end if;

      end if;

   end process P_data_mx;

end architecture RTL;
