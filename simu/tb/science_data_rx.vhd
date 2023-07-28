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
--!   @file                   science_data_rx.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data receipt
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity science_data_rx is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_science        : in     std_logic                                                            ; --! Science Clock

         i_science_data_ser   : in     std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB+1 downto 0)               ; --! Science Data: Serial Data
         o_science_data_ctrl  : out    t_slv_arr(0 to 1)(c_SC_DATA_SER_W_S-1 downto 0)                      ; --! Science Data: Control word
         o_science_data       : out    t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! Science Data: Data
         o_science_data_rdy   : out    std_logic                                                              --! Science Data Ready ('0' = Inactive, '1' = Active)
   );
end entity science_data_rx;

architecture Behavioral of science_data_rx is
constant c_SER_BIT_CNT_NB_VAL : integer:= c_SC_DATA_SER_W_S-3                                               ; --! Serial bit counter: number of value
constant c_SER_BIT_CNT_MAX_VAL: integer:= c_SER_BIT_CNT_NB_VAL-1                                            ; --! Serial bit counter: maximal value
constant c_SER_BIT_CNT_S      : integer:= log2_ceil(c_SER_BIT_CNT_MAX_VAL+1)+1                              ; --! Serial bit counter: size bus (signed)

signal   ser_bit_cnt          : std_logic_vector(c_SER_BIT_CNT_S-1 downto 0)                                ; --! Serial bit counter
signal   ser_bit_cnt_msb_r    : std_logic                                                                   ; --! Serial bit counter MSB
signal   ser_bit_cnt_msb_re   : std_logic                                                                   ; --! Serial bit counter MSB rising edge
signal   science_data_ser     : t_slv_arr(0 to c_NB_COL*c_SC_DATA_SER_NB+1)(c_SC_DATA_SER_W_S-1 downto 0)   ; --! Science Data: Serial Data
signal   science_data         : t_slv_arr(0 to c_NB_COL*c_SC_DATA_SER_NB+1)(c_SC_DATA_SER_W_S-1 downto 0)   ; --! Science Data: Data

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Serial bit counter
   -- ------------------------------------------------------------------------------------------------------
   P_ser_bit_cnt : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         ser_bit_cnt <= c_MINUSONE(ser_bit_cnt'range);

      elsif rising_edge(i_clk_science) then
         if (science_data_ser(science_data_ser'high)(science_data_ser(science_data_ser'low)'low) and i_science_data_ser(science_data_ser'high) and ser_bit_cnt(ser_bit_cnt'high)) = c_HGH_LEV then
            ser_bit_cnt <= std_logic_vector(to_signed(c_SER_BIT_CNT_MAX_VAL, ser_bit_cnt'length));

         elsif ser_bit_cnt(ser_bit_cnt'high) = c_LOW_LEV then
            ser_bit_cnt <= std_logic_vector(signed(ser_bit_cnt) - 1);

         end if;

      end if;

   end process P_ser_bit_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Serial bit counter MSB rising edge
   -- ------------------------------------------------------------------------------------------------------
   P_ser_bit_cnt_msb_re : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         ser_bit_cnt_msb_r  <= c_HGH_LEV;
         ser_bit_cnt_msb_re <= c_LOW_LEV;
         o_science_data_rdy <= c_LOW_LEV;

      elsif rising_edge(i_clk_science) then
         ser_bit_cnt_msb_r  <= ser_bit_cnt(ser_bit_cnt'high);
         ser_bit_cnt_msb_re <= not(ser_bit_cnt_msb_r) and ser_bit_cnt(ser_bit_cnt'high);
         o_science_data_rdy <= ser_bit_cnt_msb_re;

      end if;

   end process P_ser_bit_cnt_msb_re;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data serial
   -- ------------------------------------------------------------------------------------------------------
   G_science_data_ser: for k in 0 to i_science_data_ser'high generate
   begin

      --! Science data serial
      P_science_data_ser : process (i_rst, i_clk_science)
      begin

         if i_rst = c_RST_LEV_ACT then
            science_data_ser(k) <= c_ZERO(science_data_ser(science_data_ser'low)'range);
            science_data(k)     <= c_ZERO(science_data(science_data'low)'range);

         elsif rising_edge(i_clk_science) then
            science_data_ser(k) <= science_data_ser(k)(science_data_ser(k)'high-1 downto 0) & i_science_data_ser(k);

            if ser_bit_cnt_msb_re = c_HGH_LEV then
               science_data(k)  <= science_data_ser(k);

            end if;

         end if;

      end process P_science_data_ser;

   end generate G_science_data_ser;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data
   -- ------------------------------------------------------------------------------------------------------
   o_science_data_ctrl(o_science_data_ctrl'high) <= science_data(science_data'high);
   o_science_data_ctrl(o_science_data_ctrl'low)  <= science_data(science_data'high-1);

   G_science_data: for k in 0 to c_NB_COL-1 generate
   begin

      G_science_data_pos: for j in 0 to c_SC_DATA_SER_NB-1 generate
      begin

         o_science_data(k)((j+1)*c_SC_DATA_SER_W_S-1 downto j*c_SC_DATA_SER_W_S) <= science_data(c_SC_DATA_SER_NB*k+j);

      end generate G_science_data_pos;

   end generate G_science_data;

end architecture Behavioral;
