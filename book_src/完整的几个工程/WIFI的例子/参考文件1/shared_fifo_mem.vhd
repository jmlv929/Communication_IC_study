
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: shared_fifo_mem.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.6  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Shared FIFO memory
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/shared_fifo_mem/vhdl/rtl/shared_fifo_mem.vhd,v  
--  Log: shared_fifo_mem.vhd,v  
-- Revision 1.6  2003/06/27 09:08:15  Dr.C
-- Changed target_suplier generic into constant
-- Added xilinx_memory library
--
-- Revision 1.5  2003/06/26 16:12:33  Dr.C
-- Modified xilinx component name
--
-- Revision 1.4  2003/04/07 07:26:58  Dr.C
-- Updated sensitivity list
--
-- Revision 1.3  2003/04/04 17:01:44  Dr.C
-- Corrected error on rd_ptr1
--
-- Revision 1.2  2003/04/04 16:47:32  Dr.C
-- Inverted read pointers
--
-- Revision 1.1  2003/03/27 17:06:18  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;

--library target_config_pkg;
library work;
--use target_config_pkg.target_config_pkg.all;
use work.target_config_pkg.all;

--library xilinx_memory_rtl;
library work;

--------------------------------------------
-- Entity
--------------------------------------------
entity shared_fifo_mem is
  generic (
    datawidth_g  : integer := 22;
    addrsize_g   : integer := 6;
    depth_g      : integer := 128
    );

  port (
    --------------------------------
    -- Clock & reset
    --------------------------------
    clk     : in std_logic;
    reset_n : in std_logic;

    --------------------------------
    -- Init sync 
    --------------------------------
    init_sync_read_i      : in std_logic;
    init_sync_read_ptr1_i : in std_logic_vector(addrsize_g downto 0);
    init_sync_write_i     : in std_logic;
    init_sync_write_ptr_i : in std_logic_vector(addrsize_g downto 0);
    init_sync_wdata_i     : in std_logic_vector(datawidth_g - 1 downto 0);
    --------------------------------
    -- Fine frequency estimation 
    --------------------------------
    ffe_wdata_i           : in std_logic_vector(datawidth_g - 1 downto 0);
    ffe1_read_ptr_i       : in std_logic_vector(addrsize_g downto 0);
    ffe2_read_ptr_i       : in std_logic_vector(addrsize_g downto 0);
    ffe_write_ptr_i       : in std_logic_vector(addrsize_g downto 0);
    ffe_write_i           : in std_logic;
    ffe_read_i            : in std_logic;

    --------------------------------
    -- Read data
    --------------------------------    
    fifo_mem_data1_o : out std_logic_vector(datawidth_g - 1 downto 0);
    fifo_mem_data2_o : out std_logic_vector(datawidth_g - 1 downto 0)
    );

end shared_fifo_mem;
