
#include <stdint.h>
#include <pdca.h>
#include <usart.h>
#include <stdarg.h>
#include <sysclk.h>
#include <ioport.h>

static char txbuf[512];
#define PDCA_TX_CHANNEL 0

/* PDCA channel options */
static pdca_channel_config_t pdca_tx_configs = {
    .addr   = (void *)txbuf,            /* memory address              */
    .pid    = 21,                       //USART3_TX
    .size   = 0,                         /* transfer counter            */
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



void bldebug_init()
{
    ioport_set_pin_mode(PIN_PB10A_USART3_TXD, MUX_PB10A_USART3_TXD);
    ioport_disable_pin(PIN_PB10A_USART3_TXD);
    ioport_set_pin_mode(PIN_PB09A_USART3_RXD, MUX_PB09A_USART3_RXD);
    ioport_disable_pin(PIN_PB09A_USART3_RXD);
    sysclk_enable_peripheral_clock(USART3);
    usart_reset(USART3);
    usart_init_rs232(USART3, &usart_settings, sysclk_get_main_hz());
    usart_enable_tx(USART3);
    usart_enable_rx(USART3);

 //   while(1)
  //  {
  //      usart_putchar(USART3, 'x');
  //  }
    
  //  sprintf(txbuf, "lol %d %dsdf sdfsdf sdf sdf",1337,5012);
    /* Enable PDCA module clock */
    pdca_enable(PDCA);

    /* Init PDCA channel with the pdca_options.*/
    pdca_channel_set_config(PDCA_TX_CHANNEL, &pdca_tx_configs);

    /* Enable PDCA channel */
    pdca_channel_enable(PDCA_TX_CHANNEL);
    
   // pdca_channel_set_callback(PDCA_TX_CHANNEL, pdca_tranfer_done, PDCA_0_IRQn,
	//	1, PDCA_IER_RCZ);
}


void bl_printf(char* fmt, ...)
{
    va_list args;
    int cnt;
    uint32_t tmt;
    uint32_t d_stat;
    volatile uint32_t d_copy;
    va_start(args, fmt);
    
    for (tmt = 1000000; tmt > 0 && pdca_get_channel_status(PDCA_TX_CHANNEL) != PDCA_CH_TRANSFER_COMPLETED; tmt--);
    cnt = vsnprintf(&txbuf[0], 511, fmt, args);
    pdca_channel_write_reload(PDCA_TX_CHANNEL, (void*) &txbuf[0], cnt);
  //  usart_putchar(USART3, 'X');
    va_end(args);
}

int lowlevel_putc(int c)
{
    usart_putchar(USART3, c);
    return 1;
}

void blspike()
{
    ioport_set_pin_level(PIN_PB08, 1);
    ioport_set_pin_level(PIN_PB08, 1);
    ioport_set_pin_level(PIN_PB08, 0);
}
void blassert(uint8_t condition, const char* file, uint16_t line) 
{
    uint32_t newstate = 1;
    if (!condition)
    {
        bl_printf("ASSERTION FAILED %s:%d\n",file, line);
        asm volatile(
		"msr primask, %0"
		: // output
		: "r" (newstate) // input
	    );
        while(1);
    }
}


