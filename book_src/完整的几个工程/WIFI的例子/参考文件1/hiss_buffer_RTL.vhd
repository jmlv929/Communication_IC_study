

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of hiss_buffer is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type ARRAY_BUF is array (1 to buf_size_g) of
    std_logic_vector(rx_length_g-1 downto 0);

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal toggle_ff       : std_logic;   -- Flip flop on toggle.
  signal buf_i           : ARRAY_BUF;   -- Buffer for I inputs.
  signal buf_q           : ARRAY_BUF;   -- Buffer for Q inputs.
  signal read_pointer    : natural range 0 to buf_size_g;  -- To read into buffer.
  signal output_possible : std_logic;  -- After 2 data stored in buf, able to read.
  signal two_counter     : std_logic;   -- Counter to output 1 data each 2 clk.
  -- Clock Skip delay counter : Delay the clock skip from the interpolator 
  signal clk_2skip_ff0   : std_logic;   -- Flip flop on clk_2skip.
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  ------------------------------------------------
  -- Toggle
  ------------------------------------------------
  -- purpose: Flip flop on toggle to detect edge.
  -- type   : sequential
  -- inputs : clk_44_g, reset_n, toggle_i
  -- outputs: toggle_ff
  toggle_ff_p : process (clk_44g, reset_n)
  begin  -- process toggle_ff_p
    if reset_n = '0' then
      toggle_ff <= '0';
    elsif clk_44g'event and clk_44g = '1' then
      toggle_ff <= toggle_i;
    end if;
  end process toggle_ff_p;

  ------------------------------------------------
  -- Write Buffer
  ------------------------------------------------
  -- purpose: Buffer write process
  -- type   : sequential
  -- inputs : clk_44g, reset_n, toggle_i, toggle_ff, rx_i_i, rx_q_i
  -- outputs: 
  buffer_read_write : process (clk_44g, reset_n)
  begin  -- process buffer_read_write
    if reset_n = '0' then
      buf_i <= (others => (others => '0'));
      buf_q <= (others => (others => '0'));
    elsif clk_44g'event and clk_44g = '1' then
      if hiss_buf_init = '1' then
        buf_i <= (others => (others => '0'));
        buf_q <= (others => (others => '0'));
      elsif toggle_ff /= toggle_i then
        buf_i(1) <= rx_i_i;
        buf_q(1) <= rx_q_i;
        for i in 1 to buf_size_g-1 loop
          buf_i(i+1) <= buf_i(i);
          buf_q(i+1) <= buf_q(i);
        end loop;  -- i
      end if;
    end if;
  end process buffer_read_write;
  
  ------------------------------------------------
  -- Read buffer address.
  ------------------------------------------------
  -- purpose: Read of the buffer.
  -- type   : sequential
  -- inputs : clk_44g, reset_n, buf_i, buf_q, two_counter, output_possible
  -- outputs: read_pointer
  read_add_p : process (clk_44g, reset_n)
  begin  -- process buffer_read_p
    if reset_n = '0' then
      read_pointer <= 0;
    elsif clk_44g'event and clk_44g = '1' then
      if hiss_buf_init = '1' then
        read_pointer <= 0;
      elsif toggle_ff /= toggle_i and
        (two_counter = '0' or output_possible = '0') then
        read_pointer <= read_pointer + 1;
      elsif toggle_ff = toggle_i and two_counter = '1'
        and output_possible = '1' and read_pointer /= 0 then
        read_pointer <= read_pointer - 1;
      end if;
    end if;
  end process read_add_p;
  
  -----------------------------------------------
  -- Read buffer
  ------------------------------------------------
  -- purpose: Read buffer.
  -- type   : sequential
  -- inputs : clk_44g, reset_n, read_pointer, buf_i, buf_q
  -- outputs: rx_i_o, rx_q_o
  buffer_read_p : process (clk_44g, reset_n)
  begin  -- process buffer_read_p
    if reset_n = '0' then
      rx_i_o <= (others => '0');
      rx_q_o <= (others => '0');
    elsif clk_44g'event and clk_44g = '1' then
      if hiss_buf_init = '1' then
        rx_i_o <= (others => '0');
        rx_q_o <= (others => '0');
      elsif read_pointer /= 0 and output_possible = '1' and two_counter = '1' then
        rx_i_o <= buf_i(read_pointer);
        rx_q_o <= buf_q(read_pointer);
      end if;
    end if;
  end process buffer_read_p;
  
  -----------------------------------------------
  -- two counter
  ------------------------------------------------
  -- on data should be output every 2 periods
  two_counter_p: process (clk_44g, reset_n)
  begin  -- process two_counter-p
    if reset_n = '0' then            
      two_counter     <= '0';
      output_possible <= '0';
    elsif clk_44g'event and clk_44g = '1' then
      if hiss_buf_init = '1' then
        output_possible <= '0'; -- reinit for next_time
      else       
        two_counter     <= not two_counter;
        if read_pointer = 2 and output_possible = '0' then
          -- enough data inside the buf - data output can start
          output_possible <= '1';
        end if;
      end if;
    end if;
  end process two_counter_p;
  
  -----------------------------------------------
  -- Clock skip
  ------------------------------------------------
  
  -- purpose: flip-flops at 44 MHz on clock_2skip.
  -- type   : sequential
  -- inputs : clk_44, reset_n, clk_2skip_i
  -- outputs: clk_2skip_ff0, clk_2skip_ff1
  clk2skip_ff_p: process (clk_44, reset_n)
  begin  -- process clkskip_ff_p
    if reset_n = '0' then
      clk_2skip_ff0 <= '0';
    elsif clk_44'event and clk_44 = '1' then
      clk_2skip_ff0 <= clk_2skip_i;
    end if;
  end process clk2skip_ff_p;

  -- Output of the clock skip : For one clk_2skip we need to skip 2 clock periods.
  -- To avoid missing any toggle on data, we gate the clock twice separated by
  -- one clock period :
  -- ___   ___   ___   ___   ___   ___   ___   ___
  -- |  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__ clk_44
  --        _________________________________
  -- _______|                                |_______ clk_2skip_i
  --             ______      ______
  -- ____________|    |______|    |__________________ clkskip_o

  
  -- purpose: generation of clock2skip_int
  -- type   : sequential
  -- inputs : clk_44, reset_n, clk_2skip_ff0, clk_2skip_ff1
  -- outputs: clk2skip_int
  clk2skip_out_p: process (clk_44, reset_n)
    variable count_clk2skip : std_logic_vector(1 downto 0);
  begin  -- process clkskip_out_p
    if reset_n = '0' then
      clkskip_o <= '0';
      count_clk2skip := "00";
    elsif clk_44'event and clk_44 = '1' then
      if count_clk2skip="00" and clk_2skip_ff0 /= clk_2skip_i then
        clkskip_o <= '1';
        count_clk2skip := count_clk2skip + '1';
      elsif count_clk2skip = "01" then
        clkskip_o <= '0';
        count_clk2skip :=count_clk2skip + '1';
      elsif count_clk2skip = "10" then
        clkskip_o <= '1';
        count_clk2skip := "00";
      else
        clkskip_o <= '0';
      end if;
    end if;
  end process clk2skip_out_p;
  
end RTL;
