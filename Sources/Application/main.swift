import MMIO
import Registers

@_cdecl("_start")
public func _start() -> Never {
    while true {
        // spin
    }
}

/// Very crude busy loop (replace with timer later)
func delay() {
    for _ in 0..<10_000_000 {
        _ = 0
    }
}
