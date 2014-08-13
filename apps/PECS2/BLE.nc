interface BLE
{
    async event void command_received(uint8_t cmd, uint8_t* val);
    async command void send_packet(uint8_t* packet, uint8_t length);



}