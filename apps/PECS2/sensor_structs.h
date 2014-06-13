
//Sensor record format
typedef struct
{
    /* The number of ticks since reset */
    uint32_t ticks;
    
    /* what record type is this */
    /* 1 = notification of reboot, ticks will begin from scratch */
    /* 2 = occupancy */
    /* 3 = fan setting change */
    /* 4 = heat setting change */
    /* 5 = periodic tick */
    uint8_t type;
    uint8_t heat_val;
    uint8_t fan_val;
    uint8_t occupancy_val;
    uint16_t temp_val;
    uint16_t rh_val;
    uint32_t reserved;
} sense_record_t; //16 bytes
#define RECORD_SIZE 16
#define METABLOCK_SENTINEL 0x5aa5
typedef struct
{
    uint32_t sentinel; //0x5AA5
    uint32_t last written record;
} sense_metablock_t; //252 bytes unused, metabloc has room for a page
