library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.washing_machine_pkg.all; -- Ensure this includes all required types and constants

entity signal_module_td is
end signal_module_td;

architecture Behavioral of signal_module_td is

    -- Component Declaration
    component signal_handler_module
        Port (
            clk, reset : in STD_LOGIC;
            current_state : in state_type;
            preset_sel : in STD_LOGIC_VECTOR(2 downto 0);
            temp_sel, speed_sel : in STD_LOGIC_VECTOR(1 downto 0);
            prewash_btn, extra_rinse_btn, start_btn, door_closed, config_saved : in STD_LOGIC;
            washing_substate : out washing_substate_type;
            manual_temp_reg, manual_speed_reg, auto_temp, auto_speed : out STD_LOGIC_VECTOR(1 downto 0);
            prewash_enabled, extra_rinse_enabled : out STD_LOGIC;
            temp_saved, speed_saved, options_saved : out boolean;
            selected_time, remaining_time, counter : out integer;
            motor_on, water_valve, drain_valve, heater, door_lock : out STD_LOGIC;
            spin_phase : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    -- Signals
    signal clk, reset : STD_LOGIC := '0';
    signal current_state : state_type := AUTO_PRESET;
    signal preset_sel : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal temp_sel, speed_sel : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal prewash_btn, extra_rinse_btn, start_btn, door_closed, config_saved : STD_LOGIC := '0';

    signal washing_substate : washing_substate_type;
    signal manual_temp_reg, manual_speed_reg, auto_temp, auto_speed : STD_LOGIC_VECTOR(1 downto 0);
    signal prewash_enabled, extra_rinse_enabled : STD_LOGIC;
    signal temp_saved, speed_saved, options_saved : boolean;
    signal selected_time, remaining_time, counter : integer;
    signal motor_on, water_valve, drain_valve, heater, door_lock : STD_LOGIC;
    signal spin_phase : STD_LOGIC_VECTOR(1 downto 0);

    -- Clock process
    constant clk_period : time := 10 ns;
    begin
        clk_process : process
        begin
            while true loop
                clk <= '0';
                wait for clk_period / 2;
                clk <= '1';
                wait for clk_period / 2;
            end loop;
        end process;

    -- Instantiate the Unit Under Test
    uut: signal_handler_module
        port map (
            clk => clk,
            reset => reset,
            current_state => current_state,
            preset_sel => preset_sel,
            temp_sel => temp_sel,
            speed_sel => speed_sel,
            prewash_btn => prewash_btn,
            extra_rinse_btn => extra_rinse_btn,
            start_btn => start_btn,
            door_closed => door_closed,
            config_saved => config_saved,
            washing_substate => washing_substate,
            manual_temp_reg => manual_temp_reg,
            manual_speed_reg => manual_speed_reg,
            auto_temp => auto_temp,
            auto_speed => auto_speed,
            prewash_enabled => prewash_enabled,
            extra_rinse_enabled => extra_rinse_enabled,
            temp_saved => temp_saved,
            speed_saved => speed_saved,
            options_saved => options_saved,
            selected_time => selected_time,
            remaining_time => remaining_time,
            counter => counter,
            motor_on => motor_on,
            water_valve => water_valve,
            drain_valve => drain_valve,
            heater => heater,
            door_lock => door_lock,
            spin_phase => spin_phase
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset pulse
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- AUTO_PRESET: Select Quick Wash (preset_sel = "000")
        preset_sel <= "000";
        wait for 50 ns;

        -- Transition to READY
        current_state <= READY;
        door_closed <= '1';
        start_btn <= '1';
        wait for 30 ns;
        start_btn <= '0';

        -- Enter WASHING
        current_state <= WASHING;

        -- Simulate for some time to observe the cycle
        wait for 2 ms;

        -- Stop simulation
        wait;
    end process;

end Behavioral;
