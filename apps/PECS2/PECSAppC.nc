
configuration PECSAppC{}
implementation
{
    components MainC, PECS2C;
    components HplSam4GPIOC as pins;
    components new Timer32khzC();
    components SPIMuxC;
    components ScreenC;
    components RIRQP;
    components HilTimer32khzC;
    components RealMainP;
    
    RIRQP.clk -> HilTimer32khzC.LocalTime;
    RIRQP.PlatformInit <- RealMainP.PlatformInit;
    PECS2C.IRQ -> RIRQP.IRQ;
    
    PECS2C.mux -> SPIMuxC;
    PECS2C.scr -> ScreenC;
    PECS2C.t -> Timer32khzC;
    pins.PB8 <-  PECS2C.p;
    MainC.Boot <-  PECS2C;
    
}

