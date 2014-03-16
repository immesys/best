
configuration TimingC
{
    provides
    {
        interface Alarm<T32khz, uint32_t> as Alarm32khz32[uint8_t id];
        interface Timer<T32khz> as Timer32khz [uint8_t id];
        interface LocalTime<T32khz> as LocalTime;
    }
}
implementation
{
    components MainC,
               Alarm32khzP,
               HplASTP,
               new AlarmToTimerC(T32khz),
               new VirtualizeAlarmC(T32khz, uint32_t, uniqueCount("storm.TimingC.Alarm")),
               new VirtualizeTimerC(T32khz, uniqueCount("storm.TimingC.Timer"));
   
    VirtualizeAlarmC.Init <- MainC.SoftwareInit;
  //  VirtualizeTimerC.Init <- MainC.SoftwareInit;
  //  AlarmToTimerC.Init <- MainC.SoftwareInit;
    
    LocalTime = HplASTP.LocalTime;
    
    Alarm32khzP.HplAST -> HplASTP;
    MainC.SoftwareInit -> HplASTP.Init;
    
    VirtualizeAlarmC.AlarmFrom -> Alarm32khzP.Alarm;
    AlarmToTimerC.Alarm -> VirtualizeAlarmC.Alarm[unique("storm.TimingC.Alarm")];
    
    VirtualizeTimerC.TimerFrom -> AlarmToTimerC.Timer;
    
    Timer32khz = VirtualizeTimerC.Timer;
    Alarm32khz32 = VirtualizeAlarmC.Alarm;
    
}
