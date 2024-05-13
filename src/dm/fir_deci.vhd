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
--!   @file                   fir_deci.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Filter Finite Impulse Response with decimation
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

entity fir_deci is generic (
         g_FIR_DCI_VAL        : integer                                                                     ; --! Filter FIR decimation value
         g_FIR_TAB_NW         : integer                                                                     ; --! Filter FIR table number word
         g_FIR_COEF_S         : integer                                                                     ; --! Filter FIR coefficient bus size
         g_FIR_COEF           : t_slv_arr(0 to g_FIR_TAB_NW-1)(g_FIR_COEF_S-1 downto 0)                     ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     : integer                                                                     ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         : integer                                                                     ; --! Filter FIR data bus size
         g_FIR_RES_S          : integer                                                                       --! Filter FIR result bus size
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_fir_init_val       : in     std_logic_vector(g_FIR_DATA_S-1 downto 0)                            ; --! Filter FIR data initialization value
         i_fir_init_ena       : in     std_logic                                                            ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)

         i_data               : in     std_logic_vector(g_FIR_DATA_S-1 downto 0)                            ; --! Data (signed)
         i_data_rdy           : in     std_logic                                                            ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            : out    std_logic_vector( g_FIR_RES_S-1 downto 0)                            ; --! Filter FIR result (signed)
         o_fir_res_rdy        : out    std_logic                                                              --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );
end entity fir_deci;

architecture RTL of fir_deci is
constant c_DATA_IN_RDY_POS    : integer := 0                                                                ; --! Ready position: Data
constant c_DATA_CNT_RDY_POS   : integer := c_DATA_IN_RDY_POS + 1                                            ; --! Ready position: Data counter
constant c_FIR_DT_CNT_RDY_POS : integer := c_DATA_IN_RDY_POS + 1                                            ; --! Ready position: Filter FIR data decimation word counter
constant c_FIR_PRD_RDY_POS    : integer := c_FIR_DT_CNT_RDY_POS + c_MEM_RD_DATA_NPER + c_DSP_NPER + 1       ; --! Ready position: Filter FIR product result
constant c_FIR_A_MSB_RDY_POS  : integer := c_FIR_PRD_RDY_POS - c_FIR_DT_CNT_RDY_POS + 2                     ; --! Ready position: Filter FIR address counter MSB sync. with FIR sum result
constant c_FIR_SUM_RDY_POS    : integer := c_FIR_PRD_RDY_POS + 1                                            ; --! Ready position: Filter FIR sum result

constant c_TOT_RDY_POS        : integer := c_FIR_SUM_RDY_POS                                                ; --! Ready position: Total

constant c_FIR_SYNC_COEF_DATA : integer := 3                                                                ; --! Filter FIR synchronization between FIR coefficient and data
constant c_FIR_ADD_INIT       : integer := g_FIR_TAB_NW - g_FIR_DCI_VAL                                     ; --! Filter FIR data address initialization value

constant c_FIR_W_CNT_MAX_VAL  : integer:= g_FIR_DCI_VAL - 2                                                 ; --! Filter FIR data decimation word counter: maximal value
constant c_FIR_W_CNT_S        : integer:= log2_ceil(c_FIR_W_CNT_MAX_VAL + 1) + 1                            ; --! Filter FIR data decimation word counter: size bus (signed)

constant c_FIR_A_CNT_MAX_VAL  : integer:= g_FIR_TAB_NW - 2                                                  ; --! Filter FIR address counter: maximal value
constant c_FIR_A_CNT_S        : integer:= log2_ceil(c_FIR_A_CNT_MAX_VAL + 1) + 1                            ; --! Filter FIR address counter: size bus (signed)

constant c_FIR_ADD_S          : integer := log2_ceil(g_FIR_TAB_NW)                                          ; --! Filter FIR address bus size
constant c_FIR_PROD_S         : integer := g_FIR_DATA_S + g_FIR_COEF_S - 1                                  ; --! Filter FIR product result bus size
constant c_FIR_SUM_S          : integer := g_FIR_DATA_S + g_FIR_COEF_SUM_S                                  ; --! Filter FIR result bus size

signal   mem_fir_data_wr      : t_mem(
                                add(    c_FIR_ADD_S-1 downto 0),
                                data_w(g_FIR_DATA_S-1 downto 0))                                            ; --! Filter FIR data write: memory inputs

signal   mem_fir_data_rd      : t_mem(
                                add(    c_FIR_ADD_S-1 downto 0),
                                data_w(g_FIR_DATA_S-1 downto 0))                                            ; --! Filter FIR data read: memory inputs

signal   fir_init_ena_r       : std_logic                                                                   ; --! Filter FIR initialization enable register
signal   fir_init_ena_fe      : std_logic                                                                   ; --! Filter FIR initialization enable falling edge

signal   data_rdy_r           : std_logic_vector(c_TOT_RDY_POS  downto 0)                                   ; --! Data ready register
signal   data_mux_init        : std_logic_vector(g_FIR_DATA_S-1 downto 0)                                   ; --! Data multiplexed with initialization value
signal   cnt_data             : std_logic_vector(c_FIR_ADD_S -1 downto 0)                                   ; --! Data counter

signal   cnt_fir_data_wd      : std_logic_vector(c_FIR_W_CNT_S-1 downto 0)                                  ; --! Filter FIR data decimation word counter
signal   cnt_fir_data_wd_lst  : std_logic                                                                   ; --! Filter FIR data decimation word counter MSB last
signal   cnt_fir_add          : std_logic_vector(c_FIR_A_CNT_S-1 downto 0)                                  ; --! Filter FIR address counter
signal   cnt_fir_add_msb_r    : std_logic_vector(c_FIR_A_MSB_RDY_POS-1 downto 0)                            ; --! Filter FIR address counter MSB register
signal   cnt_fir_add_msb_fe   : std_logic                                                                   ; --! Filter FIR address counter MSB falling edge
signal   fir_data_add_init    : std_logic_vector(c_FIR_ADD_S -1 downto 0)                                   ; --! Filter FIR data address initialization
signal   fir_add              : std_logic_vector(c_FIR_ADD_S -1 downto 0)                                   ; --! Filter FIR address
signal   fir_add_r            : t_slv_arr(0 to c_FIR_SYNC_COEF_DATA-1)(c_FIR_ADD_S-1 downto 0)              ; --! Filter FIR address register
signal   fir_data_add         : std_logic_vector(c_FIR_ADD_S -1 downto 0)                                   ; --! Filter FIR data address
signal   fir_data             : std_logic_vector(g_FIR_DATA_S-1 downto 0)                                   ; --! Filter FIR data
signal   fir_data_mux         : std_logic_vector(g_FIR_DATA_S-1 downto 0)                                   ; --! Filter FIR data multiplexed
signal   fir_coef             : std_logic_vector(g_FIR_COEF_S-1 downto 0)                                   ; --! Filter FIR coefficient
signal   fir_prod             : std_logic_vector(c_FIR_PROD_S-1 downto 0)                                   ; --! Filter FIR product result
signal   fir_sum              : std_logic_vector(c_FIR_SUM_S -1 downto 0)                                   ; --! Filter FIR sum result
signal   fir_sum_stall_msb    : std_logic_vector(g_FIR_RES_S    downto 0)                                   ; --! Filter FIR sum result stall on msb

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         data_rdy_r  <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         data_rdy_r  <= data_rdy_r(data_rdy_r'high-1 downto 0) & i_data_rdy;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR initialization enable synchonized on data ready
   -- ------------------------------------------------------------------------------------------------------
   P_fir_init_ena_sync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_init_ena_r    <= c_HGH_LEV;
         fir_init_ena_fe   <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         fir_init_ena_r    <= i_fir_init_ena;
         fir_init_ena_fe   <= not(i_fir_init_ena) and fir_init_ena_r;

      end if;

   end process P_fir_init_ena_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data counter
   -- ------------------------------------------------------------------------------------------------------
   P_cnt_dta_err_cor : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         cnt_data <= c_ZERO(cnt_data'range);

      elsif rising_edge(i_clk) then
         if i_fir_init_ena = c_HGH_LEV then
            cnt_data <= std_logic_vector(unsigned(cnt_data) + 1);

         elsif fir_init_ena_fe = c_HGH_LEV then
            cnt_data <= std_logic_vector(to_unsigned(c_FIR_ADD_INIT - 1, cnt_data'length));

         elsif data_rdy_r(c_DATA_IN_RDY_POS) = c_HGH_LEV then
            cnt_data <= std_logic_vector(unsigned(cnt_data) + 1);

         end if;

      end if;

   end process P_cnt_dta_err_cor;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data multiplexed with initialization value
   -- ------------------------------------------------------------------------------------------------------
   P_data_mux_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         data_mux_init <= c_ZERO(data_mux_init'range);

      elsif rising_edge(i_clk) then
         if i_fir_init_ena = c_HGH_LEV then
            data_mux_init <= i_fir_init_val;

         elsif data_rdy_r(c_DATA_IN_RDY_POS) = c_HGH_LEV then
            data_mux_init <= i_data;

         end if;

      end if;

   end process P_data_mux_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for Filter FIR data
   -- ------------------------------------------------------------------------------------------------------
   I_mem_fir_data: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_DATA_TX   , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_FIR_ADD_S          , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => g_FIR_DATA_S         , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_RAM_INIT_EMPTY       -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => mem_fir_data_wr      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => open                 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => open                 , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_fir_data_rd      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => fir_data             , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory Filter FIR data: memory signals management
   -- ------------------------------------------------------------------------------------------------------
   mem_fir_data_wr.add      <= cnt_data;
   mem_fir_data_wr.we       <= c_HGH_LEV;
   mem_fir_data_wr.cs       <= i_fir_init_ena or data_rdy_r(c_DATA_CNT_RDY_POS);
   mem_fir_data_wr.data_w   <= data_mux_init;
   mem_fir_data_wr.pp       <= c_LOW_LEV;

   mem_fir_data_rd.add      <= fir_data_add;
   mem_fir_data_rd.we       <= c_LOW_LEV;
   mem_fir_data_rd.cs       <= c_HGH_LEV;
   mem_fir_data_rd.data_w   <= c_ZERO(mem_fir_data_rd.data_w'range);
   mem_fir_data_rd.pp       <= c_LOW_LEV;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR data multiplexed
   -- ------------------------------------------------------------------------------------------------------
   P_fir_data_mux : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_data_mux   <= c_ZERO(fir_data_mux'range);

      elsif rising_edge(i_clk) then
         if i_fir_init_ena = c_HGH_LEV then
            fir_data_mux <= i_fir_init_val;

         else
            fir_data_mux <= fir_data;

         end if;

      end if;

   end process P_fir_data_mux;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR data decimation word counter
   -- ------------------------------------------------------------------------------------------------------
   P_cnt_fir_data_wd : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         cnt_fir_data_wd     <= std_logic_vector(to_signed(c_FIR_W_CNT_MAX_VAL, cnt_fir_data_wd'length));
         cnt_fir_data_wd_lst <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if i_fir_init_ena = c_HGH_LEV then
            cnt_fir_data_wd <= std_logic_vector(to_signed(c_FIR_W_CNT_MAX_VAL, cnt_fir_data_wd'length));

         elsif data_rdy_r(c_DATA_IN_RDY_POS) = c_HGH_LEV then
            if cnt_fir_data_wd(cnt_fir_data_wd'high) = c_HGH_LEV then
               cnt_fir_data_wd <= std_logic_vector(to_signed(c_FIR_W_CNT_MAX_VAL, cnt_fir_data_wd'length));

            else
               cnt_fir_data_wd <= std_logic_vector(signed(cnt_fir_data_wd) - 1);

            end if;

         end if;

         if data_rdy_r(c_DATA_IN_RDY_POS) = c_HGH_LEV then
            cnt_fir_data_wd_lst <= cnt_fir_data_wd(cnt_fir_data_wd'high);

         end if;

      end if;

   end process P_cnt_fir_data_wd;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR data address initialization
   -- ------------------------------------------------------------------------------------------------------
   P_fir_data_add_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_data_add_init <= std_logic_vector(to_unsigned(c_FIR_ADD_INIT, fir_data_add_init'length));

      elsif rising_edge(i_clk) then
         if i_fir_init_ena = c_HGH_LEV then
            fir_data_add_init <= std_logic_vector(to_unsigned(c_FIR_ADD_INIT, fir_data_add_init'length));

         elsif (cnt_fir_data_wd(cnt_fir_data_wd'high) and data_rdy_r(c_FIR_DT_CNT_RDY_POS)) = c_HGH_LEV then
            fir_data_add_init <= std_logic_vector(unsigned(fir_data_add_init) + to_unsigned(g_FIR_DCI_VAL, fir_data_add_init'length));

         end if;

      end if;

   end process P_fir_data_add_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR address counter
   -- ------------------------------------------------------------------------------------------------------
   P_cnt_fir_add : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         cnt_fir_add         <= c_MINUSONE(cnt_fir_add'range);
         cnt_fir_add_msb_r   <= (others => c_HGH_LEV);
         cnt_fir_add_msb_fe  <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if i_fir_init_ena = c_HGH_LEV then
            cnt_fir_add <= c_MINUSONE(cnt_fir_add'range);

         elsif (cnt_fir_data_wd(cnt_fir_data_wd'high) and data_rdy_r(c_FIR_DT_CNT_RDY_POS)) = c_HGH_LEV then
            cnt_fir_add <= std_logic_vector(to_unsigned(c_FIR_A_CNT_MAX_VAL, cnt_fir_add'length));

         elsif cnt_fir_add(cnt_fir_add'high) = c_LOW_LEV then
            cnt_fir_add <= std_logic_vector(signed(cnt_fir_add) - 1);

         end if;

         cnt_fir_add_msb_r   <= cnt_fir_add_msb_r(cnt_fir_add_msb_r'high-1 downto 0) & cnt_fir_add(cnt_fir_add'high);
         cnt_fir_add_msb_fe  <= cnt_fir_add_msb_r(cnt_fir_add_msb_r'low) and not(cnt_fir_add(cnt_fir_add'high));

      end if;

   end process P_cnt_fir_add;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR address
   -- ------------------------------------------------------------------------------------------------------
   P_fir_add : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_add       <= c_ZERO(fir_add'range);
         fir_data_add  <= c_ZERO(fir_data_add'range);
         fir_add_r     <= (others => c_ZERO(fir_add_r(fir_add_r'low)'range));

      elsif rising_edge(i_clk) then
         fir_add       <= std_logic_vector(signed(to_unsigned(c_FIR_A_CNT_MAX_VAL, fir_add'length)) - signed(cnt_fir_add(fir_add'range)));
         fir_data_add  <= std_logic_vector(unsigned(fir_add) + unsigned(fir_data_add_init));
         fir_add_r     <= fir_add & fir_add_r(0 to fir_add_r'high-1);

      end if;

   end process P_fir_add;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for Filter FIR coefficients (Read only)
   -- ------------------------------------------------------------------------------------------------------
   P_fir_coef : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_coef <= g_FIR_COEF(to_integer(unsigned(c_ZERO(fir_add_r(fir_add_r'low)'range))));

      elsif rising_edge(i_clk) then
         fir_coef <= g_FIR_COEF(to_integer(unsigned(fir_add_r(fir_add_r'high))));

      end if;

   end process P_fir_coef;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR product result
   -- ------------------------------------------------------------------------------------------------------
   I_fir_prod: entity work.dsp generic map (
         g_PORTA_S            => g_FIR_DATA_S         , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => g_FIR_COEF_S         , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_MULT_ALU_PORTC_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_FIR_PROD_S         , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_ENA  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_MULT_ALU_SAT_NU    , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => fir_data_mux         , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => fir_coef             , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO( c_MULT_ALU_PORTC_S-1 downto 0), -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(       g_FIR_COEF_S-1 downto 0), -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => fir_prod             , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR sum result
   -- ------------------------------------------------------------------------------------------------------
   P_fir_sum : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_sum <= c_ZERO(fir_sum'range);

      elsif rising_edge(i_clk) then
         if cnt_fir_add_msb_fe = c_HGH_LEV then
            fir_sum <= c_ZERO(fir_sum'range);

         elsif cnt_fir_add_msb_r(cnt_fir_add_msb_r'high) = c_LOW_LEV then
            fir_sum <= std_logic_vector(resize(signed(fir_prod), fir_sum'length) + signed(fir_sum));

         elsif (cnt_fir_data_wd_lst and data_rdy_r(c_FIR_PRD_RDY_POS)) = c_HGH_LEV then
            fir_sum <= std_logic_vector(resize(signed(fir_prod), fir_sum'length) + signed(fir_sum));

         end if;

      end if;

   end process P_fir_sum;

   I_fir_sum_stall_msb : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_FIR_SUM_S          , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => g_FIR_RES_S + 1        -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => fir_sum              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => fir_sum_stall_msb    , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR result
   -- ------------------------------------------------------------------------------------------------------
   I_fir_sum_round_sat: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => g_FIR_RES_S + 1        -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => fir_sum_stall_msb    , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_fir_res              -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR result ready
   -- ------------------------------------------------------------------------------------------------------
   P_fir_res_rdy : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_fir_res_rdy <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         o_fir_res_rdy <= cnt_fir_data_wd_lst and data_rdy_r(data_rdy_r'high);

      end if;

   end process P_fir_res_rdy;

end architecture RTL;
