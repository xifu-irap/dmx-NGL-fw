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
--!   @file                   adder_acc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Adder with accumulators (saturation on minimum and maximum value if exceeding) indexed in memory
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity adder_acc is generic (
         g_DATA_ACC_S         : integer                                                                     ; --! Data to accumulate bus size
         g_DATA_ELN_S         : integer                                                                     ; --! Data element n bus size (>= g_DATA_ACC_S)
         g_MEM_ACC_NW         : integer                                                                       --! Memory accumulator number word
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_mem_eln_rd_add     : in     std_logic_vector(log2_ceil(g_MEM_ACC_NW)-1 downto 0)                 ; --! Memory accumulator address element n read
         i_mem_acc_wr_add     : in     std_logic_vector(log2_ceil(g_MEM_ACC_NW)-1 downto 0)                 ; --! Memory accumulator address data to accumulate write
         i_squid_close_mode_n : in     std_logic                                                            ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   : in     std_logic                                                            ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)

         i_mem_acc_init_val   : in     std_logic_vector(g_DATA_ELN_S-1 downto 0)                            ; --! Memory accumulator initialization value (signed)
         i_rl_ena             : in     std_logic                                                            ; --! Relock enable ('0' = No, '1' = Yes)
         i_rl_ena_rdy         : in     std_logic                                                            ; --! Relock enable ready

         i_data_acc           : in     std_logic_vector(g_DATA_ACC_S-1 downto 0)                            ; --! Data to accumulate (signed)
         i_data_acc_rdy       : in     std_logic                                                            ; --! Data to accumulate ready ('0' = Not ready, '1' = Ready)
         i_data_eln_rdy       : in     std_logic                                                            ; --! Data element n ready     ('0' = Not ready, '1' = Ready)

         o_data_elnp1         : out    std_logic_vector(g_DATA_ELN_S-1 downto 0)                            ; --! Data element n+1 (signed)
         o_data_eln           : out    std_logic_vector(g_DATA_ELN_S-1 downto 0)                              --! Data element n   (signed)
   );
end entity adder_acc;

architecture RTL of adder_acc is
constant c_FF_RL_ENA_RDY_NB   : integer := 2                                                                ; --! Flip-Flop number used for Relock enable  ready register
constant c_FF_DATA_ELN_RDY_NB : integer := 2                                                                ; --! Flip-Flop number used for Data element n ready register

signal   mem_acc              : t_slv_arr(0 to 2**log2_ceil(g_MEM_ACC_NW)-1)(g_DATA_ELN_S-1 downto 0)       ; --! Memory accumulator

signal   rl_ena_rdy_r         : std_logic_vector(c_FF_RL_ENA_RDY_NB-1 downto 0)                             ; --! Relock enable ready register
signal   data_acc_rdy_r       : std_logic                                                                   ; --! Data to accumulate ready register ('0' = Not ready, '1' = Ready)
signal   data_eln_rdy_r       : std_logic_vector(c_FF_DATA_ELN_RDY_NB-1 downto 0)                           ; --! Data element n ready register     ('0' = Not ready, '1' = Ready)

signal   data_acc_rs          : std_logic_vector(g_DATA_ELN_S-1 downto 0)                                   ; --! Data to accumulate resize (signed)
signal   dta_add_acc_sat      : std_logic_vector(g_DATA_ELN_S-1 downto 0)                                   ; --! Data adder and accumulate with saturation
signal   data_add_acc_sat     : std_logic_vector(g_DATA_ELN_S-1 downto 0)                                   ; --! Data adder and accumulate with saturation
signal   data_eln             : std_logic_vector(g_DATA_ELN_S-1 downto 0)                                   ; --! Data element n
signal   data_elnp1_r         : std_logic_vector(g_DATA_ELN_S-1 downto 0)                                   ; --! Data element n+1 register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         rl_ena_rdy_r   <= (others => c_LOW_LEV);
         data_acc_rdy_r <= c_LOW_LEV;
         data_eln_rdy_r <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         rl_ena_rdy_r   <= rl_ena_rdy_r(    rl_ena_rdy_r'high-1 downto 0) & i_rl_ena_rdy;
         data_acc_rdy_r <= i_data_acc_rdy;
         data_eln_rdy_r <= data_eln_rdy_r(data_eln_rdy_r'high-1 downto 0) & i_data_eln_rdy;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data adder and accumulate with saturation
   -- ------------------------------------------------------------------------------------------------------
   data_acc_rs <= std_logic_vector(resize(signed(i_data_acc), data_acc_rs'length));

   I_adder_sat: entity work.adder_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_S             => g_DATA_ELN_S           -- integer                                            --! Data bus size
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_data_fst           => data_acc_rs          , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data first (signed)
         i_data_sec           => o_data_eln           , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data second (signed)

         o_data_add_sat       => dta_add_acc_sat        -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Data added with saturation (signed)
   );

   --!   Data adder and accumulate with saturation
   P_data_add_acc_sat : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         data_add_acc_sat <= c_ZERO(data_add_acc_sat'range);

      elsif rising_edge(i_clk) then
         if data_acc_rdy_r = c_HGH_LEV then
            data_add_acc_sat <= dta_add_acc_sat;

         end if;

      end if;

   end process P_data_add_acc_sat;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data element n+1 (signed)
   -- ------------------------------------------------------------------------------------------------------
   P_data_elnp1 : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_data_elnp1 <= c_ZERO(o_data_elnp1'range);
         data_elnp1_r <= c_ZERO(data_elnp1_r'range);

      elsif rising_edge(i_clk) then
         if i_rl_ena_rdy = c_HGH_LEV then
            if (i_rl_ena or i_squid_close_mode_n or i_amp_frst_lst_frm)= c_HGH_LEV then
               o_data_elnp1 <= i_mem_acc_init_val;

            else
               o_data_elnp1 <= data_add_acc_sat;

            end if;

         end if;

         data_elnp1_r <= o_data_elnp1;

      end if;

   end process P_data_elnp1;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory accumulator
   -- ------------------------------------------------------------------------------------------------------
   P_mem_acc_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if rl_ena_rdy_r(rl_ena_rdy_r'high) = c_HGH_LEV then
            mem_acc(to_integer(unsigned(i_mem_acc_wr_add))) <= data_elnp1_r;

         end if;

      end if;

   end process P_mem_acc_wr;

   --! Accumulator: memory read
   P_mem_acc_rd : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         data_eln    <= c_ZERO(data_eln'range);
         o_data_eln  <= c_ZERO(o_data_eln'range);

      elsif rising_edge(i_clk) then
         data_eln <= mem_acc(to_integer(unsigned(i_mem_eln_rd_add)));

         if data_eln_rdy_r(data_eln_rdy_r'high) = c_HGH_LEV then
            if i_squid_close_mode_n = c_HGH_LEV then
               o_data_eln <= c_ZERO(o_data_eln'range);

            elsif i_amp_frst_lst_frm = c_HGH_LEV then
               o_data_eln <= i_mem_acc_init_val;

            else
               o_data_eln <= data_eln;

            end if;

         end if;

      end if;

   end process P_mem_acc_rd;

end architecture RTL;
