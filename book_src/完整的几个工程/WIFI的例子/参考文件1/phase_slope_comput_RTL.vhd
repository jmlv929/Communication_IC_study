

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of phase_slope_comput is
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant mult_operand   : std_logic_vector(5  downto 0) := "110011"; -- = 1/10
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal su4_pipe          : std_logic_vector(xd_size_g+1 downto 0);
  -- Multiplication with the fraction (1/10,1/35...etc)
  signal mult_res          : signed(xd_size_g+8 downto 0);
  signal mult_res_slv      : std_logic_vector(xd_size_g+8 downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Multiplication with the fraction (1/10)
  -----------------------------------------------------------------------------

  mult_res     <= unsigned(mult_operand) * signed(su4_pipe); --
  mult_res_slv <= std_logic_vector(mult_res); 

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  su_reg_proc: process (clk, reset_n)
  begin  -- process su_reg_proc
    if reset_n = '0' then              
      su4_pipe <= (others => '0');
    elsif clk'event and clk = '1' then  
      -- with 4 : su_pipe <= Sum (const * XD(i))
      if enable_slope_comp_i = '1' then
         su4_pipe <= sxt((unsigned'("11") * signed(xd_buffer0_i)),xd_size_g+2)
                    +sxt( xd_buffer1_i, xd_size_g+2);   
      end if;
    end if;
  end process su_reg_proc;
  -- output linking

  -----------------------------------------------------------------------------
  --  Select according to M the result of calc
  -----------------------------------------------------------------------------
  with m_factor_i select
    su_o <=
    xd_buffer0_i(xd_buffer0_i'high downto 1)                  when '0',   --(3)
    sxt(mult_res_slv(mult_res_slv'high downto 9),xd_size_g-1) when others;  --(4)

 

end RTL;
