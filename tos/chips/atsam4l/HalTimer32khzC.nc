

configuration HalTimer32khzC
{
    provides
    {
        interface Timer<T32khz> as Timer32khz;
        interface LocalTime<T32khz> as LocalTime;
    }
}
implementation
{
    components MainC;
    components Alarm32khzC;
    components HplASTP;
    components new AlarmToTimerC(T32khz);
    
    LocalTime = HplASTP.LocalTime;
    Alarm32khzC.HplAST -> HplASTP;
    Timer32khz = AlarmToTimerC.Timer;
    AlarmToTimerC.Alarm -> Alarm32khzC.Alarm;
}
