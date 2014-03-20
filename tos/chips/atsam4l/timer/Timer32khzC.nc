
generic configuration Timer32khzC()
{
    provides interface Timer<T32khz> as Timer32khz;
}
implementation
{
    components TimingC;
    Timer32khz = TimingC.Timer32khz[unique("storm.TimingC.Timer")];
}
