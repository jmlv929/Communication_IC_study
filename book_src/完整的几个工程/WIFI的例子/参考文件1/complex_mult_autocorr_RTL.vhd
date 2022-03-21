

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of complex_mult_autocorr is

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  operand_a_proc: process (data_in_i, data_in_q, sign_i)
  begin  -- process operanda_0i_proc
    if sign_i = '0' then
      operand_a_i <= sxt(data_in_i,size_in_g + 1);
      operand_a_q <= sxt(data_in_q,size_in_g + 1);
    else
      operand_a_i <= - signed(sxt(data_in_i,size_in_g + 1));
      operand_a_q <= - signed(sxt(data_in_q,size_in_g + 1));        
    end if;
  end process operand_a_proc;
  
  operand_b_proc: process (data_in_i, data_in_q, sign_q)
  begin  -- process operanda_0i_proc
    if sign_q = '0' then
      operand_b_i <= sxt(data_in_q,size_in_g + 1);
      operand_b_q <= - signed(sxt(data_in_i,size_in_g + 1));
    else
      operand_b_i <= - signed(sxt(data_in_q,size_in_g + 1));  
      operand_b_q <= sxt(data_in_i,size_in_g + 1);   
    end if;
  end process operand_b_proc;

end RTL;
