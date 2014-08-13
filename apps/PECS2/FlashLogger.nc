#include "flash_logger.h"
interface FlashLogger
{
    async command void log_record(sense_record_t* r);
    async command uint32_t get_num_records();
    async command void query_record(uint32_t num);
}
