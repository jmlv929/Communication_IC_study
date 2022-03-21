

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of complex_4mult is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal oper1_i1_mult  : std_logic_vector(csize_g-1 downto 0);
  signal oper1_i2_mult  : std_logic_vector(csize_g-1 downto 0);
  signal oper1_q1_mult  : std_logic_vector(csize_g-1 downto 0);
  signal oper1_q2_mult  : std_logic_vector(csize_g-1 downto 0);
  signal oper2_i1_mult  : std_logic_vector(dsize_g-1 downto 0);
  signal oper2_i2_mult  : std_logic_vector(dsize_g-1 downto 0);
  signal oper2_q1_mult  : std_logic_vector(dsize_g-1 downto 0);
  signal oper2_q2_mult  : std_logic_vector(dsize_g-1 downto 0);
  signal coeffq         : std_logic_vector(csize_g-1 downto 0);
  signal coeffi         : std_logic_vector(csize_g-1 downto 0);
  signal datai          : std_logic_vector(dsize_g-1 downto 0);
  signal dataq          : std_logic_vector(dsize_g-1 downto 0);
  
  
begin

  -----------------------------------------------------------------------------
  -- Selection of the multiplication to perform
  -----------------------------------------------------------------------------
  -- 00 => (coeff0_i + j * coeff0_q)(data0_i + j * data0_q)
  -- 01 => (coeff1_i + j * coeff1_q)(data1_i + j * data1_q)
  -- 10 => (coeff2_i + j * coeff2_q)(data2_i + j * data2_q)
  -- 11 => (coeff3_i + j * coeff3_q)(data3_i + j * data3_q)
  
  with div_counter select
    coeffi <=
    coeff0_i when "00",
    coeff1_i when "01",
    coeff2_i when "10",
    coeff3_i when others;

  with div_counter select
    coeffq <=
    coeff0_q when "00",
    coeff1_q when "01",
    coeff2_q when "10",
    coeff3_q when others;

  with div_counter select
    datai <=
    data0_i when "00",
    data1_i when "01",
    data2_i when "10",
    data3_i when others;

  with div_counter select
    dataq <=
    data0_q when "00",
    data1_q when "01",
    data2_q when "10",
    data3_q when others;

  oper1_i1_mult <= coeffi;
  oper1_i2_mult <= coeffq;
  oper1_q1_mult <= coeffi; 
  oper1_q2_mult <= coeffq;
  
  oper2_i1_mult <= datai;
  oper2_i2_mult <= (not dataq + '1');
  oper2_q1_mult <= dataq; 
  oper2_q2_mult <= datai;
  -- the subtraction is perform on operand instead of on result, in order
  -- reduce the number of bits. 

  -- perform the multiplication
  data_i1_mult <= signed (oper1_i1_mult) * signed (oper2_i1_mult);
  data_i2_mult <= signed (oper1_i2_mult) * signed (oper2_i2_mult);
  data_q1_mult <= signed (oper1_q1_mult) * signed (oper2_q1_mult);
  data_q2_mult <= signed (oper1_q2_mult) * signed (oper2_q2_mult);

 
end RTL;
