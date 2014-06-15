interface Controls
{
    async command uint8_t get_heating();
    async command void set_heating(uint8_t);
    async command uint8_t get_fan();
    async command void set_fan(uint8_t);
    async command uint8_t get_occupancy();
    async event void controls_changed();
}