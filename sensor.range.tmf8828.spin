{
    --------------------------------------------
    Filename: sensor.range.tmf8828.spin
    Author: Jesse Burt
    Description: Driver for the TMF8828 dToF 8x8 range/proximity sensor
    Copyright (c) 2022
    Started: Dec 10, 2022
    Updated: Dec 10, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR | 1

OBJ

    i2c: "com.i2c"
    core: "core.con.tmf8828"
    time: "time"
    ser : "com.serial.terminal.ansi"

VAR

    word _ptr_fw
    word _img_sz
    byte _INT_PIN

PUB null{}

PUB startx(SCL_PIN, SDA_PIN, I2C_FREQ, ENA_PIN): status

    status := i2c.init(SCL_PIN, SDA_PIN, I2C_FREQ)
    outa[ENA_PIN] := 0
    dira[ENA_PIN] := 1
    _INT_PIN := 25
    ser.init(17, 16, 0, 115_200)
    time.msleep(30)
    ser.clear
    ser.strln(@"serial started")
    outa[ENA_PIN] := 1

PUB stop{}

PUB app | tries, ena, appid, img_ptr, chunk_sz, img_remain, img_csum, status, aid, int_status, tmp 

    ser.str(@"enabling sensor power...")
    powered(true)

    tries := 1
    repeat until cpu_ready{}
        ++tries
    ser.printf1(@"success after %d tries\n\r", tries)

    case app_id{}
        $80:
            ser.strln(@"bootloader running")
        $03:
            ser.strln(@"application running")
        other:
            ser.strln(@"unknown state - halting")
            repeat

    fw_load{}

'3.2)
    ser.str(@"checking APPID...")
    tries := 0
    repeat
        time.usleep(500)
        if (++tries > 5)
            ser.strln(@"APPID read failed")
            repeat
    until app_id{} == core#MEAS_APP_RUNNING

' 4.1 step 1
    ser.str(@"Loading common config page...")
    command(core#CMD_LD_CFG_PG_COM)

    tries := 0
    repeat until cmd_status{} == core#STAT_OK
        if (++tries > 5)
            ser.strln(@"failed")
            repeat
    ser.strln(@"done")

    ser.str(@"Verifying the config page is loaded...")
    if (get_config_page{} == core#COMMON_CID)
        ser.strln(@"verified")
    else
        ser.strln(@"verification failed - halting")
        repeat

    ser.str(@"changing measurement period to 100ms...")
    set_meas_period(100)
    ser.strln(@"done")

    ser.str(@"selecting pre-defined SPAD mask #6...")
    set_spad_map(core#WIDE_3X3)
    ser.strln(@"done")

    ser.str(@"config GPIO0 low while VCSEL is emitting...")
    'writereg($31, 1, $03)
    gpio0(core#OUT_LO_VCSEL_PULSE)
    ser.strln(@"done")

    ser.str(@"writing common page...")
    command(core#CMD_WRITE_CFG_PG)
    ser.strln(@"done")

    ser.str(@"Verifying the command executed...")
    tries := 0
    repeat until cmd_status{} == core#STAT_OK
        if (++tries > 5)
            ser.strln(@"failed")
            repeat
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
    dira[_INT_PIN] := 0
    repeat
        repeat until ina[_INT_PIN] == 0
        readreg($e1, 1, @int_status)
        writereg($e1, 1, int_status)
        readreg($20, 132, @_ramdump)
        ser.pos_xy(0, 27)
        ser.hexdump(@_ramdump+4, $20, 2, 132-4, 16)

VAR byte _ramdump[132]

PUB app_id{}: id
' Get currently running application
'   Returns:
'       $03: measurement application
'       $80: bootloader
    id := 0
    readreg(core#APPID, 1, @id)

PUB cmd_status{}: s
' Get status of last command
'   Returns:
'       STAT_OK ($00)
'       STAT_ACCEPTED ($01)
'       STAT_ERR_CFG ($02)
'       STAT_ERR_APP ($03)
'       STAT_ERR_WAKEUP_TIMED ($04)
'       STAT_ERR_RESET_UNEXPECTED ($05)
'       STAT_ERR_UNKNOWN_CMD ($06)
'       STAT_ERR_NO_REF_SPAD ($07)
'       STAT_ERR_UNKNOWN_CID ($09)
'       STAT_WARN_CFG_SPAD1_NOT_ACCEPT ($0a)
'       STAT_WARN_CFG_SPAD2_NOT_ACCEPT ($0b)
'       STAT_WARN_OSC_TRIM_NOT_ACCEPT ($0c)
'       STAT_WARN_I2C_ADDR_NOT_ACCEPT ($0d)
'       STAT_ERR_UNKNOWN_MODE ($0e)
    s := 0
    readreg(core#CMD_STAT, 1, @s)

PUB get_config_page{}: p

    p := 0
    readreg(core#CONFIG_RESULT, 1, @p)

PUB gpio0(mode): curr_mode
' Set GPIO0 mode
    case mode
        0..$df:
            mode &= core#GPIO_0_MASK
            writereg(core#GPIO_0, 1, mode)
        other:
            curr_mode := 0
            readreg(core#GPIO_0, 1, @curr_mode)

PUB gpio1(mode): curr_mode
' Set GPIO0 mode
    case mode
        0..$df:
            mode &= core#GPIO_1_MASK
            writereg(core#GPIO_1, 1, mode)
        other:
            curr_mode := 0
            readreg(core#GPIO_1, 1, @curr_mode)

PUB cpu_ready{}: flag
' Flag indicating the sensor CPU is ready
    flag := 0
    readreg(core#ENABLE, 1, @flag)
    return (((flag >> core#CPU_RDY) & 1) == 1)

PUB fw_load{} | img_remain, img_ptr, chunk_sz, status, img_csum, ena, tries, tmp
' Load a firmware image
'   ptr_image: pointer to firmware/application image
'   img_sz: size of image, in bytes
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
    img_ptr := _ptr_fw                        ' init pointer to start of FW image
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
            if (++tries > 5)
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

PUB meas_per{}: per

    per := 0
    readreg(core#PERIOD_MS_LSB, 2, @per)

PUB set_meas_period(per)
' Set measurement period, in milliseconds
'   Valid values: 0..65535
    writereg(core#PERIOD_MS_LSB, 2, (0 #> per <# 65535))

PUB powered(state): curr_state
' Enable sensor power
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    ser.printf1(@"reading %02.2x\n\r", curr_state)
    case ||(state)
        0, 1:
            state &= 1
            state := ((curr_state & core#PON_MASK & core#PWRUP_SEL_MASK) | state)
            ser.printf1(@"writing %02.2x\n\r", state)
            writereg(core#ENABLE, 1, state)
        other:
            return ((curr_state & 1) == 1)

PUB set_fw_image(ptr_img, img_sz)
' Setup firmware image
'   ptr_img: pointer to firmware/application image
'   img_sz: size of image, in bytes
    _ptr_fw := ptr_img
    _img_sz := img_sz

PUB set_spad_map(id)
' Set SPAD map/define field of view (FoV)
    if (lookdown(id: 1..7, 10..15))
        writereg(core#SPAD_MAP_ID, 1, @id)

PUB spad_map{}: id
' Get currently set SPAD map/FoV
    id := 0
    readreg(core#SPAD_MAP_ID, 1, @id)

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

PUB sum_blk(ptr_data, len): ck | tmp
' Sum a block of data
    ck := 0
    repeat tmp from 0 to len-1
        ck += byte[ptr_data][tmp]

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

'#include "tmf8828_image.spin"

