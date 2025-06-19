# Experiment to get Bare Metal Swift for ESP32 - RISC-V family

This is an experiment to get Bare Metal Swift for ESP32-C6 family.

## Build testing project

```shell
make
make elf2image
make flash
espflash monitor
```

## Boostrapping toolchain

```
git clone https://github.com/apple/swift.git
./swift/utils/update-checkout --clone
```



