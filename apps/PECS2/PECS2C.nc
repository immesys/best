
#include <ioport.h>
#include <ast.h>
#include "bldebug.h"

module PECS2C 
{
    uses
    {
        interface Boot;
        interface GeneralIO as p;
        interface Timer<TMilli> as t;
        interface Screen as scr;
    }
 
}

implementation
{

  uint32_t iteration @C();
  uint32_t _dbg_fire_count @C() = 0;
  uint32_t left = 10;
  event void t.fired()
  {
    _dbg_fire_count ++;
    call p.set();
    call p.clr();
    
    bl_printf("Fired count is: %u\n", _dbg_fire_count);
   
  }


  
  event void Boot.booted() {
    call scr.start();
    bldebug_init();
    iteration = 0;
    call p.makeOutput();
    call t.startPeriodic(500);
    
  }
}

