#include <ioport.h>
#include <bldebug.h>

#define LCD_X 320
#define LCD_Y 240

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
    // LCD_WR       : DCTLC : PA13 (manual rewire needed)
    // LCD_RD       : PC9
    // LCD_RESET    : PB13
    // LCD_CS       : PC0
    
    GpioPort *gpC = (GpioPort*) GPIO_PORT_C_ADDR;
    GpioPort *gpB = (GpioPort*) GPIO_PORT_B_ADDR;
    GpioPort *gpA = (GpioPort*) GPIO_PORT_A_ADDR;
    
   // uint16_t *pardatw = (uint16_t*) (GPIO_PORT_C_ADDR + 0x52);
  //  uint16_t *pardatr = (uint16_t*) (GPIO_PORT_C_ADDR + 0x62);
    inline void set_RS() {gpB->GPIO_OVRS = (1<<11);}
    inline void clr_RS() {gpB->GPIO_OVRC = (1<<11);}
    inline void set_WR() {gpA->GPIO_OVRS = (1<<13);}
    inline void clr_WR() {gpA->GPIO_OVRC = (1<<13);}
    inline void set_RD() {gpC->GPIO_OVRS = (1<<9);}
    inline void clr_RD() {gpC->GPIO_OVRC = (1<<9);}
    inline void set_CS() {gpC->GPIO_OVRS = (1);}
    inline void clr_CS() {gpC->GPIO_OVRC = (1);}
    inline void set_RST() {gpB->GPIO_OVRS = (1<<13);}
    inline void clr_RST() {gpB->GPIO_OVRC = (1<<13);}
    inline void set_par_output()
    {
        gpC->GPIO_ODERS = 0xFFFF0000;
        gpC->GPIO_STERC = 0xFFFF0000;
    }
    inline void set_par_input()
    {
        gpC->GPIO_ODERC = 0xFFFF0000;
        gpC->GPIO_STERS = 0xFFFF0000;
    }
    inline void wr_pardat(uint16_t v)
    {
        gpC->GPIO_OVR = (gpC->GPIO_OVR & 0xFFFF) | (((uint32_t) v) << 16);
    }
    inline uint16_t rd_pardat()
    {
        return (uint16_t) (gpC->GPIO_PVR >> 16);
    }
    void dly()
    {
        volatile uint32_t i;
        for (i=0;i<300000;i++)
        {
             asm("nop");
        }

    }
    void sdly()
    {
        volatile uint32_t i;
        for (i=0;i<4000;i++)
        {
             asm("nop");
        }

    }
    void lcdw_data(uint16_t val)
    {
        set_par_output();
        clr_CS();
        sdly();
        set_RS();
        sdly();
        wr_pardat(val);
        clr_WR();
        sdly();
        set_WR();
        sdly();
        set_CS();
        sdly();
    }
    void lcdw_index(uint16_t idx)
    {
        set_par_output();
        clr_CS();
        sdly();
        clr_RS();
        sdly();
        wr_pardat(idx);
        clr_WR();
        sdly();
        set_WR();
        sdly();
        set_CS();
        sdly();
    }
    void lcdw_reg(uint16_t addr, uint16_t val)
    {
        lcdw_index(addr);
        lcdw_data(val);
    }
    uint16_t lcdr_data()
    {
        uint16_t rv;
        set_par_input();
        clr_CS();
        sdly();
        set_RS();
        sdly();
        set_WR();
        sdly();
        clr_RD();
        sdly();
        rv = rd_pardat();
        set_RD();
        sdly();
        set_CS();
        sdly();
        return rv;
    }
    uint16_t lcdr_reg(uint16_t addr)
    {
        uint16_t rv;
        lcdw_index(addr);
        rv = lcdr_data();
        return rv;
    }
    command error_t Init.init()
    {
        //Configure the parallel data ports as output
        gpC->GPIO_GPERS = 0xFFFF0000;
        //gpC->GPIO_ODERS = 0xFFFF0000;
        
        //Configure others
    //    ioport_set_pin_dir(PIN_PA14, IOPORT_DIR_OUTPUT); //Supplementary power
    //    ioport_set_pin_level(PIN_PA14, 1);  //See http://storm.pm/msg/SB-001
        ioport_set_pin_dir(PIN_PB11, IOPORT_DIR_OUTPUT); //LCD_RS
        ioport_set_pin_dir(PIN_PA13, IOPORT_DIR_OUTPUT); //LCD_WR
        ioport_set_pin_dir(PIN_PC09, IOPORT_DIR_OUTPUT); //LCD_RD
        ioport_set_pin_dir(PIN_PB13, IOPORT_DIR_OUTPUT); //LCD_RESET
        ioport_set_pin_dir(PIN_PC00, IOPORT_DIR_OUTPUT); //LCD_CS

        return SUCCESS;
    }

    void lcd_set_cursor(uint16_t x, uint16_t y)
    {
        lcdw_reg(0x0020, x );
        lcdw_reg(0x0021, y );
    }

    void g_fill_rgb()
    {
        uint16_t x, y;
        lcd_set_cursor(0, 0);
        bl_printf("set cursor\n");
        lcdw_index(0x022);

        for (x = 0; x < LCD_X; x++)
        {
            for (y = 0; y < LCD_Y; y++)
            {
                lcdw_data((x << 8) | y);
            }
        }
    }

    //This is copied and translated from the screen supplier's example code
    void magic_incantation()
    {
        int i;
        int mplex = 10;
		lcdw_reg(0x00e7,0x0010);      
		lcdw_reg(0x0000,0x0001);  	/* start internal osc */
		lcdw_reg(0x0001,0x0100);     
		lcdw_reg(0x0002,0x0700); 	/* power on sequence */
		lcdw_reg(0x0003,(1<<12)|(1<<5)|(1<<4)|(0<<3) ); 	/* importance */
		lcdw_reg(0x0004,0x0000);                                   
		lcdw_reg(0x0008,0x0207);	           
		lcdw_reg(0x0009,0x0000);         
		lcdw_reg(0x000a,0x0000); 	/* display setting */        
		lcdw_reg(0x000c,0x0001);	/* display setting */        
		lcdw_reg(0x000d,0x0000); 			        
		lcdw_reg(0x000f,0x0000);
		/* Power On sequence */
		lcdw_reg(0x0010,0x0000);   
		lcdw_reg(0x0011,0x0007);
		lcdw_reg(0x0012,0x0000);                                                                 
		lcdw_reg(0x0013,0x0000);

		dly();  /* delay 50 ms */
		lcdw_reg(0x0010,0x1590);   
		lcdw_reg(0x0011,0x0227);
	    dly();  /* delay 50 ms */
		lcdw_reg(0x0012,0x009c);                  
		dly();  /* delay 50 ms */
		lcdw_reg(0x0013,0x1900);   
		lcdw_reg(0x0029,0x0023);
		lcdw_reg(0x002b,0x000e);
		dly();  /* delay 50 ms */
		lcdw_reg(0x0020,0x0000);                                                            
		lcdw_reg(0x0021,0x0000);           
		dly();  /* delay 50 ms */
		lcdw_reg(0x0030,0x0007); 
		lcdw_reg(0x0031,0x0707);   
		lcdw_reg(0x0032,0x0006);
		lcdw_reg(0x0035,0x0704);
		lcdw_reg(0x0036,0x1f04); 
		lcdw_reg(0x0037,0x0004);
		lcdw_reg(0x0038,0x0000);        
		lcdw_reg(0x0039,0x0706);     
		lcdw_reg(0x003c,0x0701);
		lcdw_reg(0x003d,0x000f);
		dly();  /* delay 50 ms */
		lcdw_reg(0x0050,0x0000);        
		lcdw_reg(0x0051,0x00ef);   
		lcdw_reg(0x0052,0x0000);     
		lcdw_reg(0x0053,0x013f);
		lcdw_reg(0x0060,0xa700);        
		lcdw_reg(0x0061,0x0001); 
		lcdw_reg(0x006a,0x0000);
		lcdw_reg(0x0080,0x0000);
		lcdw_reg(0x0081,0x0000);
		lcdw_reg(0x0082,0x0000);
		lcdw_reg(0x0083,0x0000);
		lcdw_reg(0x0084,0x0000);
		lcdw_reg(0x0085,0x0000);
		  
		lcdw_reg(0x0090,0x0010);     
		lcdw_reg(0x0092,0x0000);  
		lcdw_reg(0x0093,0x0003);
		lcdw_reg(0x0095,0x0110);
		lcdw_reg(0x0097,0x0000);        
		lcdw_reg(0x0098,0x0000);  
		/* display on sequence */    
		lcdw_reg(0x0007,0x0133);
		
		lcdw_reg(0x0020,0x0000);  /* Line first address 0 */                                                          
		lcdw_reg(0x0021,0x0000);  /* Column first site 0 */  
    }

    async command void Screen.start()
    {
        uint32_t i,j;
        uint16_t code;

        set_par_output();

        //Configure others
    //    ioport_set_pin_dir(PIN_PA14, IOPORT_DIR_OUTPUT); //Supplementary power
    //    ioport_set_pin_level(PIN_PA14, 1);  //See http://storm.pm/msg/SB-001
        ioport_set_pin_dir(PIN_PB11, IOPORT_DIR_OUTPUT); //LCD_RS
        ioport_set_pin_dir(PIN_PA13, IOPORT_DIR_OUTPUT); //LCD_WR
        ioport_set_pin_dir(PIN_PC09, IOPORT_DIR_OUTPUT); //LCD_RD
        ioport_set_pin_dir(PIN_PB13, IOPORT_DIR_OUTPUT); //LCD_RESET
        ioport_set_pin_dir(PIN_PC00, IOPORT_DIR_OUTPUT); //LCD_CS

      //  set_par_input();
      //  while(1)
      //  {
      //      i = gpC->GPIO_PVR;
      //      bl_printf("a: %d\n", i);
      //      i = *pardatr;
      //      bl_printf("b: %d\n", i);

      //  }

        bl_printf("resetting\n");
        set_CS();
        set_RS();
        set_RD();
        set_WR();
        set_RST();

        dly();
        clr_RST();
        dly();
        dly();
        set_RST();
        bl_printf("Waiting for 100ms\n");

        dly();
        dly();

        /*
        clr_WR();
        sdly();
        set_WR();
        sdly();
        clr_RD();
        sdly();
        set_RD();
        sdly();
        clr_RS();
        sdly();
        set_RS();
        sdly();
        clr_CS();
        sdly();
        set_CS();
        sdly();
        clr_RST();
        sdly();
        set_RST();
        sdly();
        */

        lcdw_index(0);
        bl_printf("done\n");
        code = lcdr_reg(0);
        bl_printf("screen dev code: %d\n", code);
        code = lcdr_reg(22);
        bl_printf("not code: %d\n", code);

        magic_incantation();
        bl_printf("Finished incantation\n");
        g_fill_rgb();
        bl_printf("done rgb\n");

    }
    
    
}
