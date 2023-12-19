library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- The 8-bit register records the last not '0' value of the sequence
entity register is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_write_en : in std_logic;

    i_data : in std_logic_vector(7 downto 0);
    o_data : out std_logic_vector(7 downto 0)
  );
end register;
architecture register_arch of register is
  signal stored_value : std_logic_vector(7 downto 0);

begin

end register_arch;