
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : CORDIC
--    ,' GoodLuck ,'      RCSfile: cordic_fft2_stage.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : CORDIC base stage.
--             _________                       ___________
--            |         |                     |           |
--            |  x_in   |                     |   y_in    |
--            |_________|                     |___________|
--              |    |                           |      |
--              |    |                           |      |
--              |    |                           |      |
--              |  __V_________         _________V__    |
--              |  \           \        \           \   |
--              |   \ shift by  \        \ shift by  \  |
--              |   / stage_g   /        / stage_g   /  |
--              |  /___________/        /___________/   |
--              |           |              |            |
--              |           |              |            |
--              |           |      .-------'            |
--            __V__         `------|----.             __V__
--           |     |               |    |            |     |     delta(stage_g)
--     ----->| +/- |<--------------'    `----------->| +/- |<-------
-- not delta |_____|                                 |_____|
--  (stage_g)   |                                       |
--              |                                       |
--              |                                       |
--              |                                       |
--          ____V____                              _____V_____
--         |         |                            |           |
--         |  x_out  |                            |   y_out   |
--         |_________|                            |___________|
--
--

--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic_fft2/vhdl/rtl/cordic_fft2_stage.vhd,v  
--  Log: cordic_fft2_stage.vhd,v  
-- Revision 1.1  2003/03/17 07:59:04  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 

---------------------------------------------------------------------
-- Entity
---------------------------------------------------------------------
entity cordic_fft2_stage is 
  generic (
    data_size_g  : integer;  
    stage_g      : integer  
  );
  port (
    x_i        : in  std_logic_vector(data_size_g-1 downto 0);   
    y_i        : in  std_logic_vector(data_size_g-1 downto 0);   
    delta_i    : in  std_logic;   

    x_o        : out std_logic_vector(data_size_g-1 downto 0);   
    y_o        : out std_logic_vector(data_size_g-1 downto 0)   
  );
end cordic_fft2_stage;
