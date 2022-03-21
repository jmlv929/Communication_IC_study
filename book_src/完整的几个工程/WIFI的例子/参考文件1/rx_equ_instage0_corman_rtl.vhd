
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_equ_instage0_corman is

  constant INTERNAL_WIDTH_CT : integer := (FFT_WIDTH_CT + CHMEM_WIDTH_CT); 
  constant MSB_CORMAN_CT     : integer := corman_o'high;
  
  signal corman_d   : std_logic_vector(corman_o'range);
  signal op1        : std_logic_vector(INTERNAL_WIDTH_CT - 1 downto 0);
  signal op2        : std_logic_vector(INTERNAL_WIDTH_CT - 1 downto 0);

  signal corman_int  : std_logic_vector(INTERNAL_WIDTH_CT-4 downto 0);
  signal op1_shifted : std_logic_vector(INTERNAL_WIDTH_CT-4 downto 0);
  signal op2_shifted : std_logic_vector(INTERNAL_WIDTH_CT-4 downto 0);


begin

  -------------------------------------------------------------------
  ---                    Input STAGE (products) 
  -------------------------------------------------------------------

 
  -- 12bitsX12bits      => 24 bits
  -- shift right 4 bits => 20 bits
  -- 20bits + 20bits    => 20 bits + overflow (21 bits) <-- Internal width
  -- after saturation   => 20 bits : width of cormani_prod and cormanr_o. 
  -- hpowman is always positive, its width is 1 bit less (19)
  
  -- calculation of cormanr_o and cormani_o: do the following:
 
  -- 1) do the multiplication and then shift right 4 bits:the 
  --    mult results can be considered as a 20 bits vector. 
  -- 2) extend the result on internal width : 20 + 1 in order not 
  --    to loose the overflow bit when doing the sum
  -- 3) Do the sum
  
  op1_shifted <= op1(INTERNAL_WIDTH_CT-1 downto 3) + '1';
  op2_shifted <= op2(INTERNAL_WIDTH_CT-1 downto 3) + '1';

  -- if cormanr generation (real part) :
  cormanr_g : if (complex_part_g = 0) generate
    op1        <= signed(z_re_i) * signed(h_re_i);
    op2        <= signed(z_im_i) * signed(h_im_i);
    corman_int <= SXT(op1_shifted(INTERNAL_WIDTH_CT-4 downto 1),
                      corman_int'length) +
                  SXT(op2_shifted(INTERNAL_WIDTH_CT-4 downto 1),
                      corman_int'length);
  end generate cormanr_g;

  -- if cormani generation (imaginary part) :
  cormani_g : if (complex_part_g = 1) generate
    op1        <= signed(z_im_i) * signed(h_re_i);
    op2        <= signed(z_re_i) * signed(h_im_i);
    corman_int <= SXT(op1_shifted(INTERNAL_WIDTH_CT-4 downto 1),
                      corman_int'length) -
                  SXT(op2_shifted(INTERNAL_WIDTH_CT-4 downto 1),
                      corman_int'length);
  end generate cormani_g;


  --------------------------------------------
  -- Corman saturation
  --------------------------------------------
  saturate_p : process (corman_int)
    variable i             : integer;
  begin

    -- reduce to sign + 19 bits and saturate if it is the case 
    -- overflow : saturate
    if (corman_int(MSB_CORMAN_CT+1) /= corman_int(MSB_CORMAN_CT)) then  
      -- sign
      corman_d(MSB_CORMAN_CT) <= corman_int(MSB_CORMAN_CT+1);
      --remaining bits
      for i in MSB_CORMAN_CT-1 downto 0 loop
        corman_d(i) <= not (corman_int(MSB_CORMAN_CT+1));
      end loop;
    else --regular case, just skip the product msb's
      corman_d <= corman_int(MSB_CORMAN_CT downto 0);
    end if;

  end process saturate_p;


  ------------------------------------------
  -- Sequential part
  ------------------------------------------
  seq_p: process( reset_n, clk )
    begin
    if reset_n = '0' then
      corman_o <= (others =>'0');
    elsif clk'event and clk = '1' then
      -- data flow
      if module_enable_i = '1' and pipeline_en_i = '1' then
        corman_o <= corman_d;
      end if;
    end if;
  end process seq_p;

end rtl;
