
#include "flash_logger.h"

module FlashLoggerP
{
    uses interface SPIMux as flash_iface;
    uses interface Resource as flash_resource;
    uses interface Counter<TMilli, uint32_t> as counter;

    provides interface FlashLogger;
    provides interface Init;
    uses interface Boot;
}

implementation
{
    uint32_t rxbuffer[sizeof(sense_metablock_t)];
    uint32_t upper_bits;
    sense_record_t next_write;
    sense_metablock_t mblock;

    enum
    {
        st_init,
        st_write_metablock,
        st_write_value,
        st_idle
    } fl_state;

    void dly()
    {
        volatile uint32_t i;
        for (i=0;i<300000;i++)
        {
             asm("nop");
        }

    }

    task void fl_init()
    {
        fl_state = st_init;
        call flash_resource.request();
    }
    command error_t Init.init()
    {
        fl_state = st_idle;
        post fl_init();
        upper_bits = 0;
    }

    event void Boot.booted()
    {
       // sense_record_t r;
       // r.type = FS_TYPE_REBOOT;
       // call FlashLogger.log_record(&r);

    }

    async command uint32_t FlashLogger.get_num_records()
    {
        return mblock.last_written_record;
    }
    async command void FlashLogger.query_record(uint32_t v)
    {
        //TODO
    }
    async command void FlashLogger.log_record(sense_record_t* r)
    {
        uint32_t now;
        if (mblock.last_written_record == FS_MAX_RECORDS)
        {
            bl_printf("badness: no more flash space\n");
        }
        now = call counter.get();
        r->ticks = ((uint64_t) now) + (((uint64_t) upper_bits) << 32);

        bl_printf("Logging FR %08x %08x\n", upper_bits, now);

        if (fl_state == st_idle)
        {
            fl_state = st_write_value;
            next_write = *r;
            bl_printf("Requesting flash resource\n");
            call flash_resource.request();
        }
        else
        {
            bl_printf("Flash logger overrun\n");
            //Well this sucks, its like a log overrun
        }
    }

    async event void counter.overflow()
    {
        upper_bits += 1;
    }

    task void to_idle()
    {
        if (call flash_resource.isOwner())
        {
            bl_printf("logger flash lock released\n");
            call flash_resource.release();
        }
        fl_state = st_idle;
    }
    async event void flash_iface.flash_transfer_complete()
    {
        int i;
        if (! call flash_resource.isOwner() )
            return;
        switch (fl_state)
        {
            case st_init:
                for (i = 0; i < sizeof(sense_metablock_t); i++)
                {
                    ((uint8_t*)(&mblock))[i] = (uint8_t) rxbuffer[i];
                }
                if (mblock.sentinel != METABLOCK_SENTINEL)
                {
                    bl_printf("Metablock sentinel does not match\n");
                }
                else
                {
                    bl_printf("Metablock sentinel matched!\n");
                }
                post to_idle();
                break;
        }
    }

    task void write_metablock()
    {
        dly();
        call flash_iface.initiate_flash_write((uint8_t*)(&mblock), sizeof(sense_metablock_t), FS_METABLOCK_ADDR);
    }

    async event void flash_iface.flash_write_complete()
    {
        bl_printf("Flash write completed\n");
        if (! call flash_resource.isOwner() )
        {
            bl_printf("not owner\n");
            return;
        }
        switch(fl_state)
        {
            case st_write_value:
                bl_printf("Record written\n");
                mblock.last_written_record ++;
                fl_state = st_write_metablock;
                post write_metablock();
                break;
            case st_write_metablock:
                bl_printf("Metablock updated\n");
                post to_idle();
                break;
        }

    }
    event void flash_resource.granted()
    {
        bl_printf("logger flash resource granted\n");
        switch(fl_state)
        {
            case st_init:
                call flash_iface.initiate_flash_transfer(&rxbuffer[0], sizeof(sense_metablock_t), FS_METABLOCK_ADDR);
                break;
            case st_write_value:
                call flash_iface.initiate_flash_rmwrite((uint8_t*)(&next_write), sizeof(sense_record_t), FS_RECORD_START + (FS_RECORD_SIZE * mblock.last_written_record));
                break;
        }

    }
}
