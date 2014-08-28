interface ADC
{
     command void config();

     async command void sample();
     async event void sampleComplete(uint16_t r);
}