
configuration TimingC
{
    provides
    {
        interface Alarm<T32khz, uint32_t> as Alarm32khz32[uint8_t id];
        interface Timer<T32khz> as Timer32khz [uint8_t id];
        interface Timer<TMilli> as TimerMilli [uint8_t id];
        interface LocalTime<T32khz> as LocalTime;
        interface LocalTime<TMilli> as LocalTimeMilli;
        interface Counter<TMilli, uint32_t> as CounterMilli;
    }
}
implementation
{
    components MainC,
               Alarm32khzP,
               HplASTP,
               RealMainP,
               new AlarmToTimerC(T32khz),
               new AlarmToTimerC(TMilli) as ATTMilli,
               new VirtualizeAlarmC(T32khz, uint32_t, uniqueCount("storm.TimingC.Alarm")) as VAC,
               new VirtualizeTimerC(T32khz, uniqueCount("storm.TimingC.Timer")),
               new VirtualizeTimerC(TMilli, uniqueCount("storm.TimingC.TimerMilli")) as VTMilli,
               new CounterToLocalTimeC(TMilli),
               new TransformAlarmCounterC(TMilli, uint32_t, T32khz, uint32_t, 5, uint32_t);
              
    components TimingP;
    
    TimingP.Init <- RealMainP.PlatformInit;
    VAC.Init <- MainC.SoftwareInit;
    
    CounterMilli = TransformAlarmCounterC;
  //  VirtualizeTimerC.Init <- MainC.SoftwareInit;
  //  AlarmToTimerC.Init <- MainC.SoftwareInit;
    
    CounterToLocalTimeC.Counter -> TransformAlarmCounterC.Counter;
    LocalTimeMilli = CounterToLocalTimeC.LocalTime;
    LocalTime = HplASTP.LocalTime;
    
    Alarm32khzP.HplAST -> HplASTP;
    MainC.SoftwareInit -> HplASTP.Init;
    
    VAC.AlarmFrom -> Alarm32khzP.Alarm;
    AlarmToTimerC.Alarm -> VAC.Alarm[unique("storm.TimingC.Alarm")];
    
    VirtualizeTimerC.TimerFrom -> AlarmToTimerC.Timer;
    TransformAlarmCounterC.CounterFrom -> HplASTP.Counter;
    TransformAlarmCounterC.AlarmFrom -> VAC.Alarm[unique("storm.TimingC.Alarm")];
    ATTMilli.Alarm -> TransformAlarmCounterC.Alarm;
    
    VTMilli.TimerFrom -> ATTMilli.Timer;
    TimerMilli = VTMilli.Timer;
    Timer32khz = VirtualizeTimerC.Timer;
    Alarm32khz32 = VAC.Alarm;
    
}
