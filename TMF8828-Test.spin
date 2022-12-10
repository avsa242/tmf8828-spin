{
    --------------------------------------------
    Filename: TMF8828-Test.spin
    Author: Jesse Burt
    Description: TMF8828 bootloader and application test
    Copyright (c) 2022
    Started: Dec 9, 2022
    Updated: Dec 10, 2022
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

pub main() | tries, ena, appid, tmp, img_ptr, img_remain, chunk_sz, img_csum, status, aid, int_status

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
    if (appid == $80)
        ser.strln(@"bootloader running")
    elseif (appid == $03)
        ser.strln(@"application running")
    else
        ser.strln(@"error: exception")
        repeat

'3.2)
    ser.str(@"sending DOWNLOAD_INIT...")
    bl_command(core#DOWNLOAD_INIT, 1, $29)
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
    until (aid == $03)

' 4.1 step 1
    ser.str(@"Loading common config page...")
    command(core#CMD_LD_CFG_PG_COM)

    repeat
        status := 0
        readreg(core#CMD_STAT, 1, @status)
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
        readreg(core#CMD_STAT, 1, @status)
        if (status == $00)
            ser.strln(@"STAT_OK")
            quit
    while (status => $10)
    ser.strln(@"done")

'4.5) MEASURE cmd
    ser.str(@"Enabling interrupts...")
    writereg(core#INT_ENAB, 1, $02) '$62 to include error/warning/cmd done interrupts
    ser.strln(@"done")

    writereg($e1, 1, $ff)
    ser.strln(@"done")

    ser.str(@"measuring...")
    command(core#CMD_MEASURE)

    ser.str(@"Verifying the command executed...")
    repeat
        status := 0
        readreg(core#CMD_STAT, 1, @status)
        if (status == $01)
            ser.strln(@"STAT_OK")
            quit
        if ((status > $01) and (status < $10))
            ser.printf1(@"error: %2.2x\n\r", status)
            repeat
    while (status => $10)
    ser.strln(@"done")

    ser.str(@"checking app mode...")
    status := 0
    readreg($10, 1, @status)
    ser.hexs(status, 2)
    ser.newline()

'4.6)
    ser.str(@"Measuring results...")
    dira[INT_PIN] := 0
    repeat
        repeat until ina[INT_PIN] == 0
        readreg($e1, 1, @int_status)
        writereg($e1, 1, int_status)
        readreg($20, 132, @_ramdump)
        ser.pos_xy(0, 27)
        ser.hexdump(@_ramdump+4, $20, 2, 132-4, 16)

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

PUB command(cmd)
' Execute application command
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core#CMD_STAT)
    i2c.write(cmd)
    i2c.stop()

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

