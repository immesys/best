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
    uses
    {
        interface SPIMux;
        interface Resource as FlashResource;
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

    uint32_t _gfx_buffer [240*2]; //Max xfer is full line * 2
    uint32_t _gfx_fbuffer [240*2]; //Because im lazy

    uint32_t* gfx_buffer = &_gfx_buffer[0];
    uint32_t* gfx_fbuffer = &_gfx_fbuffer[0];


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
        for (i=0;i<40;i++)
        {
             asm("nop");
        }
    }
    void lcdw_data(uint16_t val)
    {
        set_par_output();
        clr_CS();
        set_RS();
        wr_pardat(val);
        clr_WR();
        asm("nop");
        set_WR();
        set_CS();
    }
    void lcdw_index(uint16_t idx)
    {
        set_par_output();
        clr_CS();
        clr_RS();
        wr_pardat(idx);
        clr_WR();
        asm("nop");
        set_WR();
        set_CS();
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
        set_RS();
        set_WR();
        clr_RD();
        sdly();
        rv = rd_pardat();
        set_RD();
        set_CS();
        return rv;
    }
    uint16_t lcdr_reg(uint16_t addr)
    {
        uint16_t rv;
        lcdw_index(addr);
        rv = lcdr_data();
        return rv;
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
        lcdw_index(0x022);

        for (x = 0; x < LCD_X; x++)
        {
            for (y = 0; y < LCD_Y; y++)
            {
                lcdw_data((x << 8) | y);
            }
        }
    }

    async command void Screen.fill_color(uint16_t color)
    {
        uint16_t x, y;
        lcd_set_cursor(0, 0);
        lcdw_index(0x022);

        for (x = 0; x < LCD_X; x++)
        {
            for (y = 0; y < LCD_Y; y++)
            {
                lcdw_data(color);
            }
        }
    }

    async command void Screen.fill_colorw(uint16_t color, uint16_t x, uint16_t y, uint16_t w, uint16_t h)
    {
        uint16_t ix, iy;
        for (iy = y; iy < y+h; iy++)
        {
            lcd_set_cursor(x, iy);
            lcdw_index(0x022);
            for (ix = 0; ix < w; ix++)
            {
                lcdw_data(color);
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

    }

    bool screen_busy;
    uint16_t bw_dst_sx, bw_dst_sy, bw_dst_width, bw_dst_height;
    uint16_t bw_asset_sx, bw_asset_sy, bw_asset_width, bw_asset_height;
    uint8_t bw_rows_done;
    uint32_t bw_asset_address;

    event void FlashResource.granted()
    {
        uint16_t to_xfer = bw_dst_width*2;
        bl_printf("screen flash resource granted\n");
        call SPIMux.initiate_flash_transfer(&gfx_buffer[0], bw_dst_width*2,
            bw_asset_address + (uint32_t)bw_asset_sy*(uint32_t)bw_asset_width*2 + (uint32_t)bw_asset_sx*2);

    }
    task void process_buffer()
    {
        uint32_t* tbuf = gfx_buffer;
        uint32_t i;
        gfx_buffer = gfx_fbuffer;
        gfx_fbuffer = tbuf;
        //bl_printf("processing row %d\n", bw_rows_done);
        bw_rows_done++;
        if (bw_rows_done != bw_dst_height)
        {
            call SPIMux.initiate_flash_transfer(&gfx_buffer[0], bw_dst_width*2,
                bw_asset_address + (uint32_t)(bw_asset_sy+bw_rows_done)*(uint32_t)bw_asset_width*2 + (uint32_t)bw_asset_sx*2);
        }
        lcd_set_cursor(bw_dst_sx, bw_dst_sy + bw_rows_done - 1);
        lcdw_index(0x022);
        for (i = 0; i < bw_dst_width*2; i+=2)
        {
            lcdw_data( ((gfx_fbuffer[i] & 0xFF) << 8) | (gfx_fbuffer[i+1] & 0xFF) );
            //lcdw_data(0x5050);
        }
        if (bw_rows_done == bw_dst_height)
        {
            bl_printf("screen flash resource released\n");
            call FlashResource.release();
            screen_busy = FALSE;
            signal Screen.blit_window_complete();
        }
    }
    async event void SPIMux.flash_transfer_complete()
    {
        //Now we take our buffer, whose contents are identified by the bw_* variables, and stick
        //it on the screen. First though, we shadow the vars and rerequest the next line if required
        post process_buffer();
    }

    async event void SPIMux.flash_write_complete()
    {
        //Doesn't concern us
    }
    async void command Screen.blit_window(uint16_t dst_sx, uint16_t dst_sy, uint16_t dst_width, uint16_t dst_height,
                    uint16_t asset_sx, uint16_t asset_sy, uint16_t asset_width, uint16_t asset_height,
                    uint32_t asset_address)
    {
        if (screen_busy)
        {
            bl_printf("attempt to blit while busy");
            return;
        }
        screen_busy = TRUE;
        bw_dst_sx = dst_sx;
        bw_dst_sy = dst_sy;
        bw_dst_width = dst_width;
        bw_dst_height = dst_height;
        bw_asset_sx = asset_sx;
        bw_asset_sy = asset_sy;
        bw_asset_width = asset_width;
        bw_asset_height = asset_height;
        bw_asset_address = asset_address;
        bw_rows_done = 0;
        call FlashResource.request();
    }

    command error_t Init.init()
    {
        uint16_t code;

        ioport_set_pin_dir(PIN_PB11, IOPORT_DIR_OUTPUT); //LCD_RS
        ioport_set_pin_dir(PIN_PA13, IOPORT_DIR_OUTPUT); //LCD_WR
        ioport_set_pin_dir(PIN_PC09, IOPORT_DIR_OUTPUT); //LCD_RD
        ioport_set_pin_dir(PIN_PB13, IOPORT_DIR_OUTPUT); //LCD_RESET
        ioport_set_pin_dir(PIN_PC00, IOPORT_DIR_OUTPUT); //LCD_CS

        set_par_output();

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
        dly();
        dly();
        code = lcdr_reg(0);
        magic_incantation();

        return SUCCESS;
    }

}
