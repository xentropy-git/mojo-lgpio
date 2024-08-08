from sys import ffi, info

alias LIBGPIO_PATH = "/usr/local/lib/liblgpio.so"
alias LG_GPIO_NAME_LEN = 32
alias LG_GPIO_LABEL_LEN = 32
alias LG_GPIO_USER_LEN = 32

@register_passable('trivial')
struct c_ChipInfo:
    var lines: Int32
    var name: SIMD[DType.uint8, LG_GPIO_NAME_LEN]
    var label: SIMD[DType.uint8, LG_GPIO_LABEL_LEN]

    fn __init__(inout self):
        self.lines = 0
        self.name = SIMD[DType.uint8, 32]()
        self.label = SIMD[DType.uint8, 32]()

@value
struct ChipInfo:
    var lines: Int32
    var name: String
    var label: String

    fn __init__(inout self, c: c_ChipInfo):
        self.lines = c.lines
        self.name = ""
        for i in range(LG_GPIO_NAME_LEN):
            if c.name[i] == 0:
                continue
            self.name += chr(int(c.name[i]))

        self.label = ""
        for i in range(LG_GPIO_LABEL_LEN):
            if c.label[i] == 0:
                continue
            self.label += chr(int(c.label[i]))

alias c_LGPIO_lgGpiochipOpen = fn(Int32) -> Int32
alias c_LGPIO_lgGpioGetChipInfo = fn(Int32, Pointer[c_ChipInfo]) -> Int32
alias c_LGPIO_lgGpioClaimOutput = fn(Int32, Int32, Int32, Int32) -> Int32
alias c_LGPIO_lgGpioClaimInput = fn(Int32, Int32, Int32) -> Int32
alias c_LGPIO_lgGpioRead = fn(Int32, Int32) -> Int32
alias c_LGPIO_lgGpioWrite = fn(Int32, Int32, Int32) -> Int32


struct LineFlag:
    var value: Int32

    alias Default: LineFlag = LineFlag(0)
    alias SetActiveLow: LineFlag = LineFlag(4)
    alias SetOpenDrain: LineFlag = LineFlag(8)
    alias SetOpenSource: LineFlag = LineFlag(16)
    alias SetPullUp: LineFlag = LineFlag(32)
    alias SetPullDown: LineFlag = LineFlag(64)
    alias SetPullNone: LineFlag = LineFlag(128)

    fn __init__(inout self, value: Int32):
        self.value = value

@value
struct GPIO(Stringable):
    var _handle: Int32

    var _get_chip_info: c_LGPIO_lgGpioGetChipInfo
    var _open_device: c_LGPIO_lgGpiochipOpen
    var _claim_output: c_LGPIO_lgGpioClaimOutput
    var _claim_input: c_LGPIO_lgGpioClaimInput
    var _read: c_LGPIO_lgGpioRead
    var _write: c_LGPIO_lgGpioWrite

    fn __init__(inout self, device: Int32) raises:
        var lgpio = ffi.DLHandle(LIBGPIO_PATH)
        self._open_device = lgpio.get_function[c_LGPIO_lgGpiochipOpen]("lgGpiochipOpen")
        self._get_chip_info = lgpio.get_function[c_LGPIO_lgGpioGetChipInfo]("lgGpioGetChipInfo")
        self._claim_output = lgpio.get_function[c_LGPIO_lgGpioClaimOutput]("lgGpioClaimOutput")
        self._claim_input = lgpio.get_function[c_LGPIO_lgGpioClaimInput]("lgGpioClaimInput")
        self._read = lgpio.get_function[c_LGPIO_lgGpioRead]("lgGpioRead")
        self._write = lgpio.get_function[c_LGPIO_lgGpioWrite]("lgGpioWrite")
        self._handle = self._open_device(device)
    
    fn get_chip_info(self) -> ChipInfo:
        var info = c_ChipInfo()
        var info_ptr = Pointer.address_of(info)
        var ok = self._get_chip_info(self._handle, info_ptr)
        return ChipInfo(info)

    fn claim_output(self, line: Int32, level: Int, flags: LineFlag) -> Int32:
        return self._claim_output(self._handle, flags.value, line, level)

    fn claim_input(self, line: Int32, flags: LineFlag) -> Int32:
        return self._claim_input(self._handle, flags.value, line)

    fn read(self, line: Int32) -> Int32:
        return self._read(self._handle, line)

    fn write(self, line: Int32, level: Int32) -> Int32:
        return self._write(self._handle, line, level)

    fn __str__(self) -> String:
        var chip = self.get_chip_info()
        return "GPIODevice(handle: " + String(self._handle) + ", lines:" + String(chip.lines) + 
                            ", name: \"" + chip.name + "\", label: \"" + chip.label + "\")"

