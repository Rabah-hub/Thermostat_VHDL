library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity THERMO is

    port
    (
        CLK            : in std_logic;
        CURRENT_TEMP   : in std_logic_vector (6 downto 0);
        DESIRED_TEMP   : in std_logic_vector (6 downto 0);
        DISPLAY_SELECT : in std_logic;
        HEAT           : in std_logic;
        COOL           : in std_logic;
        AC_READY       : in std_logic;
        FURNACE_HOT    : in std_logic;
        TEMP_DISPLAY   : out std_logic_vector (6 downto 0);
        AC_ON          : out std_logic;
        FURNACE_ON     : out std_logic;
        FAN_ON         : out std_logic
    );

end THERMO;

------------------------------------------------------------------------------------------------------

architecture RTL of THERMO is

type STATE_TYPE is (IDLE,HEATON,FURNACENOWHOT,FURNACECOOL,
                    COOLON,ACNOWREADY,ACDONE);

signal state, next_state : STATE_TYPE;

signal CURRENT_TEMP_REG   : std_logic_vector(6 downto 0);
signal DESIRED_TEMP_REG   : std_logic_vector(6 downto 0);
signal DISPLAY_SELECT_REG : std_logic;
signal COOL_REG           : std_logic;
signal HEAT_REG           : std_logic;
signal AC_READY_REG       : std_logic;
signal FURNACE_HOT_REG    : std_logic;

signal COUNTDOWN          : std_logic_vector(4 downto 0);

begin

------------------------------------------------------------------------------------------------------

process(clk)
begin

    if clk'event and clk = '1' then
        CURRENT_TEMP_REG   <= CURRENT_TEMP;
        DESIRED_TEMP_REG   <= DESIRED_TEMP;
        DISPLAY_SELECT_REG <= DISPLAY_SELECT;
        HEAT_REG           <= HEAT;
        COOL_REG           <= COOL;
        AC_READY_REG       <= AC_READY;
        FURNACE_HOT_REG    <= FURNACE_HOT;
    end if;

end process;

------------------------------------------------------------------------------------------------------

process(clk)
begin

    if clk'event and clk='1' then

        if DISPLAY_SELECT_REG = '1' then
            TEMP_DISPLAY <= CURRENT_TEMP_REG;
        else
            TEMP_DISPLAY <= DESIRED_TEMP_REG;
        end if;

    end if;

end process;

------------------------------------------------------------------------------------------------------

process(clk)
begin

    if clk'event and clk='1' then
        state <= next_state;
    end if;

end process;

------------------------------------------------------------------------------------------------------

process(state, DESIRED_TEMP_REG, CURRENT_TEMP_REG, COOL_REG, AC_READY_REG,
        FURNACE_HOT_REG, HEAT_REG, countdown)

begin

    case(state) is

        when IDLE =>

            if (DESIRED_TEMP_REG > CURRENT_TEMP_REG) and HEAT_REG = '1' then
                next_state <= HEATON;

            elsif (DESIRED_TEMP_REG < CURRENT_TEMP_REG) and COOL_REG = '1' then
                next_state <= COOLON;

            else
                next_state <= IDLE;

            end if;


        when HEATON =>

            if FURNACE_HOT_REG = '1' then
                next_state <= FURNACENOWHOT;

            else
                next_state <= HEATON;

            end if;


        when FURNACENOWHOT =>

            if not((DESIRED_TEMP_REG > CURRENT_TEMP_REG) and HEAT_REG = '1') then
                next_state <= FURNACECOOL;

            else
                next_state <= FURNACENOWHOT;

            end if;


        when FURNACECOOL =>

            if FURNACE_HOT_REG = '0' and countdown = 0 then
                next_state <= IDLE;

            else
                next_state <= FURNACECOOL;

            end if;


        when COOLON =>

            if AC_READY_REG = '1' then
                next_state <= ACNOWREADY;

            else
                next_state <= COOLON;

            end if;


        when ACNOWREADY =>

            if not((DESIRED_TEMP_REG < CURRENT_TEMP_REG) and COOL_REG = '1') then
                next_state <= ACDONE;

            else
                next_state <= ACNOWREADY;

            end if;


        when ACDONE =>

            if AC_READY_REG = '0' and countdown = 0 then
                next_state <= IDLE;

            else
                next_state <= ACDONE;

            end if;


        when others =>

            next_state <= IDLE;

    end case;

end process;

------------------------------------------------------------------------------------------------------

process(clk)
begin

    if clk'event and clk = '1' then

        if next_state = HEATON or next_state = FURNACENOWHOT then
            FURNACE_ON <= '1';

        else
            FURNACE_ON <= '0';

        end if;


        if next_state = COOLON or next_state = ACNOWREADY then
            AC_ON <= '1';

        else
            AC_ON <= '0';

        end if;


        if next_state = FURNACENOWHOT or next_state = ACNOWREADY or
           next_state = FURNACECOOL or next_state = ACDONE then

            FAN_ON <= '1';

        else
            FAN_ON <= '0';

        end if;

    end if;

end process;

------------------------------------------------------------------------------------------------------

process(clk)
begin

    if clk'event and clk = '1' then

        if next_state = FURNACENOWHOT then

            countdown <= "01010";

        elsif next_state = ACNOWREADY then

            countdown <= "10100";

        elsif next_state = FURNACECOOL or next_state = ACDONE then

            countdown <= countdown - 1;

        end if;

    end if;

end process;


end rtl;
