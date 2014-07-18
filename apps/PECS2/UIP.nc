#include "assets.h"

module UIP
{
    uses
    {
        interface Boot;
        interface Screen;
        interface Controls;
        interface Timer<TMilli> as tmr;
    }
    provides
    {
        interface Init;
    }
}
implementation
{

    enum
    {
        st_ui_idle,
        st_ui_pc,
        st_ui_pa_logo,
        st_ui_pa_connect,
        st_ui_pa_hu,
        st_ui_pa_cu,
        st_ui_pa_hd,
        st_ui_pa_cd,
        st_ui_hot_dig_clear,
        st_ui_hot_dig_max,
        st_ui_hot_dig_1,
        st_ui_hot_dig_2,
        st_ui_hot_dig_p,
        st_ui_cold_dig_clear,
        st_ui_cold_dig_max,
        st_ui_cold_dig_1,
        st_ui_cold_dig_2,
        st_ui_cold_dig_p,
        st_ui_cal_pt1,
        st_ui_cal_pt2,
        st_ui_cal_pt3
    } ui_state;

    uint32_t hot_digit_addr [] =
    {
        ASSET_RED_0_ADDR,
        ASSET_RED_1_ADDR,
        ASSET_RED_2_ADDR,
        ASSET_RED_3_ADDR,
        ASSET_RED_4_ADDR,
        ASSET_RED_5_ADDR,
        ASSET_RED_6_ADDR,
        ASSET_RED_7_ADDR,
        ASSET_RED_8_ADDR,
        ASSET_RED_9_ADDR
    };

    uint32_t cold_digit_addr [] =
    {
        ASSET_BLUE_0_ADDR,
        ASSET_BLUE_1_ADDR,
        ASSET_BLUE_2_ADDR,
        ASSET_BLUE_3_ADDR,
        ASSET_BLUE_4_ADDR,
        ASSET_BLUE_5_ADDR,
        ASSET_BLUE_6_ADDR,
        ASSET_BLUE_7_ADDR,
        ASSET_BLUE_8_ADDR,
        ASSET_BLUE_9_ADDR
    };


    uint8_t hot_dirty;
    uint8_t cold_dirty;
    uint8_t activate_touch;
    uint8_t hot_paint_value;
    uint8_t cold_paint_value;
    task void ui_paint_all();
    task void ui_paint_all_logo();
    task void ui_paint_all_connect();
    task void ui_paint_all_hu();
    task void ui_paint_all_hd();
    task void ui_paint_all_cu();
    task void ui_paint_all_cd();

    enum
    {
        nt_cal1,
        nt_cal2,
        nt_cal3
    } next_transition;

    command error_t Init.init() @exactlyonce()
    {
        activate_touch = 0;
        return SUCCESS;
    }
    event void tmr.fired()
    {
        switch(next_transition)
        {
            case nt_cal1:
                call Controls.transition_cal_pt1();
                break;
            case nt_cal2:
                call Controls.transition_cal_pt2();
                break;
            case nt_cal3:
                call Controls.transition_cal_pt3();
                break;
        }
    }

    task void ui_paint_all()
    {
        if (ui_state != st_ui_idle)
        {
            bl_printf("invalid ui state #0\n");
        }
        bl_printf("painting all\n");
        hot_dirty = 1;
        cold_dirty = 1;
        call Screen.fill_color(0xFFFF);
        post ui_paint_all_logo();
    }

    task void ui_paint_all_logo()
    {
        ui_state = st_ui_pa_logo;
        call Screen.blit_window(ASSET_LOGO_X, ASSET_LOGO_Y, ASSET_LOGO_W, ASSET_LOGO_H,
            0, 0, ASSET_LOGO_W, ASSET_LOGO_H, ASSET_LOGO_ADDR);
    }

    task void ui_paint_all_connect()
    {
        ui_state = st_ui_pa_connect;
        call Screen.blit_window(ASSET_CONNECT_X, ASSET_CONNECT_Y, ASSET_CONNECT_W, ASSET_CONNECT_H,
            0, 0, ASSET_CONNECT_W, ASSET_CONNECT_H, ASSET_CONNECT_ADDR);
    }

    task void ui_paint_all_hu()
    {
        ui_state = st_ui_pa_hu;
        call Screen.blit_window(ASSET_HOT_UARROW_X, ASSET_HOT_UARROW_Y, ASSET_HOT_UARROW_W, ASSET_HOT_UARROW_H,
            0, 0, ASSET_HOT_UARROW_W, ASSET_HOT_UARROW_H, ASSET_HOT_UARROW_ADDR);
    }

    task void ui_paint_all_hd()
    {
        ui_state = st_ui_pa_hd;
        call Screen.blit_window(ASSET_HOT_DARROW_X, ASSET_HOT_DARROW_Y, ASSET_HOT_DARROW_W, ASSET_HOT_DARROW_H,
            0, 0, ASSET_HOT_DARROW_W, ASSET_HOT_DARROW_H, ASSET_HOT_DARROW_ADDR);
    }

    task void ui_paint_all_cu()
    {
        ui_state = st_ui_pa_cu;
        call Screen.blit_window(ASSET_COLD_UARROW_X, ASSET_COLD_UARROW_Y, ASSET_COLD_UARROW_W, ASSET_COLD_UARROW_H,
            0, 0, ASSET_COLD_UARROW_W, ASSET_COLD_UARROW_H, ASSET_COLD_UARROW_ADDR);
    }

    task void ui_paint_all_cd()
    {
        ui_state = st_ui_pa_cd;
        call Screen.blit_window(ASSET_COLD_DARROW_X, ASSET_COLD_DARROW_Y, ASSET_COLD_DARROW_W, ASSET_COLD_DARROW_H,
            0, 0, ASSET_COLD_DARROW_W, ASSET_COLD_DARROW_H, ASSET_COLD_DARROW_ADDR);
    }

    task void ui_hot_dig_clear()
    {
        hot_dirty = 0;
        call Screen.fill_colorw(0xFFFF, 10, 137, 80, 45);
        if (hot_paint_value >= 100)
        {
            ui_state = st_ui_hot_dig_max;
            call Screen.blit_window(ASSET_RED_MAX_X, ASSET_RED_MAX_Y, ASSET_RED_MAX_W, ASSET_RED_MAX_H,
                0, 0, ASSET_RED_MAX_W, ASSET_RED_MAX_H, ASSET_RED_MAX_ADDR);
        }
        else
        {
            ui_state = st_ui_hot_dig_1;
            call Screen.blit_window(ASSET_RED_D1_X, ASSET_RED_D1_Y, ASSET_RED_0_W, ASSET_RED_0_H,
                0, 0, ASSET_RED_0_W, ASSET_RED_0_H,
                hot_digit_addr[(hot_paint_value / 10)]);
        }
    }

    task void ui_hot_dig_2()
    {
        ui_state = st_ui_hot_dig_2;
        call Screen.blit_window(ASSET_RED_D2_X, ASSET_RED_D2_Y, ASSET_RED_0_W, ASSET_RED_0_H,
            0, 0, ASSET_RED_0_W, ASSET_RED_0_H,
            hot_digit_addr[(hot_paint_value % 10)]);
    }

    task void ui_hot_dig_p()
    {
        ui_state = st_ui_hot_dig_p;
        call Screen.blit_window(ASSET_RED_P_X, ASSET_RED_P_Y, ASSET_RED_0_W, ASSET_RED_0_H,
            0, 0, ASSET_RED_0_W, ASSET_RED_0_H,
            ASSET_RED_PERCENT_ADDR);
    }
    
    task void ui_cold_dig_clear()
    {
        cold_dirty = 0;
        call Screen.fill_colorw(0xFFFF, 150, 137, 80, 45);
        //TODO some white rectangle clearance here
        if (cold_paint_value >= 100)
        {
            ui_state = st_ui_cold_dig_max;
            call Screen.blit_window(ASSET_BLUE_MAX_X, ASSET_BLUE_MAX_Y, ASSET_COLD_MAX_W, ASSET_COLD_MAX_H,
                0, 0, ASSET_COLD_MAX_W, ASSET_COLD_MAX_H, ASSET_COLD_MAX_ADDR);
        }
        else
        {
            ui_state = st_ui_cold_dig_1;
            call Screen.blit_window(ASSET_BLUE_D1_X, ASSET_BLUE_D1_Y, ASSET_BLUE_0_W, ASSET_BLUE_0_H,
                0, 0, ASSET_BLUE_0_W, ASSET_BLUE_0_H,
                cold_digit_addr[(cold_paint_value / 10)]);
        }
    }

    task void ui_cold_dig_2()
    {
        ui_state = st_ui_cold_dig_2;
        call Screen.blit_window(ASSET_BLUE_D2_X, ASSET_BLUE_D2_Y, ASSET_BLUE_0_W, ASSET_BLUE_0_H,
            0, 0, ASSET_BLUE_0_W, ASSET_BLUE_0_H,
            cold_digit_addr[(cold_paint_value % 10)]);
    }

    task void ui_cold_dig_p()
    {
        ui_state = st_ui_cold_dig_p;
        call Screen.blit_window(ASSET_BLUE_P_X, ASSET_BLUE_P_Y, ASSET_BLUE_0_W, ASSET_BLUE_0_H,
            0, 0, ASSET_BLUE_0_W, ASSET_BLUE_0_H,
            ASSET_BLUE_PERCENT_ADDR);
    }

    task void ui_to_idle()
    {
        if (hot_dirty)
        {
            post ui_hot_dig_clear();
        }
        else if (cold_dirty)
        {
            post ui_cold_dig_clear();
        }
        else
        {
            ui_state = st_ui_idle;
        }
        if (activate_touch)
        {
            call Controls.transition_active();
            activate_touch = 0;
        }
    }

    task void ui_paint_calibrate()
    {
        ui_state = st_ui_pc;
        call Screen.fill_color(0xFFFF);
        call Screen.blit_window(ASSET_CALIBRATE_X, ASSET_CALIBRATE_Y, ASSET_CALIBRATE_W, ASSET_CALIBRATE_H,
            0, 0, ASSET_CALIBRATE_W, ASSET_CALIBRATE_H,
            ASSET_CALIBRATE_ADDR);
    }

    task void ui_cal_pt1()
    {
        ui_state = st_ui_cal_pt1;
        call Screen.blit_window(35, 35, ASSET_CROSSHAIR_W, ASSET_CROSSHAIR_H,
            0, 0, ASSET_CROSSHAIR_W, ASSET_CROSSHAIR_H,
            ASSET_CROSSHAIR_ADDR);
    }

    task void ui_cal_pt2()
    {
        ui_state = st_ui_cal_pt2;
        call Screen.blit_window(35, 260, ASSET_CROSSHAIR_W, ASSET_CROSSHAIR_H,
            0, 0, ASSET_CROSSHAIR_W, ASSET_CROSSHAIR_H,
            ASSET_CROSSHAIR_ADDR);
    }

    task void ui_cal_pt3()
    {
        ui_state = st_ui_cal_pt3;
        call Screen.blit_window(180, 180, ASSET_CROSSHAIR_W, ASSET_CROSSHAIR_H,
            0, 0, ASSET_CROSSHAIR_W, ASSET_CROSSHAIR_H,
            ASSET_CROSSHAIR_ADDR);
    }

    async event void Controls.touch(uint16_t x, uint16_t y)
    {
        bl_printf("Touch at %d, %d\n", x, y);
        if (y < 60) return;
        if (y > 260) return;
        if (x < 120)
        {
            if (y < 160)
            {
                call Controls.heat_up();
            }
            else
            {
                call Controls.heat_down();
            }
        }
        else
        {
            if (y < 160)
            {
                call Controls.fan_up();
            }
            else
            {
                call Controls.fan_down();
            }
        }

        //Debug black squares
        //call Screen.fill_colorw(0xFF0000, x-2, y-2, 4, 4);
    }
    async event void Screen.blit_window_complete()
    {
        switch(ui_state)
        {
            case st_ui_pa_logo:
                post ui_paint_all_connect();
                break;
            case st_ui_pa_connect:
                post ui_paint_all_hu();
                break;
            case st_ui_pa_hu:
                post ui_paint_all_cu();
                break;
            case st_ui_pa_cu:
                post ui_paint_all_hd();
                break;
            case st_ui_pa_hd:
                post ui_paint_all_cd();
                break;
            case st_ui_pa_cd:
                post ui_to_idle();
                break;
            case st_ui_hot_dig_max:
                post ui_to_idle();
                break;
            case st_ui_hot_dig_1:
                post ui_hot_dig_2();
                break;
            case st_ui_hot_dig_2:
                post ui_hot_dig_p();
                break;
            case st_ui_hot_dig_p:
                post ui_to_idle();
                break;
            case st_ui_cold_dig_max:
                post ui_to_idle();
                break;
            case st_ui_cold_dig_1:
                post ui_cold_dig_2();
                break;
            case st_ui_cold_dig_2:
                post ui_cold_dig_p();
                break;
            case st_ui_cold_dig_p:
                post ui_to_idle();
                break;
            case st_ui_pc:
                post ui_cal_pt1();
                break;
            case st_ui_cal_pt1:
                next_transition = nt_cal1;
                call tmr.startOneShot(500);
                //call Controls.transition_cal_pt1();
                break;
            case st_ui_cal_pt2:
                next_transition = nt_cal2;
                call tmr.startOneShot(500);
                //call Controls.transition_cal_pt2();
                break;
            case st_ui_cal_pt3:
                next_transition = nt_cal3;
                call tmr.startOneShot(500);
                //call Controls.transition_cal_pt3();
                break;
        }
    }

    async event void Controls.controls_changed()
    {
        hot_paint_value = call Controls.get_heating();
        cold_paint_value = call Controls.get_fan();
        hot_dirty = 1;
        cold_dirty = 1;
        if (ui_state == st_ui_idle)
            post ui_to_idle();
    }

    async event void Controls.cal1_done()
    {
        post ui_cal_pt2();
    }

    async event void Controls.cal2_done()
    {
        post ui_cal_pt3();
    }

    async event void Controls.cal3_done()
    {
        ui_state = st_ui_idle;
        post ui_paint_all();
        activate_touch = 1;
    }

    event void Boot.booted()
    {
        hot_dirty = 0;
        cold_dirty = 0;
        ui_state = st_ui_idle;
        post ui_paint_calibrate();

    }
}