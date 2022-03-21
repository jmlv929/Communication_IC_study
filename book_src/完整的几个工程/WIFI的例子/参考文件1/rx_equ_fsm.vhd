

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_equ_fsm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.3  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Equalizer state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_equ/vhdl/rtl/rx_equ_fsm.vhd,v  
--  Log: rx_equ_fsm.vhd,v  
-- Revision 1.3  2003/03/28 15:53:15  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.2  2003/03/17 17:06:25  Dr.F
-- removed debug signals.
--
-- Revision 1.1  2003/03/17 10:01:21  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library rx_equ_rtl;
library work;
--use rx_equ_rtl.rx_equ_pkg.all;
use work.rx_equ_pkg.all;


--------------------------------------------
-- Entity
--------------------------------------------
entity rx_equ_fsm is
  port (
    clk                 : in    std_logic; --Clock input
    reset_n             : in    std_logic; --Asynchronous negative reset
    sync_reset_n        : in    std_logic; --'0': The control state of the module will be reset
    i_i                 : in    std_logic_vector(FFT_WIDTH_CT-1 downto 0); 
    q_i                 : in    std_logic_vector(FFT_WIDTH_CT-1 downto 0); 
    data_valid_i        : in    std_logic; 
    data_ready_o        : out   std_logic; 
    ich_i               : in    std_logic_vector(CHMEM_WIDTH_CT-1 downto 0); 
    qch_i               : in    std_logic_vector(CHMEM_WIDTH_CT-1 downto 0); 
    data_valid_ch_i     : in    std_logic; 
    data_ready_ch_o     : out   std_logic; 
    burst_rate_i        : in    std_logic_vector(BURST_RATE_WIDTH_CT - 1 downto 0); 
    signal_field_valid_i: in    std_logic; 
    data_ready_i        : in    std_logic; 
    start_of_burst_i    : in    std_logic; 
    start_of_symbol_i   : in    std_logic; 
    start_of_burst_o    : out   std_logic;
    start_of_symbol_o   : out   std_logic; 

    i_saved_o           : out   std_logic_vector(FFT_WIDTH_CT-1 downto 0); 
    q_saved_o           : out   std_logic_vector(FFT_WIDTH_CT-1 downto 0); 
    ich_saved_o         : out   std_logic_vector(CHMEM_WIDTH_CT-1 downto 0); 
    qch_saved_o         : out   std_logic_vector(CHMEM_WIDTH_CT-1 downto 0); 
    module_enable_o     : out   std_logic;

    burst_rate_o        : out   std_logic_vector(BURST_RATE_WIDTH_CT - 1 downto 0);
    burst_rate_4_hist_o : out   std_logic_vector(BURST_RATE_WIDTH_CT - 1 downto 0);
    pipeline_en_o       : out   std_logic;
    cumhist_en_o        : out   std_logic;
    ctr_input_o         : out   std_logic_vector(1 downto 0);

    current_symb_o      : out   std_logic_vector(1 downto 0);

    data_valid_last_stage_i      : in    std_logic; 
    start_of_symbol_last_stage_i : in    std_logic
  );

end rx_equ_fsm;
