interface Controls
{
    async command uint8_t get_heating();
    async command void set_heating(uint8_t);
    async command uint8_t get_fan();
    async command void set_fan(uint8_t);
    async command uint8_t get_occupancy();

    async command void fan_up();
    async command void fan_down();
    async command void heat_up();
    async command void heat_down();

    async command void transition_cal_pt1();
    async event void cal1_done();

    async command void transition_cal_pt2();
    async event void cal2_done();

    async command void transition_cal_pt3();
    async event void cal3_done();

    async event void controls_changed();

    async event void touch(uint16_t x, uint16_t y);
    async command void transition_active();

    async event void ble_activity();
}