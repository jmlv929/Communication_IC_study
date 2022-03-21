

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of microrotation is

  --------------------------------------------
  -- Signals
  --------------------------------------------
  -- y_i sign : 1: neg ; 0: pos
  signal y_sign        : std_logic; 
  signal shift_x_i     : std_logic_vector(data_length_g downto 0);
  signal shift_y_i     : std_logic_vector(data_length_g downto 0);
  signal neg_shift_x_i : std_logic_vector(data_length_g downto 0);
  signal neg_shift_y_i : std_logic_vector(data_length_g downto 0);
  signal delta_x       : std_logic_vector(data_length_g downto 0);
  signal delta_y       : std_logic_vector(data_length_g downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- y sign
  y_sign <= y_i(data_length_g);
  
  -- The inputs are left shifted of stage_g bits (*2^(-stage_g)).
  shift_p : process(x_i, y_i)
  begin
    -- shift_x_i = 2^(-stage_g)*x_i :
    shift_x_i <= 
        EXT(x_i(data_length_g downto stage_g), data_length_g+1);
    -- shift_y_i = 2^(-stage_g)*y_i :
    shift_y_i <= 
        SXT(y_i(data_length_g downto stage_g), data_length_g+1);
  end process shift_p;

  -- neg shift_x_i and shift_y_i
  neg_shift_x_i <= not(shift_x_i) + '1';
  neg_shift_y_i <= not(shift_y_i) + '1';
  
  -- compute delta_x and delta_y
  -- delta_x = (1-2*y_sign)*shift_y_i :
  delta_x <= shift_y_i when y_sign = '0' else neg_shift_y_i;
  -- delta_y = -(1-2*y_sign)*shift_y_i :
  delta_y <= shift_x_i when y_sign = '1' else neg_shift_x_i;
  
  -- Output generation
  -- x_o = x_i + delta_x :
  x_o <= x_i + delta_x;
  -- y_o = y_i + delta_y :
  y_o <= y_i + delta_y;

end rtl;
