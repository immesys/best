#include <ioport.h>
#include <bldebug.h>

module ScreenP
{
    provides
    {
        interface Init;
        interface Screen;
    }
}
implementation
{
    
    //Screen IO pins:
    // Parallel data: PC16 - PC31
    // LCD_GFX_CS   : 
    // LCD_RS       : PB11 
    // LCD_WR       : DCTL2 : PA16 (manual rewire needed)
    // LCD_RD       : PC9
    // LCD_RESET    : PB13
    
    GpioPort *gpC = (GpioPort*) GPIO_PORT_C_ADDR;
    GpioPort *gpB = (GpioPort*) GPIO_PORT_B_ADDR;
    GpioPort *gpA = (GpioPort*) GPIO_PORT_A_ADDR;
    
    uint16_t *pardat = (uint16_t*) (GPIO_PORT_C_ADDR + 0x52);
    inline void set_RS() {gpB->GPIO_OVRS = (1<<11);}
    inline void clr_RS() {gpB->GPIO_OVRC = (1<<11);}
    inline void set_WR() {gpA->GPIO_OVRS = (1<<16);}
    inline void clr_WR() {gpA->GPIO_OVRC = (1<<16);}
    inline void set_RD() {gpC->GPIO_OVRS = (1<<9);}
    inline void clr_RD() {gpC->GPIO_OVRC = (1<<9);}
    
    bool flip = FALSE;
    task void test_iterate()
    {
        //set_RS();
        //clr_RS();
        if (flip)
        {
        /*
        ioport_set_pin_level(PIN_PB11, 1);
        ioport_set_pin_level(PIN_PA16, 1);
        ioport_set_pin_level(PIN_PC09, 1);
        ioport_set_pin_level(PIN_PB13, 1);
        ioport_set_pin_level(PIN_PB08, 1);
        */
        //gpC->GPIO_OVRS = 0xFFFF0000;
        *pardat = 0x5555; 
        flip = FALSE;
        }
        else
        {
        /*
        ioport_set_pin_level(PIN_PB11, 0);
        ioport_set_pin_level(PIN_PA16, 0);
        ioport_set_pin_level(PIN_PB13, 0);
        ioport_set_pin_level(PIN_PC09, 0);
        ioport_set_pin_level(PIN_PB08, 0);
        */
        //gpC->GPIO_OVRC = 0xFFFF0000;
        *pardat = 0xAAAA;
        flip = TRUE;
        }
        bl_printf("^");
        post test_iterate();
    }
    async command void Screen.start()
    {
        post test_iterate();
    }
    command error_t Init.init()
    {
        //Configure the parallel data ports as output
        gpC->GPIO_GPERS = 0xFFFF0000;
        gpC->GPIO_ODERS = 0xFFFF0000;
        ioport_init();
        
        //Configure others
        ioport_set_pin_dir(PIN_PA14, IOPORT_DIR_OUTPUT); //Supplementary power
        ioport_set_pin_level(PIN_PA14, 1);  //See http://storm.pm/msg/SB-001
        ioport_set_pin_dir(PIN_PB11, IOPORT_DIR_OUTPUT); //LCD_RS
        ioport_set_pin_dir(PIN_PA16, IOPORT_DIR_OUTPUT); //LCD_WR
        ioport_set_pin_dir(PIN_PC09, IOPORT_DIR_OUTPUT); //LCD_RD
        ioport_set_pin_dir(PIN_PB13, IOPORT_DIR_OUTPUT); //LCD_RESET
        
        return SUCCESS;
    }
    
    
}
