

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of crc32_8 is


  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal crc_int : std_logic_vector (31 downto 0); -- crc register

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  crc_int_proc:process (clk, resetn)
  begin
    if resetn ='0' then
      crc_int <= (others => '1');     -- reset registers
    
    elsif (clk'event and clk = '1') then
      if ld_init = '1' then           -- reset registers for new calculation  
        crc_int <= (others => '1');
      
      elsif calc = '1' then           -- ask of calculation
        -- parallel computation of the CRC-32 according to specifications.
 crc_int(0 ) <= crc_int(30) xor data_in(7 ) xor crc_int(24) xor data_in(1 );
 crc_int(1 ) <= crc_int(30) xor crc_int(31) xor data_in(6 ) xor data_in(7 ) 
            xor crc_int(24) xor data_in(0 ) xor crc_int(25) xor data_in(1 );
 crc_int(2 ) <= crc_int(30) xor crc_int(31) xor data_in(5 ) xor data_in(6 ) 
            xor data_in(7 ) xor crc_int(24) xor crc_int(25) xor crc_int(26) 
            xor data_in(0 ) xor data_in(1 );
 crc_int(3 ) <= data_in(4 ) xor crc_int(31) xor data_in(5 ) xor data_in(6 ) 
            xor crc_int(25) xor crc_int(26) xor crc_int(27) xor data_in(0 );
 crc_int(4 ) <= crc_int(30) xor data_in(4 ) xor data_in(5 ) xor data_in(7 ) 
            xor crc_int(24) xor crc_int(26) xor crc_int(27) xor crc_int(28) 
            xor data_in(1 ) xor data_in(3 );
 crc_int(5 ) <= crc_int(30) xor data_in(4 ) xor crc_int(31) xor data_in(6 ) 
            xor data_in(7 ) xor crc_int(24) xor crc_int(25) xor crc_int(27) 
            xor crc_int(28) xor crc_int(29) xor data_in(0 ) xor data_in(1 ) 
            xor data_in(2 ) xor data_in(3);
 crc_int(6 ) <= crc_int(30) xor crc_int(31) xor data_in(5 ) xor data_in(6 ) 
            xor crc_int(25) xor crc_int(26) xor crc_int(28) xor crc_int(29) 
            xor data_in(0 ) xor data_in(1 ) xor data_in(2 ) xor data_in(3 );
 crc_int(7 ) <= data_in(4 ) xor data_in(5 ) xor crc_int(31) xor data_in(7 ) 
            xor crc_int(24) xor crc_int(26) xor crc_int(27) xor crc_int(29) 
            xor data_in(0 ) xor data_in(2 );
 crc_int(8 ) <= data_in(4 ) xor data_in(6 ) xor data_in(7 ) xor crc_int(24) 
            xor crc_int(25) xor crc_int(27) xor crc_int(28) xor crc_int(0 ) 
            xor data_in(3 );
 crc_int(9 ) <= data_in(5 ) xor data_in(6 ) xor crc_int(25) xor crc_int(26) 
            xor crc_int(28) xor crc_int(29) xor data_in(2 ) xor crc_int(1 ) 
            xor data_in(3 );
 crc_int(10) <= data_in(4 ) xor data_in(5 ) xor data_in(7 ) xor crc_int(24) 
            xor crc_int(26) xor crc_int(27) xor crc_int(29) xor data_in(2 ) 
            xor crc_int(2 );
 crc_int(11) <= data_in(4 ) xor crc_int(3 ) xor data_in(6 ) xor data_in(7 ) 
            xor crc_int(24) xor crc_int(25) xor crc_int(27) xor crc_int(28) 
            xor data_in(3 );
 crc_int(12) <= crc_int(30) xor data_in(5 ) xor crc_int(4 ) xor data_in(6 ) 
            xor data_in(7 ) xor crc_int(24) xor crc_int(25) xor crc_int(26) 
            xor crc_int(28) xor crc_int(29) xor data_in(1 ) xor data_in(2 ) 
            xor data_in(3 );
 crc_int(13) <= data_in(4 ) xor crc_int(30) xor crc_int(31) xor data_in(5 ) 
            xor data_in(6 ) xor crc_int(5 ) xor crc_int(25) xor crc_int(26) 
            xor crc_int(27) xor crc_int(29) xor data_in(0 ) xor data_in(1 ) 
            xor data_in(2 );
 crc_int(14) <= data_in(4 ) xor crc_int(30) xor data_in(5 ) xor crc_int(31) 
            xor crc_int(6 ) xor crc_int(26) xor crc_int(27) xor crc_int(28) 
            xor data_in(0 ) xor data_in(1 ) xor data_in(3 );
 crc_int(15) <= data_in(4 ) xor crc_int(31) xor crc_int(7 ) xor crc_int(27) 
            xor crc_int(28) xor crc_int(29) xor data_in(0 ) xor data_in(2 ) 
            xor data_in(3 );
 crc_int(16) <= data_in(7 ) xor crc_int(24) xor crc_int(8 ) xor crc_int(28) 
            xor crc_int(29) xor data_in(2 ) xor data_in(3 );
 crc_int(17) <= crc_int(30) xor data_in(6 ) xor crc_int(25) xor crc_int(9 ) 
            xor crc_int(29) xor data_in(1 ) xor data_in(2 );
 crc_int(18) <= crc_int(30) xor data_in(5 ) xor crc_int(31) xor crc_int(26) 
            xor data_in(0 ) xor data_in(1 ) xor crc_int(10);
 crc_int(19) <= data_in(4 ) xor crc_int(31) xor crc_int(27) xor data_in(0 ) 
            xor crc_int(11);
 crc_int(20) <= crc_int(12) xor crc_int(28) xor data_in(3 );
 crc_int(21) <= crc_int(13) xor crc_int(29) xor data_in(2 );
 crc_int(22) <= crc_int(14) xor data_in(7 ) xor crc_int(24);
 crc_int(23) <= crc_int(30) xor data_in(6 ) xor data_in(7 ) xor crc_int(24) 
            xor crc_int(15) xor crc_int(25) xor data_in(1 );
 crc_int(24) <= crc_int(31) xor data_in(5 ) xor data_in(6 ) xor crc_int(25) 
            xor crc_int(16) xor crc_int(26) xor data_in(0 );
 crc_int(25) <= data_in(4 ) xor data_in(5 ) xor crc_int(26) xor crc_int(17) 
            xor crc_int(27);
 crc_int(26) <= crc_int(30) xor data_in(4 ) xor data_in(7 ) xor crc_int(24) 
            xor crc_int(27) xor crc_int(18) xor crc_int(28) xor data_in(1 ) 
            xor data_in(3 );
 crc_int(27) <= crc_int(31) xor data_in(6 ) xor crc_int(25) xor crc_int(28) 
            xor crc_int(19) xor crc_int(29) xor data_in(0 ) xor data_in(2 ) 
            xor data_in(3 );
 crc_int(28) <= crc_int(30) xor data_in(5 ) xor crc_int(26) xor crc_int(29) 
            xor data_in(1 ) xor data_in(2 ) xor crc_int(20);
 crc_int(29) <= data_in(4 ) xor crc_int(30) xor crc_int(21) xor crc_int(31) 
            xor crc_int(27) xor data_in(0 ) xor data_in(1 );
 crc_int(30) <= crc_int(31) xor crc_int(22) xor crc_int(28) xor data_in(0 ) 
            xor data_in(3 );
 crc_int(31) <= crc_int(23) xor crc_int(29) xor data_in(2 );
                              
      end if;
    end if;
  end process;

  -- 1's complement + bit & byte reversal 
 crc_out_1st (0) <= not crc_int (31);
 crc_out_1st (1) <= not crc_int (30);
 crc_out_1st (2) <= not crc_int (29);
 crc_out_1st (3) <= not crc_int (28);
 crc_out_1st (4) <= not crc_int (27);
 crc_out_1st (5) <= not crc_int (26);
 crc_out_1st (6) <= not crc_int (25);
 crc_out_1st (7) <= not crc_int (24);
 
 crc_out_2nd (0) <= not crc_int (23);
 crc_out_2nd (1) <= not crc_int (22);
 crc_out_2nd (2) <= not crc_int (21);
 crc_out_2nd (3) <= not crc_int (20);
 crc_out_2nd (4) <= not crc_int (19);
 crc_out_2nd (5) <= not crc_int (18);
 crc_out_2nd (6) <= not crc_int (17);
 crc_out_2nd (7) <= not crc_int (16);

 crc_out_3rd (0) <= not crc_int (15);
 crc_out_3rd (1) <= not crc_int (14);
 crc_out_3rd (2) <= not crc_int (13);
 crc_out_3rd (3) <= not crc_int (12);
 crc_out_3rd (4) <= not crc_int (11);
 crc_out_3rd (5) <= not crc_int (10);
 crc_out_3rd (6) <= not crc_int ( 9);
 crc_out_3rd (7) <= not crc_int ( 8);
 
 crc_out_4th (0) <= not crc_int ( 7);
 crc_out_4th (1) <= not crc_int ( 6);
 crc_out_4th (2) <= not crc_int ( 5);
 crc_out_4th (3) <= not crc_int ( 4);
 crc_out_4th (4) <= not crc_int ( 3);
 crc_out_4th (5) <= not crc_int ( 2);
 crc_out_4th (6) <= not crc_int ( 1);
 crc_out_4th (7) <= not crc_int ( 0);


end RTL;
