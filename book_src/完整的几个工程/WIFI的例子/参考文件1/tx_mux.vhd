
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: tx_mux.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.13   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Transmission mux. This block sends out preamble or tx data.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/tx_mux/vhdl/rtl/tx_mux.vhd,v  
--  Log: tx_mux.vhd,v  
-- Revision 1.13  2004/12/14 11:00:20  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.12  2004/01/14 09:58:25  Dr.C
-- Added test on marker_i for toggle generation.
--
-- Revision 1.11  2003/11/18 15:09:08  Dr.C
-- Added resynchronisation for res_intfil_o.
--
-- Revision 1.10  2003/11/14 15:40:38  Dr.C
-- Changed dac_on2off_i to tx_enddel_i.
--
-- Revision 1.9  2003/10/20 13:26:10  Dr.C
-- Keep res_intfil_o during 2 clock cycles.
--
-- Revision 1.8  2003/10/20 13:22:00  Dr.C
-- Changed res_intfil_o output.
--
-- Revision 1.7  2003/10/10 12:16:16  Dr.B
-- Corrected filter_sampleready generation for the 1st data in tx_mux_preamble state.
--
-- Revision 1.6  2003/05/26 15:37:57  Dr.A
-- Shifted tx_sample_ready.
--
-- Revision 1.5  2003/03/31 15:14:51  Dr.A
-- Updates for tx_rx_filter. Reset inverted.
--
-- Revision 1.4  2003/03/28 13:43:16  Dr.A
-- Changed inconsistent port name.
--
-- Revision 1.3  2003/03/27 17:22:57  Dr.A
-- Reset filter_sampleready.
--
-- Revision 1.2  2003/03/27 17:10:14  Dr.A
-- Changed interface to tx_filter: data_ready_i generated internally.
--
-- Revision 1.1  2003/03/13 15:09:49  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity tx_mux is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in  std_logic; -- Module clock
    reset_n             : in  std_logic; -- Asynchronous reset
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i            : in  std_logic; -- TX path enable.
    start_burst_i       : in  std_logic; -- Start of burst.
    end_preamble_i      : in  std_logic; -- End of preamble.
    marker_i            : in  std_logic; -- End of burst.
    tx_enddel_i         : in  std_logic_vector(7 downto 0); -- End of tx delay.
    --
    tx_start_end_conf_o : out std_logic;
    res_intfil_o        : out std_logic; -- Reset tx filter.
    data_valid_o        : out std_logic; -- Output data is valid.
    pream_ready_o       : out std_logic; -- tx_mux ready for preamble data.
    data_ready_o        : out std_logic; -- tx_mux ready for tx data.
    filter_sampleready_o: out std_logic; -- sample signal for tx filter.
    --------------------------------------
    -- Data
    --------------------------------------
    preamble_in_i       : in  std_logic_vector(9 downto 0); -- I preamble data.
    preamble_in_q       : in  std_logic_vector(9 downto 0); -- Q preamble data.
    data_in_i           : in  std_logic_vector(9 downto 0); -- I TX data.
    data_in_q           : in  std_logic_vector(9 downto 0); -- Q TX data.
    --
    out_i               : out std_logic_vector(9 downto 0); -- I data out.
    out_q               : out std_logic_vector(9 downto 0)  -- Q data out.

  );

end tx_mux;
