

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of long_sfd_comp is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant LONG_SFD_CHAIN_CT : std_logic_vector (15 downto 0)
                              := "0000010111001111";
  -- 7 last preamble bits + long sfd (after descrambling)

  constant SHORT_SFD_CHAIN_CT : std_logic_vector (15 downto 0)
                              := "1111001110100000";
  -- 7 last preamble bits + short sfd (after descrambling)
  
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal shift_reg      : std_logic_vector (14 downto 0);
  -- register for comparison
  signal long_packet_sync_int : std_logic; -- indicate when detect of long SFD
  signal short_packet_sync_int : std_logic;  -- indicate when detect of short SFD

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  -----------------------------------------------------------------------------
  -- store data
  -----------------------------------------------------------------------------
  shift_reg_proc: process (clk, reset_n)
  begin  
    if reset_n = '0' then                
      shift_reg <= (others => '0');
    elsif clk'event and clk = '1' then
      if lg_sfd_comp_activate = '1' and symbol_sync = '1' then
        shift_reg(0) <= delta_phi0;
        shift_reg(14 downto 1) <= shift_reg (13 downto 0);
      end if;
    end if; 
  end process shift_reg_proc;

  -----------------------------------------------------------------------------
  -- compare
  -----------------------------------------------------------------------------
  -- Outputs assignation.
  long_packet_sync  <= long_packet_sync_int;
  short_packet_sync <= short_packet_sync_int;
    
  sync_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      long_packet_sync_int <= '0';
      short_packet_sync_int <= '0';
    elsif clk'event and clk = '1' then
      -- Block not activated.
      if lg_sfd_comp_activate = '0' then
        long_packet_sync_int <= '0';
        short_packet_sync_int <= '0';
      else
        
        -- generate packet_sync only when there is no difference with long ct.
        if (shift_reg& delta_phi0 = LONG_SFD_CHAIN_CT) then --and sfd_state = IDLE then
          long_packet_sync_int <= '1';
        elsif long_packet_sync_int = '1' and symbol_sync = '1' then
          long_packet_sync_int <= '0';
        end if;
        
        -- generate packet_sync only when there is no difference with short ct.
        if (shift_reg& delta_phi0 = SHORT_SFD_CHAIN_CT) then --and sfd_state = IDLE then
          short_packet_sync_int <= '1';
        elsif short_packet_sync_int = '1' and symbol_sync = '1' then
          short_packet_sync_int <= '0';
        end if;
        
      end if;
          
    end if;
  end process sync_p;

end RTL;
