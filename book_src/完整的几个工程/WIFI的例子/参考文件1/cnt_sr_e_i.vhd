
--------------------------------------------------------------------------------
-- end of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : GoodLuck Package
--    ,' GoodLuck ,'      RCSfile: cnt_sr_e_i.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : counter with syncronous reset, enable and final count
-- interrupt.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/packages/commonlib/vhdl/rtl/cnt_sr_e_i.vhd,v  
--  Log: cnt_sr_e_i.vhd,v  
-- Revision 1.5  2001/12/06 09:18:38  Dr.J
-- Added description and project name
--
-- Revision 1.4  2001/02/13 09:38:49  omilou
-- changed positive into integer
--
-- Revision 1.3  2000/01/26 13:02:15  Dr.F
-- replaced masterclk port name by clk.
-- reordered interface.
-- changed termint generation : it is not registered any more.
--
-- Revision 1.2  2000/01/21 13:51:05  igimeno
-- Changed the generic parameter name 'N' into 'depth_g'.
--
-- Revision 1.1  2000/01/20 18:03:56  dbchef
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library commonlib;
library work;
--use commonlib.slv_pkg.all;
use work.slv_pkg.all;


--------------------------------------------------------------------------------
-- entity
--------------------------------------------------------------------------------
entity cnt_sr_e_i is
  generic ( depth_g             : integer := 8);

  port ( reset_n     :  in slv1;
         clk         :  in slv1;
         sreset      :  in slv1;
         enable      :  in slv1;
         termint     : out slv1;
         q           : out std_logic_vector(depth_g-1 downto 0)

       );
end cnt_sr_e_i;
