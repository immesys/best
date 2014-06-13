interface FlashLogger
{
    async command void log_record(flash_record_t* r);
}
