

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of comb_stage_vectoring is

  --------------------------------------------
  -- Types
  --------------------------------------------
  type DATA_ARRAY_T    is array (natural range <>) of 
                           std_logic_vector(data_length_g downto 0);
  type ANGLE_ARRAY_T   is array (natural range <>) of 
                           std_logic_vector(angle_length_g-1 downto 0);

  --------------------------------------------
  -- Signals
  --------------------------------------------
  --remaining angle after each microrotation stage
  signal z            : ANGLE_ARRAY_T(nbr_comb_stage_g downto 0);

  -- y sign for each stage : 1 : neg ; 0 : pos
  signal y_sign       : std_logic_vector(nbr_comb_stage_g-1 downto 0);
  
  --intermediate rotated outputs of microrotation :
  signal x            : DATA_ARRAY_T(nbr_comb_stage_g downto 0);
  signal y            : DATA_ARRAY_T(nbr_comb_stage_g downto 0);
  
  -- Arctangent reference values (32-bit).
  signal arctan_array : ANGLE_ARRAY_T(nbr_comb_stage_g-1 downto 0);
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  z(0) <= z_i;
  x(0) <= x_i;
  y(0) <= y_i;
  
  gen_stage : for i in 0 to nbr_comb_stage_g-1 generate
  
    --------------------------------------------
    -- Z computation
    --------------------------------------------
    y_sign(i) <= y(i)(data_length_g);
    arctan_array(i) <= "00" & arctan_array_ref(i)(31 downto 31 - angle_length_g + 3) when y_sign(i) = '0'
              else (not("00" & arctan_array_ref(i)(31 downto 31 - angle_length_g + 3)) + '1');
    z(i+1) <= z(i) + arctan_array(i);
  
    --------------------------------------------
    -- Stage of microrotations 
    --------------------------------------------
    microrotation_i : microrotation
      generic map ( data_length_g => data_length_g,
                    stage_g       => i+start_stage_g)
      port map    ( x_i           => x(i),
                    y_i           => y(i),
                    x_o           => x(i+1),
                    y_o           => y(i+1)
      );
  end generate;
      

  --------------------------------------------
  -- Samples the generated outputs
  --------------------------------------------
  sample_out_p : process(reset_n, clk)
  begin
    if (reset_n = '0') then
      z_o <= (others => '0');
      x_o <= (others => '0');
      y_o <= (others => '0');
    elsif (clk'event and clk = '1') then
      z_o <= z(nbr_comb_stage_g);
      x_o <= x(nbr_comb_stage_g);
      y_o <= y(nbr_comb_stage_g);
    end if;
  end process sample_out_p;
      
end rtl;
