

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of calibration_mux is


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  mux_p : process (calmode_i, int_filter_outputi_i, int_filter_outputq_i,
                   iq_gen_sig_im_i, iq_gen_sig_re_i, enable_i)
  begin
    if calmode_i = '1' then
      i_out               <= iq_gen_sig_re_i;
      q_out               <= iq_gen_sig_im_i;
      iq_gen_data_ready_o <= '1';
      enable_o            <= '1';
    else
      i_out               <= int_filter_outputi_i;
      q_out               <= int_filter_outputq_i;
      iq_gen_data_ready_o <= '0';
      enable_o            <= enable_i;
    end if;
  end process mux_p;

end RTL;
