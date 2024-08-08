import time
from lgpio.gpio import GPIO, LineFlag
from lgpio.spi import Spi

struct ADS1264:
    var gpio: GPIO
    var spi: Spi
    var drdy_pin: Int
    var rst_pin: Int
    var cs_pin: Int

    fn __init__(inout self, gpio: GPIO, spi: Spi):
        self.gpio = gpio
        self.spi = spi
        self.drdy_pin = 17
        self.rst_pin = 18
        self.cs_pin = 22

        var ok = self.gpio.claim_output(self.cs_pin, 1, LineFlag.Default)
        if ok < 0:
            print("Failed to claim CS pin")
            return

        ok = self.gpio.claim_output(self.rst_pin, 0, LineFlag.Default)
        if ok < 0:
            print("Failed to claim RST pin")
            return

        ok = self.gpio.claim_input(self.drdy_pin, LineFlag.SetPullUp)
        if ok < 0:
            print("Failed to claim DRDY pin")
            return

    fn reset(self):
        var ok = self.gpio.write(self.rst_pin, 1)
        if ok < 0:
            print("Failed to set RST pin")
            return
        time.sleep(0.2)
        ok = self.gpio.write(self.rst_pin, 0)
        if ok < 0:
            print("Failed to clear RST pin")
            return
        time.sleep(0.2)
        ok = self.gpio.write(self.rst_pin, 1)
        if ok < 0:
            print("Failed to set RST pin")
            return

    fn checksum(self, value: Int, byt: UInt8) -> UInt8:
        var val = value
        var sum = 0
        var mask = 0xff

        while val > 0:
            sum += value & mask
            val = val >> 8

        sum += 0x9b

        return (sum & mask) ^ byt

    def wait_ready(self, timeout_s: Float32) -> Bool:
        var start_ns = time.now()
        var timeout_ns = int(timeout_s * 1_000_000_000)

        while self.gpio.read(self.drdy_pin) != 0:
            var now_ns = time.now()
            if now_ns - start_ns > timeout_ns:
                return False

        return True
fn main() raises:
    var gpio = GPIO(0)
    var spi = Spi(0, 0)

    print(gpio)

    print("Setting up ADS1264")
    var ads1264 = ADS1264(gpio, spi)
    ads1264.reset()
    print("Waiting for DRDY")
    var ok = ads1264.wait_ready(1.0)
    if ok:
        print("DRDY is ready")
    else:
        print("DRDY timed out")
        return

    
    
