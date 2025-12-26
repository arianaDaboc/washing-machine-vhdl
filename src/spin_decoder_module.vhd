----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/09/2025 01:52:32 PM
-- Design Name: 
-- Module Name: spin_decoder_module - Behavioral
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
use work.washing_machine_pkg.all;

entity spin_decoder_module is
    Port (
        spin_phase : in STD_LOGIC_VECTOR(1 downto 0);
        spin_outputs : out STD_LOGIC_VECTOR(3 downto 0)
    );
end spin_decoder_module;

architecture Behavioral of spin_decoder_module is
begin
    -- Simple decoder implementation
    with spin_phase select
        spin_outputs <=
            "0001" when "00",  -- Drain valve on, motor off at start
            "0011" when "01",  -- Drain valve on, motor on at full speed
            "0101" when "10",  -- Drain valve on, medium speed
            "0100" when "11",  -- Drain valve off, motor slowing down
            "0000" when others;
end Behavioral;

