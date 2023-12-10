-- Archit Jaiswal
-- Convolve pipeline testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.math_custom.all;



entity convolve_tb is
end entity convolve_tb;

architecture tb_arch of convolve_tb is

    component mult_add_pipeline is 
        generic (NUM_ELEMENTS: integer; -- Number of elements in the buffer
                 IN1_WIDTH:    integer;
                 IN2_WIDTH:    integer); -- Number of bits in each element
    
        port(
            -- Signal buffer pins
            sig_rd_en   : in std_logic;  -- Acknowledge the read from bufferr
            sig_wr_en   : in std_logic;  -- Allow to write new data
            sig_wr_data : in std_logic_vector(IN1_WIDTH-1 downto 0);
            sig_empty   : out std_logic; 
            sig_full    : out std_logic;
    
            -- Kernel buffer pins
            kernel_wr_en   : in std_logic;  -- Allow to write new data
            kernel_wr_data : in std_logic_vector(IN2_WIDTH-1 downto 0); 
            kernel_empty   : out std_logic; 
            kernel_full    : out std_logic;
    
            -- Mult add pipeline pins
            clk       : in  std_logic;
            rst       : in  std_logic;
            en        : in  std_logic;
            valid_in  : in std_logic;
            valid_out : out std_logic;
            -- input1    : in  std_logic_vector(NUM_ELEMENTS*IN1_WIDTH-1 downto 0);
            -- input2    : in  std_logic_vector(NUM_ELEMENTS*IN2_WIDTH-1 downto 0);
            output    : out std_logic_vector(IN1_WIDTH+IN2_WIDTH+clog2(NUM_ELEMENTS)-1 downto 0)
        );
    end component;

    -- Constants
    constant NUM_ELEMENTS : integer := 5;
    constant IN1_WIDTH    : integer := 16;
    constant IN2_WIDTH    : integer := 16;

    -- Signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal clk_en    : std_logic := '1';
    signal sig_wr_en : std_logic := '0';
    signal sig_rd_en : std_logic := '0';
    signal ker_wr_en : std_logic := '0';
    signal valid_in       : std_logic;   
    signal valid_out_flag : std_logic;

    signal input1 : std_logic_vector (IN1_WIDTH-1 downto 0); -- signal buffer input
    signal input2 : std_logic_vector (IN2_WIDTH-1 downto 0); -- kernel buffer input
    signal pipeline_enble : std_logic;

    signal sig_full_flag : std_logic;
    signal ker_full_flag : std_logic;
    signal sig_empty_flag : std_logic;
    signal ker_empty_flag : std_logic;
    signal output : std_logic_vector(IN1_WIDTH+IN2_WIDTH+clog2(NUM_ELEMENTS)-1 downto 0);

begin

    -- Define CLK = 10 ns
    clk <= not clk and clk_en after 5 ns;

    -- DESIGN UNDER TEST
    DUT: mult_add_pipeline
        generic map(
            NUM_ELEMENTS => NUM_ELEMENTS,
            IN1_WIDTH    => IN1_WIDTH,
            IN2_WIDTH    => IN2_WIDTH
        )
        port map(

            -- Signal buffer pins
            sig_rd_en   => sig_rd_en,
            sig_wr_en   => sig_wr_en,
            sig_wr_data => input1,
            sig_empty   => sig_empty_flag,
            sig_full    => sig_full_flag,

            -- Kernel buffer pins
            kernel_wr_en   => ker_wr_en,
            kernel_wr_data => input2,
            kernel_empty   => ker_empty_flag,
            kernel_full    => ker_full_flag,

            -- Mult add pipeline pins
            clk       => clk,
            rst       => rst,
            en        => pipeline_enble,
            valid_in  => valid_in,
            valid_out => valid_out_flag,
            -- input1    => input1,
            -- input2    => input2,
            output    => output
        );

    -- pipeline is ready when it gets valid data for inputs
    valid_in <= sig_full_flag and not ker_empty_flag;
    pipeline_enble <= valid_in;

--- Load signal buffer --------------------------------------------------------------------
    process 
    begin

        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        rst <= '0';
        wait until rising_edge(clk);
        
        sig_wr_en <= '1';
        for i in 0 to 2*NUM_ELEMENTS+2 loop 
            wait until rising_edge(clk);
        end loop;

        -- wr_en <= '0';

        for i in 0 to 2*NUM_ELEMENTS+5 loop
            wait until rising_edge(clk);
        end loop;

        clk_en <= '0'; -- Stop the clock
        report "Done writing to signal buffer.";
        wait;

    end process;

    process(sig_full_flag)
    begin
        if (rising_edge(sig_full_flag)) then
            report "signal buff is full";
        end if;
    end process;

---------------------------------------------------------------------------------------------

--- Load kernel buffer --------------------------------------------------------------------
    process 
    begin

        -- rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- rst <= '0';
        wait until rising_edge(clk);
        
        ker_wr_en <= '1';
        for i in 0 to 2*NUM_ELEMENTS+2 loop 
            wait until rising_edge(clk);
        end loop;

        -- wr_en <= '0';

        for i in 0 to 2*NUM_ELEMENTS+5 loop
            wait until rising_edge(clk);
        end loop;

    end process;

    process(ker_full_flag)
    begin
        if (rising_edge(ker_full_flag)) then
            report "kernel buff is full";
        end if;
    end process;

---------------------------------------------------------------------------------------------

    -- Write inputs to both signal and kernel buffer
    process
        variable i : unsigned(IN1_WIDTH-1 downto 0) := (others => '0');
    begin

        -- input1 <= std_logic_vector(i); 
        -- input2 <= std_logic_vector(i+3);
        input1 <= (others => '0'); 
        input2 <= (others => '0');
        -- i := i + 1;

        if (clk_en = '0') then
            wait;
        end if;
        wait until rising_edge(clk);
    end process;


end tb_arch;