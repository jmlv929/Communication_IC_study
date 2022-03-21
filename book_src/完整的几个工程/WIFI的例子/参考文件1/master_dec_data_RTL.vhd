

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of master_dec_data is
  ------------------------------------------------------------------------------
  -- Constants 
  ------------------------------------------------------------------------------
  constant CLK_SKIP_CT : std_logic_vector(9 downto 0) := "1100000000";


  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- toggle signals
  signal rx_val_tog_ff0 : std_logic;    -- memorized tx_val_tog_i
  signal rx_val_tog     : std_logic;
  -- clk_skip signals
  -- For generating a 2 pulses signal
  signal clk_skip      : std_logic;
  signal clk_2skip_tog : std_logic;
  signal cs_mem        : std_logic;  -- memorize for getting the 2nd info

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  extract_data_p: process (sampling_clk, reset_n)
  begin  -- process extract_data_p
    if reset_n = '0' then
      rx_val_tog_ff0     <= '0';
      rx_val_tog         <= '0';
      rx_i_o             <= (others => '0');
      rx_q_o             <= (others => '0');
      clk_skip           <= '0';
      cs_mem             <= '0';
      cs_o               <= (others => '0');
      cs_valid_o         <= '0';
      cs_error_o         <= '0';
    elsif sampling_clk'event and sampling_clk = '1' then
      clk_skip           <= '0';
      cs_valid_o         <= '0';
      cs_error_o         <= '0';
      rx_val_tog_ff0 <= rx_val_tog_i;   -- memorize last tx_val_tog_i
      if recep_enable_i = '1' then
        if rx_val_tog_i /= rx_val_tog_ff0 then
          if rx_abmode_i = '0' then
            -----------------------------------------------------------------------
            -- A Mode
            -----------------------------------------------------------------------
            -- detect CS information
            if rx_i_i(11) /= rx_i_i(10) and cs_mem = '0' then
              -- first bit info
              cs_o(0) <= rx_q_i(11);
              cs_mem  <= '1';
            end if;

            if cs_mem = '1' then
              if rx_i_i(11) /= rx_i_i(10) then
               -- second bit info
                cs_o(1)    <= rx_q_i(11);
                cs_mem     <= '0';
                cs_valid_o <= '1';
              else
                -- The 2nd bit is not present ! There is an error. Indicate it
                -- with cs_error flag
                cs_error_o   <= '1';
                cs_mem       <= '0';
              end if;              
            end if;
            
            rx_i_o     <= rx_i_i(10 downto 0);
            rx_q_o     <= rx_q_i(10 downto 0);
            rx_val_tog <= not rx_val_tog;

          else
            ---------------------------------------------------------------------
            -- B Mode
            ---------------------------------------------------------------------
            if rx_i_i(11 downto 2) = CLK_SKIP_CT
              and rx_q_i (11 downto 2) = CLK_SKIP_CT then
              -- it is a clk_skip => don't output data
              clk_skip <= '1';
            else
              rx_val_tog         <= not rx_val_tog;
              rx_i_o(7 downto 0) <= rx_i_i(9 downto 2);
              rx_q_o(7 downto 0) <= rx_q_i(9 downto 2);
            end if;
          end if;
        end if;
      else
        cs_mem <= '0'; -- reinit in case the 2nd one didn't occur.
        cs_o   <= (others => '0');
        rx_i_o <= (others => '0');
        rx_q_o <= (others => '0');
      end if;
    end if;
  end process extract_data_p;


  -----------------------------------------------------------------------------
  -- Generate toggle  of clk_skip => 2 clk_skips needed
  -----------------------------------------------------------------------------
  clk_skip_p: process (sampling_clk, reset_n)
  begin  -- process clk_skip_p
    if reset_n = '0' then               
      clk_2skip_tog <= '0';
    elsif sampling_clk'event and sampling_clk = '1'  then
      if clk_skip = '1' then
        clk_2skip_tog <= not clk_2skip_tog;        
      end if;
    end if;
  end process clk_skip_p;

  -- output linking
  rx_val_tog_o    <= rx_val_tog;
  clk_2skip_tog_o <= clk_2skip_tog;
  
end RTL;
