CON

    SLAVE_ADDR          = $41 << 1

    APPID               = $00

    { bootloader commands/status }
    BL_CMD_STAT         = $08
        RAMREMAP_RESET  = $11
        DOWNLOAD_INIT   = $14
        RAM_BIST        = $2a
        I2C_BIST        = $2c
        W_RAM           = $41
        ADDR_RAM        = $43

    CMD_STAT            = $08
        MEASURE         = $10

    { registers }
    LOAD_CFG_PAGE_COM   = $16
    ACTIVE_RANGE        = $19   ' don't sw modes when measurement or cal is ongoing - undef behavior
        SHORT_RANGE_ACC = $6e
        LONG_RANGE_ACC  = $6f   ' firmware default bootup
        ACC_UNSUPPORTED = $00

    INT_ENAB            = $42