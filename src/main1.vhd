library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.washing_machine_pkg.all;

entity main is
    Port (
        clk              : in  STD_LOGIC;
        reset            : in  STD_LOGIC;
        start_btn        : in  STD_LOGIC;
        door_closed      : in  STD_LOGIC;
        mode_auto        : in  STD_LOGIC;  -- '1' = auto, '0' = manual
        preset_sel       : in  STD_LOGIC_VECTOR(2 downto 0);
        temp_sel         : in  STD_LOGIC_VECTOR(1 downto 0);
        speed_sel        : in  STD_LOGIC_VECTOR(1 downto 0);
        prewash_btn      : in  STD_LOGIC;
        extra_rinse_btn  : in  STD_LOGIC;
        config_saved     : in  STD_LOGIC;
        ssd_display      : out STD_LOGIC_VECTOR(7 downto 0);
        state_leds       : out STD_LOGIC_VECTOR(3 downto 0)
    );
end main;

architecture Behavioral of main is
    -- Common types and signals used across modules
    type state_type is (
        IDLE, MODE_SELECT, CHECK_MODE, AUTO_PRESET, 
        MANUAL_TEMP, MANUAL_SPEED, MANUAL_OPTIONS, 
        READY, WASHING
    );
    
    type washing_substate_type is (
        FILL_WATER, PRE_WASH, DRAIN_PRE, HEAT_WATER,
        MAIN_WASH, DRAIN_MAIN, RINSE_FILL, RINSE,
        EXTRA_RINSE_CHECK, EXTRA_RINSE, DRAIN_RINSE,
        SPIN, COMPLETE
    );
    
    -- State signals
    signal current_state, next_state : state_type;
    signal washing_substate : washing_substate_type := FILL_WATER;
    
    -- Configuration signals
    signal manual_temp_reg : STD_LOGIC_VECTOR(1 downto 0);
    signal manual_speed_reg : STD_LOGIC_VECTOR(1 downto 0);
    signal prewash_enabled : STD_LOGIC;
    signal extra_rinse_enabled : STD_LOGIC;
    signal selected_temp, selected_speed, auto_temp, auto_speed : STD_LOGIC_VECTOR(1 downto 0);
    signal temp_saved, speed_saved, options_saved : boolean;
    
    -- Time signals
    signal selected_time, remaining_time : integer;
    signal counter : integer range 0 to 59;
    
    -- Washing machine control signals
    signal motor_on, water_valve, drain_valve, heater, door_lock : STD_LOGIC;
    
    -- Spin phase signals
    signal spin_phase : STD_LOGIC_VECTOR(1 downto 0);
    signal spin_outputs : STD_LOGIC_VECTOR(3 downto 0);
    
    -- Component declarations
    component state_transition_module is
        Port (
            clk, reset : in STD_LOGIC;
            start_btn, door_closed, mode_auto, config_saved : in STD_LOGIC;
            temp_saved, speed_saved, options_saved : in boolean;
            washing_substate : in washing_substate_type;
            current_state : out state_type;
            next_state : out state_type
        );
    end component;
    
    component signal_handler_module is
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
            selected_time, remaining_time : out integer;
            counter : out integer range 0 to 59;
            motor_on, water_valve, drain_valve, heater, door_lock : out STD_LOGIC;
            spin_phase : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;
    
    component display_controller_module is
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
    
    component spin_decoder_module is
        Port (
            spin_phase : in STD_LOGIC_VECTOR(1 downto 0);
            spin_outputs : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    
begin
    -- Signal assignments
    selected_temp <= auto_temp when mode_auto = '1' else manual_temp_reg;
    selected_speed <= auto_speed when mode_auto = '1' else manual_speed_reg;
    
    -- Instantiate modules
    state_transition_inst: state_transition_module
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
    
    signal_handler_inst: signal_handler_module
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
    
    display_controller_inst: display_controller_module
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
    
    spin_decoder_inst: spin_decoder_module
        port map (
            spin_phase => spin_phase,
            spin_outputs => spin_outputs
        );
    
end Behavioral;
