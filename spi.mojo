from sys import ffi, info

alias LIBGPIO_PATH = "/usr/local/lib/liblgpio.so"

alias c_LGPIO_lgSpiOpen = fn (Int32, Int32, Int32, Int32) -> Int32
alias c_LGPIO_lgSpiClose = fn (Int32) -> Int32
alias c_LGPIO_lgSpiRead = fn (Int32, String, Int32) -> Int32
alias c_LGPIO_lgSpiWrite = fn (Int32, String, Int32) -> Int32

struct Spi:
    var _handle: Int32
    var _channel: Int32


    var _close: c_LGPIO_lgSpiClose
    var _open: c_LGPIO_lgSpiOpen
    var _read: c_LGPIO_lgSpiRead
    var _write: c_LGPIO_lgSpiWrite

    fn __init__(inout self, handle: Int32, channel: Int32) raises:
        self._handle = handle
        self._channel = channel
        var lgpio = ffi.DLHandle(LIBGPIO_PATH)
        self._close = lgpio.get_function[c_LGPIO_lgSpiClose]("lgSpiClose")
        self._open = lgpio.get_function[c_LGPIO_lgSpiOpen]("lgSpiOpen")
        self._read = lgpio.get_function[c_LGPIO_lgSpiRead]("lgSpiRead")
        self._write = lgpio.get_function[c_LGPIO_lgSpiWrite]("lgSpiWrite")

        var ok = self._open(self._handle, self._channel, 1000000, 0)
        if ok < 0:
            raise Error("Failed to open SPI channel")

    fn close(self) raises:
        var ok = self._close(self._handle)
        if ok < 0:
            raise Error("Failed to close SPI channel")

    fn write(self, data: String) raises:
        var ok = self._write(self._handle, data, len(data))
        if ok < 0:
            raise Error("Failed to write to SPI channel")


fn main() raises:
    var spi = Spi(0, 0)
    spi.write("Hello, world!")
    spi.close()
