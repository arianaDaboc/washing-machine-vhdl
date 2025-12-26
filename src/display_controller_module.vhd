-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/09/2025 01:52:32 PM
-- Design Name: 
-- Module Name: display_controller_module - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.washing_machine_pkg.all;

entity display_controller_module is
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
end display_controller_module;

architecture Behavioral of display_controller_module is
    -- Convert integer to SSD code
    function int_to_ssd(val : integer) return STD_LOGIC_VECTOR is
    begin
        return std_logic_vector(to_unsigned(val, 8));
    end function;
    
begin
    -- Display output process
    process(current_state, selected_temp, selected_speed, prewash_enabled, 
            extra_rinse_enabled, remaining_time, washing_substate, mode_auto, preset_sel)
    begin
        case current_state is
            when IDLE =>
                state_leds <= "0000";
                ssd_display <= (others => '0');
                
            when MODE_SELECT =>
                state_leds <= "0001";
                ssd_display <= "00000001";  -- Display '1'
                
            when CHECK_MODE =>
                state_leds <= "0010";
                if mode_auto = '1' then
                    ssd_display <= "00001010";  -- Display 'A' for auto
                else
                    ssd_display <= "00001101";  -- Display 'M' for manual
                end if;
                
            when AUTO_PRESET =>
                state_leds <= "0011";
                -- Display the preset number (1-5)
                case preset_sel is
                    when "000" => ssd_display <= "00000001";  -- 1
                    when "001" => ssd_display <= "00000010";  -- 2
                    when "010" => ssd_display <= "00000011";  -- 3
                    when "011" => ssd_display <= "00000100";  -- 4
                    when "100" => ssd_display <= "00000101";  -- 5
                    when others => ssd_display <= "00000000";  -- 0
                end case;
                
            when MANUAL_TEMP =>
                state_leds <= "0100";
                -- Display temperature
                case selected_temp is
                    when "00" => ssd_display <= "00110000";  -- '30' (simplified)
                    when "01" => ssd_display <= "01000000";  -- '40' (simplified)
                    when "10" => ssd_display <= "01100000";  -- '60' (simplified)
                    when "11" => ssd_display <= "10010000";  -- '90' (simplified)
                    when others => ssd_display <= "00000000";
                end case;
                
            when MANUAL_SPEED =>
                state_leds <= "0101";
                -- Display speed
                case selected_speed is
                    when "00" => ssd_display <= "10000000";  -- '800' (simplified)
                    when "01" => ssd_display <= "00010000";  -- '1000' (simplified)
                    when "10" => ssd_display <= "00100000";  -- '1200' (simplified)
                    when others => ssd_display <= "00000000";
                end case;
                
            when MANUAL_OPTIONS =>
                state_leds <= "0110";
                -- Display options (P for prewash, r for rinse, b for both)
                if prewash_enabled = '1' and extra_rinse_enabled = '1' then
                    ssd_display <= "00001011";  -- 'b' for both
                elsif prewash_enabled = '1' then
                    ssd_display <= "00010000";  -- 'P' for prewash
                elsif extra_rinse_enabled = '1' then
                    ssd_display <= "00010010";  -- 'r' for rinse
                else
                    ssd_display <= "00000000";  -- No options
                end if;
                
            when READY =>
                state_leds <= "0111";
                ssd_display <= int_to_ssd(remaining_time);
                
            when WASHING =>
                state_leds <= "1000";
                -- Show remaining time and indicate current washing phase
                if remaining_time > 0 then
                    ssd_display <= int_to_ssd(remaining_time);
                else
                    -- If time runs out, show washing phase
                    case washing_substate is
                        when FILL_WATER => ssd_display <= "00000001";
                        when PRE_WASH => ssd_display <= "00000010";
                        when HEAT_WATER => ssd_display <= "00000011";
                        when MAIN_WASH => ssd_display <= "00000100";
                        when RINSE => ssd_display <= "00000101";
                        when EXTRA_RINSE => ssd_display <= "00000110";
                        when SPIN => ssd_display <= "00000111";
                        when COMPLETE => ssd_display <= "00001000";
                        when others => ssd_display <= "00000000";
                    end case;
                end if;
                
            when others =>
                state_leds <= "1111";
                ssd_display <= (others => '1');
        end case;
    end process;
    
end Behavioral;
