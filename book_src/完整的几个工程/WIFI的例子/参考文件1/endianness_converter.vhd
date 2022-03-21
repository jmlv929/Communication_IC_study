
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : ENDIANNESS_CONVERTER
--    ,' GoodLuck ,'      RCSfile: endianness_converter.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Bridge to connect a little endian AHB master to a system
--               where data is written in memory by a big-endian based
--               processor. This block will be included into the AHB master.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/endianness_converter/vhdl/rtl/endianness_converter.vhd,v  
--  Log: endianness_converter.vhd,v  
-- Revision 1.2  2003/11/12 16:15:52  Dr.A
-- debugged halfword accesses.
--
-- Revision 1.1  2003/10/31 15:59:45  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library endianness_converter_rtl;
library work;
--use endianness_converter_rtl.endianness_converter_pkg.all;
use work.endianness_converter_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity endianness_converter is
  port (
    --------------------------------------
    -- Data busses
    --------------------------------------
    -- Little endian master interface.
    wdata_i    : in  std_logic_vector(31 downto 0);
    rdata_o    : out std_logic_vector(31 downto 0);
    -- Big endian system interface.
    wdata_o    : out std_logic_vector(31 downto 0);
    rdata_i    : in  std_logic_vector(31 downto 0);

    --------------------------------------
    -- Controls
    --------------------------------------
    acctype    : in  std_logic_vector( 1 downto 0) -- Type of data accessed.
    
  );

end endianness_converter;
