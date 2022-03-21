
--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of biggest_picker_4 is

  signal max_re_im_i0    : std_logic_vector(data_length_g-1 downto 0);
  signal max_re_im_i1    : std_logic_vector(data_length_g-1 downto 0);
  signal max_re_im_i2    : std_logic_vector(data_length_g-1 downto 0);
  signal max_re_im_i3    : std_logic_vector(data_length_g-1 downto 0);
  signal max_i0_i1       : std_logic_vector(data_length_g-1 downto 0);
  signal max_i2_i3       : std_logic_vector(data_length_g-1 downto 0);
  signal index_s0        : std_logic;
  signal index_s1        : std_logic;
  signal index_all       : std_logic_vector(1 downto 0);

  -- absolute values of each input
  signal input0_re_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input0_im_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input1_re_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input1_im_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input2_re_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input2_im_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input3_re_abs   : std_logic_vector(data_length_g-1 downto 0);
  signal input3_im_abs   : std_logic_vector(data_length_g-1 downto 0);
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------------
  -- Get the absolute value of each input
  --------------------------------------------
  input_abs_p : process (input0_re, input0_im,
                         input1_re, input1_im,
                         input2_re, input2_im,
                         input3_re, input3_im)
  begin
    
    if (input0_re(data_length_g-1) = '1') then
      input0_re_abs <= not(input0_re) + '1';
    else
      input0_re_abs <= input0_re;
    end if;
    if (input0_im(data_length_g-1) = '1') then
      input0_im_abs <= not(input0_im) + '1';
    else
      input0_im_abs <= input0_im;
    end if;
    
    if (input1_re(data_length_g-1) = '1') then
      input1_re_abs <= not(input1_re) + '1';
    else
      input1_re_abs <= input1_re;
    end if;
    if (input1_im(data_length_g-1) = '1') then
      input1_im_abs <= not(input1_im) + '1';
    else
      input1_im_abs <= input1_im;
    end if;
    
    if (input2_re(data_length_g-1) = '1') then
      input2_re_abs <= not(input2_re) + '1';
    else
      input2_re_abs <= input2_re;
    end if;
    if (input2_im(data_length_g-1) = '1') then
      input2_im_abs <= not(input2_im) + '1';
    else
      input2_im_abs <= input2_im;
    end if;
    
    if (input3_re(data_length_g-1) = '1') then
      input3_re_abs <= not(input3_re) + '1';
    else
      input3_re_abs <= input3_re;
    end if;
    if (input3_im(data_length_g-1) = '1') then
      input3_im_abs <= not(input3_im) + '1';
    else
      input3_im_abs <= input3_im;
    end if;
    
  end process input_abs_p;
  
  --------------------------------------------
  -- Get the max between re and im of each input.
  -- We assume that re and im are positive
  --------------------------------------------
  max_0 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => input0_re_abs,
                 operande1   => input0_im_abs,
                 max         => max_re_im_i0,
                 index       => open
  );
  
  max_1 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => input1_re_abs,
                 operande1   => input1_im_abs,
                 max         => max_re_im_i1,
                 index       => open
  );
  
  max_2 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => input2_re_abs,
                 operande1   => input2_im_abs,
                 max         => max_re_im_i2,
                 index       => open
  );
  
  max_3 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => input3_re_abs,
                 operande1   => input3_im_abs,
                 max         => max_re_im_i3,
                 index       => open
  );
  
  --------------------------------------------
  -- Get the max between max_re_im
  --------------------------------------------
  max_4 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => max_re_im_i0,
                 operande1   => max_re_im_i1,
                 max         => max_i0_i1,
                 index       => index_s0
  );
  
  max_5 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => max_re_im_i2,
                 operande1   => max_re_im_i3,
                 max         => max_i2_i3,
                 index       => index_s1
  );

  --------------------------------------------
  -- Get the final max
  --------------------------------------------
  max_6 : max_picker_2
    generic map (data_length_g => data_length_g)
    port map    (operande0   => max_i0_i1,
                 operande1   => max_i2_i3,
                 max         => open,
                 index       => index_all(1)
  );

  --------------------------------------------
  -- index of the input containing the max
  --------------------------------------------
  index_all(0) <= index_s0 when (index_all(1) = '0') else index_s1;

  --------------------------------------------
  -- Outputs
  --------------------------------------------
  index <= index_all;
  biggest_p : process(index_all,
                      input0_re, input0_im,
                      input1_re, input1_im,
                      input2_re, input2_im,
                      input3_re, input3_im)
  begin
    case index_all is            
      when "00" =>               
        output_re <= input0_re;  
        output_im <= input0_im;  
      when "01" =>               
        output_re <= input1_re;  
        output_im <= input1_im;  
      when "10" =>               
        output_re <= input2_re;  
        output_im <= input2_im;  
      when "11" =>               
        output_re <= input3_re;  
        output_im <= input3_im;  
      when others =>             
        null;                    
    end case;                    
  end process biggest_p;
  
end rtl;
