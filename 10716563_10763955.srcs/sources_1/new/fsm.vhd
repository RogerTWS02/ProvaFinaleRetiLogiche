library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- The state machine that controls the process
entity fsm is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;

    i_start : in std_logic; -- start value for the process
    i_k : in std_logic_vector(9 downto 0); -- the k words
    i_word_count : in std_logic_vector(9 downto 0); -- the current word count
    i_mem_data : in std_logic_vector(7 downto 0); -- the data from the memory

    o_mux_select : out std_logic;
    o_register_we : out std_logic;
    o_counter_increment : out std_logic;
    o_rev_count_reset : out std_logic;
    o_rev_count_decrement : out std_logic;
    o_mem_we : out std_logic;
    o_done : out std_logic
  );
end fsm;
architecture fsm_arch of fsm is
  type STATE is (INIT, READ_MEM, ZERO_VALUE, NON_ZERO_VALUE, SET_CREDIBILITY, DONE);
  signal current_state : STATE;
begin

  process (i_clk, i_rst)
  begin
    -- If reset, then... reset!
    if i_rst = '1' then
      current_state <= INIT;
    elsif i_clk'event and i_clk = '1' then
      case current_state is
        when INIT =>
          if i_start = '1' then
            current_state <= READ_MEM;
          end if;
        when READ_MEM =>
          if i_mem_data = "00000000" then
            current_state <= ZERO_VALUE;
          else
            current_state <= NON_ZERO_VALUE;
          end if;
        when ZERO_VALUE =>
          current_state <= SET_CREDIBILITY;
        when NON_ZERO_VALUE =>
          current_state <= SET_CREDIBILITY;
        when SET_CREDIBILITY =>
          if i_word_count = i_k then
            current_state <= DONE;
          else
            current_state <= READ_MEM;
          end if;
        when DONE =>
          if i_start = '0' then
            current_state <= INIT;
          end if;
      end case;
    end if;
  end process;

  process (current_state)
  begin
    o_mux_select <= '0';
    o_register_we <= '0';
    o_counter_increment <= '0';
    o_rev_count_reset <= '0';
    o_rev_count_decrement <= '0';
    o_mem_we <= '0';
    o_done <= '0';

    -- the INIT and READ_MEM states do not set any flags
    case current_state is
      when INIT =>
      when READ_MEM =>
      when ZERO_VALUE =>
        o_mux_select <= '0'; -- select the register, technically not needed but for clarity
        o_counter_increment <= '1'; -- go to the next mem address
        o_mem_we <= '1'; -- write the register value into the memory address
      when NON_ZERO_VALUE =>
        o_register_we <= '1'; -- save the value to the register
        o_counter_increment <= '1'; -- go to the next mem address
        o_rev_count_reset <= '1'; -- reset the reverse counter
      when SET_CREDIBILITY =>
        o_mux_select <= '1'; -- select the reverse counter
        o_counter_increment <= '1'; -- go to the next mem address
        o_rev_count_decrement <= '1'; -- decrement the reverse counter
        o_mem_we <= '1'; -- write the reverse counter value into the memory address
      when DONE =>
        o_done <= '1'; -- done!
    end case;
  end process;

end fsm_arch;