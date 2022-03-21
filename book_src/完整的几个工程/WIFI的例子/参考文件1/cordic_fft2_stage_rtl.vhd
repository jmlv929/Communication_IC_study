
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of cordic_fft2_stage is

  ---------------------------------------------------------------------
  -- General signals
  ---------------------------------------------------------------------
  signal y_i_shifted     : std_logic_vector(data_size_g-1 downto 0);
  signal x_i_shifted     : std_logic_vector(data_size_g-1 downto 0);
    
---------------------------------------------------------------------
-- Architecture Body
---------------------------------------------------------------------
begin

---------------------------------------------------------------------
-- Yi shift by 2-i
--------------------------------------------------------------------- 

 y_i_shifted((data_size_g-stage_g-1) downto 0) 
                   <= y_i(data_size_g-1 downto stage_g);

 y_i_shifted_high_g: for i in data_size_g-1 downto data_size_g-stage_g generate
   y_i_shifted(i) <= y_i(data_size_g-1);
 end generate y_i_shifted_high_g;

---------------------------------------------------------------------
-- Xi shift by 2-i
--------------------------------------------------------------------- 

 x_i_shifted((data_size_g-stage_g-1) downto 0) 
                   <= x_i(data_size_g-1 downto stage_g);

 x_i_shifted_high_g: for i in data_size_g-1 downto data_size_g-stage_g generate
   x_i_shifted(i) <= x_i(data_size_g-1);
 end generate x_i_shifted_high_g;

---------------------------------------------------------------------
-- final addition/substraction
--------------------------------------------------------------------- 
 
 x_o <= x_i + y_i_shifted  when delta_i = '0' else
          x_i - y_i_shifted;
 y_o <= y_i + x_i_shifted  when delta_i = '1' else
          y_i - x_i_shifted;

end rtl;
