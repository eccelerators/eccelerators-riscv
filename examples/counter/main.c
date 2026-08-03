#define UART_TX_ADDRESS 0x40000000u

int main(void)
{
    unsigned char value = 0u;

    while (value < 16u)
    {
        *(volatile unsigned char *)UART_TX_ADDRESS = value;
        value = value + 1u;
    }

    return 0;
}
