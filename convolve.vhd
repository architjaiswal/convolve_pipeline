-- Archit Jaiswal
-- Entity: Mult_add_pipeline
--         It takes the input from kernel buffer and signal buffer, then passes it to the multiply-add pipeline

-- Functionality: 

-- Just instantiates kernel buffer and signal buffer.
-- Takes inputs from both and multiples the corresponding pairs of elements
-- Then it adds the multiplied elements

----------------------------------------------------------------------------------


---------------------- MULT_ADD_PIPELINE Entity --------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;


entity mult_add_pipeline is 
    generic (NUM_ELEMENTS: integer          := 128; -- Number of elements in the buffer
             IN1_WIDTH:    integer          := 16;  -- Signal buffer width
             IN2_WIDTH:    integer          := 16); -- Kernel buffer width

    port(
        -- Signal buffer pins
        sig_rd_en   : in std_logic;  -- Acknowledge the read from bufferr
        sig_wr_en   : in std_logic;  -- Allow to write new data
        sig_wr_data : in std_logic_vector(IN1_WIDTH-1 downto 0); -- INPUT element (16 bits)
        sig_empty   : out std_logic; 
        sig_full    : out std_logic;

        -- Kernel buffer pins
        kernel_wr_en   : in std_logic;  -- Allow to write new data
        kernel_wr_data : in std_logic_vector(IN2_WIDTH-1 downto 0); -- INPUT element (16 bits)
        kernel_empty   : out std_logic; 
        kernel_full    : out std_logic;

        -- Mult add pipeline pins
        clk       : in  std_logic;
        rst       : in  std_logic;
        en        : in  std_logic;
        valid_in  : in std_logic;
        -- input1    : in  std_logic_vector(NUM_ELEMENTS*IN1_WIDTH-1 downto 0);
        -- input2    : in  std_logic_vector(NUM_ELEMENTS*IN2_WIDTH-1 downto 0);
        valid_out : out std_logic;
        output    : out std_logic_vector(IN1_WIDTH+IN2_WIDTH+clog2(NUM_ELEMENTS)-1 downto 0)
    );
end mult_add_pipeline;

architecture BHV of mult_add_pipeline is

    -- COMPONENT DECLARATION
    component delay
        generic(CYCLES : natural;
                WIDTH  : positive);
        port(
            clk    : in  std_logic;
            rst    : in  std_logic;
            en     : in  std_logic;
            input  : in  std_logic_vector(WIDTH-1 downto 0);
            output : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    component signal_buffer
        generic (NUM_ELEMENTS: integer; -- Number of elements in the buffer
                 WIDTH:        integer;
                 RESET_VALUE:  std_logic_vector := ""); -- Number of bits in each element
        port ( 
            clk     : in std_logic;
            rst     : in std_logic;
            rd_en   : in std_logic;  -- Acknowledge the read from bufferr
            wr_en   : in std_logic;  -- Allow to write new data
            wr_data : in std_logic_vector(WIDTH-1 downto 0); -- INPUT element (16 bits)
            rd_data : out std_logic_vector(NUM_ELEMENTS*WIDTH-1 downto 0); -- OUTPUT vector (all elements) 
            empty   : out std_logic; 
            full    : out std_logic
        );
    end component;

    component kernel_buffer 
        generic (NUM_ELEMENTS: integer; -- Number of elements in the buffer
                 WIDTH:        integer;
                 RESET_VALUE:  std_logic_vector := ""); 
        port ( 
            clk : in std_logic;
            rst : in std_logic;
            wr_en  : in std_logic;
            wr_data : in std_logic_vector(WIDTH-1 downto 0);
            rd_data : out std_logic_vector(NUM_ELEMENTS*WIDTH-1 downto 0);
            empty : out std_logic;
            full : out std_logic
        );
    end component;

    component mult_add_tree is
        generic (
            num_inputs   : positive;
            input1_width : positive;
            input2_width : positive);
        port (
            clk    : in  std_logic;
            rst    : in  std_logic;
            en     : in  std_logic;
            input1 : in  std_logic_vector(num_inputs*input1_width-1 downto 0);
            input2 : in  std_logic_vector(num_inputs*input2_width-1 downto 0);
            output : out std_logic_vector(input1_width+input2_width+clog2(num_inputs)-1 downto 0)
        );
    end component;

    -- WIRE DECLARATION
    constant MULT_ADD_LATENCY : integer := clog2(NUM_ELEMENTS)+1;
    signal signal_buff_output : std_logic_vector(NUM_ELEMENTS*IN1_WIDTH-1 downto 0);
    signal kernel_buff_output : std_logic_vector(NUM_ELEMENTS*IN2_WIDTH-1 downto 0);

begin

    U_DELAY: delay
        generic map(
            WIDTH  => 1,
            CYCLES => MULT_ADD_LATENCY
        )
        port map(
            clk    => clk,
            rst    => rst,
            en     => en,
            input(0)  => valid_in,
            output(0) => valid_out
        );

    U_SIGNAL_BUFFER: signal_buffer
        generic map(
            NUM_ELEMENTS => NUM_ELEMENTS,
            WIDTH        => IN1_WIDTH)
        port map(
            clk     => clk,
            rst     => rst,
            rd_en   => sig_rd_en,
            wr_en   => sig_wr_en,
            wr_data => sig_wr_data,
            rd_data => signal_buff_output,
            empty   => sig_empty,
            full    => sig_full
        );

    U_KERNEL_BUFF : kernel_buffer
        generic map (
            NUM_ELEMENTS => NUM_ELEMENTS,
            WIDTH        => IN2_WIDTH)
        port map (
            clk      => clk,
            rst      => rst,
            wr_en    => kernel_wr_en,
            wr_data  => kernel_wr_data,
            rd_data  => kernel_buff_output,
            empty    => kernel_empty,
            full     => kernel_full
        );

    U_MULT_ADD_TREE: mult_add_tree
        generic map (
            num_inputs   => NUM_ELEMENTS,
            input1_width => IN1_WIDTH,
            input2_width => IN2_WIDTH)
        port map(
            clk    => clk,
            rst    => rst,
            en     => en,
            input1 => signal_buff_output,
            input2 => kernel_buff_output,
            output => output
        );


end BHV;