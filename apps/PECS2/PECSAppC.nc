
configuration PECSAppC{}
implementation {
  components MainC, PECS2C;
  components HplSam4GPIOC as pins;
  components new TimerMilliC();
  
  components ScreenC;

  PECS2C.scr -> ScreenC;
  PECS2C.t -> TimerMilliC;
  pins.PB8 <-  PECS2C.p;
  MainC.Boot <-  PECS2C;
}

