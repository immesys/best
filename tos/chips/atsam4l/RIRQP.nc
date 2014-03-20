
#include <ioport.h>

module RIRQP
{
    provides
    {
        interface GpioCapture as IRQ;
        interface Init as PlatformInit;
    }
    uses
    {
        interface LocalTime<T32khz> as clk;
    }
}
implementation
{
    void EIC_5_Handler(void) @C() @spontaneous()
    {
        REG_EIC_ICR = 1 << 5;
        signal IRQ.captured((uint16_t) (call clk.get()));
    }
    
    command error_t PlatformInit.init() @exactlyonce()
    {
        //The pin is PA20 (RIRQ)
        ioport_set_pin_mode(PIN_PA20C_EIC_EXTINT5, PINMUX_PA20C_EIC_EXTINT5);
	    ioport_disable_pin(PIN_PA20C_EIC_EXTINT5);
	
        //Enable the interrupt, but mask it off
        REG_EIC_IDR = 1 << 5;
        REG_EIC_EN = 1 << 5;
        
        //Line is edge triggered
        REG_EIC_MODE &= ~(1<<5);
         
        NVIC_SetPriority(EIC_5_IRQn, 1);
        NVIC_ClearPendingIRQ(EIC_5_IRQn);
        NVIC_EnableIRQ(EIC_5_IRQn);
        return SUCCESS;
    }
    
    async command void IRQ.disable()
    {
        REG_EIC_IDR = 1 << 5;
    }
    
    async command error_t IRQ.captureRisingEdge()
    {
        REG_EIC_EDGE |= (1<<5);
        REG_EIC_IER = 1 << 5;
        return SUCCESS;
    }
    
    default async event void IRQ.captured(uint16_t time)
    {}
    
    async command error_t IRQ.captureFallingEdge()
    {
        REG_EIC_EDGE &= ~(1<<5);
        REG_EIC_IER = 1 << 5;
        return SUCCESS;
    }
}
