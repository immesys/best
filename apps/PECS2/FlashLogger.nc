#include "flash_logger.h"
interface FlashLogger
{
    async command void log_record(sense_record_t* r);
}
