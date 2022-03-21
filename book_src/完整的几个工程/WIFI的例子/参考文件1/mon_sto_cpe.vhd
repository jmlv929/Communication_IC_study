
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: mon_sto_cpe.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : STO and CPE monitoring.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/mon_sto_cpe.vhd,v  
--  Log: mon_sto_cpe.vhd,v  
-- Revision 1.4  2003/07/17 13:59:45  Dr.F
-- changed PI_CT definition.
--
-- Revision 1.3  2003/06/25 16:15:50  Dr.F
-- code cleaning.
--
-- Revision 1.2  2003/04/01 16:31:39  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:52  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity mon_sto_cpe is

  generic (nbit_sto_cpe_g : integer := 17
    );
  port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    sync_reset_n      : in  std_logic;
    data_valid_i      : in  std_logic;
    start_of_burst_i  : in  std_logic;
    sto_i             : in  std_logic_vector(nbit_sto_cpe_g-1 downto 0);
    cpe_i             : in  std_logic_vector(nbit_sto_cpe_g-1 downto 0);
    skip_cpe_o        : out std_logic_vector(1 downto 0)
  );

end mon_sto_cpe;
