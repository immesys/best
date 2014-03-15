
interface SPIMux
{
    async command error_t initiate_flash_transfer(uint32_t* rx, uint16_t bufsize, uint32_t xaddr);

    async event void flash_transfer_complete();

}
