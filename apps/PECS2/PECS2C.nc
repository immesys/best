
#include <ioport.h>
#include <ast.h>
#include "bldebug.h"

module PECS2C 
{
    uses
    {
        interface Boot;
        interface GeneralIO as p;
        interface Timer<T32khz> as t;
        interface Screen as scr;
        interface SPIMux as mux;
        interface GpioCapture as IRQ;
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
  event void t.fired()
  {
    _dbg_fire_count ++;
    call p.set();
    call p.clr();
    
   // bl_printf("First message\n");
  //  bl_printf("Second message\n");
   // bl_printf("Fired count is: %u\n", _dbg_fire_count);
   
  }
  async event void IRQ.captured(uint16_t tm)
  {
     bl_printf("Cap %d\n", tm);
  }
  task void rearm()
  {
    bl_printf("Arming for rising edge\n");
     call IRQ.captureRisingEdge();
  }
  task void foo()
  {
    call mux.initiate_flash_transfer(&spi_rx_buff_a[0], 32, 0x0080000);
  }
  task void printbuffer()
  {
    uint32_t bar;
    for (bar = 0; bar < 32; bar++)
    {
        bl_printf(":%d\n",(uint8_t)(spi_rx_buff_a[bar]));
    }
    post foo();
  }
  async event void mux.flash_transfer_complete()
  {
    volatile uint32_t bar2;
    bar2 = 1337;
    bar2++;
    post printbuffer();
    
  }

  
  event void Boot.booted() {
    bldebug_init();
    bl_printf("BooteD!\n");
    call scr.start();
    iteration = 0;
    call p.makeOutput();
    call t.startPeriodic(16000);
   // post foo();
   post rearm();
  }
}

