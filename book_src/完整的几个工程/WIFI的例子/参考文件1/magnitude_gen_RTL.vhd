

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of magnitude_gen is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- absolute values
  signal abs_mag_in_i        : std_logic_vector (size_in_g -1 downto 0);
  signal abs_mag_in_q        : std_logic_vector (size_in_g -1 downto 0);
  signal abs_sum             : std_logic_vector (size_in_g    downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Calculate absolute value
  -----------------------------------------------------------------------------
  abs_mag_in_i <=  abs(signed(data_in_i)); 
  abs_mag_in_q <=  abs(signed(data_in_q));
  abs_sum      <=  '0'& abs_mag_in_q + abs_mag_in_i;
  -- max is 2^15+2^15 = 2^16

  -----------------------------------------------------------------------------
  -- Calculate magnitude
  -----------------------------------------------------------------------------
  magnitude_gen_p: process (abs_mag_in_i, abs_mag_in_q, abs_sum)
    variable mag_out_large : std_logic_vector (size_in_g +1 downto 0);
  begin  -- process magnitude_gen
    if abs_mag_in_q & "00" <= abs_mag_in_i then
      mag_out <= abs_mag_in_i;

    elsif abs_mag_in_i & "00" <= abs_mag_in_q then
      mag_out <= abs_mag_in_q;
    else
      mag_out_large := abs_sum + (abs_sum & '0');
      mag_out <= mag_out_large (mag_out_large'high downto 2);
    end if;   
  end process magnitude_gen_p;


end RTL;
