
#include "flash_logger.h"

module FlashLoggerP
{
    uses interface SPIMux as flash_iface;
    uses interface Resource as flash_resource;
    provides interface FlashLogger;
    provides interface Init;
}

implementation
{
    
    bool log_in_progress;
    uint32_t write_idx;
    uint8_t rxbuffer[32];
    flash_record_t next_write;
    
    command error_t Init.init()
    {
        log_in_progress = False;
        write_idx = 0; //TODO replace this with metablock read
    }
    async command void FlashLogger.log_record(flash_record_t* r)
    {
        if (!log_in_progress)
        {
            next_write = *r;
            call flash_resource.request();
        }
        else
        {
            //Well this sucks, its like a log overrun
        }
    }
    async event flash_resource.granted()
    {
        flash_iface.initiate_flash_w
    }
}
