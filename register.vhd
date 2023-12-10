-- Archit Jaiswal
-- Entity: Register 

----------------------- REGISTER ENTITY ------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg is
    generic (WIDTH: integer := 16); -- Number of bits in the register | default : 16 bits
    port (
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        input : in std_logic_vector(WIDTH-1 downto 0);
        output : out std_logic_vector(WIDTH-1 downto 0)
        );
end reg;

architecture BHV of reg is 
begin
    process (clk, rst)
    begin
        if (rst = '1') then
            output <= (others => '0');
        elsif (rising_edge(clk)) then
            if (en = '1') then
                output <= input;
            end if;
        end if;
    end process;
end BHV;
----------------------------------------------------------------------------------