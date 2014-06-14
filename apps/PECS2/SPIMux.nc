
interface SPIMux
{
    //These appear to be for reads only
    async command error_t initiate_flash_transfer(uint32_t* rx, uint16_t bufsize, uint32_t xaddr);    
    async event void flash_transfer_complete();

    //These are for writes
    async command error_t initiate_flash_write(uint8_t* tx, uint8_t bufsize, uint32_t xaddr);
    async event void flash_write_complete();
}
