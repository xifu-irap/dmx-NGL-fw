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
--!   @file                   rst_clk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Manage the global resets and generate the clocks
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

entity rst_clk_mgt is port (
         i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         i_cmd_ck_adc_ena     : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_adc_dis     : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         i_cmd_ck_sqm_dac_ena : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_sqm_dac_dis : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         o_rst                : out    std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         o_rst_sqm_adc_dac    : out    std_logic                                                            ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         o_rst_sqm_adc_dac_pd : out    std_logic                                                            ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock

         o_clk                : out    std_logic                                                            ; --! System Clock
         o_clk_sqm_adc_dac    : out    std_logic                                                            ; --! SQUID MUX ADC/DAC internal Clock

         o_ck_sqm_adc         : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC Image Clocks
         o_ck_sqm_dac         : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC Image Clocks
         o_ck_science         : out    std_logic                                                            ; --! Science Data Image Clock

         o_clk_90             : out    std_logic                                                            ; --! System Clock 90 degrees shift
         o_clk_sqm_adc_dac_90 : out    std_logic                                                            ; --! SQUID MUX ADC/DAC internal 90 degrees shift

         o_sqm_adc_pwdn       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)
   );
end entity rst_clk_mgt;

architecture RTL of rst_clk_mgt is
constant c_CNT_RST_MX_VAL     : integer:= c_FF_RST_NB - 3                                                   ; --! Counter for reset generation: maximal value
constant c_CNT_RST_S          : integer:= log2_ceil(c_CNT_RST_MX_VAL + 1) + 1                               ; --! Counter for reset generation: size bus (signed)

constant c_CNT_RST_ADC_MX_VAL : integer:= c_FF_RST_ADC_DAC_NB - 3                                           ; --! Counter for reset SQUID ADC/DAC generation: maximal value
constant c_CNT_RST_ADC_S      : integer:= log2_ceil(c_CNT_RST_ADC_MX_VAL + 1) + 1                           ; --! Counter for reset SQUID ADC/DAC generation: size bus (signed)

signal   rst_sqm_adc_dac_pad  : std_logic                                                                   ; --! Reset for SQUID ADC/DAC pads, de-assertion on system clock

signal   cnt_rst              : std_logic_vector(c_CNT_RST_S-1 downto 0)                                    ; --! Counter for reset generation
signal   cnt_rst_msb_r_n      : std_logic                                                                   ; --! Counter for reset generation MSB inverted register

signal   cnt_rst_adc          : std_logic_vector(c_CNT_RST_ADC_S-1 downto 0)                                ; --! Counter for reset SQUID ADC/DAC generation
signal   cnt_rst_adc_msb_r_n  : std_logic                                                                   ; --! Counter for reset SQUID ADC/DAC generation MSB inverted register

signal   clk_sqm_adc          : std_logic                                                                   ; --! SQUID MUX ADC Clocks
signal   clk_sqm_dac_out      : std_logic                                                                   ; --! SQUID MUX DAC output Clock

signal   cmd_ck_adc           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC Clocks switch commands ('0' = Inactive, '1' = Active)
signal   cmd_ck_sqm_dac       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC Clocks switch commands ('0' = Inactive, '1' = Active)

signal   ck_science           : std_logic                                                                   ; --! Science Data Image Clock

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Clocks generation
   -- ------------------------------------------------------------------------------------------------------
   I_pll: entity work.pll port map (
         i_arst               => i_arst               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock
         o_clk                => o_clk                , -- out    std_logic                                 ; --! System Clock
         o_clk_sqm_adc_dac    => o_clk_sqm_adc_dac    , -- out    std_logic                                 ; --! SQUID MUX ADC/DAC internal Clock
         o_clk_sqm_adc        => clk_sqm_adc          , -- out    std_logic                                 ; --! Clock for SQUID MUX ADC Image Clock
         o_clk_sqm_dac_out    => clk_sqm_dac_out      , -- out    std_logic                                 ; --! Clock for SQUID MUX DAC output Image Clock
         o_clk_90             => o_clk_90             , -- out    std_logic                                 ; --! System Clock 90 degrees shift
         o_clk_sqm_adc_dac_90 => o_clk_sqm_adc_dac_90   -- out    std_logic                                   --! SQUID MUX ADC/DAC internal 90 degrees shift
   );

   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      -- ------------------------------------------------------------------------------------------------------
      --!  Command switch SQUID MUX ADC Image Clock
      --    @Req : DRE-DMX-FW-REQ-0100
      --    @Req : DRE-DMX-FW-REQ-0115
      -- ------------------------------------------------------------------------------------------------------
      I_cmd_ck_adc: entity work.cmd_im_ck generic map (
         g_CK_CMD_DEF         => c_CMD_CK_SQM_ADC_DEF   -- std_logic                                          --! Clock switch command default value at reset
      ) port map (
         i_rst                => o_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => o_clk                , -- in     std_logic                                 ; --! System Clock
         i_cmd_ck_ena         => i_cmd_ck_adc_ena(k)  , -- in     std_logic                                 ; --! Clock switch command enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_dis         => i_cmd_ck_adc_dis(k)  , -- in     std_logic                                 ; --! Clock switch command disable ('0' = Inactive, '1' = Active)
         o_cmd_ck             => cmd_ck_adc(k)        , -- out    std_logic                                 ; --! Clock switch command
         o_cmd_ck_sleep       => o_sqm_adc_pwdn(k)      -- out    std_logic                                   --! Clock switch command sleep ('0' = Inactive, '1' = Active)
      );

      -- ------------------------------------------------------------------------------------------------------
      --!  SQUID MUX ADC Image Clock generation
      --    @Req : DRE-DMX-FW-REQ-0100
      --    @Req : DRE-DMX-FW-REQ-0110
      --    @Req : DRE-DMX-FW-REQ-0120
      -- ------------------------------------------------------------------------------------------------------
      I_sqm_adc: entity work.im_ck generic map (
         g_FF_RSYNC_NB        => c_FF_RSYNC_NB + 1    , -- integer                                          ; --! Flip-Flop number used for resynchronization
         g_FF_CK_REF_NB       => c_FF_RSYNC_NB + 1      -- integer                                            --! Flip-Flop number used for delaying image clock reference
      ) port map (
         i_reset              => '0'                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => clk_sqm_adc          , -- in     std_logic                                 ; --! Clock
         i_cmd_ck             => cmd_ck_adc(k)        , -- in     std_logic                                 ; --! Clock switch command ('0' = Inactive, '1' = Active)
         o_im_ck              => o_ck_sqm_adc(k)        -- out    std_logic                                   --! Image clock, frequency divided by 2
      );

      -- ------------------------------------------------------------------------------------------------------
      --!  Command switch SQUID MUX DAC Image Clock
      --    @Req : DRE-DMX-FW-REQ-0240
      --    @Req : DRE-DMX-FW-REQ-0260
      -- ------------------------------------------------------------------------------------------------------
      I_cmd_ck_sqm_dac: entity work.cmd_im_ck generic map (
         g_CK_CMD_DEF         => c_CMD_CK_SQM_DAC_DEF   -- std_logic                                          --! Clock switch command default value at reset
      ) port map (
         i_rst                => o_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => o_clk                , -- in     std_logic                                 ; --! System Clock
         i_cmd_ck_ena         => i_cmd_ck_sqm_dac_ena(k),--in     std_logic                                 ; --! Clock switch command enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_dis         => i_cmd_ck_sqm_dac_dis(k),--in     std_logic                                 ; --! Clock switch command disable ('0' = Inactive, '1' = Active)
         o_cmd_ck             => cmd_ck_sqm_dac(k)    , -- out    std_logic                                 ; --! Clock switch command
         o_cmd_ck_sleep       => o_sqm_dac_sleep(k)     -- out    std_logic                                   --! Clock switch command sleep ('0' = Inactive, '1' = Active)
      );

      -- ------------------------------------------------------------------------------------------------------
      --!  SQUID MUX DAC Image Clock generation
      --    @Req : DRE-DMX-FW-REQ-0240
      --    @Req : DRE-DMX-FW-REQ-0250
      --    @Req : DRE-DMX-FW-REQ-0270
      -- ------------------------------------------------------------------------------------------------------
      I_sqm_dac_out: entity work.im_ck generic map (
         g_FF_RSYNC_NB        => c_FF_RSYNC_NB        , -- integer                                          ; --! Flip-Flop number used for resynchronization
         g_FF_CK_REF_NB       => c_FF_RSYNC_NB + 1      -- integer                                            --! Flip-Flop number used for delaying image clock reference
      ) port map (
         i_reset              => '0'                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clock              => clk_sqm_dac_out      , -- in     std_logic                                 ; --! Clock
         i_cmd_ck             => cmd_ck_sqm_dac(k)    , -- in     std_logic                                 ; --! Clock switch command ('0' = Inactive, '1' = Active)
         o_im_ck              => o_ck_sqm_dac(k)        -- out    std_logic                                   --! Image clock, frequency divided by 2
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!  Science Data Image Clock generation
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   P_rst_sqm_adc_dac_pd: process (o_rst_sqm_adc_dac_pd, o_clk_sqm_adc_dac)
   begin

      if o_rst_sqm_adc_dac_pd = c_RST_LEV_ACT then
         rst_sqm_adc_dac_pad <= c_RST_LEV_ACT;

      elsif rising_edge(o_clk_sqm_adc_dac) then
         rst_sqm_adc_dac_pad <= not(c_RST_LEV_ACT);

      end if;

   end process P_rst_sqm_adc_dac_pd;

   --! Science Data Image Clock
   P_ck_science : process (rst_sqm_adc_dac_pad, o_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_pad = c_RST_LEV_ACT then
         ck_science    <= '0';
         o_ck_science  <= '0';

      elsif rising_edge(o_clk_sqm_adc_dac) then
         ck_science    <= not(ck_science);
         o_ck_science  <= ck_science;

      end if;

   end process P_ck_science;

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on system clock generation
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   P_cnt_rst : process (i_arst, o_clk)
   begin

      if i_arst = c_RST_LEV_ACT then
         cnt_rst           <= std_logic_vector(to_unsigned(c_CNT_RST_MX_VAL, cnt_rst'length));
         cnt_rst_msb_r_n   <= '1';

      elsif rising_edge(o_clk) then
         if cnt_rst(cnt_rst'high) = '0' then
            cnt_rst  <= std_logic_vector(signed(cnt_rst) - 1);

         end if;

         cnt_rst_msb_r_n  <= not(cnt_rst(cnt_rst'high));

      end if;

   end process P_cnt_rst;

   I_rst: entity work.lowskew port map (
         i_sig                => cnt_rst_msb_r_n      , -- in     std_logic                                 ; --! Signal
         o_sig_lowskew        => o_rst                  -- out    std_logic                                   --! Signal connected to lowskew network
   );

   --! Counter for reset SQUID ADC/DAC generation
   P_cnt_rst_adc : process (i_arst, o_clk_sqm_adc_dac)
   begin

      if i_arst = c_RST_LEV_ACT then
         cnt_rst_adc          <= std_logic_vector(to_unsigned(c_CNT_RST_ADC_MX_VAL, cnt_rst_adc'length));
         cnt_rst_adc_msb_r_n  <= '1';

      elsif rising_edge(o_clk_sqm_adc_dac) then
         if cnt_rst_adc(cnt_rst_adc'high) = '0' then
            cnt_rst_adc       <= std_logic_vector(signed(cnt_rst_adc) - 1);

         end if;

         cnt_rst_adc_msb_r_n  <= not(cnt_rst_adc(cnt_rst_adc'high));

      end if;

   end process P_cnt_rst_adc;

   I_rst_sqm_adc_dac: entity work.lowskew port map (
         i_sig                => cnt_rst_adc_msb_r_n  , -- in     std_logic                                 ; --! Signal
         o_sig_lowskew        => o_rst_sqm_adc_dac      -- out    std_logic                                   --! Signal connected to lowskew network
   );

   I_rst_sqm_adc_dac_pd: entity work.lowskew port map (
         i_sig                => not(cnt_rst_adc(cnt_rst_adc'high)), -- in     std_logic                    ; --! Signal
         o_sig_lowskew        => o_rst_sqm_adc_dac_pd   -- out    std_logic                                   --! Signal connected to lowskew network
   );

end architecture RTL;
