configuration ControlsC
{
    provides interface Controls;
    uses interface FlashLogger;
}
implementation
{
    components ControlsP;
    Controls = ControlsP;

    components MainC;
    components new TimerMilliC() as controlt;
    components new TimerMilliC() as periodict;
    components new TimerMilliC() as pwmt;

    ControlsP.Init <- MainC;
    ControlsP.touchTmr -> controlt;
    ControlsP.reportTmr -> periodict;
    ControlsP.pwmTmr -> pwmt;

    ControlsP.FlashLogger = FlashLogger;
}