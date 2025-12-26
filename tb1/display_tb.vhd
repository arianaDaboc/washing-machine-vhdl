library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.washing_machine_pkg.all;

entity tb_display_controller_module is
end tb_display_controller_module;

architecture Behavioral of tb_display_controller_module is

    -- DUT (Device Under Test)
    component display_controller_module
        Port (
            current_state : in state_type;
            washing_substate : in washing_substate_type;
            selected_temp, selected_speed : in STD_LOGIC_VECTOR(1 downto 0);
            prewash_enabled, extra_rinse_enabled, mode_auto : in STD_LOGIC;
            preset_sel : in STD_LOGIC_VECTOR(2 downto 0);
            remaining_time : in integer;
            ssd_display : out STD_LOGIC_VECTOR(7 downto 0);
            state_leds : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    -- Signals
    signal current_state : state_type := IDLE;
    signal washing_substate : washing_substate_type := FILL_WATER;
    signal selected_temp, selected_speed : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal prewash_enabled, extra_rinse_enabled, mode_auto : STD_LOGIC := '0';
    signal preset_sel : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal remaining_time : integer := 0;
    signal ssd_display : STD_LOGIC_VECTOR(7 downto 0);
    signal state_leds : STD_LOGIC_VECTOR(3 downto 0);

begin

    -- Instantiate the DUT
    uut: display_controller_module
        port map (
            current_state => current_state,
            washing_substate => washing_substate,
            selected_temp => selected_temp,
            selected_speed => selected_speed,
            prewash_enabled => prewash_enabled,
            extra_rinse_enabled => extra_rinse_enabled,
            mode_auto => mode_auto,
            preset_sel => preset_sel,
            remaining_time => remaining_time,
            ssd_display => ssd_display,
            state_leds => state_leds
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- IDLE
        current_state <= IDLE;
        wait for 10 ns;

        -- MODE_SELECT
        current_state <= MODE_SELECT;
        wait for 10 ns;

        -- CHECK_MODE (AUTO)
        current_state <= CHECK_MODE;
        mode_auto <= '1';
        wait for 10 ns;

        -- CHECK_MODE (MANUAL)
        mode_auto <= '0';
        wait for 10 ns;

        -- AUTO_PRESET (try each preset)
        current_state <= AUTO_PRESET;
        for i in 0 to 4 loop
            preset_sel <= std_logic_vector(to_unsigned(i, 3));
            wait for 10 ns;
        end loop;

        -- MANUAL_TEMP
        current_state <= MANUAL_TEMP;
        for i in 0 to 3 loop
            selected_temp <= std_logic_vector(to_unsigned(i, 2));
            wait for 10 ns;
        end loop;

        -- MANUAL_SPEED
        current_state <= MANUAL_SPEED;
        for i in 0 to 2 loop
            selected_speed <= std_logic_vector(to_unsigned(i, 2));
            wait for 10 ns;
        end loop;

        -- MANUAL_OPTIONS (test all option combinations)
        current_state <= MANUAL_OPTIONS;

        prewash_enabled <= '0'; extra_rinse_enabled <= '0';
        wait for 10 ns;

        prewash_enabled <= '1'; extra_rinse_enabled <= '0';
        wait for 10 ns;

        prewash_enabled <= '0'; extra_rinse_enabled <= '1';
        wait for 10 ns;

        prewash_enabled <= '1'; extra_rinse_enabled <= '1';
        wait for 10 ns;

        -- READY (show remaining_time as SSD)
        current_state <= READY;
        for i in 0 to 3 loop
            remaining_time <= i * 10;
            wait for 10 ns;
        end loop;

        -- WASHING (with remaining time > 0)
        current_state <= WASHING;
        remaining_time <= 15;
        wait for 10 ns;

        -- WASHING (remaining_time = 0, show substate)
        remaining_time <= 0;
        for phase in washing_substate_type loop
            washing_substate <= phase;
            wait for 10 ns;
        end loop;

        -- Invalid state test
        current_state <= IDLE;
wait for 10 ns;
        wait;
    end process;

end Behavioral;
