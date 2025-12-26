library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.washing_machine_pkg.all;

entity state_transition_module_tb is
end state_transition_module_tb;

architecture Behavioral of state_transition_module_tb is

    -- Component Declaration
    component state_transition_module
        Port (
            clk, reset : in STD_LOGIC;
            start_btn, door_closed, mode_auto, config_saved : in STD_LOGIC;
            temp_saved, speed_saved, options_saved : in boolean;
            washing_substate : in washing_substate_type;
            current_state : out state_type;
            next_state : out state_type
        );
    end component;

    -- Signals
    signal clk, reset : STD_LOGIC := '0';
    signal start_btn, door_closed, mode_auto, config_saved : STD_LOGIC := '0';
    signal temp_saved, speed_saved, options_saved : boolean := false;
    signal washing_substate : washing_substate_type := COMPLETE; -- default valid value
    signal current_state, next_state : state_type;

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Instantiate UUT
    uut: state_transition_module
        port map (
            clk => clk,
            reset => reset,
            start_btn => start_btn,
            door_closed => door_closed,
            mode_auto => mode_auto,
            config_saved => config_saved,
            temp_saved => temp_saved,
            speed_saved => speed_saved,
            options_saved => options_saved,
            washing_substate => washing_substate,
            current_state => current_state,
            next_state => next_state
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Close the door to go from IDLE → MODE_SELECT
        door_closed <= '1';
        wait for 200 ns;

        -- MODE_SELECT → CHECK_MODE → AUTO_PRESET
        wait for 20 ns;
        mode_auto <= '1';

        -- AUTO_PRESET → READY
        wait for 40 ns;
        config_saved <= '1';
        wait for 20 ns;

        -- READY → WASHING
        start_btn <= '1';
        wait for 20 ns;
        start_btn <= '0';
        wait for 40 ns;

        -- WASHING → IDLE (only if COMPLETE)
        washing_substate <= COMPLETE;
        wait for 20 ns;

        -- Manual mode test
        config_saved <= '0';
        mode_auto <= '0';
        temp_saved <= false;
        speed_saved <= false;
        options_saved <= false;
        wait for 400 ns;

        -- MANUAL_TEMP
  
        config_saved <= '1';
        wait for 30 ns;
        temp_saved <= true;
        wait for 20 ns;

        -- MANUAL_SPEED
        speed_saved <= true;
        wait for 20 ns;

        -- MANUAL_OPTIONS
        options_saved <= true;
        wait for 20 ns;

        -- READY → WASHING again
        start_btn <= '1';
        wait for 20 ns;
        start_btn <= '0';
        wait for 40 ns;

        -- Finish cycle
        washing_substate <= COMPLETE;
        wait for 20 ns;

        -- End simulation
        wait;
    end process;

end Behavioral;
