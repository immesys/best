
interface Screen
{
    async command void start();
    async command void blit_window(uint16_t dst_sx, uint16_t dst_sy, uint16_t dst_width, uint16_t dst_height,
                    uint16_t asset_sx, uint16_t asset_sy, uint16_t asset_width, uint16_t asset_height,
                    uint32_t asset_address);
    async event void blit_window_complete();
    async command void fill_color(uint16_t color);
    async command void fill_colorw(uint16_t color, uint16_t x, uint16_t y, uint16_t w, uint16_t h);
    async command void backlight(uint8_t ison);

}
