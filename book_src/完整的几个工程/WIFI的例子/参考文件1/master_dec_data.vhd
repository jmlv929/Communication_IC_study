
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: master_dec_data.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Master Decode Data : From deserializer, decode data (for A or
-- for B modem), and get possible extra information (like clk_skip)
--
--   for B |in |fo |rm |b7 |b6 |b5 |b4 |b3 |b2 |b1 |b0 | X |   I/Q
--
--   for A |in |aA |a9 |a8 |a7 |a6 |a5 |a4 |a3 |a2 |a1 |a0 |   I/Q
--
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/master_dec_data.vhd,v  
--  Log: master_dec_data.vhd,v  
-- Revision 1.8  2005/10/04 12:21:03  Dr.A
-- #BugId:1397#
-- Added txv_immstop_i to tx_sm sensitivity list
--
-- Revision 1.7  2005/03/08 09:51:53  sbizet
-- #BugId:1117#
-- Set rx samples to 0 when no Rx
--
-- Revision 1.6  2003/11/20 11:16:47  Dr.B
-- add protection on CS.
--
-- Revision 1.5  2003/10/30 14:35:38  Dr.B
-- clk2_skip => clk_2skip_tog.
--
-- Revision 1.4  2003/10/09 08:21:42  Dr.B
-- add carrier sense info.
--
-- Revision 1.3  2003/09/25 12:19:22  Dr.B
-- clk2skip instead of 2 * clk_skip.
--
-- Revision 1.2  2003/09/23 13:00:52  Dr.B
-- mux a and b.
--
-- Revision 1.1  2003/09/22 09:30:38  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity master_dec_data is
  generic (
    rx_a_size_g : integer := 10         -- size of data input of tx_filter A
    );  
  port (
    sampling_clk    : in  std_logic;
    reset_n         : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    -- Data from deserializer
    rx_i_i          : in  std_logic_vector(11 downto 0);
    rx_q_i          : in  std_logic_vector(11 downto 0);
    rx_val_tog_i    : in  std_logic;    -- high = data is valid
    --
    recep_enable_i  : in  std_logic;    -- when low reinit 
    rx_abmode_i     : in  std_logic;
    -- Data for Tx Filter A and B
    rx_i_o          : out std_logic_vector(rx_a_size_g-1 downto 0);  -- B data are on LSB
    rx_q_o          : out std_logic_vector(rx_a_size_g-1 downto 0);  -- B data are on LSB
    rx_val_tog_o    : out std_logic;    -- high = data is valid
    --
    clk_2skip_tog_o : out std_logic;    -- inform that 2 clk_skip are neededwhen toggle
    cs_error_o      : out std_logic;  -- when toggle : error on CS
    cs_o            : out std_logic_vector(1 downto 0);  -- CS info for AGC/CCA
    cs_valid_o      : out std_logic     -- high when the CS is valid
    );

end master_dec_data;
