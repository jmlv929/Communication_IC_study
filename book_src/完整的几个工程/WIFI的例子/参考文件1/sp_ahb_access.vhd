
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processor
--    ,' GoodLuck ,'      RCSfile: sp_ahb_access.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.17   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Read/Write Access to AHB.
--
-- It manages the request of writing/reading of the different blocks on the ahb
-- bus. It is able to manage a read and write access at the same time, by
-- giving the priority to the read access.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/sp_ahb_access/vhdl/rtl/sp_ahb_access.vhd,v  
--  Log: sp_ahb_access.vhd,v  
-- Revision 1.17  2005/05/31 15:46:29  Dr.A
-- #BugId:938#
-- New diags
--
-- Revision 1.16  2005/04/27 14:12:45  Dr.A
-- #BugId:1231#
-- Assert write_done when AHB data phase is over (end of wr_last_state).
--
-- Revision 1.15  2005/04/27 12:02:50  Dr.A
-- #BugId:1184#
-- Break burst when crossing 1kB boundary.
-- Maintain htrans till next inc_addr is high
--
-- Revision 1.14  2005/04/26 07:57:48  Dr.A
-- #BugId:1184#
-- Burst broken when hsize changes by setting htrans to NON_SEQ
--
-- Revision 1.13  2003/12/04 09:36:36  Dr.A
-- Removed mux on read data. read_done delayed according to this change.
--
-- Revision 1.12  2003/11/12 15:23:20  Dr.A
-- Put back read_addr LSB registers (required for synthesis).
--
-- Revision 1.11  2003/10/09 16:39:03  Dr.A
-- Cleaned.
--
-- Revision 1.10  2003/10/02 12:54:29  Dr.A
-- FSM returns to idle on interrupt debugged.
-- write_done asserted too early in case of AHB wait states debugged.
-- start_mem signals are now used to memorize start during last write phase only.
-- Removed unused mux on read_data, and register on rd_addr LSB.
--
-- Revision 1.9  2003/08/28 15:21:18  Dr.A
-- Cleaned code. Changed state machine to accept write data two clock cycles after strt_write is set (time to request the bus).
--
-- Revision 1.8  2003/07/03 14:16:15  Dr.A
-- data_read words are now registered and padded with '0' following read_size inside the AHB block.
--
-- Revision 1.7  2003/03/17 09:12:11  Dr.B
-- bug on multimaster mode corrected (gen of busreq).
--
-- Revision 1.6  2002/11/27 17:34:21  Dr.B
-- busreq debugged.
--
-- Revision 1.5  2002/11/20 10:59:39  Dr.B
-- add addrmax_g generic.
--
-- Revision 1.4  2002/11/13 17:34:32  Dr.B
-- complete if/else and some simplifications.
--
-- Revision 1.3  2002/11/07 16:51:13  Dr.B
-- wr_access removed.
--
-- Revision 1.2  2002/10/31 16:07:51  Dr.B
-- redesign + debug.
--
-- Revision 1.1  2002/10/25 14:14:10  Dr.B
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

--library ahb_config_pkg;
library work;
--use ahb_config_pkg.ahb_config_pkg.all;
use work.ahb_config_pkg.all;

--library master_interface_rtl;
library work;

--library sp_ahb_access_rtl;
library work;
--use sp_ahb_access_rtl.sp_ahb_access_pkg.all;
use work.sp_ahb_access_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity sp_ahb_access is
  generic (
    addrmax_g  : integer := 32          -- AHB Address bus width. Minimum = 5.
  );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in  std_logic;     
    reset_n      : in  std_logic;      

    --------------------------------------
    -- Interrupts
    --------------------------------------
    sp_init      : in  std_logic;       -- Interrupt occurs -> reinit
    --
    ahb_interrupt : out std_logic;      -- Interrupt line.    

    --------------------------------------
    -- Read Accesses
    --------------------------------------
    start_read   : in  std_logic;       -- Pulse to start read access.
    read_size    : in  std_logic_vector( 3 downto 0); -- Read size in bytes.
    read_addr    : in  std_logic_vector(addrmax_g-1 downto 0); -- Read address.
    --
    read_done    : out std_logic;       -- Flag indicating read done.
    -- Read data words.
    read_word0   : out std_logic_vector(31 downto 0);
    read_word1   : out std_logic_vector(31 downto 0);
    read_word2   : out std_logic_vector(31 downto 0);
    read_word3   : out std_logic_vector(31 downto 0);

    --------------------------------------
    -- Write Accesses
    --------------------------------------
    start_write  : in  std_logic;       -- Pulse to start write access.
    write_size   : in  std_logic_vector( 3 downto 0); -- Write size in bytes.
    write_addr   : in  std_logic_vector(addrmax_g-1 downto 0); -- Write address.
    -- Data to write.
    write_word0  : in  std_logic_vector(31 downto 0);
    write_word1  : in  std_logic_vector(31 downto 0);
    write_word2  : in  std_logic_vector(31 downto 0);
    write_word3  : in  std_logic_vector(31 downto 0);
    --
    write_done   : out std_logic;       -- Flag indicating data written.

    --------------------------------------
    -- AHB Master interface
    --------------------------------------
    hgrant        : in  std_logic;                      -- Bus grant.
    hready        : in  std_logic;                      -- AHB Slave ready.
    hresp         : in  std_logic_vector( 1 downto 0);  -- AHB Transfer response.
    hrdata        : in  std_logic_vector(31 downto 0);  -- AHB Read data bus.
    --
    hwdata        : out std_logic_vector(31 downto 0);  -- AHB Write data bus.
    hbusreq       : out std_logic;                      -- Bus request.
    htrans        : out std_logic_vector( 1 downto 0);  -- AHB Transfer type.
    hwrite        : out std_logic;                      -- Write request
    haddr         : out std_logic_vector(addrmax_g-1 downto 0); -- AHB Address.
    hburst        : out std_logic_vector( 2 downto 0);  -- Burst transfer.
    hsize         : out std_logic_vector( 2 downto 0);  -- Transfer size.

    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    diag          : out std_logic_vector(7 downto 0)
  );

end sp_ahb_access;
