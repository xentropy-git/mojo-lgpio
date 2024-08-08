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

alias c_LGPIO_lgGpiochipOpen = fn(d: Int32) -> Int32
alias c_LGPIO_lgGpioGetChipInfo = fn(d: Int32, info: Pointer[c_ChipInfo]) -> Int32

struct GPIODevice(Stringable):
    var _handle: Int32

    var _get_chip_info: c_LGPIO_lgGpioGetChipInfo
    fn __init__(inout self, handle: Int32) raises:
        self._handle = handle
        var lgpio = ffi.DLHandle(LIBGPIO_PATH)
        self._get_chip_info = lgpio.get_function[c_LGPIO_lgGpioGetChipInfo]("lgGpioGetChipInfo")
    
    fn get_chip_info(self) -> ChipInfo:
        var info = c_ChipInfo()
        var info_ptr = Pointer.address_of(info)
        var ok = self._get_chip_info(self._handle, info_ptr)
        return ChipInfo(info)

    fn __str__(self) -> String:
        var chip = self.get_chip_info()
        return "GPIODevice(handle: " + String(self._handle) + ", lines:" + String(chip.lines) + 
                            ", name: \"" + chip.name + "\", label: \"" + chip.label + "\")"

struct LGPIO:
    var _open_device: c_LGPIO_lgGpiochipOpen

    fn open_device(inout self, device: Int32) raises -> GPIODevice:
        var handle = self._open_device(device)
        return GPIODevice(handle)
    
    fn __init__(inout self):
        var lgpio = ffi.DLHandle(LIBGPIO_PATH)
        self._open_device = lgpio.get_function[c_LGPIO_lgGpiochipOpen]("lgGpiochipOpen")

fn main() raises:
    var lgpio = LGPIO()

    var gpio = lgpio.open_device(0)
    print(gpio)
