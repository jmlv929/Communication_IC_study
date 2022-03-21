

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_equ_instage0_ctr is

begin


  -------------------------------------------------------------------
  ---                    Input STAGE (products) 
  -------------------------------------------------------------------

  ----------------------
  -- Mux Inputs 
  ----------------------
  mux_input_p : process (ctr_input_i, ich_i, ich_saved_i, qch_i, qch_saved_i,
                                      i_i,   i_saved_i,   q_i,   q_saved_i)
  begin
    --default
    z_re_o <= i_i;
    z_im_o <= q_i;
    h_re_o <= ich_i;
    h_im_o <= qch_i;

    case ctr_input_i is
      when SAVED_DATA_CT =>
        z_re_o <= i_saved_i;
        z_im_o <= q_saved_i;
      when SAVED_CHMEM_CT =>
        h_re_o <= ich_saved_i;
        h_im_o <= qch_saved_i;
      when others => null;
    end case;

  end process mux_input_p;
      

  ------------------------------------------
  -- Sequential part
  ------------------------------------------
  seq_p: process(reset_n, clk)
  begin
    if reset_n = '0' then

      current_symb_o     <= PREAMBLE_CT;
      data_valid_o       <= '0';
      burst_rate_o       <= RATE_6_CT;
      cumhist_valid_o    <= '0';

    elsif clk'event and clk='1' then
      if sync_reset_n = '0' then 
        current_symb_o     <= PREAMBLE_CT;
        data_valid_o       <= '0';
        burst_rate_o       <= RATE_6_CT;
        cumhist_valid_o    <= '0';

      elsif module_enable_i = '1' then 
        if pipeline_en_i = '1' then
          current_symb_o     <= current_symb_i;
          data_valid_o       <= '1';
          burst_rate_o       <= burst_rate_i;
        else
          data_valid_o <= '0';
        end if;
      end if;

      if module_enable_i = '1' then
        cumhist_valid_o <=cumhist_en_i;
      end if;
    end if;
  end process seq_p;

end rtl;
