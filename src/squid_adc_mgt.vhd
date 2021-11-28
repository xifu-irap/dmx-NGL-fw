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
--!   @file                   squid_adc_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid ADC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid_adc_mgt is port
      (  i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_ck_rdy             : in     std_logic                                                            ; --! Clock ready ('0' = Not ready, '1' = Ready)
         i_clk_sq1_adc_acq    : in     std_logic                                                            ; --! SQUID1 ADC acquisition Clock

         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_tm_mode_dmp_cmp    : in     std_logic                                                            ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_sq1_adc_data       : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC - Data, no rsync
         i_sq1_adc_oor        : in     std_logic                                                            ; --! SQUID1 ADC - Out of range, no rsync (‘0’= No, ‘1’= under/over range)

         i_sq1_mem_dump_add   : in     std_logic_vector(c_MEM_DUMP_ADD_S-1 downto 0)                        ; --! SQUID1 Memory Dump: address
         i_sq1_mem_dump_cs    : in     std_logic                                                            ; --! SQUID1 Memory Dump: chip select ('0' = Inactive, '1' = Active)
         o_sq1_mem_dump_data  : out    std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                        ; --! SQUID1 Memory Dump: data
         o_sq1_mem_dump_bsy   : out    std_logic                                                            ; --! SQUID1 Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

         o_sq1_data_err       : out    std_logic_vector(c_SQ1_DATA_ERR_S-1 downto 0)                          --! SQUID1 Data error
   );
end entity squid_adc_mgt;

architecture RTL of squid_adc_mgt is
constant c_ADC_DATA_SYNC_NPER : integer := c_ADC_DATA_RDY_NPER - c_ADC_SYNC_RDY_NPER - 1                    ; --! ADC clock periods number between ADC data ready and Pixel sequence sync. ready

constant c_DMP_CNT_NB_VAL     : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Dump counter: number of value
constant c_DMP_CNT_MAX_VAL    : integer:= c_DMP_CNT_NB_VAL-1                                                ; --! Dump counter: maximal value
constant c_DMP_CNT_S          : integer:= log2_ceil(c_DMP_CNT_MAX_VAL + 1) + 1                              ; --! Dump counter: size bus (signed)

constant c_MEM_DUMP_DATA_S    : integer := c_SQ1_ADC_DATA_S + 1                                             ; --! Memory Dump: data bus size (<= c_RAM_DATA_S)

signal   rst_sq1_adc          : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)

signal   sync_r               : std_logic_vector(c_ADC_DATA_SYNC_NPER+c_FF_RSYNC_NB-1 downto 0)             ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   tm_mode_dmp_cmp_r    : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
signal   sq1_adc_data_r       : t_sq1_adc_data_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 ADC - Data register
signal   sq1_adc_oor_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC - Out of range register (‘0’ = No, ‘1’ = under/over range)

signal   mem_dump_adc_cs_rs   : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Memory Dump, ADC acquisition side: chip select, resynchronized on system clock

signal   sync_re_adc_data     : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge, synchronized on ADC data first pixel
signal   tm_mode_dmp_cmp_last : std_logic                                                                   ; --! Telemetry mode, status "Dump" compared last sync. ('0' = Inactive, '1' = Active)

signal   mem_dump_adc_cnt_w   : std_logic_vector(     c_DMP_CNT_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: counter words
signal   mem_dump_adc_add     : std_logic_vector(c_MEM_DUMP_ADD_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: address
signal   mem_dump_adc_cs      : std_logic                                                                   ; --! Memory Dump, ADC acquisition side: chip select ('0' = Inactive, '1' = Active)
signal   mem_dump_adc_data_in : std_logic_vector(c_MEM_DUMP_DATA_S-1 downto 0)                              ; --! Memory Dump, ADC acquisition side: data in

signal   mem_dump_data_out    : std_logic_vector(c_MEM_DUMP_DATA_S-1 downto 0)                              ; --! Memory Dump, Science TM side: data out
signal   mem_dump_flg_err     : std_logic                                                                   ; --! Memory Dump, Science TM side: flag error uncorrectable detected ('0' = No, '1' = Yes)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID1 pulse shaping Clock generation
   --!     Necessity to generate local reset in order to reach expected frequency
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_sq1_adc: entity work.reset_gen generic map
   (     g_FF_RESET_NB        => c_FF_RST_SQ1_ADC_NB    -- integer                                            --! Flip-Flop number used for generated reset
   ) port map
   (     i_arst_n             => i_arst_n             , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clock              => i_clk_sq1_adc_acq    , -- in     std_logic                                 ; --! Main Pll Status ('0' = Pll not locked, '1' = Pll locked)
         i_ck_rdy             => i_ck_rdy             , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              => rst_sq1_adc            -- out    std_logic                                   --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization on SQUID1 ADC acquisition Clock
   --    @Req : DRE-DMX-FW-REQ-0100
   -- ------------------------------------------------------------------------------------------------------
   P_in_rsync : process (rst_sq1_adc, i_clk_sq1_adc_acq)
   begin

      if rst_sq1_adc = '1' then
         sync_r            <= (others => c_I_SYNC_DEF);
         tm_mode_dmp_cmp_r <= (others => '0');
         sq1_adc_data_r    <= (others => c_I_SQ1_ADC_DATA_DEF);
         sq1_adc_oor_r     <= (others => c_I_SQ1_ADC_OOR_DEF);

      elsif rising_edge(i_clk_sq1_adc_acq) then
         sync_r            <= sync_r(sync_r'high-1 downto 0) & i_sync_rs;
         tm_mode_dmp_cmp_r <= tm_mode_dmp_cmp_r(tm_mode_dmp_cmp_r'high-1  downto 0) & i_tm_mode_dmp_cmp;
         sq1_adc_data_r    <= i_sq1_adc_data & sq1_adc_data_r(0 to sq1_adc_data_r'high-1);
         sq1_adc_oor_r     <= sq1_adc_oor_r(sq1_adc_oor_r'high-1 downto 0) & i_sq1_adc_oor;

      end if;

   end process P_in_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals registered
   -- ------------------------------------------------------------------------------------------------------
   P_reg : process (rst_sq1_adc, i_clk_sq1_adc_acq)
   begin

      if rst_sq1_adc = '1' then
         sync_re_adc_data     <= '0';
         tm_mode_dmp_cmp_last <= '0';

      elsif rising_edge(i_clk_sq1_adc_acq) then
         sync_re_adc_data  <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);

         if sync_re_adc_data = '1' then
            tm_mode_dmp_cmp_last <= tm_mode_dmp_cmp_r(tm_mode_dmp_cmp_r'high);

         end if;

      end if;

   end process P_reg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: writing data signals
   --!      (SQUID1 ADC acquisition Clock side)
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_adc_cnt_w : process (rst_sq1_adc, i_clk_sq1_adc_acq)
   begin

      if rst_sq1_adc = '1' then
         mem_dump_adc_cnt_w   <= (others => '1');

      elsif rising_edge(i_clk_sq1_adc_acq) then
         if (mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) and not(tm_mode_dmp_cmp_last) and tm_mode_dmp_cmp_r(tm_mode_dmp_cmp_r'high) and sync_re_adc_data) = '1' then
            mem_dump_adc_cnt_w <= std_logic_vector(to_unsigned(c_DMP_CNT_MAX_VAL, mem_dump_adc_cnt_w'length));

         elsif mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = '0' then
            mem_dump_adc_cnt_w <= std_logic_vector(signed(mem_dump_adc_cnt_w) - 1);

         end if;
      end if;

   end process P_mem_dump_adc_cnt_w;

   mem_dump_adc_add  <= std_logic_vector(resize(unsigned(mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high-1 downto 0)), mem_dump_adc_add'length));
   mem_dump_adc_cs   <= not(mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high));

   mem_dump_adc_data_in(c_SQ1_ADC_DATA_S-1 downto 0) <= sq1_adc_data_r(sq1_adc_data_r'high);
   mem_dump_adc_data_in(c_SQ1_ADC_DATA_S)            <= sq1_adc_oor_r(sq1_adc_oor_r'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode
   -- ------------------------------------------------------------------------------------------------------
   I_mem_dump: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_DATA_TX   , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_DUMP_ADD_S     , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_MEM_DUMP_DATA_S    , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_RAM_INIT_EMPTY       -- t_ram_init                                         --! Memory content at initialization
   ) port map
   (     a_clk                => i_clk_sq1_adc_acq    , -- in     std_logic                                 ; --! Memory port A: main clock
         a_clk_shift          => '0'                  , -- in     std_logic                                 ; --! Memory port A: 90° shifted clock (used for memory content correction)

         a_add                => mem_dump_adc_add     , -- in     slv( g_RAM_ADD_S-1 downto 0)              ; --! Memory port A: address
         a_we                 => '1'                  , -- in     std_logic                                 ; --! Memory port A: write enable ('0' = Inactive, '1' = Active)
         a_cs                 => mem_dump_adc_cs      , -- in     std_logic                                 ; --! Memory port A: chip select ('0' = Inactive, '1' = Active)
         a_data_in            => mem_dump_adc_data_in , -- in     slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data in
         a_data_out           => open                 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out

         a_flg_err            => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         b_clk                => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         b_clk_shift          => '0'                  , -- in     std_logic                                 ; --! Memory port B: 90° shifted clock (used for memory content correction)

         b_add                => i_sq1_mem_dump_add   , -- in     slv( g_RAM_ADD_S-1 downto 0)              ; --! Memory port B: address
         b_we                 => '0'                  , -- in     std_logic                                 ; --! Memory port B: write enable ('0' = Inactive, '1' = Active)
         b_cs                 => i_sq1_mem_dump_cs    , -- in     std_logic                                 ; --! Memory port B: chip select ('0' = Inactive, '1' = Active)
         b_data_in            => (others => '0')      , -- in     slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data in
         b_data_out           => mem_dump_data_out    , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         b_flg_err            => mem_dump_flg_err       -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: reading data signals
   --!      (System Clock side)
   -- ------------------------------------------------------------------------------------------------------
   o_sq1_mem_dump_data(c_MEM_DUMP_DATA_S-1 downto 0)  <= mem_dump_data_out;
   o_sq1_mem_dump_data(c_MEM_DUMP_DATA_S)             <= mem_dump_flg_err;

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs Resynchronization on System Clock
   -- ------------------------------------------------------------------------------------------------------
   P_out_rsync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         mem_dump_adc_cs_rs   <= (others => '0');

      elsif rising_edge(i_clk) then
         mem_dump_adc_cs_rs   <= mem_dump_adc_cs_rs(mem_dump_adc_cs_rs'high-1 downto 0) & mem_dump_adc_cs;

      end if;

   end process P_out_rsync;

   o_sq1_mem_dump_bsy <= mem_dump_adc_cs_rs(mem_dump_adc_cs_rs'high);

   -- TODO
   o_sq1_data_err <= (others => '0');

end architecture RTL;