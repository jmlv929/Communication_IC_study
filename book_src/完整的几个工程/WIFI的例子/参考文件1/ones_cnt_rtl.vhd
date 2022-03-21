

--------------------------------------------------------------------------------
-- architecture declaration
--------------------------------------------------------------------------------
architecture rtl of ones_cnt is
begin
  
  ----------------------------------------------------------------------------
  -- process
  ----------------------------------------------------------------------------
  cnt : process (vector_in)
    variable i : integer;
    variable ones_out_v   : std_logic_vector(depthout_g-1 downto 0);
  begin
    ones_out_v := (others => '0');
    for i in 0 to depthin_g-1 loop
      if vector_in(i) = '1' then
        ones_out_v := ones_out_v + '1';
      end if;
    end loop;
    ones_out <= ones_out_v;
  end process cnt;

end rtl;
