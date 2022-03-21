
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processor
--    ,' GoodLuck ,'      RCSfile: stream_processor.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.27   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Stream Processor. This block encrypts a data buffer in a
-- memory position and writes the result in another memory position.
-- The encryption is done with the RC4 or AES algorithms, under the control of
-- a host system.
-- This block is master on the AHB and slave on the APB.
-- Reed Solomon data can be transfered.
-- 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/stream_processor/vhdl/rtl/stream_processor.vhd,v  
--  Log: stream_processor.vhd,v  
-- Revision 1.27  2005/05/31 15:47:46  Dr.A
-- #BugId:938#
-- New diags
--
-- Revision 1.26  2003/11/26 08:43:07  Dr.A
-- Updated diag. Added d4/d6 bit.
--
-- Revision 1.25  2003/11/12 16:33:30  Dr.A
-- Added endianness_converter.
--
-- Revision 1.24  2003/09/29 16:00:06  Dr.A
-- Added crc_debug. Removed aes_ksize.
--
-- Revision 1.23  2003/09/23 14:09:22  Dr.A
-- New ports from str_proc_control. aes ram address bus set to 4 bits.
--
-- Revision 1.22  2003/09/15 13:12:05  Dr.A
-- Changed aes diag.
--
-- Revision 1.21  2003/09/15 08:41:30  Dr.A
-- dianostic port changed.
--
-- Revision 1.20  2003/09/03 13:55:37  Dr.A
-- Changed diag_port.
--
-- Revision 1.19  2003/08/28 15:23:53  Dr.A
-- Changed bsize length.
--
-- Revision 1.18  2003/08/06 13:46:27  Dr.A
-- Connected diag port control.
--
-- Revision 1.17  2003/07/16 13:43:25  Dr.A
-- Updated for version 0.09.
--
-- Revision 1.16  2003/07/03 14:40:20  Dr.A
-- Updated for TKIP and CCMP. Use control structures.
--
-- Revision 1.15  2003/01/09 17:31:27  Dr.B
-- diag_ports added.
--
-- Revision 1.14  2003/01/07 09:38:43  Dr.B
-- rs_dec_packet finished added.
--
-- Revision 1.13  2002/12/12 18:10:13  Dr.B
-- remove extended size.
--
-- Revision 1.12  2002/11/20 13:59:43  elama
-- Added the default values in case RC4 or AES are not enabled.
--
-- Revision 1.11  2002/11/20 11:02:10  Dr.B
-- add addrmax_g generic.
--
-- Revision 1.10  2002/11/14 18:19:58  Dr.B
-- correct signals in case of no Reed Solomon implemented.
--
-- Revision 1.9  2002/11/13 17:43:13  Dr.B
-- some ports removed.
--
-- Revision 1.8  2002/11/07 16:55:01  Dr.B
-- registered read data.
--
-- Revision 1.7  2002/10/31 16:11:44  Dr.B
-- debug & read_accessses registered.
--
-- Revision 1.6  2002/10/25 14:08:02  Dr.B
-- sp_loop_access added.
--
-- Revision 1.5  2002/10/25 08:02:52  Dr.B
-- nonce signals added.
--
-- Revision 1.4  2002/10/25 07:55:28  Dr.B
-- reed solomon added
--
-- Revision 1.3  2002/10/18 09:38:11  elama
-- Removed the CRC functionality from the top (now included
-- in the RC4-CRC block).
--
-- Revision 1.2  2002/10/17 08:43:03  elama
-- Added the possibility of MAC size = 0 bits.
-- Moved the CRC calculation to the RC4-CRC block.
--
-- Revision 1.1  2002/10/16 07:44:39  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Revision 1.4  2002/10/16 09:42:00  elama
-- Taken the SRAMs out of the block.
--
-- Revision 1.3  2002/10/14 13:27:01  elama
-- Solved many bugs.
-- Added the new version of the different subblocks.
--
-- Revision 1.2  2002/09/16 14:22:27  elama
-- Included the new versions of the RC4 and AES sequencers.
--
-- Revision 1.1  2002/07/30 09:51:17  elama
-- Initial revision
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

--library endianness_converter_rtl;
library work;

--library rc4_crc_rtl; 
library work;

--library aes_ccm_rtl; 
library work;

--library sp_ahb_access_rtl;
library work;

--library stream_processor_rtl; 
library work;
--use stream_processor_rtl.stream_processor_pkg.ALL;
use work.stream_processor_pkg.ALL;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity stream_processor is
  generic (
    big_endian_g : integer := 0;        -- 1 => Big endian bus interface.
    aes_enable_g : integer := 1         -- Enables AES. 0 => RC4 only.
                                        --              1 => AES and RC4.
                                        --              2 => AES only.
  );
  port (
    -- Clocks and resets
    clk          : in  std_logic;       -- AHB and APB clock.
    reset_n      : in  std_logic;       -- AHB and APB reset. Inverted logic.
    -- AHB Master
    hgrant       : in  std_logic;       -- Bus grant.
    hready       : in  std_logic;       -- AHB Slave ready.
    hresp        : in  std_logic_vector( 1 downto 0);-- AHB Transfer response.
    hrdata       : in  std_logic_vector(31 downto 0);-- AHB Read data bus.
    hbusreq      : out std_logic;       -- Bus request.
    hlock        : out std_logic;       -- Locked transfer.
    htrans       : out std_logic_vector( 1 downto 0);-- AHB Transfer type.
    haddr        : out std_logic_vector(31 downto 0);-- AHB Address.
    hwrite       : out std_logic;       -- Transfer direction. 1=>Write;0=>Read
    hsize        : out std_logic_vector( 2 downto 0);-- AHB Transfer size.
    hburst       : out std_logic_vector( 2 downto 0);-- AHB Burst information.
    hprot        : out std_logic_vector( 3 downto 0);-- Protection information.
    hwdata       : out std_logic_vector(31 downto 0);-- AHB Write data bus.
    -- APB Slave
    paddr        : in  std_logic_vector(4 downto 0);-- APB Address.
    psel         : in  std_logic;       -- Selection line.
    pwrite       : in  std_logic;       -- 0 => Read; 1 => Write.
    penable      : in  std_logic;       -- APB enable line.
    pwdata       : in  std_logic_vector(31 downto 0);-- APB Write data bus.
    prdata       : out std_logic_vector(31 downto 0);-- APB Read data bus.
    -- Interrupt line
    interrupt    : out std_logic;       -- Interrupt line.
    -- AES SRAM:
    aesram_di_o  : out std_logic_vector(127 downto 0);-- Data to be written.
    aesram_a_o   : out std_logic_vector(  3 downto 0);-- Address.
    aesram_rw_no : out std_logic;       -- Write Enable. Inverted logic.
    aesram_cs_no : out std_logic;       -- Chip Enable. Inverted logic.
    aesram_do_i  : in  std_logic_vector(127 downto 0);-- Data read.
    -- RC4 SRAM:
    rc4ram_di_o  : out std_logic_vector(7 downto 0);-- Data to be written.
    rc4ram_a_o   : out std_logic_vector(8 downto 0);-- Address.
    rc4ram_rw_no : out std_logic;       -- Write Enable. Inverted logic.
    rc4ram_cs_no : out std_logic;       -- Chip Enable. Inverted logic.
    rc4ram_do_i  : in  std_logic_vector(7 downto 0); -- Data read.
    -- Diagnostic ports
    test_vector  : out std_logic_vector(31 downto 0)
  );
end stream_processor;
