
configuration SPIMuxC
{
    //Used for SPI DMA transfers
    provides 
    {
        interface SPIMux;
        interface Resource as FlashResource;
        interface FastSpiByte as radioFSPI;
        interface Resource as radioFSPIResource;
        interface GeneralIO as radioSELN;
    }
}
implementation
{
    components MainC, SPIMuxP;
    
    radioSELN = SPIMuxP.RadioSELN;
    radioFSPI = SPIMuxP.RadioFSPI;
    radioFSPIResource = SPIMuxP.RadioResource;
    FlashResource = SPIMuxP.FlashResource;
    SPIMuxP.Init <- MainC.SoftwareInit;
    SPIMux = SPIMuxP.SPIMux;
}
