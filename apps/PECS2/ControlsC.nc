configuration ControlsC
{
    provides interface Controls;
}
implementation
{
    components ControlsP;
    Controls = ControlsP;

    components MainC;

    ControlsP.Init <- MainC;
}