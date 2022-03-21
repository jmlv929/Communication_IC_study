
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : AHB master interface
--    ,' GoodLuck ,'      RCSfile: master_interface.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.13   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Interface for an AHB bus master
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/PROC_SYSTEM/master_interface/vhdl/rtl/master_interface.vhd,v  
--  Log: master_interface.vhd,v  
-- Revision 1.13  2004/02/17 17:41:58  wdoyle
-- Fixed address state to hold htrans and haddr active when 2nd req on bus and hready is low.
--
-- Revision 1.12  2004/01/21 10:46:29  Dr.A
-- Added condition to release hbusreq (to avoid bus locked by BuP, this condition was already verified in the Stream Processor where all bursts are incremental).
--
-- Revision 1.11  2003/09/30 13:30:08  Dr.A
-- Release hbusreq after error state.
--
-- Revision 1.10  2002/11/27 17:27:45  Dr.B
-- set hbusreq to 0 when degranted and no busreq.
--
-- Revision 1.9  2002/11/15 13:44:40  Dr.B
-- set at least 1 time hbusreq even if already granted.
--
-- Revision 1.8  2002/04/03 08:42:30  Dr.C
-- Corrected condition to degranted state
--
-- Revision 1.7  2002/03/06 10:02:46  Dr.C
-- Changed to a generic one useful for all blocks
-- Added generic gotoaddr_g
--
-- Revision 1.6  2002/01/30 07:41:38  Dr.C
-- Debugged transition from address to last data
--
-- Revision 1.5  2001/12/03 14:01:23  Dr.C
-- Added busy state and debugged signals
--
-- Revision 1.4  2001/11/06 13:56:20  Dr.C
-- new library ahb_config_pkg
--
-- Revision 1.3  2001/07/27 12:25:49  Dr.B
-- degranted state after last_address state suppressed (error correction)
--
-- Revision 1.2  2001/07/24 09:09:58  Dr.B
-- pipeline mode added.
--
-- Revision 1.1  2001/07/19 12:49:41  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;


--library ahb_config_pkg;
library work;
--use ahb_config_pkg.ahb_config_pkg.all;
use work.ahb_config_pkg.all;





--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity master_interface is
  generic 
      (
      gotoaddr_g         : integer := 0;
      burstlinkcapable_g : integer := 1
      ) ;

  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hclk            : in  std_logic;
    hreset_n        : in  std_logic;
    
    --------------------------------------
    -- Signal to/from logic part of master
    --------------------------------------
    --write           : in  std_logic;
    burst           : in  std_logic_vector(2 downto 0);
    busreq          : in  std_logic;
    unspeclength    : in  std_logic;
    busy            : in  std_logic;
    buserror        : out std_logic;     
    inc_addr        : out std_logic;    
    valid_data      : out std_logic;
    decr_addr       : out std_logic;    
    grant_lost      : out std_logic;
    end_add         : out std_logic;
    end_data        : out std_logic;
    free            : out std_logic;
   
    --------------------------------------
    -- AHB control signals
    --------------------------------------
    hready          : in  std_logic;
    hresp           : in  std_logic_vector(1 downto 0);
    hgrant          : in  std_logic;
    htrans          : out std_logic_vector(1 downto 0);
    hbusreq         : out std_logic

  );

end master_interface;
