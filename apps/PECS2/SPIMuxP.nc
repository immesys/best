#include <pdca.h>
#include <spi.h>

module SPIMuxP
{
    provides
    {
        interface Init;
        interface SPIMux;
        interface Resource as FlashResource;
        interface Resource as RadioResource;
        interface FastSpiByte as RadioFSPI;
        interface GeneralIO as RadioSELN; 
    }
}
implementation
{
    #define PDCA_SPI_TX 1
    #define PDCA_SPI_RX 2
    
    //Flash byte coding data, last transfer and PCS
    #define FLBYTE(x,lt) ((lt<<24) | 0xFE0000 | (x))
    #define FLASH_BAUD_RATE 2000000
    #define FLASH_POSTCS_DELAY 2
    #define FLASH_IXF_DELAY 2
    
    bool transfer_busy;
    typedef enum pdca_channel_status pdca_channel_status_t;
    
    #define MAX_XFER 2048
    uint32_t dummy_tx [MAX_XFER];
    uint16_t xfer_size;
    uint32_t rdcmd_tx [16];
    uint32_t rdcmd_rx [16];
    
    typedef enum
    {
        OWN_NONE,
        OWN_FLASH,
        OWN_RADIO
    } owner_t;
    
    owner_t owner;
    
    bool radio_req;
    bool flash_req;
    
    static pdca_channel_config_t pdca_tx_configs = {
        .addr   = (void *)0,      /* memory address              */
        .pid    = 22,                       //SPI_TX
        .size   = 0,                        /* transfer counter            */
        .r_addr = 0,                        /* next memory address         */
        .r_size = 0,                        /* next transfer counter       */
        .etrig  = false,                    /* disable the transfer upon event
									         * trigger */
        .ring   = false,                    /* disable ring buffer mode    */
        .transfer_size = PDCA_MR_SIZE_WORD  /* select size of the transfer */
    };
    
    static pdca_channel_config_t pdca_rx_configs = {
        .addr   = (void *)0,    /* memory address              */
        .pid    = 4,                        //SPI_TX
        .size   = 0,                        /* transfer counter            */
        .r_addr = 0,                        /* next memory address         */
        .r_size = 0,                        /* next transfer counter       */
        .etrig  = false,                    /* disable the transfer upon event
									         * trigger */
        .ring   = false,                    /* disable ring buffer mode    */
        .transfer_size = PDCA_MR_SIZE_WORD  /* select size of the transfer */
    };

    void  spi_tx_done (pdca_channel_status_t status) @C()
    {
         pdca_channel_disable_interrupt(PDCA_SPI_TX, PDCA_IER_TRC);
         //Undo the last xfer flag on the final byte
         dummy_tx[xfer_size-1] = FLBYTE(0, 0);

    }
    void spi_rx_done (pdca_channel_status_t status) @C()
    {
         pdca_channel_disable_interrupt(PDCA_SPI_RX, PDCA_IER_TRC);

         transfer_busy = FALSE;
         signal SPIMux.flash_transfer_complete();
    }
    
    async command void RadioSELN.set()
    {
        ioport_set_pin_level(PIN_PC01, 1);
    }
    async command void RadioSELN.clr()
    {
        ioport_set_pin_level(PIN_PC01, 0);
    }
    async command void RadioSELN.toggle()
    {
        ioport_toggle_pin_level(PIN_PC01);
    }
    async command bool RadioSELN.get()
    {
        return ioport_get_pin_level(PIN_PC01);
    }
    async command void RadioSELN.makeInput()
    {
        //No you don't
    }
    async command bool RadioSELN.isInput()
    {
        return FALSE;
    }
    async command void RadioSELN.makeOutput()
    {
        //It is already
    }
    async command bool RadioSELN.isOutput()
    {
        return TRUE;
    }
    command error_t Init.init()
    {
        uint16_t i;
        xfer_size = 0;
        ioport_set_pin_mode(PIN_PC05A_SPI_MOSI, MUX_PC05A_SPI_MOSI);
        ioport_disable_pin(PIN_PC05A_SPI_MOSI);
        ioport_set_pin_mode(PIN_PC04A_SPI_MISO, MUX_PC04A_SPI_MISO);
        ioport_disable_pin(PIN_PC04A_SPI_MISO);
        ioport_set_pin_mode(PIN_PC06A_SPI_SCK, MUX_PC06A_SPI_SCK);
        ioport_disable_pin(PIN_PC06A_SPI_SCK);
        ioport_set_pin_mode(PIN_PC03A_SPI_NPCS0, MUX_PC03A_SPI_NPCS0); //FL CS
        ioport_disable_pin(PIN_PC03A_SPI_NPCS0);
        
        //For auto CS
        //ioport_set_pin_mode(PIN_PC01A_SPI_NPCS3, MUX_PC01A_SPI_NPCS3); //RAD CS
        //ioport_disable_pin(PIN_PC01A_SPI_NPCS3);
        //Radio manages CS manually
        ioport_set_pin_mode(PIN_PC01A_SPI_NPCS3, 0);
        ioport_set_pin_dir(PIN_PC01, IOPORT_DIR_OUTPUT);
        ioport_enable_pin(PIN_PC01);
        ioport_set_pin_level(PIN_PC01, 1);
        
        spi_enable_clock(SPI);
        spi_reset(SPI);
        spi_set_master_mode(SPI);
        spi_disable_mode_fault_detect(SPI);
        spi_disable_loopback(SPI);
      //  spi_set_peripheral_chip_select_value(SPI, spi_get_pcs(0));
        //spi_set_fixed_peripheral_select(SPI);
        spi_set_variable_peripheral_select(SPI);
        spi_disable_peripheral_select_decode(SPI);
        spi_set_delay_between_chip_select(SPI, 1);
        spi_set_transfer_delay(SPI, 0, FLASH_POSTCS_DELAY, FLASH_IXF_DELAY);
        
        spi_set_bits_per_transfer(SPI, 0, 8);
        spi_set_baudrate_div(SPI, 0, spi_calc_baudrate_div(FLASH_BAUD_RATE, sysclk_get_cpu_hz()));
        spi_configure_cs_behavior(SPI, 0, SPI_CS_KEEP_LOW);
        spi_set_clock_polarity(SPI, 0, 1); //SPI mode 3 for flash
        spi_set_clock_phase(SPI, 0, 0);
        
        spi_set_bits_per_transfer(SPI, 3, 8);
        spi_set_baudrate_div(SPI, 3, spi_calc_baudrate_div(FLASH_BAUD_RATE, sysclk_get_cpu_hz()));
        spi_configure_cs_behavior(SPI, 3, SPI_CS_KEEP_LOW);
        spi_set_clock_polarity(SPI, 3, 0); //SPI mode 0 for radio
        spi_set_clock_phase(SPI, 3, 1);
        
        spi_enable(SPI);
    /*
        rdcmd_tx[0] = FLBYTE(0x1B, 0);
        rdcmd_tx[4] = FLBYTE(0, 0);
        rdcmd_tx[5] = FLBYTE(0, 0);
        
        transfer_busy = FALSE;
        radio_req = FALSE;
        flash_req = FALSE;
        
        pdca_enable(PDCA);

        pdca_channel_set_config(PDCA_SPI_TX, &pdca_tx_configs);
        pdca_channel_set_config(PDCA_SPI_RX, &pdca_rx_configs);
        

    
        atomic
        {
            pdca_channel_enable(PDCA_SPI_TX);
            pdca_channel_enable(PDCA_SPI_RX);

            // This automatically enables interrupts and will cause a wild IRQ to appear..
            
            pdca_channel_set_callback(PDCA_SPI_TX, spi_tx_done, PDCA_1_IRQn, 1, PDCA_IER_TRC);
            pdca_channel_set_callback(PDCA_SPI_RX, spi_rx_done, PDCA_2_IRQn, 1, PDCA_IER_TRC);
            
            pdca_channel_disable_interrupt(PDCA_SPI_TX, PDCA_IER_TRC);
            pdca_channel_disable_interrupt(PDCA_SPI_RX, PDCA_IER_TRC);
        
            // .. so we get rid of it
            NVIC_ClearPendingIRQ(PDCA_1_IRQn);
            NVIC_ClearPendingIRQ(PDCA_2_IRQn);
        }

        for (i = 0; i < MAX_XFER; i++)
        {
            dummy_tx[i] = FLBYTE(0, 0);
        }
        
        */
        owner = OWN_NONE;
        
        return SUCCESS;
    }


    default  event void RadioResource.granted(){}
    default  event void FlashResource.granted(){}
    /**
	 * Starts a split-phase SPI data transfer with the given data.
	 * A splitRead/splitReadWrite command must follow this command even 
	 * if the result is unimportant.
	 */
	async command void RadioFSPI.splitWrite(uint8_t data)
	{
	    while(!spi_is_tx_ready(SPI));
	    spi_write(SPI, data, spi_get_pcs(3), 0);
	}

	/**
	 * Finishes the split-phase SPI data transfer by waiting till 
	 * the write command comletes and returning the received data.
	 */
	async command uint8_t RadioFSPI.splitRead()
	{
	    while(!spi_is_rx_ready(SPI));
	    return (uint8_t) spi_get(SPI);
	}

	/**
	 * This command first reads the SPI register and then writes
	 * there the new data, then returns. 
	 */
	async command uint8_t RadioFSPI.splitReadWrite(uint8_t data)
	{
	    uint8_t rv;
	    while(!spi_is_rx_ready(SPI));
	    rv = (uint8_t) spi_get(SPI);
	    while(!spi_is_tx_ready(SPI));
	    spi_write(SPI, data, spi_get_pcs(3), 0);
	    return rv;
	}

	/**
	 * This is the standard SpiByte.write command but a little
	 * faster as we should not need to adjust the power state there.
	 * (To be consistent, this command could have be named splitWriteRead).
	 */
	async command uint8_t RadioFSPI.write(uint8_t data)
	{
	    call RadioFSPI.splitWrite(data);
	    return call RadioFSPI.splitRead();
	}
	
    task void check_resources()
    {
        if (owner != OWN_NONE)
            return;
        if (radio_req)
        {
            owner = OWN_RADIO;
            radio_req = FALSE;
            pdca_channel_disable(PDCA_SPI_TX);
            pdca_channel_disable(PDCA_SPI_RX);
            signal RadioResource.granted();
        }
        else if (flash_req)
        {
            owner = OWN_FLASH;
            flash_req = FALSE;
            pdca_channel_enable(PDCA_SPI_TX);
            pdca_channel_enable(PDCA_SPI_RX);
            signal FlashResource.granted();
        }
    }
    
    async command error_t FlashResource.release()
    {
        if (owner == OWN_FLASH)
        {
            owner = OWN_NONE;
            post check_resources();
            return SUCCESS;
        }
        else
        {
            return FAIL;
        }
    }
    async command error_t FlashResource.request()
    {
        if (flash_req)
        {
            return EBUSY;
        }
        else
        {
            flash_req = TRUE;
            post check_resources();
            return SUCCESS;
        }
    }
    async command error_t FlashResource.immediateRequest()
    {
        if (owner == OWN_NONE)
        {
            flash_req = FALSE;
            owner = OWN_FLASH;
            return SUCCESS;
        }
        else
        {
            return FAIL;
        }
    }
    async command bool FlashResource.isOwner()
    {
        return owner == OWN_FLASH;
    }
    
    async command error_t RadioResource.release()
    {
        if (owner == OWN_RADIO)
        {
            owner = OWN_NONE;
            ioport_set_pin_level(PIN_PC01, 1);
            post check_resources();
            return SUCCESS;
        }
        else
        {
            return FAIL;
        }
    }
    async command error_t RadioResource.request()
    {
        bl_printf("rrq\n");
        if (radio_req)
        {
            return EBUSY;
        }
        else
        {
            radio_req = TRUE;
            post check_resources();
            return SUCCESS;
        }
    }
    
    async command error_t RadioResource.immediateRequest()
    {
        if (owner == OWN_NONE)
        {
            radio_req = FALSE;
            owner = OWN_RADIO;
            pdca_channel_disable(PDCA_SPI_TX);
            pdca_channel_disable(PDCA_SPI_RX);
            return SUCCESS;
        }
        else
        {
            return FAIL;
        }
    }
    async command bool RadioResource.isOwner()
    {
        return owner == OWN_RADIO;
    }
    
    async command error_t SPIMux.initiate_flash_transfer(uint32_t* rx, uint16_t bufsize, uint32_t addr)
    {
        if (transfer_busy)
        {
            return EBUSY;
        }
        
        rdcmd_tx[1] = FLBYTE(((uint8_t) (addr >> 16)),0);
        rdcmd_tx[2] = FLBYTE(((uint8_t) (addr >> 8)),0);
        rdcmd_tx[3] = FLBYTE(((uint8_t) (addr)),0);
        
        xfer_size = bufsize;
        dummy_tx[xfer_size-1] = FLBYTE(0,1);
        
        pdca_channel_write_load(PDCA_SPI_RX, (void *)rdcmd_rx, 6);
        pdca_channel_write_load(PDCA_SPI_TX, (void *)rdcmd_tx, 6);
        pdca_channel_write_reload(PDCA_SPI_RX, (void *)rx, bufsize);
        pdca_channel_write_reload(PDCA_SPI_TX, (void *)dummy_tx, bufsize);
        
        transfer_busy = TRUE;
        pdca_channel_enable_interrupt(PDCA_SPI_RX, PDCA_IER_TRC);
        pdca_channel_enable_interrupt(PDCA_SPI_TX, PDCA_IER_TRC);
        return SUCCESS;
    }

}
