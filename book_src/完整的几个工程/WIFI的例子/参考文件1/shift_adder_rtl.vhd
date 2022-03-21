

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of shift_adder is

  
  --------------------------------------------
  -- Constants
  --------------------------------------------
  constant DATA_LENGTH_G_MINUS_STAGE_G_CT : integer := data_length_g - stage_g;
  
  --------------------------------------------
  -- Signals
  --------------------------------------------
  signal shift_x_in    : std_logic_vector(data_length_g downto 0);
  signal shift_y_in    : std_logic_vector(data_length_g downto 0);
  signal internal_x_in : std_logic_vector(data_length_g downto 0);
  signal internal_y_in : std_logic_vector(data_length_g downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- The inputs are left shifted of stage_g bits (*2^(-stage_g)).
  shift_p : process(x_in, y_in)
  begin
    -- shift_x_in = 2^(-stage_g)*x_in :
    shift_x_in(data_length_g downto DATA_LENGTH_G_MINUS_STAGE_G_CT) <= (others => x_in(data_length_g));
    shift_x_in(DATA_LENGTH_G_MINUS_STAGE_G_CT downto 0) <= x_in(data_length_g downto stage_g);
    -- shift_y_in = 2^(-stage_g)*y_in :
    shift_y_in(data_length_g downto DATA_LENGTH_G_MINUS_STAGE_G_CT) <= (others => y_in(data_length_g));
    shift_y_in(DATA_LENGTH_G_MINUS_STAGE_G_CT downto 0) <= y_in(data_length_g downto stage_g);
  end process shift_p;

  -- shift_x_in and shift_y_in are 2 complemented.
  -- internal_x_in = (1-2*z_sign)*shift_x_in :
  internal_x_in <= shift_x_in when z_sign = '0' else not(shift_x_in) + '1';
  -- internal_y_in = -(1-2*z_sign)*shift_y_in :
  internal_y_in <= shift_y_in when z_sign = '1' else not(shift_y_in) + '1';
  
  -- Output generation
  -- x_out = x_in + internal_y_in :
  x_out <= x_in + internal_y_in;
  -- y_out = y_in + internal_x_in :
  y_out <= y_in + internal_x_in;

end rtl;
