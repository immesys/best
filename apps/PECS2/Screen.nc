
interface Screen
{
    async command void start();
    async command error_t blit_window(uint16_t dst_sx, uint16_t dst_sy, uint16_t dst_width, uint16_t dst_height,
                    uint16_t asset_sx, uint16_t asset_sy, uint16_t asset_width, uint16_t asset_height,
                    uint32_t asset_address);
    event void blit_window_complete();
}
