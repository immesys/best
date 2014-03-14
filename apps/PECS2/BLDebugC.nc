
module BLDebugC
{
    provides interface BLDebug;
}
implementation
{
    char txbuf[512];
    #define PDCA_TX_CHANNEL 0
    
    /* PDCA channel options */
    static pdca_channel_config_t pdca_tx_configs = {
	    .addr   = (void *)txbuf,            /* memory address              */
	    .pid    = 21,                       //USART3_TX
	    .size   = 0                         /* transfer counter            */
	    .r_addr = 0,                        /* next memory address         */
	    .r_size = 0,                        /* next transfer counter       */
	    .etrig  = false,                    /* disable the transfer upon event
										     * trigger */
	    .ring   = false,                    /* disable ring buffer mode    */
	    .transfer_size = PDCA_MR_SIZE_BYTE  /* select size of the transfer */
    };
    
    const sam_usart_opt_t usart_settings = {
     115200,
     US_MR_CHRL_8_BIT,
     US_MR_PAR_NO, //TODO change
     US_MR_NBSTOP_1_BIT,
     US_MR_CHMODE_NORMAL
    };

    async command void init()
    {
        usart_reset(USART3);
        usart_init_rs232(USART3, &usart_settings, sysclk_get_main_hz());
        usart_enable_tx(USART3);
        
        /* Enable PDCA module clock */
	    pdca_enable(PDCA);

	    /* Init PDCA channel with the pdca_options.*/
	    pdca_channel_set_config(PDCA_TX_CHANNEL, &pdca_tx_configs);

	    /* Enable PDCA channel */
	    pdca_channel_enable(PDCA_TX_CHANNEL);
    }



    #if 0
    /**
     * \brief Interrupt handler for UART interrupt.
     */
    static void pdca_tranfer_done(enum pdca_channel_status status)
    {
	    /* Get PDCA channel status and check if PDCA transfer complete */
	    if (status == PDCA_CH_TRANSFER_COMPLETED) {
		    /* Configure PDCA for data transfer */
		    if (bool_anim == 1){
			    pdca_channel_write_reload(PDCA_TX_CHANNEL, (void *)ascii_anim2,
				    sizeof( ascii_anim2 ));
			    bool_anim = 2;
		    } else {
			    pdca_channel_write_reload(PDCA_TX_CHANNEL, (void *)ascii_anim1,
				    sizeof( ascii_anim1 ));
			    bool_anim = 1;
		    }
	    }
    }
    #endif


    
    async command void printf(char* fmt, ...)
    {
        va_list args;
        int cnt;
        char* p = &txbuf[0];
        va_start(args, fmt);
           
        while(pdca_get_channel_status != 0); 
        cnt = vsnprintf(&txbuf[0], 511, fmt, args);
        pdca_channel_write_reload(PDCA_TX_CHANNEL, (void*) &txbuf[0], cnt);
        
        
        va_end(args);
    }
}
