

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------

--     mux_sel(0)                 mux_sel(1)
--        |                          |
--        |_  x_mux1 ___  x_mux1_ff  |_  x_mux2  ___ 
--  x_i -|\ |_______|   |-----------|\ |________|   |--- x_o
--  y_i -|/_|     | | FF|  ,--------|/_|        |FF |
--                | |___|  |                    |___|
--     mux_sel(0) |________| 
--        |
--        |_  y_mux1 ___ 
--  x_i -|\ |_______|   |--- y_o
--  y_i -|/_|       |FF |
--                  |___|
--      
--      
architecture RTL of punct_dpath is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Signals for x_o generation.
  signal x_mux1    : std_logic;
  signal x_mux1_ff : std_logic;
  signal x_mux2    : std_logic;

  -- Signals for y_o generation.
  signal y_mux : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  ---------------------------------------------------------------------------
  -- Generate X data out.
  ---------------------------------------------------------------------------

  -- X mux1 is controlled by mux_sel_i(0).
  x_mux1 <= x_i when mux_sel_i(0) = '0' else
            y_i;

  -- X mux2 is controlled by mux_sel_i(1).
  x_mux2 <= x_mux1 when mux_sel_i(1) = '0' else
            x_mux1_ff;

  -- The mux outputs are registered and sent on x_o.
  x_regs : process (clk, reset_n)
  begin
    if reset_n = '0' then
      x_mux1_ff <= '0';
      x_o       <= '0';
    elsif clk'event and clk = '1' then
      if data_valid_i = '1' and dpath_enable_i = '1' then
        x_mux1_ff <= x_mux1;
        x_o       <= x_mux2;
      end if;
    end if;
  end process x_regs;


  ---------------------------------------------------------------------------
  -- Generate Y data out.
  ---------------------------------------------------------------------------

  -- Y mux is controlled by mux_sel_i(0).
  y_mux <= y_i when mux_sel_i(0) = '0' else
           x_i;

  -- The mux output is registered and sent on y_o.
  y_regs : process (clk, reset_n)
  begin
    if reset_n = '0' then
      y_o     <= '0';
    elsif clk'event and clk = '1' then
      if data_valid_i = '1' and dpath_enable_i = '1' then
        y_o <= y_mux;
      end if;
    end if;
  end process y_regs;

end RTL;
