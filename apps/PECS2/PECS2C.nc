
#include <ioport.h>
#include <ast.h>
#include "bldebug.h"
#include <lib6lowpan/6lowpan.h>
#include <IPDispatch.h>
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/ip.h>

module PECS2C 
{
    uses
    {
        interface Boot;
        interface GeneralIO as p;

        interface Screen as scr;
        interface SPIMux as mux;
    
      //  interface SplitControl as RadioControl;
      //  interface UDP as sock;
        
        interface Timer<TMilli> as t;
    }
 
}

implementation
{

    static uint32_t spi_tx_buff   [2048];
    static uint32_t spi_rx_buff_a [2048];
    static uint32_t spi_rx_buff_b [2048];
    
    uint32_t iteration @C();
    uint32_t _dbg_fire_count @C() = 0;
    uint32_t left = 10;

    uint32_t arr [32];

   /* event void RadioControl.startDone(error_t e)
    {
        bl_printf("Radio started, error: %d\n",e);
    }
    event void RadioControl.stopDone(error_t e)
    {
        bl_printf("Radio stopped, error: %d\n", e);
    }
    event void sock.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip6_metadata *meta)
    {
        bl_printf("Got packet\n");
    }   */




    async event void mux.flash_transfer_complete()
    {
        /*
        uint8_t starr [32];
        uint8_t i;
        for (i=0;i<32;i++) starr[i] = (uint8_t) arr[i];
        starr[5] =0;
        bl_printf("read complete, value: %s", starr);
        */
    }

    event void t.fired()
    {

    }

    async event void mux.flash_write_complete()
    {
        //bl_printf("SPI transfer complete!\n");
    }

    event void scr.blit_window_complete()
    {
        bl_printf("Blit complete\n");
    }
    event void Boot.booted() 
    {
        uint32_t targetaddr = 0x0080000;
        uint8_t* myarr = "herro world";

        bl_printf("system booted\n");

        //call mux.initiate_flash_write(&myarr[0], 12, targetaddr);
        //call mux.initiate_flash_transfer(&arr[0], 8, targetaddr);
        call scr.start();
        call scr.blit_window(10, 10, 190, 50, 0, 0, 190, 50, 0x0090b00);

        bl_printf("return from screen start\n");
    }
}

