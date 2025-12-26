library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.washing_machine_pkg.all;

entity state_transition_module is
    Port (
        clk, reset : in STD_LOGIC;
        start_btn, door_closed, mode_auto, config_saved : in STD_LOGIC;
        temp_saved, speed_saved, options_saved : in boolean;
        washing_substate : in washing_substate_type;
        current_state : out state_type;
        next_state : out state_type
    );
end state_transition_module;

architecture Behavioral of state_transition_module is
    signal state_reg, state_next : state_type := IDLE;
begin
    -- State register
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= IDLE;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    -- Next-state logic
    process(state_reg, start_btn, mode_auto, config_saved, door_closed, 
            temp_saved, speed_saved, options_saved, washing_substate)
    begin
        state_next <= state_reg;

        case state_reg is
            when IDLE =>
                if door_closed = '1' then
                    state_next <= MODE_SELECT;
                end if;

            when MODE_SELECT =>
                state_next <= CHECK_MODE;

            when CHECK_MODE =>
                if mode_auto = '1' then
                    state_next <= AUTO_PRESET;
                else
                    state_next <= MANUAL_TEMP;
                end if;

            when AUTO_PRESET =>
                if config_saved = '1' then
                    state_next <= READY;
                end if;

            when MANUAL_TEMP =>
                if config_saved = '1' and temp_saved then
                    state_next <= MANUAL_SPEED;
                end if;

            when MANUAL_SPEED =>
                if config_saved = '1' and speed_saved then
                    state_next <= MANUAL_OPTIONS;
                end if;

            when MANUAL_OPTIONS =>
                if config_saved = '1' and options_saved then
                    state_next <= READY;
                end if;

            when READY =>
                if start_btn = '1' and door_closed = '1' then
                    state_next <= WASHING;
                end if;

            when WASHING =>
                if washing_substate = COMPLETE then
                    state_next <= IDLE;
                else
                    state_next <= WASHING;
                end if;

            when others =>
                state_next <= IDLE;
        end case;
    end process;
    
    -- Output current and next state
    current_state <= state_reg;
    next_state <= state_next;
end Behavioral;
