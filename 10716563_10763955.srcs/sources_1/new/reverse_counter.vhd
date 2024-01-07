library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
-- The 5 bit reverse_counter for the credibility bit
-- gets resetted to 31, decrements by 1 if enabled
entity reverse_counter is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;

    i_count_enable : in std_logic;
    o_data : out std_logic_vector(4 downto 0)
  );
end reverse_counter;
architecture reverse_counter_arch of reverse_counter is
  signal stored_value : std_logic_vector(4 downto 0);
begin
  -- The output is the stored value
  o_data <= stored_value;

  process (i_clk, i_rst, stored_value, i_count_enable)
  begin
    -- If reset, then... reset!
    if i_rst = '1' then
      stored_value <= (others => '1');
    elsif i_clk'event and i_clk = '1' then
      if i_count_enable = '1' and not (stored_value = "00000") then
        stored_value <= stored_value - 1;
      end if;
    end if;
  end process;
end reverse_counter_arch;