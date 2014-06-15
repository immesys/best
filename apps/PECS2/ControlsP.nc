#include <ioport.h>
#include <bldebug.h>

module ControlsP
{
    provides
    {
        interface Controls;
        interface Init;
    }
}
implementation
{
    uint8_t heating;
    uint8_t fan;

    inline void set_SDA()
    {
        ioport_set_pin_dir(PIN_PB01, IOPORT_DIR_INPUT);
    }
    inline void clr_SDA()
    {
        ioport_set_pin_dir(PIN_PB01, IOPORT_DIR_OUTPUT);
    }
    inline void set_SCL()
    {
        ioport_set_pin_level(PIN_PB00, 1);
    }
    inline void clr_SCL()
    {
        ioport_set_pin_level(PIN_PB00, 0);
    }
    inline uint8_t rd_SDA()
    {
        return ioport_get_pin_level(PIN_PB01);
    }
    inline void ibdly()
    {
        volatile uint32_t i;
        for (i=0;i<40;i++)
        {
             asm("nop");
        }
    }

    //SCL is PB0
    //SDA is PB1

    void i2c_S()
    {
        set_SCL();
        set_SDA();
        ibdly();
        clr_SDA();
        ibdly();
    }
    void i2c_SR()
    {
        set_SDA();
        set_SCL();
        ibdly();
        clr_SDA();
        ibdly();
        set_SDA();
    }
    void i2c_P()
    {
        clr_SDA();
        clr_SCL();
        ibdly();
        set_SCL();
        ibdly();
        set_SDA();
        ibdly();

    }
    uint8_t i2c_R()
    {
        uint8_t rv;
        set_SDA();
        clr_SCL();
        ibdly();
        set_SCL();
        ibdly();
        rv = rd_SDA();
        clr_SCL();
        return rv;
    }
    void i2c_W(uint8_t v)
    {
        clr_SCL();
        if (v) set_SDA();
        else   clr_SDA();
        ibdly();
        set_SCL();
        ibdly();
        clr_SCL();
        set_SDA();
    }
    
    void expander_w(uint8_t code, uint8_t regaddr, uint8_t dat)
    {
        uint8_t i, ack;
        i2c_S();
        for (i = 0; i< 8; i++)
        {
            i2c_W(code&0x80);
            code <<= 1;
        }
        ack = i2c_R();
        bl_printf("code ack: %d\n", ack);
        for (i = 0; i< 8; i++)
        {
            i2c_W(regaddr&0x80);
            regaddr <<= 1;
        }
        ack = i2c_R();
        bl_printf("addr ack: %d\n", ack);
        for (i = 0; i< 8; i++)
        {
            i2c_W(dat&0x80);
            dat <<= 1;
        }
        ack = i2c_R();
        i2c_P();
        bl_printf("dat ack: %d\n", ack);
    }

    command error_t Init.init()
    {
        ioport_set_pin_dir(PIN_PB00, IOPORT_DIR_OUTPUT);
        ioport_set_pin_dir(PIN_PB01, IOPORT_DIR_INPUT);
        ioport_set_pin_level(PIN_PB01, 0);

        bl_printf("pre i2c\n");

        expander_w(0x40, 0x00, 0x00); //Set all pins as output
        expander_w(0x40, 0x0A, 0xFF); //Set some output pins

        bl_printf("post i2c\n");

    }

    async command uint8_t Controls.get_heating()
    {
        return heating;
    }

    async command void Controls.set_heating(uint8_t v)
    {
        heating = v;
        //Do the PWM stuff
        signal Controls.controls_changed();
    }

    async command uint8_t Controls.get_fan()
    {
        return fan;
    }
    async command void Controls.set_fan(uint8_t v)
    {
        fan = v;
        expander_w(0x40, 0x00, 0x00); //Set all pins as output
        expander_w(0x40, 0x0A, 0x55); //Set some output pins
        //Do the I2C stuff :(
        signal Controls.controls_changed();
    }
    async command uint8_t Controls.get_occupancy()
    {
        //Do the port stuff
        return 1;
    }
}