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
--!   @file                   science_data_check.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_ep_cmd.all;

entity science_data_check is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_science        : in     std_logic                                                            ; --! Science Clock

         i_sw_adc_vin         : in     std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input

         i_adc_dmp_mem_add    : in     std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   : in     std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                        ; --! ADC Dump memory for data compare: data
         i_adc_dmp_mem_cs     : in     std_logic                                                            ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         i_science_data_ctrl  : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! Science Data: Control word
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! Science Data: Data
         i_science_data_rdy   : in     std_logic                                                            ; --! Science Data Ready ('0' = Inactive, '1' = Active)

         o_science_data_err   : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! Science data error ('0' = No error, '1' = Error)
   );
end entity science_data_check;

architecture RTL of science_data_check is
constant c_PLS_CNT_NB_VAL     : integer:= div_floor(c_PIXEL_ADC_NB_CYC, c_NB_COL)                           ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 1                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)                                  ; --! Pixel position: size bus

constant c_SEQ_CNT_MAX_VAL    : integer:= c_DMP_SEQ_ACQ_NB - 1                                              ; --! Sequence counter: maximal value
constant c_SEQ_CNT_S          : integer:= log2_ceil(c_SEQ_CNT_MAX_VAL + 1)                                  ; --! Sequence counter: size bus

signal   pls_cnt              : std_logic_vector(         c_PLS_CNT_S-1 downto 0)                           ; --! Pulse counter
signal   pixel_pos            : std_logic_vector(       c_PIXEL_POS_S-1 downto 0)                           ; --! Pixel position
signal   seq_cnt              : std_logic_vector(         c_SEQ_CNT_S-1 downto 0)                           ; --! Sequence counter

signal   science_data_rdy_r   : std_logic_vector(1 downto 0)                                                ; --! Science Data Ready register ('0' = Inactive, '1' = Active)

signal   mem_adc_dump_dta2cmp : t_slv_arr(0 to c_MUX_FACT-1)(c_SQ1_ADC_DATA_S+1 downto 0):=
                                (others => (others => '0'))                                                 ; --! Dual port memory for adc dump data to compare

signal   adc_dump_dta2cmp     : std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                               ; --! adc dump data to compare
signal   adc_dump_dta2cmp_lst : std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                               ; --! adc dump data to compare last value

signal   science_data_err     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Science data error ('0' = No error, '1' = Error)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst, i_clk_science)
   begin

      if i_rst = '1' then
         pls_cnt  <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk_science) then
         if i_science_data_rdy = '1' then

            if    i_science_data_ctrl /= c_SC_CTRL_DTA_W and i_science_data_ctrl /= c_SC_CTRL_EOD then
               pls_cnt <= std_logic_vector(to_signed(c_PLS_CNT_MAX_VAL, pls_cnt'length));

            elsif pls_cnt(pls_cnt'high) = '1' and (
                  pixel_pos < std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length)) or (
                  pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length)) and
                  seq_cnt   < std_logic_vector(to_unsigned(c_SEQ_CNT_MAX_VAL   , seq_cnt'length))  )) then
               pls_cnt <= std_logic_vector(to_signed(c_PLS_CNT_MAX_VAL, pls_cnt'length));

            elsif pls_cnt(pls_cnt'high) = '0' then
               pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

            end if;

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk_science)
   begin

      if i_rst = '1' then
         pixel_pos   <= std_logic_vector(to_unsigned(0 , pixel_pos'length));

      elsif rising_edge(i_clk_science) then
         if i_science_data_rdy = '1' then

            if    i_science_data_ctrl /= c_SC_CTRL_DTA_W and i_science_data_ctrl /= c_SC_CTRL_EOD then
               pixel_pos <= std_logic_vector(to_unsigned(0 , pixel_pos'length));

            elsif pls_cnt(pls_cnt'high) = '1' and
                  pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) and
                  seq_cnt   < std_logic_vector(to_unsigned(c_SEQ_CNT_MAX_VAL   , seq_cnt'length))   then
               pixel_pos <= std_logic_vector(to_unsigned(0 , pixel_pos'length));

            elsif pls_cnt(pls_cnt'high) = '1' and pixel_pos < std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) then
               pixel_pos <= std_logic_vector(unsigned(pixel_pos) + 1);

            end if;

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Sequence counter
   -- ------------------------------------------------------------------------------------------------------
   P_seq_cnt : process (i_rst, i_clk_science)
   begin

      if i_rst = '1' then
         seq_cnt   <= std_logic_vector(to_unsigned(0 , seq_cnt'length));

      elsif rising_edge(i_clk_science) then
         if i_science_data_rdy = '1' then

            if i_science_data_ctrl /= c_SC_CTRL_DTA_W and i_science_data_ctrl /= c_SC_CTRL_EOD then
               seq_cnt <= std_logic_vector(to_unsigned(0 , seq_cnt'length));

            elsif pls_cnt(pls_cnt'high) = '1' and pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) then
               seq_cnt <= std_logic_vector(unsigned(seq_cnt) + 1);

            end if;

         end if;

      end if;

   end process P_seq_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for adc dump data compare
   -- ------------------------------------------------------------------------------------------------------
   P_mem_adc_dmp_dta_w : process(i_clk_science)
   begin
      if rising_edge(i_clk_science) then
         if i_adc_dmp_mem_cs = '1' then
            mem_adc_dump_dta2cmp(to_integer(unsigned(i_adc_dmp_mem_add))) <=  i_adc_dmp_mem_data;

        end if;
      end if;
   end process P_mem_adc_dmp_dta_w;

   P_mem_adc_dmp_dta_r : process(i_clk_science)
   begin
      if rising_edge(i_clk_science) then
         adc_dump_dta2cmp <= mem_adc_dump_dta2cmp(to_integer(unsigned(pixel_pos)));

      end if;
   end process P_mem_adc_dmp_dta_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   adc dump data to compare last value
   -- ------------------------------------------------------------------------------------------------------
   P_dump_dta2cmp_lst : process (i_rst, i_clk_science)
   begin

      if i_rst = '1' then
         science_data_rdy_r   <= (others => '0');
         adc_dump_dta2cmp_lst <= (others => '0');

      elsif rising_edge(i_clk_science) then
         science_data_rdy_r   <= science_data_rdy_r(science_data_rdy_r'high-1 downto 0) & i_science_data_rdy;

         if i_science_data_rdy = '1' then
            adc_dump_dta2cmp_lst <= adc_dump_dta2cmp;

         end if;

      end if;

   end process P_dump_dta2cmp_lst;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data error
   -- TODO Generic case with delay management
   -- ------------------------------------------------------------------------------------------------------
   science_data_err(0) <=  '0' when (pls_cnt   = std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length)) and
                                     pixel_pos = std_logic_vector(to_unsigned(0, pixel_pos'length)) and
                                     seq_cnt   = std_logic_vector(to_unsigned(0, seq_cnt'length)))  else
                           '1' when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQ2 and i_science_data(0) /= adc_dump_dta2cmp_lst) else
                           '1' when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQ1 and
                                     pls_cnt   = std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length)) and
                                     abs(signed(i_science_data(0)) - signed(adc_dump_dta2cmp_lst)) > to_signed(1, i_science_data(0)'length)) else
                           '0';

   G_science_data_err : for k in 1 to c_NB_COL-1 generate
   begin
      science_data_err(k) <= '1' when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQ2 and i_science_data(k) /= adc_dump_dta2cmp) else '0';

   end generate G_science_data_err;

   P_science_data_err : process (i_rst, i_clk_science)
   begin

      if i_rst = '1' then
         o_science_data_err <= (others => '0');

      elsif rising_edge(i_clk_science) then
         if science_data_rdy_r(science_data_rdy_r'high) = '1' then
            o_science_data_err <= science_data_err;

         end if;

      end if;

   end process P_science_data_err;

end architecture rtl;
