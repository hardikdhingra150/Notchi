import Darwin
import Foundation

/// CPU, memory, disk and network numbers for the sidebar. Reading them is cheap and
/// needs no permission; the sidebar only samples while it's open.
public struct SystemStats: Equatable, Sendable {
    /// 0...1 across all cores since the previous sample
    public var cpu: Double
    public var memoryUsed: UInt64
    public var memoryTotal: UInt64
    public var diskFree: Int64
    public var diskTotal: Int64
    /// bytes per second since the previous sample
    public var downloadRate: Double
    public var uploadRate: Double

    public var memoryFraction: Double { memoryTotal == 0 ? 0 : Double(memoryUsed) / Double(memoryTotal) }
    public var diskUsedFraction: Double { diskTotal == 0 ? 0 : 1 - Double(diskFree) / Double(diskTotal) }

    /// Raw counters; two of them make one `SystemStats`.
    public struct Counters: Equatable, Sendable {
        public var cpuBusy: UInt64
        public var cpuTotal: UInt64
        public var netIn: UInt64
        public var netOut: UInt64
        public var time: TimeInterval
        public init(cpuBusy: UInt64, cpuTotal: UInt64, netIn: UInt64, netOut: UInt64, time: TimeInterval) {
            self.cpuBusy = cpuBusy; self.cpuTotal = cpuTotal; self.netIn = netIn; self.netOut = netOut; self.time = time
        }
    }

    /// The share of CPU time spent busy between two samples, and network bytes per second.
    /// Counters that went backwards (an interface reset) count as zero.
    public static func rates(from a: Counters, to b: Counters) -> (cpu: Double, down: Double, up: Double) {
        let total = b.cpuTotal &- a.cpuTotal, busy = b.cpuBusy &- a.cpuBusy
        let cpu = b.cpuTotal > a.cpuTotal && b.cpuBusy >= a.cpuBusy ? min(max(Double(busy) / Double(total), 0), 1) : 0
        let dt = max(b.time - a.time, 0.001)
        let down = b.netIn >= a.netIn ? Double(b.netIn - a.netIn) / dt : 0
        let up = b.netOut >= a.netOut ? Double(b.netOut - a.netOut) / dt : 0
        return (cpu, down, up)
    }

    public static func counters(now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Counters {
        var busy: UInt64 = 0, total: UInt64 = 0
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let ok = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count) }
        }
        if ok == KERN_SUCCESS {
            let user = UInt64(load.cpu_ticks.0), system = UInt64(load.cpu_ticks.1), idle = UInt64(load.cpu_ticks.2), nice = UInt64(load.cpu_ticks.3)
            busy = user + system + nice
            total = busy + idle
        }
        var netIn: UInt64 = 0, netOut: UInt64 = 0
        var ifs: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifs) == 0, let first = ifs {
            var p: UnsafeMutablePointer<ifaddrs>? = first
            while let i = p {
                let flags = Int32(i.pointee.ifa_flags)
                if let addr = i.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK),
                   flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0, let data = i.pointee.ifa_data {
                    let d = data.assumingMemoryBound(to: if_data.self).pointee
                    netIn += UInt64(d.ifi_ibytes)
                    netOut += UInt64(d.ifi_obytes)
                }
                p = i.pointee.ifa_next
            }
            freeifaddrs(first)
        }
        return Counters(cpuBusy: busy, cpuTotal: total, netIn: netIn, netOut: netOut, time: now)
    }

    public static func memory() -> (used: UInt64, total: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        var vm = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let ok = withUnsafeMutablePointer(to: &vm) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) }
        }
        guard ok == KERN_SUCCESS else { return (0, total) }
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let page = UInt64(pageSize)
        // what Activity Monitor calls "Memory Used": app memory + wired + compressed
        let used = (UInt64(vm.internal_page_count) - UInt64(vm.purgeable_count) + UInt64(vm.wire_count) + UInt64(vm.compressor_page_count)) * page
        return (min(used, total), total)
    }

    public static func disk() -> (free: Int64, total: Int64) {
        let v = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
        return (v?.volumeAvailableCapacityForImportantUsage ?? 0, Int64(v?.volumeTotalCapacity ?? 0))
    }

    /// One reading, using `previous` counters for the CPU and network rates.
    public static func sample(since previous: Counters?) -> (stats: SystemStats, counters: Counters) {
        let now = counters()
        let r = previous.map { rates(from: $0, to: now) } ?? (cpu: 0, down: 0, up: 0)
        let m = memory(), d = disk()
        return (SystemStats(cpu: r.cpu, memoryUsed: m.used, memoryTotal: m.total, diskFree: d.free, diskTotal: d.total,
                            downloadRate: r.down, uploadRate: r.up), now)
    }
}
