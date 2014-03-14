
#include <ioport.h>
#include <ast.h>
#include "bldebug.h"

module PECS2C 
{
    uses
    {
        interface Boot;
        interface GeneralIO as p;
        //interface Timer<T32khz> as t;
        interface Alarm<T32khz, uint32_t> as a;
    }
 
}

implementation
{

  uint32_t iteration @C();
  uint32_t _dbg_fire_count @C() = 0;
  async event void a.fired()
  {
    _dbg_fire_count ++;
    call p.set();
    call p.clr();
    
    bl_printf("Fired count is: %u\n", _dbg_fire_count);
    call a.start(1638);
  }

  
  event void Boot.booted() {
    bldebug_init();
    iteration = 0;
    call p.makeOutput();
    call a.start(1638);
   // call HplASTPi.init();
  
  }
}

