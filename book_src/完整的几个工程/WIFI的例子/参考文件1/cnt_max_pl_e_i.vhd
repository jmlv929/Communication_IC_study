
--------------------------------------------------------------------------------
--       ------------      Project : GoodLuck Package
--    ,' GoodLuck ,'      RCSfile: cnt_max_pl_e_i.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date:    
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Counter with max count, parallel load, enable and final count 
--               interrupt.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/packages/commonlib/vhdl/rtl/cnt_max_pl_e_i.vhd,v  
--  Log: cnt_max_pl_e_i.vhd,v  
-- Revision 1.3  2001/12/06 09:18:33  Dr.J
-- Added description and project name
--
-- Revision 1.2  2000/01/26 13:00:46  Dr.F
-- reordered interface.
--
-- Revision 1.1  2000/01/26 12:21:14  Dr.F
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
entity cnt_max_pl_e_i is
  generic ( depth_g        : integer := 4);
  port ( reset_n     :  in slv1;
         clk         :  in slv1;
         enable      :  in slv1;
         load_enable :  in slv1;
         load_data   :  in std_logic_vector(depth_g-1 downto 0);
         maxval      :  in std_logic_vector(depth_g-1 downto 0);
         termint     : out slv1;
         q           : out std_logic_vector(depth_g-1 downto 0)
       );
end cnt_max_pl_e_i;
