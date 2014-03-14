
configuration PECSAppC{}
implementation {
  components MainC, PECS2C;
  components HplSam4GPIOC as pins;
  components Alarm32khzC;
  components HplASTP;
  
  HplASTP.Init <- MainC.SoftwareInit;
   PECS2C.a -> Alarm32khzC;
 // NullC.HplASTP -> HplASTP.HplAST;
 // NullC.HplASTPi -> HplASTP.Init;
  Alarm32khzC.HplAST -> HplASTP.HplAST;
  pins.PB8 <-  PECS2C.p;
  MainC.Boot <-  PECS2C;
}

