
--------------------------------------------------------------------------------
-- end of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : GoodLuck Package
--    ,' GoodLuck ,'      RCSfile: cnt_max_sr_e_i.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Counter with max count, enable and final count interrupt.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/packages/commonlib/vhdl/rtl/cnt_max_sr_e_i.vhd,v  
--  Log: cnt_max_sr_e_i.vhd,v  
-- Revision 1.4  2001/12/06 09:18:34  Dr.J
-- Added description and project name
--
-- Revision 1.3  2000/01/26 13:01:12  Dr.F
-- replaced masterclk port name by clk.
-- reordered interface.
--
-- Revision 1.2  2000/01/21 13:50:57  igimeno
-- Changed the generic parameter name 'N' into 'depth_g'.
--
-- Revision 1.1  2000/01/20 18:00:59  dbchef
-- Initial revision
--
--
--------------------------------------------------------------------------------


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

--library commonlib;
library work;
--    use commonlib.slv_pkg.all;
use work.slv_pkg.all;


--------------------------------------------------------------------------------
-- entity
--------------------------------------------------------------------------------
entity cnt_max_sr_e_i is
  generic ( depth_g        : integer := 4);
  port ( reset_n     :  in slv1;
         clk         :  in slv1;
         sreset      :  in slv1;
         enable      :  in slv1;
         maxval      :  in std_logic_vector(depth_g-1 downto 0);
         termint     : out slv1;
         q           : out std_logic_vector(depth_g-1 downto 0)
       );
end cnt_max_sr_e_i;
