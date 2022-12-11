{
    --------------------------------------------
    Filename: core.con.tmf8828.spin
    Author: Jesse Burt
    Description: TMF8828-specific constants
    Copyright (c) 2022
    Started: Dec 9, 2022
    Updated: Dec 11, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    SLAVE_ADDR                          = $41 << 1
    I2C_MAX_FREQ                        = 1_000_000
    DEVID_RESP                          = $08

    T_RAMREMAP_RESET                    = 6_000'uS
    T_POR                               = 2_000

    { registers }
    { APPID == any, cid_rid == any }
    APPID                               = $00
        BL_RUNNING                      = $80
        MEAS_APP_RUNNING                = $03

    MINOR                               = $01
    ENABLE                              = $e0
    ENABLE_MASK                         = $31
        CPU_RDY                         = 6     ' R/O
        PWRUP_SEL                       = 4
        PWRUP_SEL_BITS                  = %11
        PWRUP_SEL_MASK                  = (PWRUP_SEL_BITS << PWRUP_SEL) ^ ENABLE_MASK
            PWRUP_DEF                   = 0 << PWRUP_SEL
            PWRUP_NOSLEEP               = 1 << PWRUP_SEL
            PWRUP_START_RAM_APP         = 2 << PWRUP_SEL
        PON                             = 0
        PON_MASK                        = (1 << PON) ^ ENABLE_MASK

    INT_STATUS                          = $e1
    INT_STATUS_MASK                     = $6a
        INT7                            = 6
        INT6                            = 5
        INT4                            = 3
        INT2                            = 1

    INT_ENAB                            = $e2
    INT_ENAB_MASK                       = $6a
        INT7_ENAB                       = 6
        INT6_ENAB                       = 5
        INT4_ENAB                       = 3
        INT2_ENAB                       = 1

    ID                                  = $e3
    ID_MASK                             = $3f

    REVID                               = $e4
    REVID_MASK                          = $07

    { APPID == $03, cid_rid == any }
    PATCH                               = $02
    BUILD_TYPE                          = $03
    APPLICATION_STATUS                  = $04
        SUCCESS                         = $00
        ERR_BIST                        = $01
        ERR_APP_CANT_STOP_M             = $02
        ERR_APP_TMR_OO_RNG              = $03
        ERR_UNEXPECTED_RST              = $04
        WARN_NO_FUSES_FOUND             = $05

    MEASURE_STATUS                      = $05
        SUCCESS                         = $00
        ERR_MEASURE_VCSEL               = $11
        ERR_MEASURE_BDV                 = $12
        ERR_MEAS_CFG_2MANY              = $13
        ERR_MEAS_NOT_STARTED            = $16
        ERR_MEAS_BUFF_RETURN            = $17
        ERR_MEAS_TDC_LOCKUP             = $18

    ALGORITHM_STATUS                    = $06
        SUCCESS                         = $00
        ERR_ALGO_EC_FAILED              = $21
        ERR_ALGO_EC_BUFF_ERR            = $22
        ERR_ALGO_EC_CFG_MISMATCH        = $23

    CALIBRATION_STATUS                  = $07
        SUCCESS                         = $00
        WARN_NO_FACT_CALIBR             = $31
        WARN_FACT_CAL_SPAD_MASK_MISMATCH= $32

    CMD_STAT                            = $08
    { commands }
        CMD_MEASURE                     = $10
        CMD_CLR_STATUS                  = $11
        CMD_GPIO                        = $12
        CMD_WRITE_CFG_PG                = $15
        CMD_LD_CFG_PG_COM               = $16
        CMD_LD_CFG_PG_SPAD1             = $17
        CMD_LD_CFG_PG_SPAD2             = $18
        CMD_LD_CFG_PG_FACT_CAL          = $19
        CMD_FACTORY_CAL                 = $20
        CMD_I2C_SL_ADDR                 = $21
        FORCE_TMF8820_21_MODE           = $65
        FORCE_TMF8828_MODE              = $6c
        CMD_RESET                       = $fe
        CMD_STOP                        = $ff
    { status results }
        STAT_OK                         = $00
        STAT_ACCEPTED                   = $01
        STAT_ERR_CFG                    = $02
        STAT_ERR_APP                    = $03
        STAT_ERR_WAKEUP_TIMED           = $04
        STAT_ERR_RESET_UNEXPECTED       = $05
        STAT_ERR_UNKNOWN_CMD            = $06
        STAT_ERR_NO_REF_SPAD            = $07
        STAT_ERR_UNKNOWN_CID            = $09
        STAT_WARN_CFG_SPAD1_NOT_ACCEPT  = $0a
        STAT_WARN_CFG_SPAD2_NOT_ACCEPT  = $0b
        STAT_WARN_OSC_TRIM_NOT_ACCEPT   = $0c
        STAT_WARN_I2C_ADDR_NOT_ACCEPT   = $0d
        STAT_ERR_UNKNOWN_MODE           = $0e

    PREV_CMD                            = $09
    LIVE_BEAT                           = $0a
    MODE                                = $10
    ACTIVE_RANGE                        = $19
        SHORT_RANGE_ACC                 = $6e
        LONG_RANGE_ACC                  = $6f
        ACC_UNSUPPORTED                 = $00

    SERIAL_NUMBER_0                     = $1c
    SERIAL_NUMBER_1                     = $1d
    SERIAL_NUMBER_2                     = $1e
    SERIAL_NUMBER_3                     = $1f
    CONFIG_RESULT                       = $20
        MEAS_RESULT                     = $10
        COMMON_CID                      = $16
        SPAD_1_CID                      = $17
        SPAD_2_CID                      = $18
        FACT_CAL_CID                    = $19
        HIST_RAW_CID                    = $81

    TID                                 = $21
    SIZE_LSB                            = $22
    SIZE_MSB                            = $23

    { APPID == $03, cid_rid == $10 }
    RESULT_NUMBER                       = $24
    TEMPERATURE                         = $25
    NUMBER_VALID_RESULTS                = $26

    AMBIENT_LIGHT_0                     = $28
    AMBIENT_LIGHT_1                     = $29
    AMBIENT_LIGHT_2                     = $2a
    AMBIENT_LIGHT_3                     = $2b

    PHOTON_COUNT_0                      = $2c
    PHOTON_COUNT_1                      = $2d
    PHOTON_COUNT_2                      = $2e
    PHOTON_COUNT_3                      = $2f

    REFERENCE_COUNT_0                   = $30
    REFERENCE_COUNT_1                   = $31
    REFERENCE_COUNT_2                   = $32
    REFERENCE_COUNT_3                   = $33

    SYS_TICK_0                          = $34
        TS_VALID                        = 1
    SYS_TICK_1                          = $35
        TS_VALID                        = 1
    SYS_TICK_2                          = $36
        TS_VALID                        = 1
    SYS_TICK_3                          = $37
        TS_VALID                        = 1

    RES_CONFIDENCE_0                    = $38
    RES_DISTANCE_0_LSB                  = $39
    RES_DISTANCE_0_MSB                  = $3a
    RES_CONFIDENCE_1                    = $3b
    RES_DISTANCE_1_LSB                  = $3c
    RES_DISTANCE_1_MSB                  = $3d
    RES_CONFIDENCE_2                    = $3e
    RES_DISTANCE_2_LSB                  = $3f
    RES_DISTANCE_2_MSB                  = $40
    RES_CONFIDENCE_3                    = $41
    RES_DISTANCE_3_LSB                  = $42
    RES_DISTANCE_3_MSB                  = $43
    RES_CONFIDENCE_4                    = $44
    RES_DISTANCE_4_LSB                  = $45
    RES_DISTANCE_4_MSB                  = $46
    RES_CONFIDENCE_5                    = $47
    RES_DISTANCE_5_LSB                  = $48
    RES_DISTANCE_5_MSB                  = $49
    RES_CONFIDENCE_6                    = $4a
    RES_DISTANCE_6_LSB                  = $4b
    RES_DISTANCE_6_MSB                  = $4c
    RES_CONFIDENCE_7                    = $4d
    RES_DISTANCE_7_LSB                  = $4e
    RES_DISTANCE_7_MSB                  = $4f
    RES_CONFIDENCE_8                    = $50
    RES_DISTANCE_8_LSB                  = $51
    RES_DISTANCE_8_MSB                  = $52
    RES_CONFIDENCE_9                    = $53
    RES_DISTANCE_9_LSB                  = $54
    RES_DISTANCE_9_MSB                  = $55
    RES_CONFIDENCE_10                   = $56
    RES_DISTANCE_10_LSB                 = $57
    RES_DISTANCE_10_MSB                 = $58
    RES_CONFIDENCE_11                   = $59
    RES_DISTANCE_11_LSB                 = $5a
    RES_DISTANCE_11_MSB                 = $5b
    RES_CONFIDENCE_12                   = $5c
    RES_DISTANCE_12_LSB                 = $5d
    RES_DISTANCE_12_MSB                 = $5e
    RES_CONFIDENCE_13                   = $5f
    RES_DISTANCE_13_LSB                 = $60
    RES_DISTANCE_13_MSB                 = $61
    RES_CONFIDENCE_14                   = $62
    RES_DISTANCE_14_LSB                 = $63
    RES_DISTANCE_14_MSB                 = $64
    RES_CONFIDENCE_15                   = $65
    RES_DISTANCE_15_LSB                 = $66
    RES_DISTANCE_15_MSB                 = $67
    RES_CONFIDENCE_16                   = $68
    RES_DISTANCE_16_LSB                 = $69
    RES_DISTANCE_16_MSB                 = $6a
    RES_CONFIDENCE_17                   = $6b
    RES_DISTANCE_17_LSB                 = $6c
    RES_DISTANCE_17_MSB                 = $6d
    RES_CONFIDENCE_18                   = $6e
    RES_DISTANCE_18_LSB                 = $6f
    RES_DISTANCE_18_MSB                 = $70
    RES_CONFIDENCE_19                   = $71
    RES_DISTANCE_19_LSB                 = $72
    RES_DISTANCE_19_MSB                 = $73
    RES_CONFIDENCE_20                   = $74
    RES_DISTANCE_20_LSB                 = $75
    RES_DISTANCE_20_MSB                 = $76
    RES_CONFIDENCE_21                   = $77
    RES_DISTANCE_21_LSB                 = $78
    RES_DISTANCE_21_MSB                 = $79
    RES_CONFIDENCE_22                   = $7a
    RES_DISTANCE_22_LSB                 = $7b
    RES_DISTANCE_22_MSB                 = $7c
    RES_CONFIDENCE_23                   = $7d
    RES_DISTANCE_23_LSB                 = $7e
    RES_DISTANCE_23_MSB                 = $7f
    RES_CONFIDENCE_24                   = $80
    RES_DISTANCE_24_LSB                 = $81
    RES_DISTANCE_24_MSB                 = $82
    RES_CONFIDENCE_25                   = $83
    RES_DISTANCE_25_LSB                 = $84
    RES_DISTANCE_25_MSB                 = $85
    RES_CONFIDENCE_26                   = $86
    RES_DISTANCE_26_LSB                 = $87
    RES_DISTANCE_26_MSB                 = $88
    RES_CONFIDENCE_27                   = $89
    RES_DISTANCE_27_LSB                 = $8a
    RES_DISTANCE_27_MSB                 = $8b
    RES_CONFIDENCE_28                   = $8c
    RES_DISTANCE_28_LSB                 = $8d
    RES_DISTANCE_28_MSB                 = $8e
    RES_CONFIDENCE_29                   = $8f
    RES_DISTANCE_29_LSB                 = $90
    RES_DISTANCE_29_MSB                 = $91
    RES_CONFIDENCE_30                   = $92
    RES_DISTANCE_30_LSB                 = $93
    RES_DISTANCE_30_MSB                 = $94
    RES_CONFIDENCE_31                   = $95
    RES_DISTANCE_31_LSB                 = $96
    RES_DISTANCE_31_MSB                 = $97
    RES_CONFIDENCE_32                   = $98
    RES_DISTANCE_32_LSB                 = $99
    RES_DISTANCE_32_MSB                 = $9a
    RES_CONFIDENCE_33                   = $9b
    RES_DISTANCE_33_LSB                 = $9c
    RES_DISTANCE_33_MSB                 = $9d
    RES_CONFIDENCE_34                   = $9e
    RES_DISTANCE_34_LSB                 = $9f
    RES_DISTANCE_34_MSB                 = $a0
    RES_CONFIDENCE_35                   = $a1
    RES_DISTANCE_35_LSB                 = $a2
    RES_DISTANCE_35_MSB                 = $a3

    { APP_ID == $03, cid_rid == $16 }
    PERIOD_MS_LSB                       = $24
    PERIOD_MS_MSB                       = $25

    KILO_ITERATIONS_LSB                 = $26
    KILO_ITERATIONS_MSB                 = $27

    INT_THRESHOLD_LOW_LSB               = $28   ' ignored in TMF8828 mode
    INT_THRESHOLD_LOW_MSB               = $29   '
    INT_THRESHOLD_HIGH_LSB              = $2a   '
    INT_THRESHOLD_HIGH_MSB              = $2b   '

    INT_ZONE_MASK_0                     = $2c   '
    INT_ZONE_MASK_1                     = $2d   '
    INT_ZONE_MASK_2                     = $2e   '
    INT_PERSISTENCE                     = $2f   '

    CONFIDENCE_THRESHOLD                = $30
    GPIO_0                              = $31
    GPIO_0_MASK                         = $df
        DRV_STRENGTH                    = 6
        DRV_STRENGTH_BITS               = %11
        DRV_STRENGTH_MASK               = (DRV_STRENGTH_BITS << DRV_STRENGTH) & !GPIO_0_MASK
            DRV_STR_4X                  = 3
            DRV_STR_3X                  = 2
            DRV_STR_2X                  = 1
            DRV_STR_DEF                 = 0
        PRE_DELAY0                      = 3
        PRE_DELAY0_BITS                 = %11
        PRE_DELAY0_MASK                 = (PRE_DELAY0_BITS << PRE_DELAY0) & !GPIO_0_MASK
            ASSERT_200US_BEF_VCSEL      = 2
            ASSERT_100US_BEF_VCSEL      = 1
            NO_DELAY                    = 0
        GPIO0                           = 0
        GPIO0_BITS                      = %111
        GPIO0_MASK                      = (GPIO0_BITS << GPIO0) & !GPIO_0_MASK
            TRISTATE                    = 0
            INP_ACTIVE_HI               = 1
            INP_ACTIVE_LO               = 2
            OUT_LO_VCSEL_PULSE          = 3
            OUT_HI_VCSEL_PULSE          = 4
            OUT_ALWAYS_HI               = 5
            OUT_ALWAYS_LO               = 6

    GPIO_1                              = $32
    GPIO_1_MASK                         = $df
        DRV_STRENGTH                    = 6
        DRV_STRENGTH_BITS               = %11
        DRV_STRENGTH_MASK               = (DRV_STRENGTH_BITS << DRV_STRENGTH) & !GPIO_1_MASK
            DRV_STR_4X                  = 3
            DRV_STR_3X                  = 2
            DRV_STR_2X                  = 1
            DRV_STR_DEF                 = 0
        PRE_DELAY1                      = 3
        PRE_DELAY1_BITS                 = %11
        PRE_DELAY1_MASK                 = (PRE_DELAY0_BITS << PRE_DELAY0) & !GPIO_1_MASK
            ASSERT_200US_BEF_VCSEL      = 2
            ASSERT_100US_BEF_VCSEL      = 1
            NO_DELAY                    = 0
        GPIO1                           = 0
        GPIO1_BITS                      = %111
        GPIO1_MASK                      = (GPIO1_BITS << GPIO1) & !GPIO_1_MASK
            TRISTATE                    = 0
            INP_ACTIVE_HI               = 1
            INP_ACTIVE_LO               = 2
            OUT_LO_VCSEL_PULSE          = 3
            OUT_HI_VCSEL_PULSE          = 4
            OUT_ALWAYS_HI               = 5
            OUT_ALWAYS_LO               = 6

    POWER_CFG                           = $33
    POWER_CFG_MASK                      = $ec
        GOTO_STBY_TIMED                 = 7
        LO_PWR_OSC_ON                   = 6
        KEEP_PLL_RUNNING                = 5
        ALLOW_OSC_RETRIM                = 3
        PULSE_INT                       = 2
        GOTO_STBY_TIMED_MASK            = (1 << GOTO_STBY_TIMED) & !POWER_CFG_MASK
        LO_PWR_OSC_ON_MASK              = (1 << LO_PWR_OSC_ON) & !POWER_CFG_MASK
        KEEP_PLL_RUNNING_MASK           = (1 << KEEP_PLL_RUNNING) & !POWER_CFG_MASK
        ALLOW_OSC_RETRIM_MASK           = (1 << ALLOW_OSC_RETRIM) & !POWER_CFG_MASK
        PULSE_INT_MASK                  = (1 << PULSE_INT) & !POWER_CFG_MASK

    SPAD_MAP_ID                         = $34
        USR_DEF_TM_MUX_MEAS_SPAD1_2     = 15
        USR_DEF_SINGLE_MEAS_SPAD1       = 14
        NARROW_4X4                      = 13    ' TMF8821
        INV_CHECKER_3X3                 = 12
        CHECKER_3X3                     = 11
        MODE_3X6                        = 10    ' TMF8821
        NORM_4X4                        = 7     ' TMF8821
        WIDE_3X3                        = 6
        MACRO_4X4_2                     = 5     ' TMF8821
        MACRO_4X4_1                     = 4     ' TMF8821
        MACRO_3X3_2                     = 3
        MACRO_3X3_1                     = 2
        NORM_3X3                        = 1

    ALG_SETTING_0                       = $35
    ALG_SETTING_0_MASK                  = $84
        LOG_CONFIDENCE                  = 7
        DISTS                           = 2

'   RESERVED                            = $36
'   RESERVED                            = $37
'   RESERVED                            = $38
    HIST_DUMP                           = $39
    HIST_DUMP_MASK                      = $01
        HISTOGRAM                       = 0

    SPREAD_SPECTRUM                     = $3a
    SPREAD_SPECTRUM_MASK                = $07
        SPREAD_SPECT_FACT               = 0

    I2C_SLAVE_ADDRESS                   = $3b
    I2C_SLAVE_ADDRESS_MASK              = $fe
        SLV_ADDR                        = 1

    OSC_TRIM_VALUE_LSB                  = $3c
    OSC_TRIM_VALUE_MSB                  = $3d
    OSC_TRIM_VALUE_MSB_MASK             = $01

    I2C_ADDR_CHANGE                     = $3e
    I2C_ADDR_CHANGE_MASK                = $0f
        GPIO_CHANGE_MASK                = 2
        GPIO_CHANGE_VAL                 = 0

    { APP_ID == $03, cid_rid == $17/$18; TMF8821 mode only }
    SPAD_ENABLE_FIRST                   = $24
    SPAD_ENABLE_2                       = $25
    SPAD_ENABLE_3                       = $26
    SPAD_ENABLE_4                       = $27
    SPAD_ENABLE_5                       = $28
    SPAD_ENABLE_6                       = $29
    SPAD_ENABLE_7                       = $2a
    SPAD_ENABLE_8                       = $2b
    SPAD_ENABLE_9                       = $2c
    SPAD_ENABLE_10                      = $2d
    SPAD_ENABLE_11                      = $2e
    SPAD_ENABLE_12                      = $2f
    SPAD_ENABLE_13                      = $30
    SPAD_ENABLE_14                      = $31
    SPAD_ENABLE_15                      = $32
    SPAD_ENABLE_16                      = $33
    SPAD_ENABLE_17                      = $34
    SPAD_ENABLE_18                      = $35
    SPAD_ENABLE_19                      = $36
    SPAD_ENABLE_20                      = $37
    SPAD_ENABLE_21                      = $38
    SPAD_ENABLE_22                      = $39
    SPAD_ENABLE_23                      = $3a
    SPAD_ENABLE_24                      = $3b
    SPAD_ENABLE_25                      = $3c
    SPAD_ENABLE_26                      = $3d
    SPAD_ENABLE_27                      = $3e
    SPAD_ENABLE_28                      = $3f
    SPAD_ENABLE_29                      = $40
    SPAD_ENABLE_LAST                    = $41
    SPAD_TDC_FIRST                      = $42
    SPAD_TDC_2                          = $43
    SPAD_TDC_3                          = $44
    SPAD_TDC_4                          = $45
    SPAD_TDC_5                          = $46
    SPAD_TDC_6                          = $47
    SPAD_TDC_7                          = $48
    SPAD_TDC_8                          = $49
    SPAD_TDC_9                          = $4a
    SPAD_TDC_10                         = $4b
    SPAD_TDC_11                         = $4c
    SPAD_TDC_12                         = $4d
    SPAD_TDC_13                         = $4e
    SPAD_TDC_14                         = $4f
    SPAD_TDC_15                         = $50
    SPAD_TDC_16                         = $51
    SPAD_TDC_18                         = $52
    SPAD_TDC_19                         = $53
    SPAD_TDC_20                         = $54
    SPAD_TDC_21                         = $55
    SPAD_TDC_22                         = $56
    SPAD_TDC_23                         = $57
    SPAD_TDC_24                         = $58
    SPAD_TDC_25                         = $59
    SPAD_TDC_26                         = $5a
    SPAD_TDC_27                         = $5b
    SPAD_TDC_28                         = $5c
    SPAD_TDC_29                         = $5d
    SPAD_TDC_30                         = $5e
    SPAD_TDC_31                         = $5f
    SPAD_TDC_32                         = $60
    SPAD_TDC_33                         = $61
    SPAD_TDC_34                         = $62
    SPAD_TDC_35                         = $63
    SPAD_TDC_36                         = $64
    SPAD_TDC_37                         = $65
    SPAD_TDC_38                         = $66
    SPAD_TDC_39                         = $67
    SPAD_TDC_40                         = $68
    SPAD_TDC_41                         = $69
    SPAD_TDC_42                         = $6a
    SPAD_TDC_43                         = $6b
    SPAD_TDC_44                         = $6c
    SPAD_TDC_45                         = $6d
    SPAD_TDC_46                         = $6e
    SPAD_TDC_47                         = $6f
    SPAD_TDC_48                         = $70
    SPAD_TDC_49                         = $71
    SPAD_TDC_50                         = $72
    SPAD_TDC_51                         = $73
    SPAD_TDC_52                         = $74
    SPAD_TDC_53                         = $75
    SPAD_TDC_54                         = $76
    SPAD_TDC_55                         = $77
    SPAD_TDC_56                         = $78
    SPAD_TDC_57                         = $79
    SPAD_TDC_58                         = $7a
    SPAD_TDC_59                         = $7b
    SPAD_TDC_60                         = $7c
    SPAD_TDC_61                         = $7d
    SPAD_TDC_62                         = $7e
    SPAD_TDC_63                         = $7f
    SPAD_TDC_64                         = $80
    SPAD_TDC_65                         = $81
    SPAD_TDC_66                         = $82
    SPAD_TDC_67                         = $83
    SPAD_TDC_68                         = $84
    SPAD_TDC_69                         = $85
    SPAD_TDC_70                         = $86
    SPAD_TDC_71                         = $87
    SPAD_TDC_72                         = $88
    SPAD_TDC_73                         = $89
    SPAD_TDC_74                         = $8a
    SPAD_TDC_75                         = $8b
    SPAD_TDC_LAST                       = $8c
    SPAD_X_OFFSET_2                     = $8d
    SPAD_Y_OFFSET_2                     = $8e
    SPAD_X_SIZE                         = $8f
    SPAD_Y_SIZE                         = $90

    { APPID == $03, cid_rid == $19 }
    FACTORY_CALIBR_FIRST                = $24
    CROSSTALK_ZONE1                     = $60
    CROSSTALK_ZONE2                     = $64
    CROSSTALK_ZONE3                     = $68
    CROSSTALK_ZONE4                     = $6c
    CROSSTALK_ZONE5                     = $70
    CROSSTALK_ZONE6                     = $74
    CROSSTALK_ZONE7                     = $78
    CROSSTALK_ZONE8                     = $7c
    CROSSTALK_ZONE9                     = $80
    CROSSTALK_ZONE1_TMUX                = $b8
    CROSSTALK_ZONE2_TMUX                = $bc
    CROSSTALK_ZONE3_TMUX                = $c0
    CROSSTALK_ZONE4_TMUX                = $c4
    CROSSTALK_ZONE5_TMUX                = $c8
    CROSSTALK_ZONE6_TMUX                = $cc
    CROSSTALK_ZONE7_TMUX                = $d0
    CROSSTALK_ZONE8_TMUX                = $d4
    CROSSTALK_ZONE9_TMUX                = $d8
    CALIBRATION_STATUS_FC               = $dc
    FACTORY_CALBR_LAST                  = $df

    { APPID == $03, cid_rid == $81 }
    SUBPACKET_NUMBER                    = $24
    SUBPACKET_PAYLOAD                   = $25
    SUBPACKET_CONFIG                    = $26   ' TMF8821 only
    SUBPACKET_DATA0                     = $27
    SUBPACKET_DATA1                     = $28
    SUBPACKET_DATA2                     = $29
    SUBPACKET_DATA3                     = $2a
    SUBPACKET_DATA4                     = $2b
    SUBPACKET_DATA5                     = $2c
    SUBPACKET_DATA6                     = $2d
    SUBPACKET_DATA7                     = $2e
    SUBPACKET_DATA8                     = $2f
    SUBPACKET_DATA9                     = $30
    SUBPACKET_DATA10                    = $31
    SUBPACKET_DATA11                    = $32
    SUBPACKET_DATA12                    = $33
    SUBPACKET_DATA13                    = $34
    SUBPACKET_DATA14                    = $35
    SUBPACKET_DATA15                    = $36
    SUBPACKET_DATA16                    = $37
    SUBPACKET_DATA17                    = $38
    SUBPACKET_DATA18                    = $39
    SUBPACKET_DATA19                    = $3a
    SUBPACKET_DATA20                    = $3b
    SUBPACKET_DATA21                    = $3c
    SUBPACKET_DATA22                    = $3d
    SUBPACKET_DATA23                    = $3e
    SUBPACKET_DATA24                    = $3f
    SUBPACKET_DATA25                    = $40
    SUBPACKET_DATA26                    = $41
    SUBPACKET_DATA27                    = $42
    SUBPACKET_DATA28                    = $43
    SUBPACKET_DATA29                    = $44
    SUBPACKET_DATA30                    = $45
    SUBPACKET_DATA31                    = $46
    SUBPACKET_DATA32                    = $47
    SUBPACKET_DATA33                    = $48
    SUBPACKET_DATA34                    = $49
    SUBPACKET_DATA35                    = $4a
    SUBPACKET_DATA36                    = $4b
    SUBPACKET_DATA37                    = $4c
    SUBPACKET_DATA38                    = $4d
    SUBPACKET_DATA39                    = $4e
    SUBPACKET_DATA40                    = $4f
    SUBPACKET_DATA41                    = $50
    SUBPACKET_DATA42                    = $51
    SUBPACKET_DATA43                    = $52
    SUBPACKET_DATA44                    = $53
    SUBPACKET_DATA45                    = $54
    SUBPACKET_DATA46                    = $55
    SUBPACKET_DATA47                    = $56
    SUBPACKET_DATA48                    = $57
    SUBPACKET_DATA49                    = $58
    SUBPACKET_DATA50                    = $59
    SUBPACKET_DATA51                    = $5a
    SUBPACKET_DATA52                    = $5b
    SUBPACKET_DATA53                    = $5c
    SUBPACKET_DATA54                    = $5d
    SUBPACKET_DATA55                    = $5e
    SUBPACKET_DATA56                    = $5f
    SUBPACKET_DATA57                    = $60
    SUBPACKET_DATA58                    = $61
    SUBPACKET_DATA59                    = $62
    SUBPACKET_DATA60                    = $63
    SUBPACKET_DATA61                    = $64
    SUBPACKET_DATA62                    = $65
    SUBPACKET_DATA63                    = $66
    SUBPACKET_DATA64                    = $67
    SUBPACKET_DATA65                    = $68
    SUBPACKET_DATA66                    = $69
    SUBPACKET_DATA67                    = $6a
    SUBPACKET_DATA68                    = $6b
    SUBPACKET_DATA69                    = $6c
    SUBPACKET_DATA70                    = $6d
    SUBPACKET_DATA71                    = $6e
    SUBPACKET_DATA72                    = $6f
    SUBPACKET_DATA73                    = $70
    SUBPACKET_DATA74                    = $71
    SUBPACKET_DATA75                    = $72
    SUBPACKET_DATA76                    = $73
    SUBPACKET_DATA77                    = $74
    SUBPACKET_DATA78                    = $75
    SUBPACKET_DATA79                    = $76
    SUBPACKET_DATA80                    = $77
    SUBPACKET_DATA81                    = $78
    SUBPACKET_DATA82                    = $79
    SUBPACKET_DATA83                    = $7a
    SUBPACKET_DATA84                    = $7b
    SUBPACKET_DATA85                    = $7c
    SUBPACKET_DATA86                    = $7d
    SUBPACKET_DATA87                    = $7e
    SUBPACKET_DATA88                    = $7f
    SUBPACKET_DATA89                    = $80
    SUBPACKET_DATA90                    = $81
    SUBPACKET_DATA91                    = $82
    SUBPACKET_DATA92                    = $83
    SUBPACKET_DATA93                    = $84
    SUBPACKET_DATA94                    = $85
    SUBPACKET_DATA95                    = $86
    SUBPACKET_DATA96                    = $87
    SUBPACKET_DATA97                    = $88
    SUBPACKET_DATA98                    = $89
    SUBPACKET_DATA99                    = $8a
    SUBPACKET_DATA100                   = $8b
    SUBPACKET_DATA101                   = $8c
    SUBPACKET_DATA102                   = $8d
    SUBPACKET_DATA103                   = $8e
    SUBPACKET_DATA104                   = $8f
    SUBPACKET_DATA105                   = $90
    SUBPACKET_DATA106                   = $91
    SUBPACKET_DATA107                   = $92
    SUBPACKET_DATA108                   = $93
    SUBPACKET_DATA109                   = $94
    SUBPACKET_DATA110                   = $95
    SUBPACKET_DATA111                   = $96
    SUBPACKET_DATA112                   = $97
    SUBPACKET_DATA113                   = $98
    SUBPACKET_DATA114                   = $99
    SUBPACKET_DATA115                   = $9a
    SUBPACKET_DATA116                   = $9b
    SUBPACKET_DATA117                   = $9c
    SUBPACKET_DATA118                   = $9d
    SUBPACKET_DATA119                   = $9e
    SUBPACKET_DATA120                   = $9f
    SUBPACKET_DATA121                   = $a0
    SUBPACKET_DATA122                   = $a1
    SUBPACKET_DATA123                   = $a2
    SUBPACKET_DATA124                   = $a3
    SUBPACKET_DATA125                   = $a4
    SUBPACKET_DATA126                   = $a5
    SUBPACKET_DATA127                   = $a6

    { APPID == $80 }
    BL_CMD_STAT                         = $08
    { bootloader commands }
        RAMREMAP_RESET                  = $11
        DOWNLOAD_INIT                   = $14
        RAM_BIST                        = $2a
        I2C_BIST                        = $2c
        W_RAM                           = $41
        ADDR_RAM                        = $43
    { status }
        STAT_READY                      = $00
        STAT_ERR_SIZE                   = $01
        STAT_ERR_CSUM                   = $02
        STAT_ERR_RANGE                  = $03
        STAT_ERR_MORE                   = $04

    BL_SIZE                             = $09
    BL_DATA                             = $0a

PUB null{}
' This is not a top-level object

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

