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
--!   @file                   rst_clk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Manage the global resets and generate the clocks
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;

entity rst_clk_mgt is port
   (     i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         i_cmd_ck_s1_adc_ena  : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_s1_adc_dis  : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         i_cmd_ck_s1_dac_ena  : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_s1_dac_dis  : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         o_ck_rdy             : out    std_logic                                                            ; --! Clocks ready ('0' = Not ready, '1' = Ready)
         o_rst                : out    std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)

         o_clk                : out    std_logic                                                            ; --! System Clock
         o_clk_sq1_adc_dac    : out    std_logic                                                            ; --! SQUID1 ADC/DAC internal Clock

         o_ck_sq1_adc         : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC Image Clocks
         o_ck_sq1_dac         : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 DAC Image Clocks
         o_ck_science         : out    std_logic                                                            ; --! Science Data Image Clock

         o_clk_90             : out    std_logic                                                            ; --! System Clock 90° shift
         o_clk_sq1_adc_dac_90 : out    std_logic                                                            ; --! SQUID1 ADC/DAC internal 90° shift

         o_sq1_adc_pwdn       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC – Power Down ('0' = Inactive, '1' = Active)
         o_sq1_dac_sleep      : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID1 DAC - Sleep ('0' = Inactive, '1' = Active)
   );
end entity rst_clk_mgt;

architecture RTL of rst_clk_mgt is
signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   clk                  : std_logic                                                                   ; --! System Clock (internal)
signal   clk_sq1_adc_dac      : std_logic                                                                   ; --! SQUID1 ADC/DAC internal Clock
signal   clk_sq1_adc          : std_logic                                                                   ; --! SQUID1 ADC Clocks
signal   clk_sq1_dac_out      : std_logic                                                                   ; --! SQUID1 DAC output Clock
signal   pll_main_lock        : std_logic                                                                   ; --! Main Pll Status ('0' = Pll not locked, '1' = Pll locked)

signal   cmd_ck_sq1_adc       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC Clocks switch commands ('0' = Inactive, '1' = Active)
signal   cmd_ck_sq1_dac       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC Clocks switch commands ('0' = Inactive, '1' = Active)

signal   rst_ck_science       : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   ck_science           : std_logic                                                                   ; --! Science Data Image Clock

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Clocks generation
   -- ------------------------------------------------------------------------------------------------------
   I_pll: entity work.pll port map
   (     i_arst               => i_arst               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock
         o_clk                => clk                  , -- out    std_logic                                 ; --! System Clock
         o_clk_sq1_adc_dac    => clk_sq1_adc_dac      , -- out    std_logic                                 ; --! SQUID1 ADC/DAC internal Clock
         o_clk_sq1_adc        => clk_sq1_adc          , -- out    std_logic                                 ; --! Clock for SQUID1 ADC Image Clock
         o_clk_sq1_dac_out    => clk_sq1_dac_out      , -- out    std_logic                                 ; --! Clock for SQUID1 DAC output Image Clock
         o_pll_main_lock      => pll_main_lock        , -- out    std_logic                                 ; --! Main Pll Status ('0' = Pll not locked, '1' = Pll locked)
         o_clk_90             => o_clk_90             , -- out    std_logic                                 ; --! System Clock 90° shift
         o_clk_sq1_adc_dac_90 => o_clk_sq1_adc_dac_90   -- out    std_logic                                   --! SQUID1 ADC/DAC internal 90° shift
   );

   o_clk             <= clk;
   o_clk_sq1_adc_dac <= clk_sq1_adc_dac;
   o_ck_rdy          <= pll_main_lock;

   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      -- ------------------------------------------------------------------------------------------------------
      --!  Command switch SQUID1 ADC Image Clock
      --    @Req : DRE-DMX-FW-REQ-0100
      -- ------------------------------------------------------------------------------------------------------
      I_cmd_ck_sq1_adc: entity work.cmd_im_ck generic map
      (  g_CK_CMD_DEF         => c_CMD_CK_SQ1_ADC_DEF   -- std_logic                                          --! Clock switch command default value at reset
      ) port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_cmd_ck_ena         => i_cmd_ck_s1_adc_ena(k),-- in     std_logic                                 ; --! Clock switch command enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_dis         => i_cmd_ck_s1_adc_dis(k),-- in     std_logic                                 ; --! Clock switch command disable ('0' = Inactive, '1' = Active)
         o_cmd_ck             => cmd_ck_sq1_adc(k)    , -- out    std_logic                                 ; --! Clock switch command
         o_cmd_ck_sleep       => o_sq1_adc_pwdn(k)      -- out    std_logic                                   --! Clock switch command sleep ('0' = Inactive, '1' = Active)
      );

      -- ------------------------------------------------------------------------------------------------------
      --!  SQUID1 ADC Image Clock generation
      --    @Req : DRE-DMX-FW-REQ-0100
      --    @Req : DRE-DMX-FW-REQ-0110
      --    @Req : DRE-DMX-FW-REQ-0120
      -- ------------------------------------------------------------------------------------------------------
      I_squid1_adc: entity work.im_ck generic map
      (  g_FF_RSYNC_NB        => c_FF_RSYNC_NB+1        -- integer                                            --! Flip-Flop number used for resynchronization
      ) port map
      (  i_clock              => clk_sq1_adc          , -- in     std_logic                                 ; --! Clock
         i_cmd_ck             => cmd_ck_sq1_adc(k)    , -- in     std_logic                                 ; --! Clock switch command ('0' = Inactive, '1' = Active)
         o_im_ck              => o_ck_sq1_adc(k)        -- out    std_logic                                   --! Image clock, frequency divided by 2
      );

      -- ------------------------------------------------------------------------------------------------------
      --!  Command switch SQUID1 DAC Image Clock
      --    @Req : DRE-DMX-FW-REQ-0240
      --    @Req : DRE-DMX-FW-REQ-0260
      -- ------------------------------------------------------------------------------------------------------
      I_cmd_ck_sq1_dac: entity work.cmd_im_ck generic map
      (  g_CK_CMD_DEF         => c_CMD_CK_SQ1_DAC_DEF   -- std_logic                                          --! Clock switch command default value at reset
      ) port map
      (  i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_cmd_ck_ena         => i_cmd_ck_s1_dac_ena(k),-- in     std_logic                                 ; --! Clock switch command enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_dis         => i_cmd_ck_s1_dac_dis(k),-- in     std_logic                                 ; --! Clock switch command disable ('0' = Inactive, '1' = Active)
         o_cmd_ck             => cmd_ck_sq1_dac(k)    , -- out    std_logic                                 ; --! Clock switch command
         o_cmd_ck_sleep       => o_sq1_dac_sleep(k)     -- out    std_logic                                   --! Clock switch command sleep ('0' = Inactive, '1' = Active)
      );

      -- ------------------------------------------------------------------------------------------------------
      --!  SQUID1 DAC Image Clock generation
      --    @Req : DRE-DMX-FW-REQ-0240
      --    @Req : DRE-DMX-FW-REQ-0250
      --    @Req : DRE-DMX-FW-REQ-0270
      -- ------------------------------------------------------------------------------------------------------
      I_squid1_dac_out: entity work.im_ck generic map
      (  g_FF_RSYNC_NB        => c_FF_RSYNC_NB          -- integer                                            --! Flip-Flop number used for resynchronization
      ) port map
      (  i_clock              => clk_sq1_dac_out      , -- in     std_logic                                 ; --! Clock
         i_cmd_ck             => cmd_ck_sq1_dac(k)    , -- in     std_logic                                 ; --! Clock switch command ('0' = Inactive, '1' = Active)
         o_im_ck              => o_ck_sq1_dac(k)        -- out    std_logic                                   --! Image clock, frequency divided by 2
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!  Science Data Image Clock generation
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst_ck_science: entity work.reset_gen generic map
   (     g_FF_RESET_NB        => c_FF_RST_SQ1_ADC_NB    -- integer                                            --! Flip-Flop number used for generated reset
   ) port map
   (     i_arst               => i_arst               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clock              => clk_sq1_adc_dac      , -- in     std_logic                                 ; --! Main Pll Status ('0' = Pll not locked, '1' = Pll locked)
         i_ck_rdy             => pll_main_lock        , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              => rst_ck_science         -- out    std_logic                                   --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );

   P_ck_science : process (rst_ck_science, clk_sq1_adc_dac)
   begin

      if rst_ck_science = '1' then
         ck_science    <= '1';
         o_ck_science  <= '0';

      elsif rising_edge(clk_sq1_adc_dac) then
         ck_science    <= not(ck_science);
         o_ck_science  <= ck_science;

      end if;

   end process P_ck_science;

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset on system clock generation
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   I_rst: entity work.reset_gen generic map
   (     g_FF_RESET_NB        => c_FF_RST_NB            -- integer                                            --! Flip-Flop number used for generated reset
   ) port map
   (     i_arst               => i_arst               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clock              => clk                  , -- in     std_logic                                 ; --! Clock
         i_ck_rdy             => pll_main_lock        , -- in     std_logic                                 ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              => rst                    -- out    std_logic                                   --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );

   o_rst <= rst;

end architecture rtl;
