

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of beta_shift is

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin


  shift_pr: process (beta, data_in)
  begin
    case beta is     
      when "000" =>
        shifted_data <= data_in & "00";
      
      when "001" =>
        shifted_data <= sxt(data_in, dsize_g+1) & '0';

      when "010" =>
        shifted_data <= sxt(data_in, dsize_g+2);

      when "011" =>
        shifted_data <= sxt(data_in(data_in'high downto 1), dsize_g+2);
      
      when "100" =>
        shifted_data <= sxt(data_in(data_in'high downto 2), dsize_g+2);
      
      when "101" => 
        shifted_data <= sxt(data_in(data_in'high downto 3), dsize_g+2);

      when others => --"110"
        shifted_data <= sxt(data_in(data_in'high downto 4), dsize_g+2);
    end case;
    
      
  end process shift_pr;

end RTL;
