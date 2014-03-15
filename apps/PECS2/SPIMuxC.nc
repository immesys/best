
configuration SPIMuxC
{
    provides interface SPIMux;
}
implementation
{
    components MainC, SPIMuxP;
    
    SPIMuxP.Init <- MainC.SoftwareInit;
    SPIMux = SPIMuxP.SPIMux;
}
