-- Archit Jaiswal
-- Entity: kernel Buffer 128 elements (16 bit each)
--         It is basically just the inverted version of signal buffer

-- Functionality: 

-- It reads the inputs from the memory map. The software that interfaces with the memory map will give it a padded kernel signal, so there is not need to add any extra zeros to it. 

-- Just read the inputs from memory map as it is and flip the elements such that the last element becomes the first element and so on. 

-- Then just output the 128 bits the way signal buffer does. 

----------------------------------------------------------------------------------

---------------------- KERNEL BUFFER Entity --------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity kernel_buffer is
    generic (NUM_ELEMENTS: integer          := 128; -- Number of elements in the buffer
             WIDTH:        integer          := 16;
             RESET_VALUE:  std_logic_vector := ""); -- Number of bits in each element
    port ( 
        clk : in std_logic;
        rst : in std_logic;
        -- rd_en  : in std_logic;  -- reading data will decrement the counter and assert EMPTY flag, so NOT needed
        wr_en  : in std_logic;  -- writes new data, until FULL flag is asserted
        wr_data : in std_logic_vector(WIDTH-1 downto 0); -- INPUT DATA | coming from the FIFO
        rd_data : out std_logic_vector(NUM_ELEMENTS*WIDTH-1 downto 0); -- OUTPUT DATA | going to the pipeline/datapath to compute the 1D convolution
        empty : out std_logic;
        full : out std_logic
    );
end kernel_buffer;

architecture BHV of kernel_buffer is

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
    end component; -- Need to flip the output because kernel elements should be reversed as it goes to the pipeline

    signal signal_buffer_output_vector : std_logic_vector(rd_data'range); -- Stores the unreversed output from signal_buffer

    type window is array(0 to NUM_ELEMENTS-1) of std_logic_vector(WIDTH-1 downto 0);
    signal data_array : window; -- Creating an instance of array

begin

    U_SIGNAL_BUFFER: signal_buffer
    generic map(
        NUM_ELEMENTS => NUM_ELEMENTS,
        WIDTH        => WIDTH)
    port map(
        clk     => clk,
        rst     => rst,
        rd_en   => '0', -- because once the data is loaded it does not changes, so the full will always remain asserted
        wr_en   => wr_en,
        wr_data => wr_data,
        rd_data => signal_buffer_output_vector,
        empty   => empty,
        full    => full
    );

      -- convert input vectors into arrays of data
    U_DEVECTORIZE : for i in 0 to NUM_ELEMENTS-1 generate
        data_array((NUM_ELEMENTS-1) - i) <= signal_buffer_output_vector((i+1)*WIDTH-1 downto i*WIDTH);
    end generate;

    -- put pipeline inputs into a big vector (i.e., "vectorize")
    U_VECTORIZE : for i in 0 to NUM_ELEMENTS-1 generate
        rd_data((i+1)*WIDTH-1 downto i*WIDTH) <= data_array(i);
    end generate;

end BHV;


