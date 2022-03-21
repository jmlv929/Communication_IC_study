

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_predmx is

  type DMX_STATE_T is (idle_e, 
                       dmx_preamble_e, 
                       state_start_symbol_e, 
                       dmx_data_e);

  signal dmx_state                      : DMX_STATE_T;
  signal dmx_next_state                 : DMX_STATE_T;

  signal d_wie_data_valid               : std_logic;
  signal wie_data_valid                 : std_logic;
  signal d_equ_data_valid               : std_logic;
  signal equ_data_valid                 : std_logic;
  signal d_pilot_valid                  : std_logic;
  signal pilot_valid                    : std_logic;
  signal d_equ_start_of_burst           : std_logic;
  signal equ_start_of_burst             : std_logic; -- same signal for
                                                     -- equalizer and chfifo
  signal equ_data_ready_ff1             : std_logic;

  signal d_symbol_end                   : std_logic;
  signal symbol_end                     : std_logic;

  signal d_wie_start_of_burst           : std_logic;
  signal wie_start_of_burst             : std_logic;
  signal d_equ_start_of_symbol          : std_logic;
  signal equ_start_of_symbol            : std_logic;
  signal d_plt_track_start_of_symbol    : std_logic;
  signal plt_track_start_of_symbol      : std_logic;
  signal d_wie_start_of_symbol          : std_logic;
  signal wie_start_of_symbol            : std_logic;
  signal dmx_wie_enable                 : std_logic;
  signal dmx_equ_enable                 : std_logic;
  signal sample_count                   : std_logic_vector(5 downto 0); --integer range 53 downto 0;
  signal d_sample_count                 : std_logic_vector(5 downto 0);
  signal delay_count                    : std_logic_vector(5 downto 0);
  signal d_delay_count                  : std_logic_vector(5 downto 0);
 
begin
  
  dmx_wie_enable    <= wie_data_ready_i or 
                       (not (wie_data_valid or wie_start_of_symbol));

--   dmx_equ_enable    <= (equ_data_ready_i and not(equ_data_ready_ff1)) or 
--                        (not (equ_data_valid or pilot_valid or equ_start_of_symbol));

  dmx_equ_enable    <= (equ_data_ready_i) or 
                       (not (equ_data_valid or pilot_valid or equ_start_of_symbol));

  ------------------------------------
  -- generate data_ready_o
  -----------------------------------
  gen_data_ready_p: process (dmx_state, inv_matrix_done_i,
                             dmx_wie_enable, dmx_equ_enable,
                             sample_count, delay_count)
  begin
    
    case dmx_state is
      -- if state is dmx_preamble_e and wiener is ready, 
      -- then data_ready_o is ready
      when dmx_preamble_e =>
         if dmx_wie_enable = '1' and 
            (sample_count = conv_std_logic_vector(LAST_SAMPLE_CT, 6)) and
            (inv_matrix_done_i = '1') then 
           data_ready_o <= '1';
         else
           data_ready_o <= '0';
         end if;
      -- if equalizer is ready in any other case, 
      -- then data_ready_o is ready
      when others =>  
         if (dmx_equ_enable = '1') and 
            ((sample_count = conv_std_logic_vector(LAST_SAMPLE_CT, 6)) or
            (dmx_state = idle_e)) then
         --if (dmx_equ_enable = '1')  and (symbol_end = '0') then
           data_ready_o <= '1';
         else
           if (sample_count = conv_std_logic_vector(LAST_SAMPLE_CT, 6))
              and (delay_count = conv_std_logic_vector(10,5)) then
             data_ready_o <= '1';
            else
             data_ready_o <= '0';
            end if;
         end if;
    end case;
  end process gen_data_ready_p;

   
  ------------------------------------------
  ------------------------------------------
  --        CONTROL PATH                  --
  ------------------------------------------
  ------------------------------------------
  dmx_fsm_p : process (dmx_state, wie_start_of_symbol, equ_start_of_burst, 
                       equ_start_of_symbol, dmx_equ_enable, plt_track_start_of_symbol,
                       wie_data_valid, equ_data_valid, pilot_valid,
                       start_of_burst_i, start_of_symbol_i, delay_count,
                       dmx_wie_enable, sample_count, symbol_end) 
    
  begin
      
    -- after a start_of_burst, the 1st symbol (ie T1 and T2) is sent to the
    -- Wiener, corresponding to the state dmx_preamble_e. All following
    -- symbols are going to equalizer.
    -- After each start_of_symbol the state becomes state_start_symbol_e.
    -- Then, it depends on dmx_equ_enable. if dmx_equ_enable = '1', 
    -- the next state becomes dmx_data_e.
    if (start_of_burst_i = '1') then
      dmx_next_state            <= dmx_preamble_e;
      d_wie_start_of_burst      <= '1';
      d_wie_start_of_symbol     <= '1';
      d_equ_start_of_burst      <= '0';
      d_equ_start_of_symbol     <= '0';
      d_plt_track_start_of_symbol <= '0';
      d_wie_data_valid          <= '0';
      d_equ_data_valid          <= '0';
      d_pilot_valid             <= '0';
      d_symbol_end              <= '0';
      d_delay_count             <= (others => '0');
      d_sample_count            <= conv_std_logic_vector(START_INDEX_CT, 6);
    else
      dmx_next_state            <= dmx_state;
      d_wie_start_of_burst      <= '0';
      d_wie_start_of_symbol     <= wie_start_of_symbol;
      d_equ_start_of_burst      <= equ_start_of_burst;
      d_equ_start_of_symbol     <= equ_start_of_symbol;
      d_plt_track_start_of_symbol <= plt_track_start_of_symbol;
      d_wie_data_valid          <= wie_data_valid;
      d_equ_data_valid          <= equ_data_valid;
      d_pilot_valid             <= pilot_valid;
      d_sample_count            <= sample_count;
      d_symbol_end              <= symbol_end;
      d_delay_count             <= delay_count;
      
      case dmx_state is
                
        ------------------------------------------------------------------
        -- preamble state :
        -- data are sent to Wiener (1st symbol)
        -- leaving this state when there is a start_of_symbol_i 
        ------------------------------------------------------------------
        when dmx_preamble_e =>  
          d_equ_data_valid      <= '0';
          d_delay_count         <= (others => '0');
          if (dmx_wie_enable = '1') then
            d_wie_start_of_symbol <= '0';
            if (start_of_symbol_i = '1') then
              d_sample_count        <= conv_std_logic_vector(START_INDEX_CT, 6);
              dmx_next_state        <= state_start_symbol_e;
              d_equ_start_of_burst  <= '1';
              d_equ_start_of_symbol <= '1';
              d_plt_track_start_of_symbol <= '1';
              d_wie_data_valid      <= '0';
              d_symbol_end          <= '0';
            else
              dmx_next_state              <= dmx_preamble_e;
              d_equ_start_of_burst        <= '0';
              d_equ_start_of_symbol       <= '0';
              d_plt_track_start_of_symbol <= '0';
              if (sample_count /= conv_std_logic_vector(LAST_SAMPLE_CT, 6)) then
                d_wie_data_valid <= '1';
                d_sample_count   <= sample_count + '1';
              else
                d_wie_data_valid <= '0';
                d_symbol_end     <= '1';
              end if;
            end if;
          end if;
        
        ------------------------------------------------------------
        -- start_symbol state :
        -- from here, data are sent to equalizer.
        ------------------------------------------------------------
        when state_start_symbol_e =>  
          d_wie_start_of_symbol <= '0';    
          d_wie_data_valid      <= '0';
          d_equ_start_of_burst  <= '0';
          d_delay_count         <= (others => '0');
          if (dmx_equ_enable = '1') then
            -- The equalizer is ready, sending the data
            dmx_next_state             <= dmx_data_e;
            d_equ_start_of_symbol      <= '0';
            d_plt_track_start_of_symbol <= '0';
            if (sample_count /= conv_std_logic_vector(LAST_SAMPLE_CT, 6)) then
              d_sample_count           <= sample_count + '1';
              d_equ_data_valid         <= '1';
              --d_symbol_end             <= '1';
            end if;
          else
            -- The equalizer is not ready: waiting .
            dmx_next_state             <= state_start_symbol_e;
          end if;

        ------------------------------------------------------------------
        -- dmx_data state : here, the first data after a start_of_symbol 
        -- has been already sent in the previous states. Sending the rest 
        -- of data.
        ------------------------------------------------------------------
        when dmx_data_e =>
          
          if (sample_count = conv_std_logic_vector(LAST_SAMPLE_CT, 6)) then
            d_delay_count         <= delay_count + '1';
          else
            d_delay_count         <= (others => '0');
          end if;
          if (dmx_equ_enable = '1') then
            -- The equalizer is ready, sending the data
            if (start_of_symbol_i = '1') then
              dmx_next_state        <= state_start_symbol_e;
              d_equ_start_of_symbol <= '1';
              d_plt_track_start_of_symbol <= '1';
              d_equ_data_valid      <= '0';
              d_pilot_valid         <= '0';
              d_symbol_end          <= '0';
              d_sample_count        <= conv_std_logic_vector(START_INDEX_CT, 6);
            else
              d_equ_start_of_symbol <= '0';
              d_plt_track_start_of_symbol <= '0';                             
              dmx_next_state        <= dmx_data_e;                            
              if (sample_count /= conv_std_logic_vector(LAST_SAMPLE_CT, 6)) then
                d_sample_count <= sample_count + 1;
                case conv_integer(sample_count) is
                  when PILOT_1_CT | PILOT_2_CT | DC_CT | 
                       PILOT_3_CT | PILOT_4_CT =>
                    -- remove the pilots into positions -21, -7, 0, 7, 21 and
                    -- send them to a external register
                    d_equ_data_valid    <= '0';
                    d_pilot_valid   <= '1';
                  when others =>
                    d_equ_data_valid    <= '1';
                    d_pilot_valid       <= '0';
                end case;
              else
                d_equ_data_valid        <= '0';
                d_symbol_end            <= '1';
              end if;
            end if;
          else  
            if (sample_count = conv_std_logic_vector(LAST_SAMPLE_CT, 6)) and
               (start_of_symbol_i = '1') then
              dmx_next_state        <= state_start_symbol_e;
              d_equ_start_of_symbol <= '1';
              d_plt_track_start_of_symbol <= '1';
              d_equ_data_valid      <= '0';
              d_pilot_valid         <= '0';
              d_symbol_end          <= '0';
              d_sample_count        <= conv_std_logic_vector(START_INDEX_CT, 6);
            else
              -- The equalizer is not ready: waiting .
              dmx_next_state             <= dmx_data_e;
            end if;
          end if;
          

        when others =>
          -- idle_e in case of reset_n or sync_reset_n
          dmx_next_state              <= idle_e;
          d_wie_start_of_symbol       <= '0';
          d_equ_start_of_burst        <= '0';
          d_equ_start_of_symbol       <= '0';
          d_plt_track_start_of_symbol <= '0';
          d_wie_data_valid            <= '0';
          d_equ_data_valid            <= '0';
          d_pilot_valid               <= '0';
          d_symbol_end                <= '0';
      end case;
    end if;
            
  end process dmx_fsm_p;


  --------------------------------------------
  -- Registered outputs
  --------------------------------------------
  control_registers_p : process (clk, reset_n)
  begin  
    if (reset_n = '0') then                 -- asynchronous reset (active low)
      dmx_state              <= idle_e;
      wie_data_valid         <= '0';
      equ_data_valid         <= '0';
      pilot_valid            <= '0';
      wie_start_of_burst     <= '0';
      wie_start_of_symbol    <= '0';
      equ_start_of_burst     <= '0';
      equ_start_of_symbol    <= '0';
      plt_track_start_of_symbol <= '0';
      symbol_end             <= '0';
      equ_data_ready_ff1     <= '0';
      delay_count            <= (others => '0');
      sample_count           <= conv_std_logic_vector(START_INDEX_CT, 6);
    elsif (clk'event) and (clk = '1') then  -- rising clock edge
      equ_data_ready_ff1 <= equ_data_ready_i;
      if (sync_reset_n = '0') then          -- synchronous reset (active low)
        dmx_state              <= idle_e;
        wie_data_valid         <= '0';
        equ_data_valid         <= '0';
        pilot_valid            <= '0';
        wie_start_of_burst     <= '0';
        wie_start_of_symbol    <= '0';
        equ_start_of_burst     <= '0';
        equ_start_of_symbol    <= '0';
        plt_track_start_of_symbol <= '0';
        symbol_end             <= '0';
        delay_count            <= (others => '0');
        sample_count           <= conv_std_logic_vector(START_INDEX_CT, 6);
      else
        dmx_state              <= dmx_next_state;
        wie_data_valid         <= d_wie_data_valid;
        equ_data_valid         <= d_equ_data_valid;
        pilot_valid            <= d_pilot_valid;
        wie_start_of_burst     <= d_wie_start_of_burst;
        wie_start_of_symbol    <= d_wie_start_of_symbol;
        equ_start_of_burst     <= d_equ_start_of_burst;
        equ_start_of_symbol    <= d_equ_start_of_symbol;
        plt_track_start_of_symbol <= d_plt_track_start_of_symbol;
        symbol_end             <= d_symbol_end;
        sample_count           <= d_sample_count;
        delay_count            <= d_delay_count;
      end if;
    end if;

  end process control_registers_p;

  
  -- outputs assignment
  wie_data_valid_o              <= wie_data_valid;
  equ_data_valid_o              <= equ_data_valid;  
  pilot_valid_o                 <= pilot_valid;  
  wie_start_of_burst_o          <= wie_start_of_burst;
  wie_start_of_symbol_o         <= wie_start_of_symbol;
  equ_start_of_burst_o          <= equ_start_of_burst;
  equ_start_of_symbol_o         <= equ_start_of_symbol;
  plt_track_start_of_symbol_o <= plt_track_start_of_symbol;


  ------------------------------------------
  --           DATA PATH                  --
  ------------------------------------------
  data_registers_p : process (clk, reset_n)
  begin  
    if (reset_n = '0') then                 -- asynchronous reset (active low)
      i_o <= (others => '0');
      q_o <= (others => '0');
    elsif (clk'event) and (clk = '1') then  -- rising clock edge
      case dmx_state is
        when dmx_preamble_e  =>
          if dmx_wie_enable = '1' then
            i_o <= i_i(conv_integer(sample_count));
            q_o <= q_i(conv_integer(sample_count));
          end if;
        when others =>
          if dmx_equ_enable = '1' then
            i_o <= i_i(conv_integer(sample_count));
            q_o <= q_i(conv_integer(sample_count));
          end if;
      end case;
    end if;

  end process data_registers_p;
                        
end rtl;
