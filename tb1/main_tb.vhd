library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.washing_machine_pkg.all;

entity tb_main is
end tb_main;

architecture sim of tb_main is

    -- Inputs
    signal clk              : STD_LOGIC := '0';
    signal reset            : STD_LOGIC := '1';
    signal start_btn        : STD_LOGIC := '0';
    signal door_closed      : STD_LOGIC := '0';
    signal mode_auto        : STD_LOGIC := '1';
    signal preset_sel       : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal temp_sel         : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal speed_sel        : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal prewash_btn      : STD_LOGIC := '0';
    signal extra_rinse_btn  : STD_LOGIC := '0';
    signal config_saved     : STD_LOGIC := '0';

    -- Outputs
    signal ssd_display      : STD_LOGIC_VECTOR(7 downto 0);
    signal state_leds       : STD_LOGIC_VECTOR(3 downto 0);

    constant clk_period : time := 10 ns;

    -- Instantiate the Unit Under Test (UUT)
    component main is
        Port (
            clk              : in  STD_LOGIC;
            reset            : in  STD_LOGIC;
            start_btn        : in  STD_LOGIC;
            door_closed      : in  STD_LOGIC;
            mode_auto        : in  STD_LOGIC;
            preset_sel       : in  STD_LOGIC_VECTOR(2 downto 0);
            temp_sel         : in  STD_LOGIC_VECTOR(1 downto 0);
            speed_sel        : in  STD_LOGIC_VECTOR(1 downto 0);
            prewash_btn      : in  STD_LOGIC;
            extra_rinse_btn  : in  STD_LOGIC;
            config_saved     : in  STD_LOGIC;
            ssd_display      : out STD_LOGIC_VECTOR(7 downto 0);
            state_leds       : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Instantiate main module
    uut: main
        port map (
            clk => clk,
            reset => reset,
            start_btn => start_btn,
            door_closed => door_closed,
            mode_auto => mode_auto,
            preset_sel => preset_sel,
            temp_sel => temp_sel,
            speed_sel => speed_sel,
            prewash_btn => prewash_btn,
            extra_rinse_btn => extra_rinse_btn,
            config_saved => config_saved,
            ssd_display => ssd_display,
            state_leds => state_leds
        );

    -- Stimulus process
    stim_proc: process
    begin
        wait for 20 ns;
        reset <= '0';

        -- Try to start with default config
        wait for 20 ns;
        start_btn <= '1';
        wait for 10 ns;
        start_btn <= '0';

        -- Simulate setting temp and speed in manual mode
        wait for 50 ns;
        mode_auto <= '0';
        temp_sel <= "10";
        speed_sel <= "01";
        prewash_btn <= '1';
        extra_rinse_btn <= '1';
        config_saved <= '1';
        wait for 20 ns;
        config_saved <= '0';

        -- Start washing
        wait for 40 ns;
        start_btn <= '1';
        wait for 10 ns;
        start_btn <= '0';

        wait for 200 ns;

        -- End simulation
        wait;
    end process;

end sim;