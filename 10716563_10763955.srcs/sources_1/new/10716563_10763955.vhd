library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity project_reti_logiche is

  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_add : in std_logic_vector(15 downto 0);
    i_k : in std_logic_vector(9 downto 0);

    o_done : out std_logic;

    o_mem_addr : out std_logic_vector(15 downto 0);
    i_mem_data : in std_logic_vector(7 downto 0);
    o_mem_data : out std_logic_vector(7 downto 0);
    o_mem_we : out std_logic;
    o_mem_en : out std_logic
  );

end project_reti_logiche;
architecture project_reti_logiche_arch of project_reti_logiche is

begin

end project_reti_logiche_arch;