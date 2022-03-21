
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

 --------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: ana_int_ctrl.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Analog interface controller
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/radioctrl/vhdl/rtl/ana_int_ctrl.vhd,v  
--  Log: ana_int_ctrl.vhd,v  
-- Revision 1.4  2003/11/27 10:25:30  Dr.B
-- no accend when rf_mode = 0.
--
-- Revision 1.3  2003/11/21 17:59:24  Dr.B
-- nothing should happen when hiss selected.
--
-- Revision 1.2  2003/09/23 13:11:03  Dr.C
-- Changed interface with req handler
--
-- Revision 1.1  2003/07/15 08:40:51  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ana_int_ctrl is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n : in std_logic;
    clk     : in std_logic;
    clk_n   : in std_logic;
    
    --------------------------------------
    -- Registers
    --------------------------------------
    rfmode     : in  std_logic;
    edgemode   : in  std_logic;         -- Single or dual edge mode
    
    --------------------------------------
    -- Request handler
    --------------------------------------
    startacc     : in  std_logic;       -- Start access on 3w bus
    rf_addr      : in  std_logic_vector(5 downto 0);  -- Reg. address
    rf_wrdata    : in  std_logic_vector(15 downto 0);  -- Write data
    writeacc     : in  std_logic;       -- Access type
    read_timeout : in  std_logic;       -- Time out on read access
    accend       : out std_logic;       -- Access finished
    ana_rddata   : out std_logic_vector(15 downto 0);  -- Read data

    --------------------------------------
    -- 3w interface
    --------------------------------------
    rf_3wdatain  : in std_logic;
    rf_3wenablein: in std_logic;
    
    rf_3wclk       : out std_logic;
    rf_3wdataout   : out std_logic;
    rf_3wdataen    : out std_logic;
    rf_3wenableout : out std_logic;
    rf_3wenableen  : out std_logic;

    --------------------------------------
    -- Diag port
    --------------------------------------
    diag_port : out std_logic_vector(1 downto 0)

    );

end ana_int_ctrl;
