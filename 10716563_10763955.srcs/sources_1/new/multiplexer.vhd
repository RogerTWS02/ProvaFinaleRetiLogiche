library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- The multiplexer switches between the two inputs for mem data between the
-- previous num register and the revere counter for credibilty bit
entity multiplexer is
  port (
    i_select : in std_logic;

    i_data_A : in std_logic_vector(7 downto 0);
    i_data_B : in std_logic_vector(4 downto 0);

    o_data : out std_logic_vector(7 downto 0)
  );
end multiplexer;

architecture multiplexer_arch of multiplexer is
begin
  -- A is an input from register_8bit and B is an input from reverse_counter
  process (i_select, i_data_A, i_data_B)
  begin
    if i_select = '1' then
      o_data <= "000" & i_data_B;
    else
      o_data <= i_data_A;
    end if;
  end process;

end multiplexer_arch;