

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of bit_ser_mult is

  ------------------------------------------------------------------------------
  -- Signals
  --
  -- NOTATION:
  --   - ar  - array
  --   - par - parallel
  --   - reg - register
  --   - ser - serial
  ------------------------------------------------------------------------------
  signal y_ser_reg : std_logic;
  signal s_ar_reg  : std_logic_vector(data_size_g downto 0);
  signal c_ar_reg  : std_logic_vector(data_size_g-1 downto 0);

  signal and_in_ar : std_logic_vector(data_size_g-1 downto 0);
  signal s_ar      : std_logic_vector(data_size_g downto 0);
  signal c_ar      : std_logic_vector(data_size_g-1 downto 0);
  
  
begin  -- rtl

  -- Register y serial input
  y_input_reg : process (clk, reset_n)
  begin  -- process y_input_reg
    if reset_n = '0' then               -- asynchronous reset (active low)
      y_ser_reg <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if sync_reset = '1' then          -- synchronous reset (active high)
        y_ser_reg <= '0';
      else
        y_ser_reg <= y_ser_in;
      end if;
    end if;
  end process y_input_reg;
  

  -- Generate a 1-dimensional array of logic and full adders to perform 
  -- the multiplication.
  gen_fa_array : for i in data_size_g-1 downto 0 generate

    -- AND multiplicand x with serially input multiplier y
    and_in_ar(i) <= x_par_in(i) and y_ser_reg;

    fa_inst : fa
      port map (
        x     => and_in_ar(i),
        y     => s_ar_reg(i+1),
        c_in  => c_ar_reg(i),
        s     => s_ar(i),
        c_out => c_ar(i));

  end generate gen_fa_array;

  
  -- MSB of sum array always zero.
  s_ar(data_size_g) <= '0';
  
  -- Sum and carry array registers.
  sc_regs : process (clk, reset_n)
  begin  -- process sc_regs
    if reset_n = '0' then               -- asynchronous reset (active low)
      s_ar_reg <= (others => '0');
      c_ar_reg <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if sync_reset = '1' then          -- synchronous reset (active high)
        s_ar_reg <= (others => '0');
        c_ar_reg <= (others => '0');
      else
        s_ar_reg <= s_ar;
        c_ar_reg <= c_ar;
      end if;
    end if;
  end process sc_regs;


  -- Serial product output assignment.
  p_ser_out <= s_ar_reg(0);
  
end rtl;
