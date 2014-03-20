
module TimingP
{
    provides interface Init;
}
implementation
{
    command error_t Init.init()
    {
        SysTick->LOAD = 0xFFFF;
        SysTick->CTRL = 5; //enable clk src=proc, enabled
        return SUCCESS;
    }
}
