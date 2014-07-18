
#include "Timer.h"

configuration HilTimerMilliC
{
  provides 
  {
      interface Init;
      interface Timer<TMilli> as TimerMilli[ uint8_t num ];
      interface LocalTime<TMilli>;
  }
}

implementation
{
    components TimingC;
    components NoInitC;
    
    Init = NoInitC;
    TimerMilli = TimingC.TimerMilli;
    LocalTime = TimingC.LocalTimeMilli;

}
