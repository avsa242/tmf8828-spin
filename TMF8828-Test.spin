{
    --------------------------------------------
    Filename: TMF8828-Test.spin
    Author: Jesse Burt
    Description: TMF8828 bootloader and application test
    Copyright (c) 2022
    Started: Dec 9, 2022
    Updated: Dec 11, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode = xtal1+pll16x
    _xinfreq = 5_000_000

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR | 1
    EN_M            = 24
    INT_PIN         = 25

OBJ

    ser: "com.serial.terminal.ansi"
    time: "time"
    i2c: "com.i2c"
    core: "core.con.tmf8828"

VAR

    byte _ramdump[132]
    byte _fact_cal[192*4]

pub main() | tries, ena, appid, tmp, img_ptr, img_remain, chunk_sz, img_csum, status, aid, int_status, mask_nr

    outa[EN_M] := 0
    dira[EN_M] := 1

    ser.init_def(115_200)
    time.msleep(30)
    ser.clear()
    ser.strln(@"serial started")

    i2c.init(28, 29, 1_000_000)
    time.msleep(30)
    ser.strln(@"i2c started")

' 1.2.1) Power up
    outa[EN_M] := 1
    writereg(core#ENABLE, 1, $01)

    tries := 0
    repeat
        ena := 0
        readreg(core#ENABLE, 1, @ena)
        ++tries
    until (ena == $41)
    ser.printf1(@"success after %d tries\n\r", tries)

    appid := 0
    readreg(core#APPID, 1, @appid)
    if (appid == core#BL_RUNNING)
        ser.strln(@"bootloader running")
    elseif (appid == core#MEAS_APP_RUNNING)
        ser.strln(@"application running")
    else
        ser.strln(@"error: exception")
        repeat

    fw_load{}
    configure{}
    factory_cal_tmf8828{}
    measure{}

PUB fw_load{} | img_remain, img_ptr, chunk_sz, img_csum, tmp, status, tries, aid, ena
'3.2)
    ser.str(@"sending DOWNLOAD_INIT...")
    bl_command(core#DOWNLOAD_INIT, 1, $29)      ' $29: seed (not otherwise documented)
    ser.strln(@"done")

    bl_wait_rdy{}

    ser.str(@"sending ADDR_RAM...")
    bl_command(core#ADDR_RAM, 2, $00_00)
    ser.strln(@"done")

    bl_wait_rdy{}

    { load RAM }
    img_remain := _img_sz
    img_ptr := @tmf8828_image                   ' init pointer to start of FW image
    repeat
        chunk_sz := img_remain <# 128           ' chunk size is the remaining size, up to 128 bytes
        ser.pos_xy(0, 10)
        ser.printf1(@"about to write offset %x\n\r", img_ptr)
        i2c.start()
        i2c.write(SLAVE_WR)
        i2c.write(core#BL_CMD_STAT)
        i2c.write(core#W_RAM)
        i2c.write(chunk_sz)                     ' BL_SIZE (number of bytes to write; up to 128)
        i2c.wrblock_lsbf(img_ptr, chunk_sz)

        { calc checksum }
        img_csum := 0
        img_csum += core#W_RAM
        img_csum += chunk_sz
        repeat tmp from img_ptr to (img_ptr+(chunk_sz-1))
            img_csum += byte[tmp]               ' calc rolling checksum
        i2c.write(img_csum ^ $ff)               ' one's comp. so sum of 0 doesn't yield chksum of 0
        i2c.stop()

        ser.str(@"checking status of write...")
        status := 0
        readreg(core#BL_CMD_STAT, 3, @status)
        if (status <> $ff_00_00)    'XXX was 00 00 ff
            ser.printf1(@"WRITE FAILED: status %06.8x\n\r", ena)
            img_ptr -= chunk_sz
            img_remain += chunk_sz
            ++tries
            if (tries > 10)                     ' 10: arbitrary
                ser.strln(@"number of retries exceeded maximum - halting")
                repeat
        else
            ser.strln(@"write OK")
            img_ptr += chunk_sz
            img_remain -= chunk_sz
            tries := 0
        ser.printf1(@"remaining: %4.4d\n\r", img_remain)
    while img_remain
    ser.strln(@"COMPLETE!")

    ser.str(@"Sending RAMREMAP_RESET command...")
    bl_command(core#RAMREMAP_RESET, 0, 0)
    ser.strln(@"done")

    ser.str(@"checking APPID...")
    tries := 0
    repeat
        aid := 0
        readreg(core#APPID, 1, @aid)
        ser.printf1(@"$%08.8x ", aid)
        { should respond with $03 after no more than 2.5ms }
        time.usleep(500)
        if (++tries > 5)
            ser.strln(@"APPID read failed")
            repeat
    until (aid == core#MEAS_APP_RUNNING)

PUB configure{} | status, tmp, mask_nr
' 4.1 step 1
    ser.str(@"Loading common config page...")
    command(core#CMD_LD_CFG_PG_COM)

    ser.strln(@"done")

    ser.str(@"Verifying the config page is loaded...")
    status := 0
    readreg(core#CONFIG_RESULT, 4, @status)

    { verify the config page was loaded by checking the first few bytes: [$16][xx][$bc][$00] }
    if ((status.byte[0] == core#CMD_LD_CFG_PG_COM) and (status.word[1] == $00_bc))
        ser.strln(@"verified")
    else
        ser.strln(@"verification failed - halting")
        repeat

    ser.str(@"changing measurement period to 100ms...")
    writereg(core#PERIOD_MS_LSB, 2, $00_64)
    ser.strln(@"done")
'XXX
    ser.str(@"selecting pre-defined SPAD mask #6...")
    writereg(core#SPAD_MAP_ID, 1, $06)
    ser.strln(@"done")

    ser.str(@"config GPIO0 low while VCSEL is emitting...")
    writereg(core#GPIO_0, 1, $03)
    ser.strln(@"done")

    ser.str(@"writing common page...")
    command(core#CMD_WRITE_CFG_PG)
    ser.strln(@"done")

PUB factory_cal_tmf8820_21{} | tmp, status

'4.4.1) factory cal TMF8820/21
    ser.str(@"starting factory cal...")
    command(core#CMD_FACTORY_CAL)
    ser.strln(@"done")

    ser.str(@"loading factory calibration config page...")
    command(core#CMD_LD_CFG_PG_FACT_CAL)
    ser.strln(@"done")
    ser.str(@"reading factory cal...")
    readreg(core#CONFIG_RESULT, 192, @_fact_cal)
    ser.strln(@"done")

'4.4.2) load factory cal
    ser.str(@"loading factory calibration config page...")
    command(core#CMD_LD_CFG_PG_FACT_CAL)
    ser.strln(@"done")

    readreg(core#CONFIG_RESULT, 4, @tmp)
    if ((tmp.byte[0] == core#CMD_LD_CFG_PG_FACT_CAL) and (tmp.word[1] == $00_bc))
        ser.strln(@"config page loaded")

    ser.str(@"writing calibration...")
    writereg(core#FACTORY_CALIBR_FIRST, 192-4, @_fact_cal+4)
    ser.strln(@"done")
    status := 0
    readreg(core#CALIBRATION_STATUS, 1, @status)
    if (status == core#WARN_NO_FACT_CALIBR)
        ser.strln(@"warning: no factory cal loaded")
    elseif (status == core#WARN_FACT_CAL_SPAD_MASK_MISMATCH)
        ser.strln(@"warning: factory cal doesn't match the selected SPAD map")

PUB factory_cal_tmf8828{} | status, tmp, mask_nr
'4.4.3) TMF8828 factory cal
    ser.strln(@"TMF8828 factory calibration")
    ser.str(@"Loading common config page...")
    command(core#CMD_LD_CFG_PG_COM)

    ser.str(@"Verifying the config page is loaded...")
    status := 0
    readreg(core#CONFIG_RESULT, 4, @status)

    { verify the config page was loaded by checking the first few bytes: [$16][xx][$bc][$00] }
    if ((status.byte[0] == core#COMMON_CID) and (status.word[1] == $00_bc))
        ser.strln(@"verified")
    else
        ser.strln(@"verification failed - halting")
        repeat

    ser.str(@"writing common page...")
    command(core#CMD_WRITE_CFG_PG)
    ser.strln(@"done")

    repeat tmp from 1 to 4
        ser.printf1(@"calibrating SPAD mask %d...\n\r", tmp)
        ser.str(@"resetting factory cal counter...")
        command(core#CMD_RESET_FACTORY_CAL)
        ser.strln(@"done")

        ser.str(@"initiating calibration...")
        command(core#CMD_FACTORY_CAL)
        ser.strln(@"done")
    command(core#CMD_RESET_FACTORY_CAL)

'steps 7..11: 4 times
    repeat mask_nr from 0 to 3
        ser.str(@"loading factory calibration config page...")
        command(core#CMD_LD_CFG_PG_FACT_CAL)

        ser.printf1(@"reading factory cal for mask #%d...", mask_nr)
        readreg(core#CONFIG_RESULT, 192, @_fact_cal+(mask_nr*192))
        ser.strln(@"done")
        command(core#CMD_WRITE_CFG_PG)
'    ser.hexdump(@_fact_cal, 0, 2, 192, 16)
'    ser.hexdump(@_fact_cal+192, 0, 2, 192, 16)
'    ser.hexdump(@_fact_cal+(192*2), 0, 2, 192, 16)
'    ser.hexdump(@_fact_cal+(192*3), 0, 2, 192, 16)

'4.4.4) load factory cal
    command(core#CMD_RESET_FACTORY_CAL)
    repeat mask_nr from 0 to 3
        command(core#CMD_LD_CFG_PG_FACT_CAL)
        tmp := 0
        readreg(core#CONFIG_RESULT, 4, @tmp)
        if ((tmp.byte[0] == core#CMD_LD_CFG_PG_FACT_CAL) and (tmp.word[1] == $00_bc))
            ser.strln(@"config page loaded")
        '_fact_cal+(0*192)+4 = _fact_cal+4 ($24)
        '_fact_cal+(1*192)+4 = _fact_cal+192+4 ($24)
        '_fact_cal+(2*192)+4 = _fact_cal+384+4 ($24)
        '_fact_cal+(3*192)+4 = _fact_cal+576+4 ($24)
        writereg(core#FACTORY_CALIBR_FIRST, 192-4, @_fact_cal+(mask_nr*192)+4)

'4.5) MEASURE cmd
    ser.str(@"Enabling interrupts...")
    writereg(core#INT_ENAB, 1, $02) '$62 to include error/warning/cmd done interrupts
    ser.strln(@"done")

    writereg(core#INT_STATUS, 1, $ff)
    ser.strln(@"done")

    ser.str(@"measuring...")
    command(core#CMD_MEASURE)

    ser.strln(@"done")

    ser.str(@"checking app mode...")
    status := 0
    readreg(core#MODE, 1, @status)
    ser.hexs(status, 2)
    ser.newline()

PUB measure{} | tmp, int_status
'4.6)
    ser.clear{}
    ser.str(@"Measuring results...")
    tmp := 0
    readreg(core#CALIBRATION_STATUS, 1, @tmp)
    ser.printf1(@"cal status = %02.2x\n\r", tmp)
    dira[INT_PIN] := 0
    repeat
        repeat until ina[INT_PIN] == 0
        readreg(core#INT_STATUS, 1, @int_status)
        writereg(core#INT_STATUS, 1, int_status)
        readreg(core#CONFIG_RESULT, 192, @_ramdump)'132
        ser.pos_xy(0, 2)
        ser.hexdump(@_ramdump, $20, 2, 192, 16)'+4, $20, 2, 132-4, 16

    repeat

PUB bl_command(cmd, len, ptr_args) | ck
' Execute bootloader command
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core#BL_CMD_STAT)
    i2c.write(cmd)
    i2c.write(len)                              ' BL_SIZE
    ck := cmd + len
    if (len > 4)
        i2c.wrblock_lsbf(ptr_args, len)
        ck += sum_blk(ptr_args, len)
    elseif (len == 0)
        ck := ck
    elseif (len < 4)
        i2c.wrblock_lsbf(@ptr_args, len)
        ck += sum_blk(@ptr_args, len)

    ser.printf1(@"sum_blk: %02.2x\n\r", ck ^ $ff)
    i2c.write(ck.byte[0] ^ $ff)  ' cksum
    i2c.stop()

PUB sum_blk(ptr_data, len): ck | tmp
' Sum a block of data
    ck := 0
    repeat tmp from 0 to len-1
        ck += byte[ptr_data][tmp]

PUB command(cmd): status
' Execute application command
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core#CMD_STAT)
    i2c.write(cmd)
    i2c.stop()

    repeat
        status := 0
        readreg(core#CMD_STAT, 1, @status)
        if (status == $01)
            ser.fgcolor(ser#GREEN)
            ser.strln(@"STAT_ACCEPTED")
            ser.fgcolor(ser#GREY)
            quit
        if ((status > $01) and (status < $10))
            ser.printf1(@"error: %2.2x\n\r", status)
            repeat
    while (status => $10)
    if (status == core#STAT_OK)
        ser.fgcolor(ser#GREEN)
        ser.strln(@"STAT_OK")
        ser.fgcolor(ser#GREY)

PUB readreg(reg_nr, nr_bytes, ptr_buff)
' Read register(s) from the device
'   reg_nr: (starting) register number
'   nr_bytes: number of bytes to read
'   ptr_buff: pointer to buffer to read data to
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(reg_nr)
    i2c.start()
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop()

PUB bl_wait_rdy{} | tries, ena
' Wait for bootloader to signal ready
    ser.str(@"polling bootloader for readiness...")
    { poll bootloader - READY? }
    tries := 0
    repeat
        ena := 0
        readreg(core#BL_CMD_STAT, 3, @ena)
        ++tries
    until (ena == $ff_00_00)
    ser.printf1(@"ready after %d tries\n\r", tries)

PUB writereg(reg_nr, nr_bytes, ptr_buff)
' Write to device register(s)
'   reg_nr: (starting) register number
'   nr_bytes: number of bytes to write
'   ptr_buff: if nr_bytes is 1..4, the value(s) to write
'             if nr_bytes is >4, a pointer to the buffer of data to write
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(reg_nr)
    if ((nr_bytes => 1) and (nr_bytes =< 4))
        i2c.wrblock_lsbf(@ptr_buff, nr_bytes)
    else
        i2c.wrblock_lsbf(ptr_buff, nr_bytes)    ' indirect
    i2c.stop()

#include "tmf8828_image.spin"

