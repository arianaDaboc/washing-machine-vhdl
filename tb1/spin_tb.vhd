library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.washing_machine_pkg.all;  -- If your module depends on this package

entity tb_spin_decoder_module is
-- Testbench has no ports
end tb_spin_decoder_module;

architecture Behavioral of tb_spin_decoder_module is
    -- Component declaration for the Unit Under Test (UUT)
    component spin_decoder_module
        Port (
            spin_phase : in STD_LOGIC_VECTOR(1 downto 0);
            spin_outputs : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    -- Signals to connect to UUT
    signal spin_phase : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal spin_outputs : STD_LOGIC_VECTOR(3 downto 0);

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: spin_decoder_module
        Port map (
            spin_phase => spin_phase,
            spin_outputs => spin_outputs
        );

    -- Stimulus process
    stimulus_proc: process
    begin
        -- Apply all spin_phase combinations with some delay
        spin_phase <= "00";
        wait for 20 ns;

        spin_phase <= "01";
        wait for 20 ns;

        spin_phase <= "10";
        wait for 20 ns;

        spin_phase <= "11";
        wait for 20 ns;

        spin_phase <= "XX";  -- invalid, just to test others
        wait for 20 ns;

        -- Finish simulation
        wait;
    end process;

end Behavioral;
