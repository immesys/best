
configuration PECSAppC{}
implementation
{
    components MainC, PECS2C;
    components HplSam4GPIOC as pins;
  //  components new Timer32khzC();
    components SPIMuxC;
    components ScreenC;
   // components RIRQP;
   // components TimingC;
    components RealMainP;
    
    

 // components new Alarm32khz16C();
  //VirtualizeAlarmC.AlarmFrom -> Alarm32khz16C;
  
 //   RIRQP.clk -> TimingC.LocalTime;
  //  RIRQP.PlatformInit <- RealMainP.PlatformInit;
 //   PECS2C.IRQ -> RIRQP.IRQ;
    
    PECS2C.mux -> SPIMuxC;
    PECS2C.scr -> ScreenC;
  //  PECS2C.t -> TimingC.Timer32khz[unique("storm.TimingC.Timer")];
  //  PECS2C.alm -> TimingC.Alarm32khz32[unique("storm.TimingC.Alarm")];
    pins.PB8 <-  PECS2C.p;
    MainC.Boot <-  PECS2C;
    
    
     components new TimerMilliC();
     PECS2C.t -> TimerMilliC;
     
     
    components IPDispatchC, UdpC;
    components IPStackC;
    PECS2C.RadioControl -> IPStackC;
    components new UdpSocketC() as sock;
    PECS2C.sock -> sock;
    components StaticIPAddressTosIdC;
    components RPLRoutingC;
    components UDPShellC;

    // prints the routing table
    components RouteCmdC;
    
}

