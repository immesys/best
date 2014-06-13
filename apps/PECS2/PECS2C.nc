
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


    }

    event void t.fired()
    {

    }

    
    
    event void Boot.booted() 
    {
        bl_printf("system booted\n");
        call scr.start();
        bl_printf("return from screen start\n");
    }
}

