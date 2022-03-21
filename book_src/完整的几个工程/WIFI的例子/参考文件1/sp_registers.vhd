
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processor
--    ,' GoodLuck ,'      RCSfile: sp_registers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.21   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is part of the Stream Processor.
-- It contains the registers that indicate the Key and address of the data
-- to be encrypted. These registers are read and/or written via the APB.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/stream_processor/vhdl/rtl/sp_registers.vhd,v  
--  Log: sp_registers.vhd,v  
-- Revision 1.21  2005/06/01 08:58:09  Dr.A
-- #BugId:938#
-- New upgrade number
--
-- Revision 1.20  2005/02/02 16:36:56  Dr.A
-- #BugId:1004#
-- Errors stop the Stream processor operation, but do not forbid start of new operation.
--
-- Revision 1.19  2004/05/04 16:16:25  Dr.A
-- Updated version register to 2.0.0
--
-- Revision 1.18  2004/05/04 09:42:49  Dr.A
-- Key address moved in control strucure.
--
-- Revision 1.17  2004/04/08 10:02:53  Dr.A
-- Added register on prdata.
--
-- Revision 1.16  2003/11/26 08:42:07  Dr.A
-- Removed diagcntl. Added D4/D6 select bit.
--
-- Revision 1.15  2003/10/09 16:44:37  Dr.A
-- Changed 'done' bits generation, STRPSTAT now reflects interrupt status.
--
-- Revision 1.14  2003/10/07 13:13:37  Dr.A
-- Debug of interrupt acknowledge.
--
-- Revision 1.13  2003/09/29 15:59:42  Dr.A
-- Added crc_debug.
--
-- Revision 1.12  2003/08/06 13:46:08  Dr.A
-- Removed unused signals and added last_cs.
--
-- Revision 1.11  2003/07/18 12:48:51  Dr.A
-- Corrected startop0 and startop1.
--
-- Revision 1.10  2003/07/16 13:42:20  Dr.A
-- Updated for version 0.09.
--
-- Revision 1.9  2003/07/03 14:39:57  Dr.A
-- Removed unused registers.
--
-- Revision 1.8  2003/01/10 15:53:06  Dr.B
-- update version register.
--
-- Revision 1.7  2003/01/09 13:15:33  elama
-- Reset on RC4.
--
-- Revision 1.6  2002/11/20 11:01:49  Dr.B
-- add version register.
--
-- Revision 1.5  2002/10/29 13:20:08  elama
-- Removed one of the conditions in the error processing.
--
-- Revision 1.4  2002/10/25 13:03:03  elama
-- Solved the bug created in revision 1.3.
--
-- Revision 1.3  2002/10/25 09:35:04  elama
-- Added the strpdsize and strpdoff registers.
--
-- Revision 1.2  2002/10/17 08:03:07  elama
-- Changed the size of strpmsize to 6 bits.
--
-- Revision 1.1  2002/10/15 09:20:10  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Revision 1.4  2002/10/15 11:22:00  elama
-- Added the new registers in the specifications.
--
-- Revision 1.3  2002/10/14 13:24:58  elama
-- Implemented the new spec changes.
-- Implemented the interruption line.
--
-- Revision 1.2  2002/09/16 14:15:01  elama
-- Improved the implementation of the generics.
--
-- Revision 1.1  2002/07/30 09:50:50  elama
-- Initial revision
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
entity sp_registers is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    pclk         : in  std_logic;   -- APB clock.
    presetn      : in  std_logic;   -- APB reset.Inverted logic.
    --------------------------------------
    -- APB interface
    --------------------------------------
    paddr        : in  std_logic_vector(4 downto 0);-- APB Address.
    psel         : in  std_logic;   -- Selection line.
    pwrite       : in  std_logic;   -- 0 => Read; 1 => Write.
    penable      : in  std_logic;   -- APB enable line.
    pwdata       : in  std_logic_vector(31 downto 0);-- APB Write data bus.
    --
    prdata       : out std_logic_vector(31 downto 0);-- APB Read data bus.
    --------------------------------------
    -- Interrupts
    --------------------------------------
    process_done : in  std_logic;   -- Pulse indicating encryption finished.
    dataflowerr  : in  std_logic;   -- Pulse indicating data flow error.
    crcerr       : in  std_logic;   -- Pulse indicating CRC error.
    micerr       : in  std_logic;   -- Pulse indicating MIC error.
    --
    interrupt    : out std_logic;   -- Stream Processor interrupt.
    --------------------------------------
    -- Registers
    --------------------------------------
    startop      : out std_logic;   -- Pulse that starts the en/decryption.
    stopop       : out std_logic;   -- Pulse that stops the en/decryption.
    crc_debug    : out std_logic;   -- Enable CRC written to control structure.
    strpcsaddr   : out std_logic_vector(31 downto 0); -- Control struct address.
    strpkaddr    : out std_logic_vector(31 downto 0); -- Key address.
    -- Hardware compliancy with IEEE 802.11i drafts, D4.0 against D6.0 and after
    comply_d6_d4n :out std_logic;   -- Low for MIC IV compliancy with D4.0.
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    reg_diag     : out std_logic_vector(7 downto 0)

  );
end sp_registers;
