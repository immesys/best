
configuration Ieee154AddressC {
  provides interface Ieee154Address;

} implementation {
  components Ieee154AddressP;
  components RealMainP;
  
  Ieee154AddressP.Init <- RealMainP.PlatformInit;
  Ieee154Address = Ieee154AddressP;
}
