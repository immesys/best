
interface BLDebug
{
    async command void init();
    async command void printf(char* fmt, ...);
}
