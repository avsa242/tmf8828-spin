con

    _clkmode = xtal1+pll16x
    _xinfreq = 5_000_000

obj

    ser: "com.serial.terminal.ansi"
    time: "time"
    i2c: "com.i2c"

con

    SL      = $41 << 1
    EN_M    = 24

    REG_APPID       = $00

    BL_CMD_STAT     = $08
    { commands }
    RAMREMAP_RESET  = $11
    DOWNLOAD_INIT   = $14
    RAM_BIST        = $2a
    I2C_BIST        = $2c
    W_RAM           = $41
    ADDR_RAM        = $43

pub main() | tries, ena, appid, csum, acc, tmp, img_ptr, img_remain, chunk_sz, img_csum, status, aid

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

    i2c.start()
    i2c.write(SL)
    i2c.write($E0)
    i2c.write($01)
    i2c.stop()

    tries := 0
    repeat
        i2c.start()
        i2c.write(SL)
        i2c.write($E0)
        i2c.start()
        i2c.write(SL|1)
        ena := i2c.read(i2c.NAK)
        i2c.stop()
        ++tries
    until ena == $41
    ser.printf1(@"success after %d tries\n\r", tries)

    i2c.start()
    i2c.write(SL)
    i2c.write($00)
    i2c.start()
    i2c.write(SL|1)
    appid := i2c.read(i2c.NAK)
    i2c.stop()

    if (appid == $80)
        ser.strln(@"bootloader running")
    elseif (appid == $03)
        ser.strln(@"application running")
    else
        ser.strln(@"error: exception")
        repeat


' checksum: CMD_STAT + SIZE + (sum of all data-bytes)
'   ex: DOWNLOAD_INIT cmd: (( $14 + $01 + $29) ^ $ff) = $c1
{ flow:
1)
    cmd(DOWNLOAD_INIT)
    repeat
        readreg(CMD_STAT)
    while CMD_STAT == BUSY  (or until CMD_STAT == READY ($00 $00 $ff))

2)
    cmd(ADDR_RAM)
    repeat
        readreg(CMD_STAT)
    while CMD_STAT == BUSY

3)
    cmd(W_RAM)
     repeat
        readreg(CMD_STAT)
    while CMD_STAT == BUSY

4)
    cmd(RAMREMAP_AND_RESET)
    readreg(APPID)
}

'1)
    ser.str(@"sending DOWNLOAD_INIT...")
    i2c.start()
    i2c.write(SL)
    i2c.write(BL_CMD_STAT)
    i2c.write(DOWNLOAD_INIT)
    i2c.write($01)  ' BL_SIZE = 1
    i2c.write($29)  ' BL_DATA0 = $0..$ff (Seed)
    i2c.write($c1)  ' cksum
    i2c.stop()
    ser.strln(@"done")

    ser.str(@"polling bootloader for readiness...")
    { poll bootloader - READY? }
    tries := 0
    repeat
        ena := 0
        i2c.start()
        i2c.write(SL)
        i2c.write(BL_CMD_STAT)
        i2c.start()
        i2c.write(SL|1)
        i2c.rdblock_msbf(@ena, 3, i2c.NAK)
        i2c.stop()
        ++tries
    until ena == $00_00_ff
    ser.printf1(@"ready after %d tries\n\r", tries)

'2)
    ser.str(@"sending ADDR_RAM...")
    i2c.start()
    i2c.write(SL)
    i2c.write(BL_CMD_STAT)
    i2c.write(ADDR_RAM)  ' cksum
    i2c.write($02)  ' |     BL_SIZE = 2
    i2c.write($00)  ' |     addr LSB
    i2c.write($00)  ' |     addr MSB
    i2c.write($ba)  ' cksum ^ $ff
    ser.strln(@"done")

    { poll bootloader - READY? }
    ser.str(@"polling bootloader for readiness...")
    tries := 0
    repeat
        ena := 0
        i2c.start()
        i2c.write(SL)
        i2c.write(BL_CMD_STAT)
        i2c.start()
        i2c.write(SL|1)
        i2c.rdblock_msbf(@ena, 3, i2c.NAK)
        i2c.stop()
        ++tries
    until ena == $00_00_ff
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
        i2c.write(SL)
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
        i2c.start()
        i2c.write(SL)
        i2c.write(BL_CMD_STAT)
        i2c.start()
        i2c.write(SL|1)
        i2c.rdblock_msbf(@status, 3, i2c.NAK)
        i2c.stop()
        if (status <> $00_00_ff)
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
    ser.strln(@"COMPLETE! Press any key")
    ser.getchar()


    ser.str(@"Issuing RAMREMAP_RESET command...")
    i2c.start()
    i2c.write(SL)
    i2c.write(BL_CMD_STAT)
    i2c.write(RAMREMAP_RESET)
    i2c.write($00)
    i2c.write($ee)
    i2c.stop()
    ser.strln(@"done")

    time.msleep(3)

    ser.str(@"checking APPID...")
    tries := 0
    repeat
        i2c.start()
        i2c.write(SL)
        i2c.write(REG_APPID)
        i2c.start()
        i2c.write(SL|1)
        aid := 0
        i2c.rdblock_lsbf(@aid, 1, i2c.NAK)
        i2c.stop()
        ser.printf1(@"$%08.8x ", aid)
        time.usleep(500)
'        if (++tries > 5)
'            ser.strln(@"APPID read failed")
'            repeat
    until aid == $03
    ser.strln(@"$03")

    repeat

#include "tmf8828_image.spin"

