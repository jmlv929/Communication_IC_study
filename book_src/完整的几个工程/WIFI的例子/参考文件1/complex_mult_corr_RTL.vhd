

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of complex_mult_corr is

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  operand_a_p: process (coeff_i, data_in_i, data_in_q)
  begin  -- process operanda_0i_proc
    case coeff_i is
      when "00" =>  -- 0
        operand_a_i <= (others => '0');
        operand_a_q <= (others => '0');
      when "01" =>  -- 1
        operand_a_i <= sxt(data_in_i,size_in_g + 1);
        operand_a_q <= sxt(data_in_q,size_in_g + 1);
      when others => -- "11" = -1
        operand_a_i <= - signed(sxt(data_in_i,size_in_g + 1));
        operand_a_q <= - signed(sxt(data_in_q,size_in_g + 1));        
    end case;
  end process operand_a_p;
  
  operand_b_p: process (coeff_q, data_in_i, data_in_q)
  begin  -- process operanda_0i_proc
    case coeff_q is
      when "00" => -- 0
        operand_b_i <= (others => '0');
        operand_b_q <= (others => '0');
      when "01" => -- 1
        operand_b_i <= sxt(data_in_q,size_in_g + 1);
        operand_b_q <= - signed(sxt(data_in_i,size_in_g + 1));
      when others => -- "11" = -1
        operand_b_i <= - signed(sxt(data_in_q,size_in_g + 1));  
        operand_b_q <= sxt(data_in_i,size_in_g + 1);   
    end case;
  end process operand_b_p;

end RTL;
