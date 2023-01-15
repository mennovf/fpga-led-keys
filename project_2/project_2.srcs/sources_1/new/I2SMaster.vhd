----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.12.2022 19:18:05
-- Design Name: 
-- Module Name: I2SMaster - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2SMaster is
    Port ( clk : in STD_LOGIC;
           din : in STD_LOGIC;
           data_ready : out STD_LOGIC  := '0'; -- High for a single clk cycle
           dout : out signed (31 downto 0) := (others=>'0');
           ws : out STD_LOGIC := '0';
           clk_out : out STD_LOGIC := '0';
           data_channel : out std_ulogic := '0');
end I2SMaster;

architecture Behavioral of I2SMaster is
signal i2sclk : std_logic := '0';
signal i2sclk_d : std_logic := '0';
signal i2sclk_fe : std_logic;
signal wsinternal : std_logic := '0';
signal shift : signed (31 downto 0);
signal ws_changed : std_logic := '0'; --One extra clock of latency
signal data_ready_internal : std_logic := '0';
begin

-- Generate a 2.5MHz clock for the I2S device
generate_clk: process (clk)
variable counter : natural range 0 to 39 := 0;
begin
    if rising_edge(clk) then
        if counter = 39 then
            counter := 0;
            i2sclk <= '0';
        else
            if counter = 19 then
                i2sclk <= '1';
            end if;
            counter := counter + 1;
        end if;
    end if;
end process;

generate_ws: process(clk)
variable counter : natural range 0 to 31 := 0;
begin
    if rising_edge(clk) then
        if i2sclk_fe = '1' then
            if counter = 31 then
                counter := 0;
                wsinternal <= not wsinternal;
                
                -- Set ws_changed signal on the falling edge of the ws
                ws_changed <= '1';
            else
                if counter = 0 then
                    ws_changed <= '0';
                end if;
                counter := counter + 1;
            end if;
        end if;
    end if;
end process;

din_shift: process(clk)
variable shifting : boolean := false;
begin
    if rising_edge(clk) then
        if i2sclk_fe = '1' then
            if wsinternal = '0' then
                -- This will start one falling edge AFTER wsinternal has been set to low.
                -- This is because it takes one rising_edge(clk) for wsinternal <= '0' to propagate to this process
                -- Once it has propagated, i2sclk_fe is no longer ='1' and we'll have to wait until the next i2sclk_fe
                shift <= shift(30 downto 0) & din;
            end if;
            
            if ws_changed = '1' then
                dout <= shift;
                data_ready_internal <= '1';
                data_channel <= not wsinternal;
            end if;
        end if;
        
                    
        if data_ready_internal = '1' then
            data_ready_internal <= '0';
        end if;
    end if;
end process;

clk_out <= i2sclk;
ws <= wsinternal;
data_ready <= data_ready_internal;

i2sclk_d <= i2sclk when rising_edge(clk);
i2sclk_fe <= i2sclk_d and not i2sclk;

end Behavioral;
