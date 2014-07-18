

configuration LedsC {
  provides interface Leds;
}
implementation {
  components NoLedsC;
  Leds = NoLedsC;
}

