
#include <pdca.h>
#include <stdint.h>
#include <usart.h>
#include <stdarg.h>
#include <sysclk.h>
#include <ioport.h>
#include <bldebug.h>



//Logging is connected to USART 0. RX is PB14, TX is PB15
module LoggingUARTP0
{
    provides interface BLE;
    provides interface Init;
}
implementation
{



/* PDCA channel options */
static pdca_channel_config_t pdca_tx_configs = {
    .addr   = (void *)0,            /* memory address              */
    .pid    = 18,                       //USART1_TX
    .size   = 0,                         /* transfer counter            */
    .r_addr = 0,                        /* next memory address         */
    .r_size = 0,                        /* next transfer counter       */
    .etrig  = false,                    /* disable the transfer upon event
									     * trigger */
    .ring   = false,                    /* disable ring buffer mode    */
    .transfer_size = PDCA_MR_SIZE_BYTE  /* select size of the transfer */
};

/* PDCA channel options */
static pdca_channel_config_t pdca_rx_configs = {
    .addr   = (void *)0,            /* memory address              */
    .pid    = 0,                       //USART1_RX
    .size   = 0,                         /* transfer counter            */
    .r_addr = 0,                        /* next memory address         */
    .r_size = 0,                        /* next transfer counter       */
    .etrig  = false,                    /* disable the transfer upon event
									     * trigger */
    .ring   = false,                    /* disable ring buffer mode    */
    .transfer_size = PDCA_MR_SIZE_BYTE  /* select size of the transfer */
};

static const sam_usart_opt_t usart_settings = {
 9600,
 US_MR_CHRL_8_BIT,
 US_MR_PAR_NO,
 US_MR_NBSTOP_1_BIT,
 US_MR_CHMODE_NORMAL
};

#define U0PDCA_TX 3
#define U0PDCA_RX 4

    typedef enum pdca_channel_status pdca_channel_status_t;

    #define SENT_F_1 0x70
    #define SENT_F_2 0xE5
    #define SENT_B_1 0xEB
    #define SENT_B_2 0xC4

    enum
    {
        st_w_fs1,
        st_w_fs2,
        st_w_cmd,
        st_w_val1,
        st_w_val2,
        st_w_val3,
        st_w_val4,
        st_w_bs1,
        st_w_bs2
    } command_state;

    uint8_t cmd;
    uint8_t val [4];
    uint8_t txbuf[21];
    uint8_t txbusy;

    void USART0_Handler(void) @C() @spontaneous()
    {
        uint8_t ch = USART0->US_RHR;
        NVIC_ClearPendingIRQ(USART0_IRQn);
        bl_printf("rx: %02x\n",ch);
        switch(command_state)
        {
            case st_w_fs1:
                bl_printf("fs1\n");
                if (ch == SENT_F_1)
                    command_state = st_w_fs2;
                    break;
            case st_w_fs2:
                bl_printf("fs2\n");
                if (ch == SENT_F_2)
                    command_state = st_w_cmd;
                else
                    command_state = st_w_fs1;
                break;

            case st_w_cmd:
                bl_printf("cmd: %02x\n",ch);
                cmd = ch;
                command_state = st_w_val1;
                break;
            case st_w_val1:
                val[0] = ch;
                command_state = st_w_val2;
                break;
            case st_w_val2:
                val[1] = ch;
                command_state = st_w_val3;
                break;
            case st_w_val3:
                val[2] = ch;
                command_state = st_w_val4;
                break;
            case st_w_val4:
                val[3] = ch;
                command_state = st_w_bs1;
                break;
            case st_w_bs1:
                if (ch == SENT_B_1)
                    command_state = st_w_bs2;
                else
                    command_state = st_w_fs1;
                break;
            case st_w_bs2:
                if (ch == SENT_B_2)
                {
                    if (cmd != 0x10) //resync
                        signal BLE.command_received(cmd, &val[0]);
                    command_state = st_w_fs1;
                }
                else
                {
                    command_state = st_w_fs1;
                }
                break;
            default:
                command_state = st_w_fs1;
                break;

        }
    }

    void u0pdca_tx_done (pdca_channel_status_t status) @C()
    {
        pdca_channel_disable_interrupt(U0PDCA_TX, PDCA_IER_TRC);
        txbusy = 0;
    }

   /* void u1pdca_rx_done (pdca_channel_status_t status) @C()
    {
         pdca_channel_disable_interrupt(U0PDCA_RX, PDCA_IER_TRC);

    }*/

    command error_t Init.init()
    {
        ioport_set_pin_mode(PIN_PB15A_USART0_TXD, MUX_PB15A_USART0_TXD);
        ioport_disable_pin(PIN_PB15A_USART0_TXD);
        ioport_set_pin_mode(PIN_PB14A_USART0_RXD, MUX_PB14A_USART0_RXD);
        ioport_disable_pin(PIN_PB14A_USART0_RXD);
        sysclk_enable_peripheral_clock(USART0);
        usart_reset(USART0);
        usart_init_rs232(USART0, &usart_settings, sysclk_get_main_hz());
        usart_enable_tx(USART0);
        usart_enable_rx(USART0);

        txbusy = 0;

        /* Enable PDCA module clock */
        pdca_enable(PDCA);

        /* Init PDCA channel with the pdca_options.*/
        pdca_channel_set_config(U0PDCA_TX, &pdca_tx_configs);
        //pdca_channel_set_config(U1PDCA_RX, &pdca_rx_configs);

        USART0->US_IER |= 1; //Enable RX interrupt

        atomic
        {
            /* Enable PDCA channel */
            pdca_channel_enable(U0PDCA_TX);
         //   pdca_channel_enable(U1PDCA_RX);
            NVIC_EnableIRQ(USART0_IRQn);

            // This automatically enables interrupts and will cause a wild IRQ to appear..
            pdca_channel_set_callback(U0PDCA_TX, u0pdca_tx_done, PDCA_3_IRQn, 1, PDCA_IER_TRC);
         //   pdca_channel_set_callback(U1PDCA_RX, u1pdca_rx_done, PDCA_4_IRQn, 1, PDCA_IER_TRC);

            pdca_channel_disable_interrupt(U0PDCA_TX, PDCA_IER_TRC);
          //  pdca_channel_disable_interrupt(U1PDCA_RX, PDCA_IER_TRC);

            // .. so we get rid of it
            NVIC_ClearPendingIRQ(PDCA_3_IRQn);
        //    NVIC_ClearPendingIRQ(PDCA_4_IRQn);
            NVIC_ClearPendingIRQ(USART0_IRQn);
        }

        return SUCCESS;
    }

    async command void BLE.send_packet(uint8_t* packet, uint8_t len)
    {
        if (txbusy) return;
        txbusy = 1;
        if (len > 20) len = 20;
        memcpy(txbuf, packet, len);
        bl_printf("Writing DMA reload for %d bytes\n", len);
        pdca_channel_write_reload(U0PDCA_TX, (void*) &txbuf[0], len);
        pdca_channel_enable_interrupt(U0PDCA_TX, PDCA_IER_TRC);
    }



}
