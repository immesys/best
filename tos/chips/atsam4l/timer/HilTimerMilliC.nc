
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
  components new VirtualizeTimerC(TMilli,uniqueCount(UQ_TIMER_MILLI)) as VirtTimersMilli32;
  components new AlarmToTimerC(TMilli) as AlarmToTimerMilli32;
 // components new AlarmMilliC() as AlarmMilli32;
  components Alarm32khzC; 
  components HplASTP;
  
  Init = HplASTP;
  Alarm32khzC.HplAST -> HplASTP.HplAST;
  TimerMilli = VirtTimersMilli32.Timer;
  LocalTime = HplASTP;
  
  VirtTimersMilli32.TimerFrom -> AlarmToTimerMilli32.Timer;
  AlarmToTimerMilli32.Alarm -> Alarm32khzC.Alarm;
}
