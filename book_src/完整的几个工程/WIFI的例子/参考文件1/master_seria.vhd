
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Wild
--    ,' GoodLuck ,'      RCSfile: master_seria.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.9   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Serialize 60 MHz data from tx_filters
--                     and 80 MHz data from registers.
--
-- In case of modem B transmission, as the 11 MB/s is not simple to transmit from
-- a 60 MHz to a 240 MHz, data are transmitted regulary with different duration.
-- This is done with 2 counters : adjust_counter and shift_counter
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/master_seria.vhd,v  
--  Log: master_seria.vhd,v  
-- Revision 1.9  2005/04/13 09:36:02  sbizet
-- #BugId:1135#
-- Serialization was cut even if no txv_immstop
--
-- Revision 1.8  2005/04/12 13:36:25  sbizet
-- #BugId:1135#
-- Do not generated seria_valid when txv_immstop requested
--
-- Revision 1.7  2005/03/16 13:10:22  sbizet
-- #BugId:1135#
-- Added txv_immstop port to master_seria
--
-- Revision 1.6  2005/03/15 10:56:09  sbizet
-- #BugId:1135#
-- Reinitialization of seria_valid when txv_immstop asked
--
-- Revision 1.5  2004/03/03 11:14:00  Dr.B
-- initialize alternate_mode.
--
-- Revision 1.4  2003/10/09 08:25:14  Dr.B
-- change start_seria conditions.
--
-- Revision 1.3  2003/09/25 12:30:31  Dr.B
-- start_data replace one_data_in_buf.
--
-- Revision 1.2  2003/09/22 09:34:04  Dr.B
-- remove cycle_counter.
--
-- Revision 1.1  2003/07/21 09:59:24  Dr.B
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
entity master_seria is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hiss_clk            : in  std_logic;
    reset_n             : in  std_logic;
    --------------------------------------
    -- Interface with Buffer_for_deseria synchronized at 240 MHz
    --------------------------------------
    -- Data from buffer for seria (extended to 12 to fit with shift_counter)
    bufi_i              : in std_logic_vector(11 downto 0);
    bufq_i              : in std_logic_vector(11 downto 0);
    tx_abmode_i         : in std_logic;  -- 0 = A - 1 = B
    trans_enable_i      : in std_logic;
    txv_immstop_i       : in std_logic;
    --
    next_data_req_tog_o : out  std_logic;
    --------------------------------------
    -- Interface with APB_interface 80 MHz
    --------------------------------------
    wrdata_i            : in  std_logic_vector(15 downto 0);
    add_i               : in  std_logic_vector( 5 downto 0);
    --------------------------------------
    -- Interface with SM 240 MHz
    --------------------------------------
    transmit_possible_i : in  std_logic;  -- high only when marker is sent
    rd_reg_pulse_i      : in  std_logic;  -- read register
    wr_reg_pulse_i      : in  std_logic;  -- write register
    seria_valid_o       : out std_logic;  -- data from seria is available
    reg_or_i_o          : out std_logic;  -- serialized a0-a2/d0-d7  val
    reg_or_q_o          : out std_logic   -- serialized a3-a5/d8-d15 val
    
  );

end master_seria;
