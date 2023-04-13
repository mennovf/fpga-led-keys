----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.03.2023 15:49:31
-- Design Name: 
-- Module Name: sfixed_multiplier - Behavioral
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
library fixed;
use fixed.fixed_pkg.all;
use fixed.fixed_float_types.all;

package SFixedMultiplierInterface is 
    constant MULTIPLIER_B : positive := 6;
    constant MULTIPLIER_F : positive := 30;
    constant MULTIPLIER_LEFT : positive := MULTIPLIER_B - 1;
    constant MULTIPLIER_RIGHT : integer := -MULTIPLIER_F;
    constant MULTIPLIER_WIDTH : positive := MULTIPLIER_B + MULTIPLIER_F;
    subtype FP is sfixed(MULTIPLIER_LEFT downto MULTIPLIER_RIGHT);
    type FPArray is array (natural range <>) of FP;
    
    type MultAddInput is record
        a : FP;
        b : FP;
        c : FP;
        valid : std_ulogic;
    end record;
    
    type MultAddOutput is record
        ready : std_ulogic;       
        result : FP;
        valid : std_ulogic;
    end record;
    
    type MultAddInputArray is array (natural range <>) of MultAddInput;
    type MultAddOutputArray is array (natural range <>) of MultAddOutput;
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library fixed;
use fixed.fixed_pkg.all;
use fixed.fixed_float_types.all;

use work.SFixedMultiplierInterface.all;

entity sfixed_multiplier is
port (
    signal clk : in std_ulogic;
    signal ins : in MultAddInput;
    signal outs: out MultAddOutput := (ready => '0', result => (others => '0'), valid => '0')
);

end sfixed_multiplier;



architecture Behavioral of sfixed_multiplier is

constant IN_HIGH : positive := MULTIPLIER_B + MULTIPLIER_F - 1;

constant WIDTH : positive := 36;
constant HIGH : positive := WIDTH - 1;
constant RHIGH : positive := 2*WIDTH + 1 - 1;
signal eA : std_ulogic_vector(HIGH downto 0);
signal eB : std_ulogic_vector(HIGH downto 0);
signal eC : std_ulogic_vector(IN_HIGH + MULTIPLIER_F downto 0);


signal eP : std_ulogic_vector(RHIGH downto 0);
signal enable : std_ulogic := '0';

signal ulv_A : std_ulogic_vector(IN_HIGH downto 0);
signal ulv_B : std_ulogic_vector(IN_HIGH downto 0);
signal ulv_C : std_ulogic_vector(IN_HIGH downto 0);

begin

outs.result <= to_sfixed(eP(IN_HIGH + MULTIPLIER_F downto MULTIPLIER_F), MULTIPLIER_LEFT, MULTIPLIER_RIGHT);

ulv_A <= to_sulv(ins.A);
eA <= (IN_HIGH downto 0 => ulv_A, others => ins.A(MULTIPLIER_LEFT));

ulv_B <= to_sulv(ins.B);
eB <= (IN_HIGH downto 0 => ulv_B, others => ins.B(MULTIPLIER_LEFT));

ulv_C <= to_sulv(ins.C);
eC <= (IN_HIGH + MULTIPLIER_F downto MULTIPLIER_F => ulv_C, others => '0');


multiplier : entity work.multadd
  port map (
    CLK => clk,
    CE => enable,
    SCLR => '0',
    A => eA,
    B => eB,
    C => (IN_HIGH + MULTIPLIER_F downto 0 => eC, others => ins.C(MULTIPLIER_LEFT)),
    SUBTRACT => '0',
    P => eP
);

controller : process(clk)
constant LATENCY : positive := 12;
variable counter : natural range 0 to LATENCY := 0;

begin

    outs.ready <= '1' when counter = 0 else '0';

    if rising_edge(clk) then
        outs.valid <= '0';
        if counter = 0 and ins.valid = '1' then
            enable <= '1';
            counter := 1;
        end if;
        
        if counter = LATENCY then
            counter := 0;
            outs.valid <= '1';
        else
            counter := counter + 1;
        end if;
    end if;
end process;

end Behavioral;
