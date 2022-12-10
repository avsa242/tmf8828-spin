CON

    SLAVE_ADDR              = $41 << 1

    BL_CMD_STAT             = $08
    { bootloader commands }
        RAMREMAP_RESET      = $11
        DOWNLOAD_INIT       = $14
        RAM_BIST            = $2a
        I2C_BIST            = $2c
        W_RAM               = $41
        ADDR_RAM            = $43
    { status }
        STAT_ERR_SIZE       = $01
        STAT_ERR_CSUM       = $02

    CMD_STAT                = $08
        MEASURE             = $10
        LOAD_CFG_PAGE_COM   = $16
        ACTIVE_RANGE        = $19
            SHORT_RANGE_ACC = $6e
            LONG_RANGE_ACC  = $6f
            ACC_UNSUPPORTED = $00


    { registers }
    { APPID == any, cid_rid == any }
    APPID                   = $00
    MINOR                   = $01
    ENABLE                  = $e0
    INT_STATUS              = $e1
    INT_ENAB                = $e2
    ID                      = $e3
    REVID                   = $e4

