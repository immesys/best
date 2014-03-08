
#ifndef __ATSAM4LTYPES_H__
#define __ATSAM4LTYPES_H__

typedef enum {
    RESMODE_DISABLED,
    RESMODE_PULLUP,
    RESMODE_PULLDOWN,
    RESMODE_KEEPER
} gpio_resistor_mode_t;

typedef enum {
    PERIPHERAL_A,
    PERIPHERAL_B,
    PERIPHERAL_C,
    PERIPHERAL_D
} gpio_peripheral_mode_t;

typedef enum {
    IRQ_DISABLED,
    IRQ_RISING_EDGE,
    IRQ_FALLING_EDGE,
    IRQ_ANY_EDGE,
} gpio_interrupt_mode_t;

#endif

