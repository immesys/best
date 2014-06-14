
configuration ScreenC
{
    provides interface Screen;
    uses
    {
        interface SPIMux;
        interface Resource as FlashResource;
    }

}
implementation
{
    components MainC, ScreenP;
    ScreenP.Init <- MainC.SoftwareInit;
    Screen = ScreenP.Screen;
    ScreenP.SPIMux = SPIMux;
    ScreenP.FlashResource = FlashResource;

}
