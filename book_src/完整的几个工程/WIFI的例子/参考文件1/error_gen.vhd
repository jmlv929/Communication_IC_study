
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: error_gen.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Error generator for phase and carrier offset estimation.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/phase_estimation/vhdl/rtl/error_gen.vhd,v  
--  Log: error_gen.vhd,v  
-- Revision 1.8  2003/04/03 13:48:19  Dr.B
-- scaling_g added.
--
-- Revision 1.7  2003/03/10 17:24:47  Dr.B
-- phase_estimation_pkg added.
--
-- Revision 1.6  2003/03/10 17:05:59  Dr.B
-- remove call of cordic_vect_pkg.
--
-- Revision 1.5  2002/10/28 10:39:44  Dr.C
-- Changed library name
--
-- Revision 1.4  2002/07/31 07:58:05  Dr.J
-- beautified.
--
-- Revision 1.3  2002/07/11 12:24:21  Dr.J
-- Changed the data size
--
-- Revision 1.2  2002/06/10 13:15:02  Dr.J
-- Removed the modulo PI
--
-- Revision 1.1  2002/03/28 12:42:09  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.std_logic_unsigned.all;  
 
--library phase_estimation_rtl;
library work;
--use phase_estimation_rtl.phase_estimation_pkg.all;
use work.phase_estimation_pkg.all;

--library cordic_vect_rtl;
library work;
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity error_gen is
  generic (
    datasize_g  : integer := 28;-- Max value is 28.
    errorsize_g : integer := 28 -- Max value is 28.
  );
  port (
    -- clock and reset.
    clk          : in  std_logic;                   
    reset_n      : in  std_logic;    
    --
    symbol_sync  : in  std_logic; -- Symbol synchronization pulse.
    -- Demodulated datain (real and im).
    data_i       : in  std_logic_vector(datasize_g-1 downto 0); 
    data_q       : in  std_logic_vector(datasize_g-1 downto 0);
    -- Demapped data.
    demap_data   : in  std_logic_vector(1 downto 0);         
    enable_error : in  std_logic;    
    --
    -- Error detected.
    phase_error  : out std_logic_vector(errorsize_g-1 downto 0); 
    -- Error ready.
    error_ready  : out std_logic                             
  );

end error_gen;
