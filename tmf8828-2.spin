con

    _clkmode = xtal1+pll16x
    _xinfreq = 5_000_000

obj

    ser: "com.serial.terminal.ansi"
    time: "time"
    i2c: "com.i2c"

con

    SLAVE_WR        = $41 << 1
    SLAVE_RD        = SLAVE_WR | 1
    EN_M            = 24

    REG_APPID       = $00

    BL_CMD_STAT     = $08
    { commands }
    RAMREMAP_RESET  = $11
    DOWNLOAD_INIT   = $14
    RAM_BIST        = $2a
    I2C_BIST        = $2c
    W_RAM           = $41
    ADDR_RAM        = $43

pub main() | tries, ena, appid, csum, acc, tmp, img_ptr, img_remain, chunk_sz, img_csum, status, aid, int_status

    outa[EN_M] := 0
    dira[EN_M] := 1

    ser.init_def(115_200)
    time.msleep(30)
    ser.clear()
    ser.strln(@"serial started")

    i2c.init(28, 29, 100_000)
    time.msleep(30)
    ser.strln(@"i2c started")
    outa[EN_M] := 1
    time.msleep(1000)

    writereg($e0, 1, $01)

    tries := 0
    repeat
        ena := 0
        readreg($e0, 1, @ena)
        ++tries
    until (ena == $41)
    ser.printf1(@"success after %d tries\n\r", tries)

    appid := 0
    readreg(REG_APPID, 1, @appid)
    if (appid == $80)
        ser.strln(@"bootloader running")
    elseif (appid == $03)
        ser.strln(@"application running")
    else
        ser.strln(@"error: exception")
        repeat

'1)
    ser.str(@"sending DOWNLOAD_INIT...")
    bl_command(DOWNLOAD_INIT, 1, $29)
    ser.strln(@"done")

    ser.str(@"polling bootloader for readiness...")
    { poll bootloader - READY? }
    tries := 0
    repeat
        ena := 0
        readreg(BL_CMD_STAT, 3, @ena)
        ++tries
    until ena == $ff_00_00  ' xxx was 00 00 ff
    ser.printf1(@"ready after %d tries\n\r", tries)

'2)
    ser.str(@"sending ADDR_RAM...")
    bl_command(ADDR_RAM, 2, $00_00)
    ser.strln(@"done")

    { poll bootloader - READY? }
    ser.str(@"polling bootloader for readiness...")
    tries := 0
    repeat
        ena := 0
        readreg(BL_CMD_STAT, 3, @ena)
        ++tries
    until ena == $ff_00_00  ' xxx was 00 00 ff
    ser.printf1(@"ready after %d tries\n\r", tries)

'3)
    { load RAM }
    img_remain := _img_sz
    img_ptr := @tmf8828_image   ' init pointer to start of FW image
    repeat
        chunk_sz := img_remain <# 128   ' chunk size is the remaining size, up to 128 bytes
        ser.pos_xy(0, 8)
        ser.printf1(@"about to write offset %x\n\r", img_ptr)
        i2c.start()
        i2c.write(SLAVE_WR)
        i2c.write(BL_CMD_STAT)
        i2c.write(W_RAM)
        i2c.write(chunk_sz)    ' BL_SIZE (number of bytes to write; up to 128)
        i2c.wrblock_lsbf(img_ptr, chunk_sz)

        { calc checksum }
        img_csum := 0
        img_csum += W_RAM
        img_csum += chunk_sz
        repeat tmp from img_ptr to (img_ptr+(chunk_sz-1))
            img_csum += byte[tmp]   ' calc rolling checksum
        i2c.write(img_csum ^ $ff)
        i2c.stop()

        ser.str(@"checking status of write...")
        status := 0
        readreg(BL_CMD_STAT, 3, @status)
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


    ser.str(@"Issuing RAMREMAP_RESET command...")
    bl_command(RAMREMAP_RESET, 0, 0)
    ser.strln(@"done")

    ser.str(@"checking APPID...")
    tries := 0
    repeat
        aid := 0
        readreg(REG_APPID, 1, @aid)
        ser.printf1(@"$%08.8x ", aid)
        { should respond with $03 after no more than 2.5ms }
        time.usleep(500)
        if (++tries > 5)
            ser.strln(@"APPID read failed")
            repeat
    until aid == $03

' Flow:
'1) Config dev (e.g., select different SPAD mask)
    ser.str(@"Loading common config page...")
    command(LOAD_CFG_PAGE_COM)

    repeat
        status := 0
        readreg(CMD_STAT, 1, @status)
        if (status == $00)
            ser.strln(@"STAT_OK")
            quit
    while (status => $10)
    ser.strln(@"done")

    ser.str(@"Verifying the config page is loaded...")
    status := 0
    readreg($20, 4, @status)

    { verify the config page was loaded by checking the first few bytes: [$16][xx][$bc][$00] }
    if ((status.byte[0] == $16) and (status.word[1] == $00_bc))
        ser.strln(@"verified")
    else
        ser.strln(@"verification failed - halting")
        repeat

    ser.str(@"changing measurement period to 100ms...")
    writereg($24, 2, $00_64)
    ser.strln(@"done")

    ser.str(@"selecting pre-defined SPAD mask #6...")
    writereg($34, 1, $06)
    ser.strln(@"done")

    ser.str(@"config GPIO0 low while VCSEL is emitting...")
    writereg($31, 1, $03)
    ser.strln(@"done")

    ser.str(@"writing common page...")
    command($15)
    ser.strln(@"done")

    ser.str(@"Verifying the command executed...")
    repeat
        status := 0
        readreg(CMD_STAT, 1, @status)
        if (status == $00)
            ser.strln(@"STAT_OK")
            quit
    while status => $10
    ser.strln(@"done")

'2) Load factory cal data (if SPAD mask has been reconfig'd)
    ser.str(@"Enabling interrupts...")
    writereg(INT_ENAB, 1, $02)
    ser.strln(@"done")

    writereg($e1, 1, $ff)
    ser.strln(@"done")

'2b) MEASURE cmd
    ser.str(@"measuring...")
    command(MEASURE)

    ser.str(@"Verifying the command executed...")
    repeat
        status := 0
        readreg(CMD_STAT, 1, @status)
        if (status == $01)
            ser.strln(@"STAT_OK")
            quit
        if ((status > $01) and (status < $10))
            ser.printf1(@"error: %2.2x\n\r", status)
            repeat
    while status => $10
    ser.strln(@"done")

    ser.str(@"checking app mode...")
    status := 0
    readreg($10, 1, @status)
    ser.hexs(status, 2)
    ser.newline()

    ser.str(@"Measuring results...")
    dira[INT_PIN] := 0
    repeat
        repeat until ina[INT_PIN]
        readreg($e1, 1, @int_status)
        writereg($e1, 1, int_status)
        readreg($20, 132, @_result)
        ser.pos_xy(0, 27)
        ser.hexdump(@_result, $20, 2, 132, 16)
    repeat
'3) Wait for interrupt or poll, and read out results
'3b) STOP cmd

PUB bl_command(cmd, len, ptr_args) | ck
' Execute bootloader command
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(BL_CMD_STAT)
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

PUB command(cmd)
' Execute application command
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(CMD_STAT)
    i2c.write(cmd)
    i2c.stop()

PUB readreg(reg_nr, nr_bytes, ptr_buff)

    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(reg_nr)
    i2c.start()
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop()

PUB writereg(reg_nr, nr_bytes, ptr_buff)

    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(reg_nr)
    if ((nr_bytes => 1) and (nr_bytes =< 4))
        i2c.wrblock_lsbf(@ptr_buff, nr_bytes)
    else
        i2c.wrblock_lsbf(ptr_buff, nr_bytes)    ' indirect
    i2c.stop()

VAR

    byte _result[132]

CON

    INT_PIN             = 25

    CMD_STAT            = $08
        MEASURE         = $10

    LOAD_CFG_PAGE_COM   = $16
    ACTIVE_RANGE        = $19   ' don't sw modes when measurement or cal is ongoing - undef behavior
        SHORT_RANGE_ACC = $6e
        LONG_RANGE_ACC  = $6f   ' firmware default bootup
        ACC_UNSUPPORTED = $00

    INT_ENAB            = $42


#include "tmf8828_image.spin"

