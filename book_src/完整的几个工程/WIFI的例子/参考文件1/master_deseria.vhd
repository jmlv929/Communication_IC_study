
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: master_deseria.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Deserialize data for rx_filter (from wild_rf)
-- or prdata from WiLD RF registers 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/master_deseria.vhd,v  
--  Log: master_deseria.vhd,v  
-- Revision 1.8  2004/07/16 07:35:48  Dr.B
-- add cca_add_info feature
--
-- Revision 1.7  2004/03/03 11:12:56  Dr.B
-- initialize alternate_mode.
--
-- Revision 1.6  2003/11/20 11:17:18  Dr.B
-- output on mem_reg.
--
-- Revision 1.5  2003/10/30 14:36:07  Dr.B
-- add deserialization of the CCA.
--
-- Revision 1.4  2003/10/09 08:22:26  Dr.B
-- simplify start condition.
--
-- Revision 1.3  2003/09/25 12:20:11  Dr.B
-- change get_conf info.
--
-- Revision 1.2  2003/09/22 09:30:53  Dr.B
-- remove cycle_count + add markers.
--
-- Revision 1.1  2003/07/21 09:54:42  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library serial_parity_rtl;
library work;

--library master_hiss_rtl;
library work;
--use master_hiss_rtl.master_hiss_pkg.all;
use work.master_hiss_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity master_deseria is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hiss_clk             : in  std_logic;
    reset_n              : in  std_logic;
    --------------------------------------
    -- Interface with BB (synchronized inside SM)
    --------------------------------------
    rf_rxi_i             : in  std_logic;  -- Received Real Part 
    rf_rxq_i             : in  std_logic;  -- Received Imaginary Part 
    --------------------------------------
    -- Interface with SM
    --------------------------------------
    start_rx_data_i      : in  std_logic;  -- high when there are rx data to deserialize
    get_reg_pulse_i      : in  std_logic;  -- get data (return from WildRF)
    cca_info_pulse_i     : in  std_logic;  -- get data (cca from WildRF)
    abmode_i             : in  std_logic;  -- 0 = A - 1 = B
    --
    get_reg_cca_conf_o   : out std_logic;  -- high (pulse) = data is ready
    --------------------------------------
    -- Interface with Rx Filters 60 MHz speed
    --------------------------------------
    -- Data for Rx Filter A or B -12 bits are output as it can contain info on unused bit.
    memo_i_reg_o         : out std_logic_vector(11 downto 0); --  CCA / RDATA or RX data
    memo_q_reg_o         : out std_logic_vector(11 downto 0); --  CCA / RDATA or RX data
    rx_val_tog_o         : out std_logic;  -- high = data is valid
    --------------------------------------
    --  Interface with Radio Controller sm 
    --------------------------------------
    hiss_enable_n_i      : in  std_logic;  -- enable block 
    -- Data (from read-access)
    parity_err_tog_o     : out std_logic;  -- toggle when parity error on reg deseria
    parity_err_cca_tog_o : out std_logic;  -- toggle when parity error on CCA deseria
    cca_tog_o            : out std_logic
  );

end master_deseria;
