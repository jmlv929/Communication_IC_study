

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of qerr_mult is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal add_re_in0 : std_logic_vector(dsize_g-1 downto 0);
  signal add_re_in1 : std_logic_vector(dsize_g-1 downto 0);
  signal add_im_in0 : std_logic_vector(dsize_g-1 downto 0);
  signal add_im_in1 : std_logic_vector(dsize_g-1 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- Notation : error_quant = s0 + j*s1 where 
  --   s0 = 1 if error_quant(1) = '0' else s0 = -1
  --   s1 = 1 if error_quant(0) = '0' else s1 = -1
  -- This blocks mutiplies the conjugate of the complex input data (a + j*b)
  -- by the complex error s0 + j*s1.
  -- (s0 + j*s1)(a - j*b) = (s0*a + s1*b) + j*(-s0*b + s1*a)

  with error_quant(1) select
    add_re_in0 <=
      data_in_re when '0',
      not(data_in_re) + '1' when others;

  with error_quant(0) select
    add_re_in1 <=
      data_in_im when '0',
      not(data_in_im) + '1' when others;

  data_out_re <= (add_re_in0(add_re_in0'high) & add_re_in0)
               + (add_re_in1(add_re_in1'high) & add_re_in1);
  
  
  with error_quant(1) select
    add_im_in0 <=
      data_in_im when '1',
      not(data_in_im) + '1' when others;

  with error_quant(0) select
    add_im_in1 <=
      data_in_re when '0',
      not(data_in_re) + '1' when others;

  data_out_im <= (add_im_in0(add_im_in0'high) & add_im_in0)
               + (add_im_in1(add_im_in1'high) & add_im_in1);
              

end RTL;
