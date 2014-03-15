
#include "Timer.h"

configuration HilTimer32khzC
{
  provides 
  {
   //   interface Init;
      interface Timer<T32khz> as Timer32khz[ uint8_t num ];
      interface LocalTime<T32khz>;
  }
}

implementation
{
  components new VirtualizeTimerC(T32khz,uniqueCount(UQ_TIMER_32KHZ)) as VirtTimers32khz32;
  components new AlarmToTimerC(T32khz) as AlarmToTimer32khz32;
 // components new Alarm32khzC() as Alarm32khz32;
  components Alarm32khzC; 
  components HplASTP;
  components RealMainP;
  
  
  HplASTP.Init <- RealMainP.PlatformInit;
  
  
 // Init = HplASTP;
  Alarm32khzC.HplAST -> HplASTP.HplAST;
  Timer32khz = VirtTimers32khz32.Timer;
  LocalTime = HplASTP;
  
  VirtTimers32khz32.TimerFrom -> AlarmToTimer32khz32.Timer;
  AlarmToTimer32khz32.Alarm -> Alarm32khzC.Alarm;
}
