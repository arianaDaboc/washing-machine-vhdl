library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.washing_machine_pkg.all;

entity signal_handler_module is
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
end signal_handler_module;

architecture Behavioral of signal_handler_module is
    -- Internal signals
    signal wash_substate_reg : washing_substate_type := FILL_WATER;
    signal manual_temperature, manual_speed_vector : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal auto_temp_reg, auto_speed_reg : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal prewash_en, extra_rinse_en : STD_LOGIC := '0';
    signal temp_saved_reg, speed_saved_reg, options_saved_reg : boolean := false;
    signal time_selected, time_remaining : integer := 0;
    signal motor, water, drain, heat, door_locked : STD_LOGIC := '0';
    signal spin_phase_reg : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal temp_code : STD_LOGIC_VECTOR(1 downto 0);

    -- Cascaded counters
    signal sec_counter : integer range 0 to ONE_SECOND-1 := 0; -- counts clock cycles
    signal seconds     : integer range 0 to 59 := 0;           -- counts seconds
    signal minutes     : integer range 0 to 59 := 0;           -- counts minutes

begin
    -- Select temperature code based on mode
    temp_code <= manual_temperature when current_state /= AUTO_PRESET else auto_temp_reg;

    process(clk, reset)
    begin
        if reset = '1' then
            wash_substate_reg <= FILL_WATER;
            manual_temperature <= (others => '0');
            manual_speed_vector <= (others => '0');
            auto_temp_reg <= (others => '0');
            auto_speed_reg <= (others => '0');
            prewash_en <= '0';
            extra_rinse_en <= '0';
            temp_saved_reg <= false;
            speed_saved_reg <= false;
            options_saved_reg <= false;
            time_selected <= 0;
            time_remaining <= 0;
            motor <= '0';
            water <= '0';
            drain <= '0';
            heat <= '0';
            door_locked <= '0';
            spin_phase_reg <= "00";
            sec_counter <= 0;
            seconds <= 0;
            minutes <= 0;
        elsif rising_edge(clk) then
            -- Cascaded counter logic
update_counters(sec_counter, seconds, minutes, time_remaining, current_state = WASHING);

            case current_state is
                when AUTO_PRESET =>
                    case preset_sel is
                        when "000" =>  -- Quick Wash
                            auto_temp_reg <= "00";  -- 30°C
                            auto_speed_reg <= "10";  -- 1200 speed
                            prewash_en <= '0';
                            extra_rinse_en <= '0';
                        when "001" =>  -- Shirts
                            auto_temp_reg <= "10";  -- 60°C
                            auto_speed_reg <= "00";  -- 800 speed
                            prewash_en <= '0';
                            extra_rinse_en <= '0';
                        when "010" =>  -- Dark colors
                            auto_temp_reg <= "01";  -- 40°C
                            auto_speed_reg <= "01";  -- 1000 speed
                            prewash_en <= '0';
                            extra_rinse_en <= '1';
                        when "011" =>  -- Dirty laundry
                            auto_temp_reg <= "01";  -- 40°C
                            auto_speed_reg <= "01";  -- 1000 speed
                            prewash_en <= '1';
                            extra_rinse_en <= '0';
                        when "100" =>  -- Antiallergenic
                            auto_temp_reg <= "11";  -- 90°C
                            auto_speed_reg <= "10";  -- 1200 speed
                            prewash_en <= '0';
                            extra_rinse_en <= '1';
                        when others =>
                            auto_temp_reg <= "01";  -- 40°C
                            auto_speed_reg <= "00";  -- 800 speed
                            prewash_en <= '0';
                            extra_rinse_en <= '0';
                    end case;

                when MANUAL_TEMP =>
                    if config_saved = '1' and not temp_saved_reg then
                        manual_temperature <= temp_sel;
                        temp_saved_reg <= true;
                    elsif config_saved = '0' and temp_saved_reg then
                        temp_saved_reg <= false;
                    end if;

                when MANUAL_SPEED =>
                    if config_saved = '1' and not speed_saved_reg then
                        manual_speed_vector <= speed_sel;
                        speed_saved_reg <= true;
                    elsif config_saved = '0' and speed_saved_reg then
                        speed_saved_reg <= false;
                    end if;

                when MANUAL_OPTIONS =>
                    if config_saved = '1' and not options_saved_reg then
                        prewash_en <= prewash_btn;
                        extra_rinse_en <= extra_rinse_btn;
                        options_saved_reg <= true;
                    elsif config_saved = '0' and options_saved_reg then
                        options_saved_reg <= false;
                    end if;

                when READY =>
                    if start_btn = '1' and door_closed = '1' then
                        case temp_code is
                            when "00" => time_selected <= calculate_time(30, prewash_en = '1', extra_rinse_en = '1');
                            when "01" => time_selected <= calculate_time(40, prewash_en = '1', extra_rinse_en = '1');
                            when "10" => time_selected <= calculate_time(60, prewash_en = '1', extra_rinse_en = '1');
                            when "11" => time_selected <= calculate_time(90, prewash_en = '1', extra_rinse_en = '1');
                            when others => time_selected <= calculate_time(30, prewash_en = '1', extra_rinse_en = '1');
                        end case;
                        time_remaining <= time_selected;
                        wash_substate_reg <= FILL_WATER;
                        door_locked <= '1';
                        sec_counter <= 0;
                        seconds <= 0;
                        minutes <= 0;
                    end if;

                when WASHING =>
                    case wash_substate_reg is
                        when FILL_WATER =>
                            water <= '1'; motor <= '0'; drain <= '0'; heat <= '0';
                            if seconds = 5 and sec_counter = 0 then
                                if prewash_en = '1' then
                                    wash_substate_reg <= PRE_WASH;
                                else
                                    wash_substate_reg <= HEAT_WATER;
                                end if;
                                water <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when PRE_WASH =>
                            motor <= '1'; water <= '0'; drain <= '0'; heat <= '0';
                            if seconds = 10 and sec_counter = 0 then
                                wash_substate_reg <= DRAIN_PRE;
                                motor <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when DRAIN_PRE =>
                            drain <= '1'; motor <= '0'; water <= '0'; heat <= '0';
                            if seconds = 3 and sec_counter = 0 then
                                wash_substate_reg <= HEAT_WATER;
                                drain <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when HEAT_WATER =>
                            heat <= '1'; water <= '1'; motor <= '0'; drain <= '0';
                            if seconds = 8 and sec_counter = 0 then
                                wash_substate_reg <= MAIN_WASH;
                                water <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when MAIN_WASH =>
                            motor <= '1'; heat <= '1'; water <= '0'; drain <= '0';
                            if seconds = 20 and sec_counter = 0 then
                                wash_substate_reg <= DRAIN_MAIN;
                                motor <= '0'; heat <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when DRAIN_MAIN =>
                            drain <= '1'; motor <= '0'; water <= '0'; heat <= '0';
                            if seconds = 3 and sec_counter = 0 then
                                wash_substate_reg <= RINSE_FILL;
                                drain <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when RINSE_FILL =>
                            water <= '1'; motor <= '0'; drain <= '0'; heat <= '0';
                            if seconds = 5 and sec_counter = 0 then
                                wash_substate_reg <= RINSE;
                                water <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when RINSE =>
                            motor <= '1'; water <= '0'; drain <= '0'; heat <= '0';
                            if seconds = 10 and sec_counter = 0 then
                                if extra_rinse_en = '1' then
                                    wash_substate_reg <= EXTRA_RINSE_CHECK;
                                else
                                    wash_substate_reg <= DRAIN_RINSE;
                                end if;
                                motor <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when EXTRA_RINSE_CHECK =>
                            wash_substate_reg <= EXTRA_RINSE;
                            water <= '1';
                            sec_counter <= 0; seconds <= 0; minutes <= 0;

                        when EXTRA_RINSE =>
                            motor <= '1'; water <= '0'; drain <= '0'; heat <= '0';
                            if seconds = 10 and sec_counter = 0 then
                                wash_substate_reg <= DRAIN_RINSE;
                                motor <= '0';
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when DRAIN_RINSE =>
                            drain <= '1'; motor <= '0'; water <= '0'; heat <= '0';
                            if seconds = 3 and sec_counter = 0 then
                                wash_substate_reg <= SPIN;
                                spin_phase_reg <= "00";
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when SPIN =>
                            drain <= '1';
                            if seconds = 2 and sec_counter = 0 then
                                case spin_phase_reg is
                                    when "00" => spin_phase_reg <= "01";
                                    when "01" => if time_remaining < 60 then spin_phase_reg <= "10"; end if;
                                    when "10" => if time_remaining < 30 then spin_phase_reg <= "11"; end if;
                                    when "11" => if time_remaining <= 1 then wash_substate_reg <= COMPLETE; sec_counter <= 0; seconds <= 0; minutes <= 0; end if;
                                    when others => spin_phase_reg <= "00";
                                end case;
                                sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;

                        when COMPLETE =>
                            motor <= '0'; water <= '0'; drain <= '0'; heat <= '0';
                                        -- Wait exactly 1 minute (minutes = 1, seconds = 0, sec_counter = 0)
                            if minutes = 1 and seconds = 0 and sec_counter = 0 then
                                  door_locked <= '0';
                                     sec_counter <= 0; seconds <= 0; minutes <= 0;
                            end if;


                        when others => null;
                    end case;

                when others =>
                    motor <= '0';
                    water <= '0';
                    drain <= '0';
                    heat <= '0';
                    door_locked <= '0';
            end case;
        end if;
    end process;

    -- Assign outputs
    washing_substate <= wash_substate_reg;
    manual_temp_reg <= manual_temperature;
    manual_speed_reg <= manual_speed_vector;
    auto_temp <= auto_temp_reg;
    auto_speed <= auto_speed_reg;
    prewash_enabled <= prewash_en;
    extra_rinse_enabled <= extra_rinse_en;
    temp_saved <= temp_saved_reg;
    speed_saved <= speed_saved_reg;
    options_saved <= options_saved_reg;
    selected_time <= time_selected;
    remaining_time <= time_remaining;
    counter <= integer(seconds); -- Output seconds for monitoring
    motor_on <= motor;
    water_valve <= water;
    drain_valve <= drain;
    heater <= heat;
    door_lock <= door_locked;
    spin_phase <= spin_phase_reg;

end Behavioral;
