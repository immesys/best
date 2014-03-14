
configuration ScreenC
{
    provides interface Screen;
}
implementation
{
    components MainC, ScreenP;
    ScreenP.Init <- MainC.SoftwareInit;
    Screen = ScreenP.Screen;
}
