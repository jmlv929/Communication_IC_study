

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of serial_parity_gen is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal parity_bit      : std_logic;        -- internal parity bit
  signal parity_bit_calc : std_logic;        -- internal parity bit
  signal reset_val       : std_logic;        -- val of parity reg at reset


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Convert integer -> std_logic
  -----------------------------------------------------------------------------
  reset1_gen: if reset_val_g = 1 generate
    reset_val <= '1';
  end generate reset1_gen;

  reset0_gen: if reset_val_g = 0 generate
    reset_val <= '0';
  end generate reset0_gen;  

  -----------------------------------------------------------------------------
  -- Generate Parity Process
  -----------------------------------------------------------------------------
  -- data_i --|
  --          |
  --     ----(+)
  --     |    |--------> parity_bit_o
  --     |   _|_
  --     |->|   |
  --        |_/\|    
  -- 
  gen_par_p: process (clk, reset_n)
  begin  -- process gen_par_p
    if reset_n = '0' then               
      parity_bit <= reset_val;
    elsif clk'event and clk = '1' then  
      if init_i = '1' then
        parity_bit <= reset_val;      
      elsif data_valid_i = '1' then
        parity_bit <= parity_bit_calc;
      end if;
    end if;
  end process gen_par_p;

  -- Perform the xor operation
  parity_bit_calc <= data_i xor parity_bit;

  -- Output Linking
  parity_bit_o <= parity_bit_calc;
  -- Parity bit available 1 period later
  parity_bit_ff_o <= parity_bit;
  
end RTL;
