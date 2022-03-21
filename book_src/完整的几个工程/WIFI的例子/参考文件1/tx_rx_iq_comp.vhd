
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Wild
--    ,' GoodLuck ,'      RCSfile: tx_rx_iq_comp.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Instantiate IQ Compensation for RX and TX path
-- tx_rxn_select select inputs from Tx path when high,
--                     inputs from Rx path when low.        
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/iq_compensation/vhdl/rtl/tx_rx_iq_comp.vhd,v  
--  Log: tx_rx_iq_comp.vhd,v  
-- Revision 1.1  2003/08/29 16:06:28  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.STD_LOGIC_UNSIGNED.all;
 
--library iq_compensation_rtl;
library work;
--use iq_compensation_rtl.iq_compensation_pkg.all;
use work.iq_compensation_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity tx_rx_iq_comp is
  generic ( 
    iq_i_width_g   : integer := 9; -- IQ inputs width.
    iq_o_width_g   : integer := 9; -- IQ outputs width.
    phase_width_g  : integer := 6; -- Phase parameter width.
    ampl_width_g   : integer := 9; -- Amplitude parameter width.
    toggle_in_g    : integer := 0; -- when 1 the data_valid_i toggles
    toggle_out_g   : integer := 0  -- when 1 the data_valid_o toggles
  );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk             : in  std_logic;    -- Module clock. 60 MHz
    reset_n         : in  std_logic;    -- Asynchronous reset.
    sync_reset_n    : in  std_logic;    -- Block enable.
    --------------------------------------
    -- Controls
    --------------------------------------
    tx_rxn_select   : in  std_logic;    -- '1' tx selected, '0' rx selected
    --------------------------------------
    -- Rx Controls
    --------------------------------------
    -- Phase compensation control.
    rx_phase_i      : in  std_logic_vector(phase_width_g-1 downto 0);
    -- Amplitude compensation control.
    rx_ampl_i       : in  std_logic_vector(ampl_width_g-1 downto 0);
    rx_data_valid_i : in  std_logic;    -- high when a new data is available
    --
    rx_data_valid_o : out std_logic;  -- high/toggle when a new data is available
    --------------------------------------
    -- Rx Data
    --------------------------------------
    rx_i_in         : in  std_logic_vector(iq_i_width_g-1 downto 0);
    rx_q_in         : in  std_logic_vector(iq_i_width_g-1 downto 0);
    --
    rx_i_out        : out std_logic_vector(iq_o_width_g-1 downto 0);
    rx_q_out        : out std_logic_vector(iq_o_width_g-1 downto 0);
    --------------------------------------
    -- Tx Controls
    --------------------------------------
    -- Phase compensation control.
    tx_phase_i      : in  std_logic_vector(phase_width_g-1 downto 0);
    -- Amplitude compensation control.
    tx_ampl_i       : in  std_logic_vector(ampl_width_g-1 downto 0);
    --------------------------------------
    -- Tx Data
    --------------------------------------
    tx_i_in         : in  std_logic_vector(iq_i_width_g-4 downto 0);
    tx_q_in         : in  std_logic_vector(iq_i_width_g-4 downto 0);
    --
    tx_i_out        : out std_logic_vector(iq_o_width_g-4 downto 0);
    tx_q_out        : out std_logic_vector(iq_o_width_g-4 downto 0)

    
  );

end tx_rx_iq_comp;
