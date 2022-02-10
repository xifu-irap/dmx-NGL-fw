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
--!   @file                   squid_data_proc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity squid_data_proc is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_sq1_data_err       : in     std_logic_vector(c_SQ1_DATA_ERR_S-1 downto 0)                        ; --! SQUID1 Data error

         o_sq1_data_sc_msb    : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! SQUID1 Data science MSB
         o_sq1_data_sc_lsb    : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! SQUID1 Data science LSB
         o_sq1_data_sc_first  : out    std_logic                                                            ; --! SQUID1 Data science first pixel ('0' = No, '1' = Yes)
         o_sq1_data_sc_last   : out    std_logic                                                            ; --! SQUID1 Data science last pixel ('0' = No, '1' = Yes)
         o_sq1_data_sc_rdy    : out    std_logic                                                            ; --! SQUID1 Data science ready ('0' = Not ready, '1' = Ready)

         o_s1_dta_pixel_pos   : out    std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID1 Data error corrected pixel position
         o_s1_dta_err_cor     : out    std_logic_vector(c_SQ1_DATA_FBK_S-1 downto 0)                        ; --! SQUID1 Data error corrected (signed)
         o_s1_dta_err_cor_cs  : out    std_logic                                                              --! SQUID1 Data error corrected chip select ('0' = Inactive, '1' = Active)
   );
end entity squid_data_proc;

architecture RTL of squid_data_proc is

-- TODO
constant c_CK_PLS_CNT_MAX_VAL : integer:= (c_PIXEL_ADC_NB_CYC * c_CLK_MULT / c_CLK_ADC_DAC_MULT) - 2        ; --! System clock pulse counter: maximal value
constant c_CK_PLS_CNT_S       : integer:= log2_ceil(c_CK_PLS_CNT_MAX_VAL+1)+1                               ; --! System clock pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)+1                                ; --! Pixel position: size bus (signed)

signal   ck_pls_cnt           : std_logic_vector(c_CK_PLS_CNT_S-1 downto 0)                                 ; --! System clock pulse counter
signal   pixel_pos            : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position

begin

   -- TODO
   P_pixel_seq : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ck_pls_cnt  <= std_logic_vector(to_signed(c_CK_PLS_CNT_MAX_VAL, ck_pls_cnt'length));
         pixel_pos   <= (others => '1');
         o_sq1_data_sc_first  <= '0';
         o_sq1_data_sc_rdy    <= '0';

      elsif rising_edge(i_clk) then
         if ck_pls_cnt(ck_pls_cnt'high) = '1' then
            ck_pls_cnt <= std_logic_vector(to_signed(c_CK_PLS_CNT_MAX_VAL, ck_pls_cnt'length));

         else
            ck_pls_cnt <= std_logic_vector(signed(ck_pls_cnt) - 1);

         end if;

         if (pixel_pos(pixel_pos'high) and ck_pls_cnt(ck_pls_cnt'high)) = '1' then
            o_sq1_data_sc_first  <= '1';
            pixel_pos            <= std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and ck_pls_cnt(ck_pls_cnt'high)) = '1' then
            o_sq1_data_sc_first  <= '0';
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

         o_sq1_data_sc_rdy <= ck_pls_cnt(ck_pls_cnt'high);

      end if;

   end process P_pixel_seq;

   o_sq1_data_sc_msb <= std_logic_vector(resize(signed(pixel_pos), o_sq1_data_sc_msb'length));
   o_sq1_data_sc_lsb <= std_logic_vector(resize(signed(pixel_pos), o_sq1_data_sc_msb'length));
   o_sq1_data_sc_last<= pixel_pos(pixel_pos'high);

   P_todo : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_s1_dta_pixel_pos   <= (others => '1');
         o_s1_dta_err_cor     <= (others => '0');
         o_s1_dta_err_cor_cs  <= '0';

      elsif rising_edge(i_clk) then
         o_s1_dta_pixel_pos   <= std_logic_vector(resize(signed(pixel_pos), o_s1_dta_pixel_pos'length));
         o_s1_dta_err_cor     <= i_sq1_data_err(o_s1_dta_err_cor'high downto 0);
         o_s1_dta_err_cor_cs  <= ck_pls_cnt(ck_pls_cnt'high);

      end if;

   end process P_todo;

end architecture RTL;
