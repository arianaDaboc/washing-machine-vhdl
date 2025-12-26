library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package washing_machine_pkg is
    -- State type definitions
    type state_type is (
        IDLE,
        MODE_SELECT,
        CHECK_MODE,
        AUTO_PRESET,
        MANUAL_TEMP,
        MANUAL_SPEED,
        MANUAL_OPTIONS,
        READY,
        WASHING  
    );
    
    type washing_substate_type is (
        FILL_WATER,
        PRE_WASH,
        DRAIN_PRE,
        HEAT_WATER,
        MAIN_WASH,
        DRAIN_MAIN,
        RINSE_FILL,
        RINSE,
        EXTRA_RINSE_CHECK,
        EXTRA_RINSE,
        DRAIN_RINSE,
        SPIN,
        COMPLETE
    );
    
    -- Constants for temperatures
    constant TEMP_30C : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant TEMP_40C : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant TEMP_60C : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant TEMP_90C : STD_LOGIC_VECTOR(1 downto 0) := "11";
    
    -- Constants for speeds
    constant SPEED_800  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant SPEED_1000 : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant SPEED_1200 : STD_LOGIC_VECTOR(1 downto 0) := "10";
    
    -- Time constants (for a 100MHz clock)
    constant CLOCK_FREQ : integer := 100000000; -- 100 MHz
    constant ONE_SECOND : integer := CLOCK_FREQ;
    constant ONE_MINUTE : integer := 60; -- Modified for cascading counters
    
    -- Types for cascading counters
    subtype sec_counter_type is integer range 0 to ONE_SECOND-1;
    subtype seconds_counter_type is integer range 0 to 59;
    subtype minutes_counter_type is integer range 0 to 59;
    
    -- Function declarations
    function calculate_time(temp : integer; prewash : boolean; extra_rinse : boolean) return integer;
    
    -- Procedure for updating cascading counters
    procedure update_counters(
        signal sec_counter  : inout sec_counter_type;
        signal seconds      : inout seconds_counter_type;
        signal minutes      : inout minutes_counter_type;
        signal time_remaining : inout integer;
        constant update_time  : in boolean := false
    );
    
    -- Function to check if specific time has elapsed
    function time_elapsed(
        seconds_value : seconds_counter_type;
        minutes_value : minutes_counter_type;
        target_seconds : integer;
        target_minutes : integer := 0
    ) return boolean;
end washing_machine_pkg;

package body washing_machine_pkg is
    function calculate_time(temp : integer; prewash : boolean; extra_rinse : boolean) return integer is
        variable total_time : integer := 0;
    begin
        total_time := (temp - 15) * 2;  -- Heating time
        if prewash then
            total_time := total_time + (temp - 15) * 2; -- Same heating again
        end if;
        if extra_rinse then
            total_time := total_time + 2 * 30; -- Each rinse ~30s
        else
            total_time := total_time + 30; -- One rinse
        end if;
        total_time := total_time + 60; -- Wash phase ~60s
        return total_time;
    end function;
    
    -- Implementation of the counter update procedure
    procedure update_counters(
        signal sec_counter  : inout sec_counter_type;
        signal seconds      : inout seconds_counter_type;
        signal minutes      : inout minutes_counter_type;
        signal time_remaining : inout integer;
        constant update_time  : in boolean := false
    ) is
    begin
        if sec_counter = ONE_SECOND-1 then
            sec_counter <= 0;
            
            if seconds = 59 then
                seconds <= 0;
                if minutes < 59 then
                    minutes <= minutes + 1;
                end if;
            else
                seconds <= seconds + 1;
            end if;
            
            -- Update time_remaining if requested
            if update_time and time_remaining > 0 then
                time_remaining <= time_remaining - 1;
            end if;
        else
            sec_counter <= sec_counter + 1;
        end if;
    end procedure;
    
    -- Implementation of time elapsed check function
    function time_elapsed(
        seconds_value : seconds_counter_type;
        minutes_value : minutes_counter_type;
        target_seconds : integer;
        target_minutes : integer := 0
    ) return boolean is
    begin
        if (minutes_value > target_minutes) or 
           (minutes_value = target_minutes and seconds_value >= target_seconds) then
            return true;
        else
            return false;
        end if;
    end function;
end washing_machine_pkg;
