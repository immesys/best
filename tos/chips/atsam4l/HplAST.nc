
interface HplAST
{

    async command void start();
    
    async command void stop();
    
    async command bool isRunning();

    async command uint32_t getCounterValue();
    async command void setCounterValue(uint32_t v);

    async command void setAlarmValue(uint32_t);
    async command uint32_t getAlarmValue();

    async command void enableAlarmInterrupt();
    async command void disableAlarmInterrupt();
    async command void clearAlarmInterrupt();

    async command void enableOverflowInterrupt();
    async command void disableOverflowInterrupt();
    async command void clearOverflowInterrupt();

    //Events
    async event void overflowFired();
    async event void alarmFired();

}
