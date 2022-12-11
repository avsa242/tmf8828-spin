{
    --------------------------------------------
    Filename: TMF8828-Demo.spin
    Author: Jesse Burt
    Description: Demo of the TMF8828 driver
    Copyright (c) 2022
    Started: Dec 11, 2022
    Updated: Dec 11, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode = xtal1+pll16x
    _xinfreq = 5_000_000

' -- User-modifiable constants --
    SER_BAUD        = 115_200

    SCL_PIN         = 28
    SDA_PIN         = 29
    I2C_FREQ        = 1_000_000                 ' 1_000_000 max
    ENABLE_PIN      = 24
    INT_PIN         = 25
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    range:  "sensor.range.tmf8828"

PUB main{} | r

    setup{}
    r := range.preset_tmf8828_spad_wide3x3{}
    if (r)
        ser.printf1(string("Setup failed - halting; error %d (see driver)\n\r"), r)
        repeat
    dira[INT_PIN] := 0

    repeat
        repeat until ina[INT_PIN] == 0
        range.int_clear(range.interrupt{})
        range.rd_packet(0)
        ser.pos_xy(0, 3)
        ser.hexdump(range.packet_ptr{}, $20, 2, 132, 16)

PUB setup{}

    ser.init_def(115_200)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if (range.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ENABLE_PIN))
        ser.strln(string("TMF8828 driver started"))
    else
        ser.strln(string("TMF8828 driver failed to start - halting"))
        repeat

    range.set_fw_image(@tmf8828_image, _img_sz)

#include "tmf8828_image.spin"

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

