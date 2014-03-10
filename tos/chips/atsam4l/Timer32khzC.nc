

configuration Timer32khzC
{
    provides
    {
        interface Timer<T32khz> as Timer32khz;
    }
}
implementation
{
    components MainC;
    components Alarm32khzC;
    components HplASTP;
    components new AlarmToTimerC(T32khz);
    
    Alarm32khzC.HplAST -> HplASTP;
    Timer32khz = AlarmToTimerC.Timer;
    AlarmToTimerC.Alarm -> Alarm32khzC.Alarm32khz;
}
