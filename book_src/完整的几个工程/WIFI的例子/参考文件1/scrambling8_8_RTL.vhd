

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of scrambling8_8 is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal s_reg             : std_logic_vector (6 downto 0); -- scrambler register
  signal last_scr_activate : std_logic; -- determine the scrambling init phase 
  signal scr_out_i         : std_logic_vector (7 downto 0); -- scrambled output

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  ------------------------------------------------------------------------------
  -- Process for register s_reg
  ------------------------------------------------------------------------------
  s_reg_proc:process (clk, resetn)
  begin
    if resetn ='0' then          -- reset registers by default long syncpackets
      s_reg <= "1101100";
          
    elsif (clk'event and clk = '1') then
      if scr_activate = '1' and txv_immstop = '0' then             
        if last_scr_activate = '0' then   -- init the registers
          -- as it is the first time the scrambler has been enabled.
          if txv_prtype = '1' then      -- long sync packets
            s_reg <= "0011011";         
          else                          -- short sync packets
            s_reg <= "1101100";  
          end if;
        elsif scramb_reg = '1' then 
        -- if a new ask of byte transfer occurs  
          -- store the last results
          s_reg(0) <=   scr_out_i (7);
          s_reg(1) <=   scr_out_i (6);
          s_reg(2) <=   scr_out_i (5);
          s_reg(3) <=   scr_out_i (4);
          s_reg(4) <=   scr_out_i (3);
          s_reg(5) <=   scr_out_i (2);
          s_reg(6) <=   scr_out_i (1);
        end if;
      end if;
    end if;
  end process;
  
  ------------------------------------------------------------------------------
  -- memorization of last_scr_activate
  ------------------------------------------------------------------------------
  mem_proc:process (clk, resetn)
  begin
    if resetn ='0' then          
      last_scr_activate   <= '0';
          
    elsif (clk'event and clk = '1') then
      last_scr_activate   <= scr_activate;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Output Wiring
  ------------------------------------------------------------------------------
   scr_out_i (0) <= scr_in(0) xor s_reg(6)  xor s_reg(3);
   scr_out_i (1) <= scr_in(1) xor s_reg(2)  xor s_reg(5);
   scr_out_i (2) <= scr_in(2) xor s_reg(1)  xor s_reg(4);
   scr_out_i (3) <= scr_in(3) xor s_reg(0)  xor s_reg(3);
   scr_out_i (4) <= scr_in(4) xor scr_in(0) xor s_reg(6) xor s_reg(2)  
                xor s_reg(3);
   scr_out_i (5) <= scr_in(5) xor s_reg(2)  xor s_reg(5) xor scr_in(1) 
                xor s_reg(1);
   scr_out_i (6) <= scr_in(6) xor scr_in(2) xor s_reg(1) xor s_reg(4)  
                xor s_reg(0);
   scr_out_i (7) <= scr_in(7) xor scr_in(3) xor s_reg(0) xor scr_in(0) 
                xor s_reg(6);

   scr_out <= scr_in when scrambling_disb = '1' else scr_out_i;

end RTL;
