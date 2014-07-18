#include <ioport.h>
#include <bldebug.h>
#include <usart.h>
#include <flash_logger.h>
#include <tc.h>

/* AD channel selection command and register */
#define	TP_CHX 	0x90 	/* channel Y+ selection command */
#define	TP_CHY 	0xd0	/* channel X+ selection command*/



module ControlsP
{
    provides
    {
        interface Controls;
        interface Init;
    }
    uses
    {
        interface Timer<TMilli> as touchTmr;
        interface Timer<TMilli> as reportTmr;
        interface Timer<TMilli> as pwmTmr;
        interface FlashLogger;
    }
}
implementation
{
    uint8_t heating;
    uint8_t fan;
    uint8_t occupancy;

    uint8_t allow_touch;
    uint8_t heat_on;

    typedef struct
    {
        int32_t x;
        int32_t y;
    } point_t;

    typedef struct Matrix
    {
       int32_t  An,
                Bn,
                Cn,
                Dn,
                En,
                Fn,
                Divider ;
    } matrix_t ;


    point_t measured_tp_points [3];
    point_t displayed_tp_points [3] = { {45,45}, {45, 270}, {190,190} };
    matrix_t cmatrix;

    uint8_t report_heat_dirty;
    uint8_t report_cool_dirty;
    uint8_t report_occu_dirty;
    uint8_t report_booted_dirty = 1;

    void tp_set_calibration_matrix(void);
    uint8_t tp_multisample_xy_raw(point_t *out);
    uint8_t tp_get_calibrated_point(uint16_t *x, uint16_t *y);
    GpioPort *gpA = (GpioPort*) GPIO_PORT_A_ADDR;
    task void process_touch();
    void expander_w(uint8_t code, uint8_t regaddr, uint8_t dat);

    void get_occupance()
    {
        if (ioport_get_pin_level(PIN_PA06) == 0)
        {
            if (occupancy == 0) report_occu_dirty = 1;
            occupancy = 1;
        }
        else
        {
            if (occupancy == 1) report_occu_dirty = 0;
            occupancy = 0;
        }

    }

    void set_fan()
    {
        //We have four levels of fan. May as well make them at quarters
        get_occupance();
        if (occupancy == 0)
        {
            expander_w(0x40, 0x0A, 0x00); //All off
        }
        else if (fan == 0)
        {
            expander_w(0x40, 0x0A, 0x00); //All off
        }
        else if (fan <= 25)
        {
            expander_w(0x40, 0x0A, 0b00100010); //FCA1 and FCB1
        }
        else if (fan <= 50)
        {
            expander_w(0x40, 0x0A, 0b00010001); //FCA0 and FCB0
        }
        else if (fan <= 75)
        {
            expander_w(0x40, 0x0A, 0b00110011); //FC*
        }
        else if (fan <= 100)
        {
            expander_w(0x40, 0x0A, 0b01110111); //FC*
        }
    }

    void set_heat()
    {
      //  call pwmTmr.stop();
      //  heat_on = 1;
      //  ioport_set_pin_level(PIN_PA08, 1);
      //  call pwmTmr.startOneShot(heat*100);
    }

    event void pwmTmr.fired()
    {
        get_occupance();
        if (heat_on)
        {
            heat_on = 0;
            ioport_set_pin_level(PIN_PA08, 0);
            ioport_set_pin_level(PIN_PA12, 0);
            call pwmTmr.startOneShot((100-heating)*100);
        }
        else
        {
            heat_on = 1;
            if (occupancy)
            {
                ioport_set_pin_level(PIN_PA08, 1);
                ioport_set_pin_level(PIN_PA12, 1);
            }
            else
            {
                ioport_set_pin_level(PIN_PA08, 0);
                ioport_set_pin_level(PIN_PA12, 0);
            }
            call pwmTmr.startOneShot(heating*100);
        }
    }

    async command void Controls.fan_up()
    {
        if (fan == 100) return;
        fan += 10;
        report_cool_dirty = 1;
        set_fan();
        signal Controls.controls_changed();
    }
    async command void Controls.fan_down()
    {
        if (fan == 0) return;
        fan -= 10;
        report_cool_dirty = 1;
        set_fan();
        signal Controls.controls_changed();
    }
    async command void Controls.heat_up()
    {
        if (heating == 100) return;
        heating += 10;
        report_heat_dirty = 1;
        set_heat();
        signal Controls.controls_changed();
    }
    async command void Controls.heat_down()
    {
        if (heating == 0) return;
        heating -= 10;
        report_heat_dirty = 1;
        set_heat();
        signal Controls.controls_changed();
    }

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

    inline void tpdly()
    {
        volatile uint32_t i;
        for (i=0;i<4;i++)
        {
             asm("nop");
        }
    }

    inline void tplongdly()
    {
        volatile uint32_t i;
        for (i=0;i<4000;i++) //7ms or so
        {
             asm("nop");
        }
    }

    void tp_get_raw_xy(uint16_t *x, uint16_t *y);

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
        for (i = 0; i< 8; i++)
        {
            i2c_W(regaddr&0x80);
            regaddr <<= 1;
        }
        ack = i2c_R();
        for (i = 0; i< 8; i++)
        {
            i2c_W(dat&0x80);
            dat <<= 1;
        }
        ack = i2c_R();
        i2c_P();
    }

    void log_settings(uint8_t type)
    {
        sense_record_t r;
        r.type = type;
        r.heat_val = heating;
        r.fan_val = fan;
        r.occupancy_val = occupancy;
        r.temp_val = 0;
        r.rh_val = 0;
        call FlashLogger.log_record(&r);
    }
    event void touchTmr.fired()
    {
        allow_touch = 1;
    }

    const usart_spi_opt_t tp_spi_settings =
    {
        1000000,
        US_MR_CHRL_8_BIT,
        SPI_MODE_3,
        US_MR_CHMODE_NORMAL
    };


    void init_tp()
    {
        usart_reset(USART2);
        usart_init_spi_master(USART2, &tp_spi_settings, sysclk_get_main_hz());
        usart_enable_tx(USART2);
        usart_enable_rx(USART2);
    }


	#define TC_CHANNEL_WAVEFORM  0
    #define ID_TC_WAVEFORM       TC0
    #define PIN_TC_WAVEFORM      PIN_PA08B_TC0_A0
    #define PIN_TC_WAVEFORM_MUX  MUX_PA08B_TC0_A0

    void pwm_init()
    {
        uint32_t ra, rc;

        bl_printf("Starting PWM init\n");

#if 0
        ioport_set_pin_dir(PIN_PA08, IOPORT_DIR_OUTPUT);
        /* Configure PIO Pins for TC */
        ioport_set_pin_mode(PIN_TC_WAVEFORM, PIN_TC_WAVEFORM_MUX);
        /* Disable IO to enable peripheral mode) */
        ioport_disable_pin(PIN_TC_WAVEFORM);

        /* Configure the PMC to enable the TC module. */
        sysclk_enable_peripheral_clock(ID_TC_WAVEFORM);

        /* Init TC to waveform mode. */
        tc_init(TC1, TC_CHANNEL_WAVEFORM,
                /* Waveform Clock Selection */
                TC_CMR_TCCLKS_TIMER_CLOCK4
                | TC_CMR_WAVE /* Waveform mode is enabled */
                | TC_CMR_ACPA_SET /* RA Compare Effect: set */
                | TC_CMR_ACPC_CLEAR /* RC Compare Effect: clear */
                | TC_CMR_CPCTRG /* UP mode with automatic trigger on RC Compare */
        );

        /* Configure waveform frequency and duty cycle. */
        /*
        rc = (sysclk_get_peripheral_bus_hz(TC) /
                divisors[gc_waveconfig[gs_uc_configuration].ul_intclock]) /
                gc_waveconfig[gs_uc_configuration].us_frequency;
        tc_write_rc(TC, TC_CHANNEL_WAVEFORM, rc);
        ra = (100 - gc_waveconfig[gs_uc_configuration].us_dutycycle) * rc / 100;
        tc_write_ra(TC, TC_CHANNEL_WAVEFORM, ra);
        */
        tc_write_rc(TC1, TC_CHANNEL_WAVEFORM, 20000);
        tc_write_ra(TC1, TC_CHANNEL_WAVEFORM, 7000);

        /* Enable TC TC_CHANNEL_WAVEFORM. */
        tc_start(TC1, TC_CHANNEL_WAVEFORM);

        bl_printf("Ending PWM init\n");*/
        #endif
    }

    command error_t Init.init()
    {
        uint32_t rv;
        ioport_set_pin_dir(PIN_PB00, IOPORT_DIR_OUTPUT);
        ioport_set_pin_dir(PIN_PB01, IOPORT_DIR_INPUT);
        ioport_set_pin_level(PIN_PB01, 0);

        expander_w(0x40, 0x00, 0x00); //Set all pins as output
        expander_w(0x40, 0x0A, 0x00); //Set some output pins

        //Configure the TP IRQ
       // ioport_set_pin_dir(PIN_PA19, IOPORT_DIR_INPUT);
       //ioport_set_pin_mode(PIN_PA19, 0);

        ioport_set_pin_mode(PIN_PA19C_EIC_EXTINT4, PINMUX_PA19C_EIC_EXTINT4);
        ioport_disable_pin(PIN_PA19C_EIC_EXTINT4);

        ioport_set_pin_mode(PIN_PC11B_USART2_RXD, MUX_PC11B_USART2_RXD);
        ioport_disable_pin(PIN_PC11B_USART2_RXD);
        ioport_set_pin_mode(PIN_PC12B_USART2_TXD, MUX_PC12B_USART2_TXD);
        ioport_disable_pin(PIN_PC12B_USART2_TXD);
        ioport_set_pin_mode(PIN_PA18A_USART2_CLK, MUX_PA18A_USART2_CLK);
        ioport_disable_pin(PIN_PA18A_USART2_CLK);
        ioport_set_pin_mode(PIN_PC07B_USART2_RTS, MUX_PC07B_USART2_RTS);
        ioport_disable_pin(PIN_PC07B_USART2_RTS);

        sysclk_enable_peripheral_clock(USART2);

        usart_reset(USART2);
        usart_init_spi_master(USART2, &tp_spi_settings, sysclk_get_main_hz());
        usart_enable_tx(USART2);
        usart_enable_rx(USART2);

        //ioport_set_pin_dir(PIN_PC07, IOPORT_DIR_OUTPUT);
        //ioport_set_pin_level(PIN_PC07, 1);

      //  init_tp();

        //Enable the interrupt, but mask it off
        REG_EIC_IDR = 1 << 4;
        REG_EIC_EN = 1 << 4;

        //Line is edge triggered
        REG_EIC_MODE &= ~(1<<4);

        NVIC_SetPriority(EIC_4_IRQn, 1);
        NVIC_ClearPendingIRQ(EIC_4_IRQn);
        NVIC_EnableIRQ(EIC_4_IRQn);

        //Configure for falling edge capture
        REG_EIC_EDGE &= ~(1<<4);
        REG_EIC_IER = 1 << 4;

        allow_touch = 1;

        call reportTmr.startPeriodic(5000);

        report_heat_dirty = 1;
        report_cool_dirty = 1;
        report_occu_dirty = 1;

        //pwm_init();

        //Configure the heating strip control pins
        ioport_set_pin_dir(PIN_PA08, IOPORT_DIR_OUTPUT);
        ioport_set_pin_dir(PIN_PA12, IOPORT_DIR_OUTPUT);
        ioport_set_pin_dir(PIN_PA06, IOPORT_DIR_INPUT);

        call pwmTmr.startOneShot(1000);

    }

    uint32_t cycles_since_last_report = 0;
    //#define PERIODIC_CYCLES 120 //10 minutes of inactivity
    #define PERIODIC_CYCLES 12 //1 minute of inactivity
    event void reportTmr.fired()
    {
        uint8_t type = 0;
        set_fan(); //HACK MUCH?
        if (report_heat_dirty)
        {
            type |= FS_TYPE_HEAT;
            report_heat_dirty = 0;
        }
        if (report_cool_dirty)
        {
            type |= FS_TYPE_COOL;
            report_cool_dirty = 0;
        }
        if (report_occu_dirty)
        {
            type |= FS_TYPE_OCC;
            report_occu_dirty = 0;

        }
        if (report_booted_dirty)
        {
            type |= FS_TYPE_REBOOT;
            report_booted_dirty = 0;
        }
        if (type == 0) cycles_since_last_report++;
        else cycles_since_last_report = 0;

        if (cycles_since_last_report > PERIODIC_CYCLES)
        {
            type |= FS_TYPE_PER;
            cycles_since_last_report = 0;
        }

        if (type != 0)
        {
            log_settings(type);
        }
    }

    void EIC_4_Handler(void) @C() @spontaneous()
    {
        REG_EIC_ICR = 1 << 4;
        post process_touch();
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
        expander_w(0x40, 0x0A, 0x00); //Set some output pins
        signal Controls.controls_changed();
    }
    async command uint8_t Controls.get_occupancy()
    {
        get_occupance();
        return occupancy;
    }

    enum
    {
        ts_active,
        ts_ignore,
        ts_cal1,
        ts_cal2,
        ts_cal3
    } touch_state;

    async command void Controls.transition_cal_pt1()
    {
        bl_printf("transitioning to cal1\n");
        touch_state = ts_cal1;
    }

    async command void Controls.transition_cal_pt2()
    {
        bl_printf("transitioning to cal2\n");
        touch_state = ts_cal2;
    }

    async command void Controls.transition_cal_pt3()
    {
        bl_printf("transitioning to cal3\n");
        touch_state = ts_cal3;
    }

    async command void Controls.transition_active()
    {
        bl_printf("Transition to active touch\n");
        touch_state = ts_active;
    }

    uint8_t get_irq()
    {
        return (gpA->GPIO_PVR & (1<<19)) != 0;
    }

    task void process_touch()
    {

        point_t touchpoint;
        uint16_t x, y;
        uint8_t rv;
        uint8_t i;

        if (touch_state == ts_ignore) return;
        if (allow_touch == 0) return;
        //disable the interrupt, as the IRQ loses it's fricking mind
        //during ADC conversions... its in small print in the datasheet
        REG_EIC_IDR = 1 << 4;

        if (touch_state == ts_active)
        {
            for (i = 0; i < 5; i++)
            {
                rv = tp_get_calibrated_point(&x, &y);
                if (rv)
                {
                    signal Controls.touch(x, y);
                    allow_touch = 0;
                    call touchTmr.startOneShot(50);
                    break;
                }
                tplongdly();
            }
        }
        else
        {
            do
            {
                rv = tp_multisample_xy_raw(&touchpoint);
            } while ((rv == 0) && (get_irq() == 0));

            if (rv != 0)
            {
                switch(touch_state)
                {
                    case ts_cal1:
                        measured_tp_points[0] = touchpoint;
                        touch_state = ts_ignore;
                        signal Controls.cal1_done();
                        break;
                    case ts_cal2:
                        measured_tp_points[1] = touchpoint;
                        touch_state = ts_ignore;
                        signal Controls.cal2_done();
                        break;
                    case ts_cal3:
                        measured_tp_points[2] = touchpoint;
                        touch_state = ts_ignore;
                        tp_set_calibration_matrix();
                        bl_printf("cal pt1 %d %d\n", measured_tp_points[0].x,  measured_tp_points[0].y);
                        bl_printf("cal pt2 %d %d\n", measured_tp_points[1].x,  measured_tp_points[1].y);
                        bl_printf("cal pt3 %d %d\n", measured_tp_points[2].x,  measured_tp_points[2].y);
                        signal Controls.cal3_done();
                        break;
                }
            }

        }

        NVIC_ClearPendingIRQ(EIC_4_IRQn);
        REG_EIC_ICR = 1 << 4;
        REG_EIC_IER = 1 << 4;
    }

    // START TOUCH STUFF
    // ------------------------------------------------------



    void tp_select()
    {
        usart_spi_force_chip_select(USART2);
        //ioport_set_pin_level(PIN_PC07, 0);
    }
    void tp_deselect()
    {
        usart_spi_release_chip_select(USART2);
        //ioport_set_pin_level(PIN_PC07, 1);
    }



uint8_t tp_spi_rwb(uint8_t v)
{
    uint32_t rv;
  //  if (usart_is_rx_ready(USART2))
   // {
   //     usart_getchar(USART2, &rv);
   // }
    //bl_printf("before putchar\n");

    usart_putchar(USART2, v);
    //bl_printf("before getchar\n");
    usart_getchar(USART2, &rv);
   // bl_printf("done\n");
    return rv;
}

inline uint16_t tp_read_ad()
{
    uint16_t rv, b;
    rv = 5;
    rv = tp_spi_rwb(0x00);
    rv <<= 8;
    tpdly();
    b = tp_spi_rwb(0x00);
    rv |= b;
    rv >>= 3;
    rv &= 0xFFF;
    return rv;
}

uint16_t tp_read_x(void)
{
    uint16_t rv;
    tp_select();
    tpdly();
    tp_spi_rwb(TP_CHX);
    tpdly();
    rv = tp_read_ad();
    tp_deselect();
    return rv;
}

uint16_t tp_read_y(void)
{
    uint16_t rv;
    tp_select();
    tpdly();
    tp_spi_rwb(TP_CHY);
    tpdly();
    rv = tp_read_ad();
    tp_deselect();
    return rv;
}

void tp_get_raw_xy(uint16_t *x, uint16_t *y)
{
    *x = tp_read_x();
    tpdly();
    *y = tp_read_y();
    tpdly();
}

void tp_set_calibration_matrix(void)
{
    cmatrix.Divider = ((measured_tp_points[0].x - measured_tp_points[2].x) * (measured_tp_points[1].y - measured_tp_points[2].y)) -
                      ((measured_tp_points[1].x - measured_tp_points[2].x) * (measured_tp_points[0].y - measured_tp_points[2].y));
    if (cmatrix.Divider == 0)
    {
        while(1)
        {
            bl_printf("cmatrix divider is zero\n");
        }
    }
    /* A\A3?((XD0\A3\ADXD2) (Y1\A3\ADY2)\A3\AD(XD1\A3\ADXD2) (Y0\A3\ADY2))\A3\AFK	*/
    cmatrix.An = ((displayed_tp_points[0].x - displayed_tp_points[2].x) * (measured_tp_points[1].y - measured_tp_points[2].y)) -
                 ((displayed_tp_points[1].x - displayed_tp_points[2].x) * (measured_tp_points[0].y - measured_tp_points[2].y)) ;
	/* B\A3?((X0\A3\ADX2) (XD1\A3\ADXD2)\A3\AD(XD0\A3\ADXD2) (X1\A3\ADX2))\A3\AFK	*/
    cmatrix.Bn = ((measured_tp_points[0].x - measured_tp_points[2].x) * (displayed_tp_points[1].x - displayed_tp_points[2].x)) -
                 ((displayed_tp_points[0].x - displayed_tp_points[2].x) * (measured_tp_points[1].x - measured_tp_points[2].x)) ;
    /* C\A3?(Y0(X2XD1\A3\ADX1XD2)+Y1(X0XD2\A3\ADX2XD0)+Y2(X1XD0\A3\ADX0XD1))\A3\AFK */
    cmatrix.Cn = (measured_tp_points[2].x * displayed_tp_points[1].x - measured_tp_points[1].x * displayed_tp_points[2].x) * measured_tp_points[0].y +
                 (measured_tp_points[0].x * displayed_tp_points[2].x - measured_tp_points[2].x * displayed_tp_points[0].x) * measured_tp_points[1].y +
                 (measured_tp_points[1].x * displayed_tp_points[0].x - measured_tp_points[0].x * displayed_tp_points[1].x) * measured_tp_points[2].y ;
    /* D\A3?((YD0\A3\ADYD2) (Y1\A3\ADY2)\A3\AD(YD1\A3\ADYD2) (Y0\A3\ADY2))\A3\AFK	*/
    cmatrix.Dn = ((displayed_tp_points[0].y - displayed_tp_points[2].y) * (measured_tp_points[1].y - measured_tp_points[2].y)) -
                 ((displayed_tp_points[1].y - displayed_tp_points[2].y) * (measured_tp_points[0].y - measured_tp_points[2].y)) ;
    /* E\A3?((X0\A3\ADX2) (YD1\A3\ADYD2)\A3\AD(YD0\A3\ADYD2) (X1\A3\ADX2))\A3\AFK	*/
    cmatrix.En = ((measured_tp_points[0].x - measured_tp_points[2].x) * (displayed_tp_points[1].y - displayed_tp_points[2].y)) -
                 ((displayed_tp_points[0].y - displayed_tp_points[2].y) * (measured_tp_points[1].x - measured_tp_points[2].x)) ;
    /* F\A3?(Y0(X2YD1\A3\ADX1YD2)+Y1(X0YD2\A3\ADX2YD0)+Y2(X1YD0\A3\ADX0YD1))\A3\AFK */
    cmatrix.Fn = (measured_tp_points[2].x * displayed_tp_points[1].y - measured_tp_points[1].x * displayed_tp_points[2].y) * measured_tp_points[0].y +
                 (measured_tp_points[0].x * displayed_tp_points[2].y - measured_tp_points[2].x * displayed_tp_points[0].y) * measured_tp_points[1].y +
                 (measured_tp_points[1].x * displayed_tp_points[0].y - measured_tp_points[0].x * displayed_tp_points[1].y) * measured_tp_points[2].y ;
}


#define THRESHOLD 2

uint8_t tp_multisample_xy_raw(point_t *out)
{
    uint8_t count = 0;
    int32_t buffer [2][9];
    int32_t temp[3];
    int32_t m0, m1, m2;
    uint16_t sx,sy;

    do
    {
        tp_get_raw_xy(&sx, &sy);
        buffer[0][count] = sx;
        buffer[1][count] = sy;
        count++;
    //} while( !TP_IRQ && count < 9);
    } while( (get_irq() == 0) &&  count < 9);

    if (count == 9)
    {
        //X
        temp[0] = ( buffer[0][0] + buffer[0][1] + buffer[0][2] ) / 3;
        temp[1] = ( buffer[0][3] + buffer[0][4] + buffer[0][5] ) / 3;
        temp[2] = ( buffer[0][6] + buffer[0][7] + buffer[0][8] ) / 3;

        /* Calculate the three groups of data */
        m0 = temp[0] - temp[1];
        m1 = temp[1] - temp[2];
        m2 = temp[2] - temp[0];

        /* Absolute value of the above difference */
        m0 = m0 > 0 ? m0 : (-m0);
        m1 = m1 > 0 ? m1 : (-m1);
        m2 = m2 > 0 ? m2 : (-m2);

        if( m0 > THRESHOLD  &&  m1 > THRESHOLD  &&  m2 > THRESHOLD )
        {
            return 0;
        }
        /* Calculating their average value */
        if( m0 < m1 )
        {
            if( m2 < m0 )
            {
                out->x = ( temp[0] + temp[2] ) / 2;
            }
            else
            {
                out->x = ( temp[0] + temp[1] ) / 2;
            }
        }
        else if(m2<m1)
        {
            out->x = ( temp[0] + temp[2] ) / 2;
        }
        else
        {
            out->x = ( temp[1] + temp[2] ) / 2;
        }
        /* calculate the average value of Y */
        temp[0] = ( buffer[1][0] + buffer[1][1] + buffer[1][2] ) / 3;
        temp[1] = ( buffer[1][3] + buffer[1][4] + buffer[1][5] ) / 3;
        temp[2] = ( buffer[1][6] + buffer[1][7] + buffer[1][8] ) / 3;

        m0 = temp[0] - temp[1];
        m1 = temp[1] - temp[2];
        m2 = temp[2] - temp[0];

        m0 = m0 > 0 ? m0 : (-m0);
        m1 = m1 > 0 ? m1 : (-m1);
        m2 = m2 > 0 ? m2 : (-m2);
        if( m0 > THRESHOLD && m1 > THRESHOLD && m2 > THRESHOLD )
        {
            return 0;
        }

        if( m0 < m1 )
        {
            if( m2 < m0 )
            {
                out->y = ( temp[0] + temp[2] ) / 2;
            }
            else
            {
                out->y = ( temp[0] + temp[1] ) / 2;
            }
        }
        else if( m2 < m1 )
        {
            out->y = ( temp[0] + temp[2] ) / 2;
        }
        else
        {
            out->y = ( temp[1] + temp[2] ) / 2;
        }
        return 1;
    }
    else
    {
        return 0;
    }
}

uint8_t tp_get_calibrated_point(uint16_t *x, uint16_t *y)
{
    point_t raw;
    int32_t xx, yy;

    if(cmatrix.Divider == 0)
    {
        bl_printf("Discarding calibrated point: zerodiv\n");
        return 0;
    }
    if(!tp_multisample_xy_raw(&raw))
    {
        bl_printf("Discarding calibrated point: zeroRV\n");
        return 0;
    }
    xx =  ( (cmatrix.An * raw.x) +
                      (cmatrix.Bn * raw.y) +
                       cmatrix.Cn
                     ) / cmatrix.Divider ;
    yy =  ( (cmatrix.Dn * raw.x) +
                       (cmatrix.En * raw.y) +
                        cmatrix.Fn
                     ) / cmatrix.Divider ;
    *x = (uint16_t)xx;
    *y = (uint16_t)yy;
    return 1;
}

#if 0
void tp_calibrate(void)
{
    uint8_t i;
    uint8_t rv;
    draw_calibrate_bg();
    for (i = 0; i < 3; i++)
    {
        rv = 0;
        draw_calibrate_point(displayed_tp_points[i].x, displayed_tp_points[i].y);

        do
        {
            if (TP_IRQ) continue;
            rv = tp_multisample_xy_raw(&measured_tp_points[i]);
        } while (rv == 0);
        if( i!= 2)
        {
            erase_calibrate_point(displayed_tp_points[i].x, displayed_tp_points[i].y);
            delay_ms(500);
        }
    }

    tp_set_calibration_matrix();

}

#endif

}