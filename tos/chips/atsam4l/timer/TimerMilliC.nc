
generic configuration TimerMilliC()
{
    provides interface Timer<TMilli> as Timer;
}
implementation
{
    components TimingC;
    Timer = TimingC.TimerMilli[unique("storm.TimingC.TimerMilli")];
}
