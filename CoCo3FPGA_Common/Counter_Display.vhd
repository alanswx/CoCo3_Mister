--------------------------------------------------------------------
--  Data Display Counters
--  Filename:Counter_Display.vhd
--  Written By: Stan Hodge
--
-- Initial release.
--
-- License:
-- This code can be freely distributed and modified as long as
-- this header is not removed.
--------------------------------------------------------------------

library IEEE, UNISIM;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity Counter_Display is
  port(
    -- host side
    clk, n_reset         : in  std_logic;  -- master clock
    counter_item         : in  std_logic;  -- true [edge detection]
    Digit4,Digit3        : out std_logic_vector(6 downto 0);
    Digit2,Digit1        : out std_logic_vector(6 downto 0)
    );
end Counter_Display;



architecture arch of Counter_Display is

    signal event: std_logic_vector(15 downto 0);
    signal time_out: std_logic_vector(27 downto 0);
	signal count_edge, time_out_expire, D1, D2, b1, b2, b3, b4, timer_run:std_logic;
	 
    constant    time_out_value:std_logic_vector(27 downto 0):="1011111010111100001000000000"; -- 200,000,000 [4 secs]

begin

--  Pos Edge
    count_edge <=   			'1' when D1 = '1' and D2 = '0' else
									'0';            

    time_out_expire <=     '1' when time_out > time_out_value else
									'0';

    Digit4 <=   "1111111"   when b4 = '1'                       else
                "1000000"   when event(15 downto 12) = "0000"   else
                "1111001"   when event(15 downto 12) = "0001"   else
                "0100100"   when event(15 downto 12) = "0010"   else
                "0110000"   when event(15 downto 12) = "0011"   else
                "0011001"   when event(15 downto 12) = "0100"   else
                "0010010"   when event(15 downto 12) = "0101"   else
                "0000010"   when event(15 downto 12) = "0110"   else
                "1111000"   when event(15 downto 12) = "0111"   else
                "0000000"   when event(15 downto 12) = "1000"   else
                "0011000"   when event(15 downto 12) = "1001"   else
                "0001000"   when event(15 downto 12) = "1010"   else
                "0000011"   when event(15 downto 12) = "1011"   else
                "1000110"   when event(15 downto 12) = "1100"   else
                "0100001"   when event(15 downto 12) = "1101"   else
                "0000110"   when event(15 downto 12) = "1110"   else
                "0001110";

    Digit3 <=   "1111111"   when b3 = '1'                       else
                "1000000"   when event(11 downto 8) = "0000"   else
                "1111001"   when event(11 downto 8) = "0001"   else
                "0100100"   when event(11 downto 8) = "0010"   else
                "0110000"   when event(11 downto 8) = "0011"   else
                "0011001"   when event(11 downto 8) = "0100"   else
                "0010010"   when event(11 downto 8) = "0101"   else
                "0000010"   when event(11 downto 8) = "0110"   else
                "1111000"   when event(11 downto 8) = "0111"   else
                "0000000"   when event(11 downto 8) = "1000"   else
                "0011000"   when event(11 downto 8) = "1001"   else
                "0001000"   when event(11 downto 8) = "1010"   else
                "0000011"   when event(11 downto 8) = "1011"   else
                "1000110"   when event(11 downto 8) = "1100"   else
                "0100001"   when event(11 downto 8) = "1101"   else
                "0000110"   when event(11 downto 8) = "1110"   else
                "0001110";

    Digit2 <=   "1111111"   when b2 = '1'                       else
                "1000000"   when event(7 downto 4) = "0000"   else
                "1111001"   when event(7 downto 4) = "0001"   else
                "0100100"   when event(7 downto 4) = "0010"   else
                "0110000"   when event(7 downto 4) = "0011"   else
                "0011001"   when event(7 downto 4) = "0100"   else
                "0010010"   when event(7 downto 4) = "0101"   else
                "0000010"   when event(7 downto 4) = "0110"   else
                "1111000"   when event(7 downto 4) = "0111"   else
                "0000000"   when event(7 downto 4) = "1000"   else
                "0011000"   when event(7 downto 4) = "1001"   else
                "0001000"   when event(7 downto 4) = "1010"   else
                "0000011"   when event(7 downto 4) = "1011"   else
                "1000110"   when event(7 downto 4) = "1100"   else
                "0100001"   when event(7 downto 4) = "1101"   else
                "0000110"   when event(7 downto 4) = "1110"   else
                "0001110";

    Digit1 <=   "1111111"   when b1 = '1'                       else
                "1000000"   when event(3 downto 0) = "0000"   else
                "1111001"   when event(3 downto 0) = "0001"   else
                "0100100"   when event(3 downto 0) = "0010"   else
                "0110000"   when event(3 downto 0) = "0011"   else
                "0011001"   when event(3 downto 0) = "0100"   else
                "0010010"   when event(3 downto 0) = "0101"   else
                "0000010"   when event(3 downto 0) = "0110"   else
                "1111000"   when event(3 downto 0) = "0111"   else
                "0000000"   when event(3 downto 0) = "1000"   else
                "0011000"   when event(3 downto 0) = "1001"   else
                "0001000"   when event(3 downto 0) = "1010"   else
                "0000011"   when event(3 downto 0) = "1011"   else
                "1000110"   when event(3 downto 0) = "1100"   else
                "0100001"   when event(3 downto 0) = "1101"   else
                "0000110"   when event(3 downto 0) = "1110"   else
                "0001110";


    process(clk, n_reset)
    begin
    if clk'event and clk='1' then
--      Edge Detection
        D1 <= counter_item;
        D2 <= D1;

        if timer_run = '1' then
            time_out <= time_out + '1';
        end if;

        if count_edge = '1' then
            event <= event + '1';
            timer_run <= '1';
            time_out <= (others => '0');
        end if;

        if time_out_expire = '1' then
            event <= (others => '0');
            time_out <= (others => '0');
            timer_run <= '0';
        end if;

--      Blanking
        if event(15 downto 12) = "0000" then
            b4 <= '1';
            if event(11 downto 8) = "0000" then
                b3 <= '1';
                if event(7 downto 4) = "0000" then
                    b2 <= '1';
                    if event(3 downto 0) = "0000" then
                        b1 <= '1';
                    else
                        b1 <= '0';
                    end if;
                 else
                    b2 <= '0';
                 end if;
            else
                b3 <= '0';
            end if;
        else
            b4 <= '0';
        end if;

    end if;

    if n_reset = '0' then
        event <= (others => '0');
        time_out <= (others => '0');
        timer_run <= '0';
        D1 <= '0';
        D2 <= '0';
        b4 <= '1';
        b3 <= '1';
        b2 <= '1';
        b1 <= '1';
    end if;
    end process;

end arch;
