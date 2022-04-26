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
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid_adc_mgt is port
   (     i_rst_sys_sq1_adc    : in     std_logic                                                            ; --! Reset for SQUID1 ADC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc_dac    : in     std_logic                                                            ; --! SQUID1 ADC/DAC internal Clock

         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_tm_mode_dmp_cmp    : in     std_logic                                                            ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_sq1_adc_data       : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC: Data, no rsync
         i_sq1_adc_oor        : in     std_logic                                                            ; --! SQUID1 ADC: Out of range, no rsync ('0'= No, '1'= under/over range)

         i_sq1_mem_dump_add   : in     std_logic_vector(c_MEM_DUMP_ADD_S-1 downto 0)                        ; --! SQUID1 Memory Dump: address
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
signal   sq1_adc_data_r       : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_SQ1_ADC_DATA_S-1 downto 0)                ; --! SQUID1 ADC: Data register
signal   sq1_adc_oor_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC: Out of range register ('0' = No, '1' = under/over range)

signal   mem_dump_adc_cs_rs   : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Memory Dump, ADC acquisition side: chip select, resynchronized on system clock

signal   sync_re_adc_data     : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge, synchronized on ADC data first pixel
signal   tm_mode_dmp_cmp_sync : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Telemetry mode, status "Dump" compared sync. on Pixel sequence sync.

signal   mem_dump_adc_cnt_w   : std_logic_vector(     c_DMP_CNT_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: counter words
signal   mem_dump_adc         : t_mem(add(c_MEM_DUMP_ADD_S-1 downto 0),data_w(c_MEM_DUMP_DATA_S-1 downto 0)); --! Memory Dump, ADC acquisition side inputs

signal   mem_dump_sc          : t_mem(add(c_MEM_DUMP_ADD_S-1 downto 0),data_w(c_MEM_DUMP_DATA_S-1 downto 0)); --! Memory Dump, Science TM side inputs
signal   mem_dump_data_out    : std_logic_vector(c_MEM_DUMP_DATA_S-1 downto 0)                              ; --! Memory Dump, Science TM side: data out
signal   mem_dump_flg_err     : std_logic                                                                   ; --! Memory Dump, Science TM side: flag error uncorrectable detected ('0' = No, '1' = Yes)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on SQUID1 pulse shaping Clock generation
   --!     Necessity to generate local reset in order to reach expected frequency
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_sq1_adc: entity work.signal_reg generic map
   (     g_SIG_FF_NB          => c_FF_RST_ADC_DAC_NB  , -- integer                                          ; --! Signal registered flip-flop number
         g_SIG_DEF            => '1'                    -- std_logic                                          --! Signal registered default value at reset
   )  port map
   (     i_reset              => i_rst_sys_sq1_adc    , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_sig                => '0'                  , -- in     std_logic                                 ; --! Signal
         o_sig_r              => rst_sq1_adc            -- out    std_logic                                   --! Signal registered
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization on SQUID1 ADC acquisition Clock
   --    @Req : DRE-DMX-FW-REQ-0100
   -- ------------------------------------------------------------------------------------------------------
   P_in_rsync : process (rst_sq1_adc, i_clk_sq1_adc_dac)
   begin

      if rst_sq1_adc = '1' then
         sync_r            <= (others => c_I_SYNC_DEF);
         tm_mode_dmp_cmp_r <= (others => '0');
         sq1_adc_data_r    <= (others => c_I_SQ1_ADC_DATA_DEF);
         sq1_adc_oor_r     <= (others => c_I_SQ1_ADC_OOR_DEF);

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sync_r            <= sync_r(sync_r'high-1 downto 0) & i_sync_rs;
         tm_mode_dmp_cmp_r <= tm_mode_dmp_cmp_r(tm_mode_dmp_cmp_r'high-1  downto 0) & i_tm_mode_dmp_cmp;
         sq1_adc_data_r    <= i_sq1_adc_data & sq1_adc_data_r(0 to sq1_adc_data_r'high-1);
         sq1_adc_oor_r     <= sq1_adc_oor_r(sq1_adc_oor_r'high-1 downto 0) & i_sq1_adc_oor;

      end if;

   end process P_in_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals registered
   -- ------------------------------------------------------------------------------------------------------
   P_reg : process (rst_sq1_adc, i_clk_sq1_adc_dac)
   begin

      if rst_sq1_adc = '1' then
         sync_re_adc_data     <= '0';
         tm_mode_dmp_cmp_sync <= (others => '0');

      elsif rising_edge(i_clk_sq1_adc_dac) then
         sync_re_adc_data  <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);

         if sync_re_adc_data = '1' then
            tm_mode_dmp_cmp_sync <= tm_mode_dmp_cmp_sync(tm_mode_dmp_cmp_sync'high-1 downto 0) & tm_mode_dmp_cmp_r(tm_mode_dmp_cmp_r'high);

         end if;

      end if;

   end process P_reg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: writing data signals
   --!      (SQUID1 ADC acquisition Clock side)
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_adc_cnt_w : process (rst_sq1_adc, i_clk_sq1_adc_dac)
   begin

      if rst_sq1_adc = '1' then
         mem_dump_adc_cnt_w   <= (others => '1');

      elsif rising_edge(i_clk_sq1_adc_dac) then
         if (mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) and not(tm_mode_dmp_cmp_sync(tm_mode_dmp_cmp_sync'high)) and tm_mode_dmp_cmp_sync(tm_mode_dmp_cmp_sync'high-1) and sync_re_adc_data) = '1' then
            mem_dump_adc_cnt_w <= std_logic_vector(to_unsigned(c_DMP_CNT_MAX_VAL, mem_dump_adc_cnt_w'length));

         elsif mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = '0' then
            mem_dump_adc_cnt_w <= std_logic_vector(signed(mem_dump_adc_cnt_w) - 1);

         end if;
      end if;

   end process P_mem_dump_adc_cnt_w;

   mem_dump_adc.pp   <= '0';
   mem_dump_adc.add  <= std_logic_vector(resize(unsigned(mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high-1 downto 0)), mem_dump_adc.add'length));
   mem_dump_adc.we   <= '1';
   mem_dump_adc.cs   <= not(mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high));

   mem_dump_adc.data_w(c_SQ1_ADC_DATA_S-1 downto 0) <= sq1_adc_data_r(sq1_adc_data_r'high);
   mem_dump_adc.data_w(c_SQ1_ADC_DATA_S)            <= sq1_adc_oor_r(sq1_adc_oor_r'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode
   -- ------------------------------------------------------------------------------------------------------
   I_mem_dump: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_DATA_TX   , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_DUMP_ADD_S     , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_MEM_DUMP_DATA_S    , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_RAM_INIT_EMPTY       -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => '0'                  , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk_sq1_adc_dac    , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => '0'                  , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => mem_dump_adc         , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => open                 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => open                 , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => '0'                  , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_dump_sc          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => mem_dump_data_out    , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => mem_dump_flg_err       -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: writing data signals
   --!      (System Clock side)
   -- ------------------------------------------------------------------------------------------------------
   mem_dump_sc.pp       <= '0';
   mem_dump_sc.add      <= i_sq1_mem_dump_add;
   mem_dump_sc.we       <= '0';
   mem_dump_sc.cs       <= '1';
   mem_dump_sc.data_w   <= (others => '0');

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
         mem_dump_adc_cs_rs   <= mem_dump_adc_cs_rs(mem_dump_adc_cs_rs'high-1 downto 0) & mem_dump_adc.cs;

      end if;

   end process P_out_rsync;

   o_sq1_mem_dump_bsy <= mem_dump_adc_cs_rs(mem_dump_adc_cs_rs'high);

   -- TODO
   o_sq1_data_err <= (others => '0');

end architecture RTL;