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
--!   @file                   science_data_tx.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data transmit
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity science_data_tx is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_science_data_tx_ena: in     std_logic                                                            ; --! Science Data transmit enable
         i_science_data       : in     t_slv_arr(0 to c_NB_COL*c_SC_DATA_SER_NB)
                                                (c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Science Data word
         o_ser_bit_cnt        : out    std_logic_vector(log2_ceil(c_SC_DATA_SER_W_S-1) downto 0)            ; --! Serial bit counter
         o_science_data_ser   : out    std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                   --! Science Data: Serial Data
   );
end entity science_data_tx;

architecture RTL of science_data_tx is
constant c_SER_BIT_CNT_NB_VAL : integer:= c_SC_DATA_SER_W_S                                                 ; --! Serial bit counter: number of value
constant c_SER_BIT_CNT_MAX_VAL: integer:= c_SER_BIT_CNT_NB_VAL-2                                            ; --! Serial bit counter: maximal value
constant c_SER_BIT_CNT_S      : integer:= log2_ceil(c_SER_BIT_CNT_MAX_VAL+1)+1                              ; --! Serial bit counter: size bus (signed)

signal   ser_bit_cnt          : std_logic_vector(c_SER_BIT_CNT_S-1 downto 0)                                ; --! Serial bit counter
signal   science_data_ser     : t_slv_arr(0 to c_NB_COL*c_SC_DATA_SER_NB)(c_SC_DATA_SER_W_S-1 downto 0)     ; --! Science Data: Serial Data

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Serial bit counter
   -- ------------------------------------------------------------------------------------------------------
   P_ser_bit_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ser_bit_cnt <= (others => '1');

      elsif rising_edge(i_clk) then
         if (i_science_data_tx_ena and ser_bit_cnt(ser_bit_cnt'high)) = '1' then
            ser_bit_cnt <= std_logic_vector(to_signed(c_SER_BIT_CNT_MAX_VAL, ser_bit_cnt'length));

         elsif ser_bit_cnt(ser_bit_cnt'high) = '0' then
            ser_bit_cnt <= std_logic_vector(signed(ser_bit_cnt) - 1);

         end if;

      end if;

   end process P_ser_bit_cnt;

   o_ser_bit_cnt <= ser_bit_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data serial
   -- ------------------------------------------------------------------------------------------------------
   G_science_data_ser: for k in 0 to o_science_data_ser'high generate
   begin

      P_science_data_ser : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            science_data_ser(k)   <= (others => '0');
            o_science_data_ser(k) <= '0';

         elsif rising_edge(i_clk) then
            if (i_science_data_tx_ena and ser_bit_cnt(ser_bit_cnt'high)) = '1' then
               science_data_ser(k) <= i_science_data(k);

            else
               science_data_ser(k) <= science_data_ser(k)(c_SC_DATA_SER_W_S-2 downto 0) & '0';

            end if;

            o_science_data_ser(k) <= science_data_ser(k)(c_SC_DATA_SER_W_S-1);

         end if;

      end process P_science_data_ser;

   end generate G_science_data_ser;

end architecture RTL;
