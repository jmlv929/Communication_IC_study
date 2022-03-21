

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of deintpun_datapath is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  subtype SOFT_BIT_T is std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
  type SUB_CARRIER_T is array ( 5 downto 0) of SOFT_BIT_T;
  type OFDM_SYMBOL_T is array (47 downto 0) of SUB_CARRIER_T;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal ofdm_symbol       : OFDM_SYMBOL_T;

  signal input_carrier     : SUB_CARRIER_T;
  signal output_carrier_x  : SUB_CARRIER_T;
  signal output_carrier_y  : SUB_CARRIER_T;

  signal soft_x_cond_value : std_logic;
  signal soft_y_cond_value : std_logic;
  signal soft_x_cond       : std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y_cond       : std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);

  signal soft_x            : std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y            : std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  input_carrier(0) <= soft_x0_i;
  input_carrier(1) <= soft_x1_i;
  input_carrier(2) <= soft_x2_i;
  input_carrier(3) <= soft_y0_i;
  input_carrier(4) <= soft_y1_i;
  input_carrier(5) <= soft_y2_i;

  -----------------------------------------------------------------------------
  -- write_input_carrier has to be implemented with nested for if construct to
  -- enable correct clock gating
  -----------------------------------------------------------------------------

  --------------------------------------
  -- Write input carrier process
  --------------------------------------
  write_input_carrier_p : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
        ofdm_symbol <= (others => (others => (others => '0')));
    elsif clk'event and clk = '1' then  -- rising clock edge
      if enable_write_i = '1' then
        for i in 0 to 47 loop           -- for loop necessary for clock gating
          if i = write_addr_i then
            ofdm_symbol(i) <= input_carrier;
          end if;
        end loop;  -- i
      end if;
    end if;
  end process write_input_carrier_p;


  output_carrier_x  <= ofdm_symbol(read_carr_x_i);
  soft_x_cond_value <= '0' when read_punc_x_i = 1 or enable_read_i = '0'
                  else '1';
  soft_x_cond       <= (others => soft_x_cond_value);
  soft_x            <= output_carrier_x(read_soft_x_i) and soft_x_cond;


  output_carrier_y  <= ofdm_symbol(read_carr_y_i);
  soft_y_cond_value <= '0' when read_punc_y_i = 1 or enable_read_i = '0'
                  else '1';
  soft_y_cond       <= (others => soft_y_cond_value);
  soft_y            <= output_carrier_y(read_soft_y_i) and soft_y_cond;

  --------------------------------------
  -- Soft bits output sequential process
  --------------------------------------
  softbits_sequential_p : process (clk, reset_n)
  begin
    if reset_n = '0' then              -- asynchronous reset (active low)
      soft_x_o <= (others => '0');
      soft_y_o <= (others => '0');
    elsif clk = '1' and clk'event then -- rising clock edge
      soft_x_o <= soft_x;
      soft_y_o <= soft_y;
    end if;
  end process softbits_sequential_p;


end RTL;
