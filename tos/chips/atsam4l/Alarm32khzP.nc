
#include "bldebug.h"

module Alarm32khzP
{
    provides
    {
        interface Alarm<T32khz, uint32_t> as Alarm;
    }
    uses
    {
        interface HplAST;
    }
}

implementation
{
    
    // basic interface
    /**
    * Set a single-short alarm to some time units in the future. Replaces
    * any current alarm time. Equivalent to start(getNow(), dt). The
    * <code>fired</code> will be signaled when the alarm expires.
    *
    * @param dt Time until the alarm fires.
    */
    async command void Alarm.start(uint32_t dt)
    {   
        call HplAST.stop();
        call HplAST.enableAlarmInterrupt();
        call HplAST.setAlarmValue(call HplAST.getCounterValue() + dt);
        call HplAST.start();
    }

    /**
    * Cancel an alarm. Note that the <code>fired</code> event may have
    * already been signaled (even if your code has not yet started
    * executing).
    */
    async command void Alarm.stop()
    {
        call HplAST.stop();
    }

    // extended interface
    /**
    * Check if alarm is running. Note that a FALSE return does not indicate
    * that the <code>fired</code> event will not be signaled (it may have
    * already started executing, but not reached your code yet).
    *
    * @return TRUE if the alarm is still running.
    */
    async command bool Alarm.isRunning()
    {
        return call HplAST.isRunning();
    }

    /**
    * Set a single-short alarm to time t0+dt. Replaces any current alarm
    * time. The <code>fired</code> will be signaled when the alarm expires.
    * Alarms set in the past will fire "soon".
    * 
    * <p>Because the current time may wrap around, it is possible to use
    * values of t0 greater than the <code>getNow</code>'s result. These
    * values represent times in the past, i.e., the time at which getNow()
    * would last of returned that value.
    *
    * @param t0 Base time for alarm.
    * @param dt Alarm time as offset from t0.
    */
    async command void Alarm.startAt(uint32_t t0, uint32_t dt)
    {

        uint32_t t1 = t0 + dt;
        uint32_t n = call HplAST.getCounterValue();
        
        //bl_printf("ASA %d %d %d - %d \n", t0, t1, dt, n);
                
        call HplAST.stop();
        if ( (t0 <= n && n < t1) ||
             (t1 < n && n < t0) )
        {//now is between the two events
            if (t1 < t0)
            {
                signal Alarm.fired();
            }
            else
            {
                call HplAST.setAlarmValue(t1);
            }
        }
        else
        {
            if (t0 <= t1)
            {
                signal Alarm.fired();
            }
            else
            {
                call HplAST.setAlarmValue(t1);
            }
        }
        call HplAST.start();
    }

    /**
    * Return the current time.
    * @return Current time.
    */
    async command uint32_t Alarm.getNow()
    {
        return call HplAST.getCounterValue();
    }
    

    /**
    * Return the time the currently running alarm will fire or the time that
    * the previously running alarm was set to fire.
    * @return Alarm time.
    */
    async command uint32_t Alarm.getAlarm()
    {
        return call HplAST.getAlarmValue();
    }
    
    async event void HplAST.alarmFired()
    {
        call HplAST.clearAlarmInterrupt();
      //  bl_printf("AF %u\n", call Alarm.getNow());
        signal Alarm.fired();

    }
    
    async event void HplAST.overflowFired()
    {
        call HplAST.clearOverflowInterrupt();
    }
    
}
