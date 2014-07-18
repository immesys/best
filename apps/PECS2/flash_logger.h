
#ifndef __FLASH_LOGGER_H__
#define __FLASH_LOGGER_H__

#define FS_METABLOCK_ADDR 0x0B0000
#define FS_RECORD_START   0x0B0100
#define FS_RECORD_SIZE 16
#define FS_MAX_RECORDS    20463

#define FS_TYPE_HEAT    8
#define FS_TYPE_COOL    4
#define FS_TYPE_OCC     2
#define FS_TYPE_REBOOT  1
#define FS_TYPE_PER     16

//Sensor record format
struct _sense_record_t {
    /* The number of milliseconds since reset */
    uint64_t ticks;
    
    /* what record type is this, OR'd */
    /* 1 = notification of reboot, ticks will begin from scratch */
    /* 2 = occupancy change */
    /* 4 = fan setting change */
    /* 8 = heat setting change */
    /* 16 = periodic tick */
    uint8_t type;
    uint8_t heat_val;
    uint8_t fan_val;
    uint8_t occupancy_val;
    uint16_t temp_val;
    uint16_t rh_val;
}; //16 bytes

typedef struct _sense_record_t sense_record_t;


#define METABLOCK_SENTINEL 0x5aa5

struct _sense_metablock_t {
    uint32_t sentinel; //0x5AA5
    uint32_t last_written_record;
}; //252 bytes unused, metabloc has room for a page

typedef struct _sense_metablock_t sense_metablock_t;


#endif