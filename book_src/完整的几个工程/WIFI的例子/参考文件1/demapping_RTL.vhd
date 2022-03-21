

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of demapping is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal demap_i_ext      : std_logic_vector(dsize_g downto 0);
  signal demap_q_ext      : std_logic_vector(dsize_g downto 0); 
  signal data_rot_i       : std_logic_vector(dsize_g downto 0);
  signal data_rot_q       : std_logic_vector(dsize_g downto 0); 

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- Extend sign bit.
  demap_i_ext <= demap_i(dsize_g-1) & demap_i;
  demap_q_ext <= demap_q(dsize_g-1) & demap_q;
  
  -- Rotation of pi/4 = multiplication by (1+i)
  -- (a+i*b)*(1+i) = (a-b) + i*(a+b)
  data_rot_i <= demap_i_ext - demap_q_ext;
  data_rot_q <= demap_i_ext + demap_q_ext;
  
  with demod_rate select
    demap_data <=
      data_rot_q(dsize_g) & data_rot_i(dsize_g) when '1',    -- QPSK
      demap_i(dsize_g-1) & demap_i(dsize_g-1)   when others; -- BPSK
  
end RTL;
