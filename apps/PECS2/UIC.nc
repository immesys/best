configuration UIC
{

}
implementation
{
    components ControlsC;
    components MainC;
    components ScreenC;
    components SPIMuxC;
    components UIP;
    components new TimerMilliC() as uit;
    components new TimerMilliC() as dimmert;
    components TimingC;

   // components LoggingUARTP;

    components new SimpleRoundRobinArbiterC("flash_spi") as farbiter;
    components FlashLoggerP;

    UIP.Screen -> ScreenC;
    UIP.Boot -> MainC;
    UIP.Init <- MainC;
    UIP.tmr -> uit;
    UIP.dimmert -> dimmert;
    UIP.Controls -> ControlsC;

    ControlsC.FlashLogger -> FlashLoggerP;

  //  ControlsC.Screen -> ScreenC;
  //  ControlsC.Boot -> MainC;


    ScreenC.SPIMux -> SPIMuxC;
    ScreenC.FlashResource -> farbiter.Resource[unique("flash_spi")];

   // LoggingUARTP.Init <- MainC;
    FlashLoggerP.flash_iface -> SPIMuxC;
    FlashLoggerP.flash_resource -> farbiter.Resource[unique("flash_spi")];
    FlashLoggerP.Init <- MainC;
    FlashLoggerP.Boot -> MainC;
   // FlashLoggerP.BLE -> LoggingUARTP.BLE;
    FlashLoggerP.counter -> TimingC.CounterMilli;

}