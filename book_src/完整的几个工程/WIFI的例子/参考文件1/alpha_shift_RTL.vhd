

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of alpha_shift is

  signal temp : std_logic_vector(6 downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  temp <= (others => data_in(dsize_g-1));

  shift_pr: process (alpha, data_in, temp)
  begin
    case alpha is
      when "000" =>
        shifted_data(dsize_g+4 downto 5) <= data_in;
        shifted_data(4 downto 0) <= (others => '0');
      
      when "001" =>
        shifted_data(dsize_g+4) <= temp(0);
        shifted_data(dsize_g+3 downto 4) <= data_in;
        shifted_data(3 downto 0) <= (others => '0');
      
      when "010" =>
        shifted_data(dsize_g+4 downto dsize_g+3) <= temp(1 downto 0);
        shifted_data(dsize_g+2 downto 3) <= data_in;
        shifted_data(2 downto 0) <= (others => '0');
      
      when "011" =>
        shifted_data(dsize_g+4 downto dsize_g+2) <= temp(2 downto 0);
        shifted_data(dsize_g+1 downto 2) <= data_in;
        shifted_data(1 downto 0) <= (others => '0');
      
      when "100" =>
        shifted_data(dsize_g+4 downto dsize_g+1) <= temp(3 downto 0);
        shifted_data(dsize_g downto 1) <= data_in;
        shifted_data(0) <= '0';
      
      when "101" =>
        shifted_data(dsize_g+4 downto dsize_g) <= temp(4 downto 0);
        shifted_data(dsize_g-1 downto 0) <= data_in;
      
      when "110" =>
        shifted_data(dsize_g+4 downto dsize_g-1) <= temp(5 downto 0);
        shifted_data(dsize_g-2 downto 0) <= data_in(data_in'high downto 1);
      
      when others => --"111"
        shifted_data(dsize_g+4 downto dsize_g-2) <= temp(6 downto 0);
        shifted_data(dsize_g-3 downto 0) <= data_in(data_in'high downto 2);
    end case;
    
      
  end process shift_pr;

end RTL;
