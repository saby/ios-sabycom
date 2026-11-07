//
//  Reachability.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 17.01.2022.
//

import Foundation
import SystemConfiguration

/// Ошибка доступа в интернет
enum ReachabilityError: Error {
    case failedToCreateWithAddress(sockaddr_in)
    case failedToCreateWithHostname(String)
    case unableToSetCallback
    case unableToSetDispatchQueue
}

/// Имя нотификации изменения доступности интернета
let ReachabilityChangedNotification = "ReachabilityChangedNotification"

func callback(_ reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else {
        return
    }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
    
    DispatchQueue.main.async {
        reachability.reachabilityChanged(flags)
    }
}

/// Класс обработчик доступа в интернет
class Reachability: CustomStringConvertible {
    
    /// Алиас функции по доступной сети
    typealias NetworkReachable = (Reachability) -> Void
    
    /// Алиас функции по недоступной сети
    typealias NetworkUnreachable = (Reachability) -> Void
    
    /// Статус сети
    enum NetworkStatus: CustomStringConvertible {
        
        case notReachable, reachableViaWiFi, reachableViaWWAN
        
        /// Описание активной сети
        var description: String {
            switch self {
            case .reachableViaWWAN:
                return "Cellular"
            case .reachableViaWiFi:
                return "WiFi"
            case .notReachable:
                return "No Connection"
            }
        }
    }
    
    // MARK: - *** properties ***
    
    /// коллбэк для активной сети
    var whenReachable: NetworkReachable?
    /// коллбэк для неактивной сети
    var whenUnreachable: NetworkUnreachable?
    /// сеть доступна по WWAN
    var reachableOnWWAN: Bool
    /// NotificationCenter.default
    var notificationCenter = NotificationCenter.default
    
    /// Текущий статус сети
    var currentReachabilityStatus: NetworkStatus {
        if isReachable() {
            if isReachableViaWiFi() {
                return .reachableViaWiFi
            }
            if isRunningOnDevice {
                return .reachableViaWWAN
            }
        }
        return .notReachable
    }
    
    /// Текущий статус сети, строкой
    var currentReachabilityString: String {
        return "\(currentReachabilityStatus)"
    }
    
    fileprivate var previousFlags: SCNetworkReachabilityFlags?
    
    // MARK: - *** Initialisation methods ***
    /// Инициализация
    ///
    /// - Parameter reachabilityRef: SCNetworkReachability
    required init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    /// Инициализация
    ///
    /// - Parameter hostname: имя хоста
    /// - Throws: ReachabilityError.failedToCreateWithHostname(hostname)
    convenience init(hostname: String) throws {
        let nodename = (hostname as NSString).utf8String
        guard let ref = SCNetworkReachabilityCreateWithName(nil, nodename!) else { throw ReachabilityError.failedToCreateWithHostname(hostname) }
        
        self.init(reachabilityRef: ref)
    }
    
    /// Инициализотор Reachability для любой сети
    ///
    /// - Returns: Reachability с доступом в интернет
    /// - Throws: ReachabilityError.failedToCreateWithAddress(zeroAddress)
    class func reachabilityForInternetConnection() throws -> Reachability {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let ref = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else { throw ReachabilityError.failedToCreateWithAddress(zeroAddress) }
        
        return Reachability(reachabilityRef: ref)
    }
    
    /// Инициализотор Reachability для локальному WiFi
    ///
    /// - Returns: Reachability с доступом в интернет
    /// - Throws: ReachabilityError.failedToCreateWithAddress(localWifiAddress)
    class func reachabilityForLocalWiFi() throws -> Reachability {
        
        var localWifiAddress: sockaddr_in = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        localWifiAddress.sin_len = UInt8(MemoryLayout.size(ofValue: localWifiAddress))
        localWifiAddress.sin_family = sa_family_t(AF_INET)
        
        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        let address: UInt32 = 0xA9FE0000
        localWifiAddress.sin_addr.s_addr = in_addr_t(address.bigEndian)
        
        guard let ref = withUnsafePointer(to: &localWifiAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else { throw ReachabilityError.failedToCreateWithAddress(localWifiAddress) }
        
        return Reachability(reachabilityRef: ref)
    }
    
    // MARK: - *** Notifier methods ***
    
    /// Начать нотификацию
    func startNotifier() throws {
        
        guard !notifierRunning else { return }
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef!, callback, &context) {
            stopNotifier()
            throw ReachabilityError.unableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef!, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.unableToSetDispatchQueue
        }
        
        // Perform an intial check
        reachabilitySerialQueue.async { () -> Void in
            let flags = self.reachabilityFlags
            self.reachabilityChanged(flags)
        }

        notifierRunning = true
    }
    
    /// Остановить нотификацию
    func stopNotifier() {
        defer { notifierRunning = false }
        guard let reachabilityRef = reachabilityRef else { return }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    // MARK: - *** Connection test methods ***
    
    /// Есть лидлоступ в интернет
    func isReachable() -> Bool {
        let flags = reachabilityFlags
        return isReachableWithFlags(flags)
    }
    
    /// Доступен ли интернет по WWAN
    func isReachableViaWWAN() -> Bool {
        let flags = reachabilityFlags
        
        // Check we're not on the simulator, we're REACHABLE and check we're on WWAN
        return isRunningOnDevice && isReachable(flags) && isOnWWAN(flags)
    }
    
    /// Доступен ли интернет по WiFi
    func isReachableViaWiFi() -> Bool {
        let flags = reachabilityFlags
        
        // Check we're reachable
        if !isReachable(flags) {
            return false
        }
        
        // Must be on WiFi if reachable but not on an iOS device (i.e. simulator)
        if !isRunningOnDevice {
            return true
        }
        
        // Check we're NOT on WWAN
        return !isOnWWAN(flags)
    }
    
    // MARK: - *** Private methods ***
    fileprivate var isRunningOnDevice: Bool = {
        #if targetEnvironment(simulator) && os(iOS)
            return false
        #else
            return true
        #endif
    }()
    
    fileprivate var notifierRunning = false
    fileprivate var reachabilityRef: SCNetworkReachability?
    fileprivate let reachabilitySerialQueue = DispatchQueue(label: "uk.co.ashleymills.reachability", attributes: [])

    fileprivate func reachabilityChanged(_ flags: SCNetworkReachabilityFlags) {
        
        guard previousFlags != flags else { return }
        
        if isReachableWithFlags(flags) {
            if let block = whenReachable {
                block(self)
            }
        } else {
            if let block = whenUnreachable {
                block(self)
            }
        }
        
        notificationCenter.post(name: Notification.Name(rawValue: ReachabilityChangedNotification), object: self)
        
        previousFlags = flags
    }
    
    fileprivate func isReachableWithFlags(_ flags: SCNetworkReachabilityFlags) -> Bool {
        
        if !isReachable(flags) {
            return false
        }
        
        if isConnectionRequiredOrTransient(flags) {
            return false
        }
        
        if isRunningOnDevice {
            if isOnWWAN(flags) && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        
        return true
    }

    // WWAN may be available, but not active until a connection has been established.
    // WiFi may require a connection for VPN on Demand.
    fileprivate func isConnectionRequired() -> Bool {
        return connectionRequired()
    }
    
    fileprivate func connectionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags)
    }
    
    // Dynamic, on demand connection?
    fileprivate func isConnectionOnDemand() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags) && isConnectionOnTrafficOrDemand(flags)
    }
    
    // Is user intervention required?
    fileprivate func isInterventionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags) && isInterventionRequired(flags)
    }

    fileprivate func isOnWWAN(_ flags: SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags.contains(.isWWAN)
        #else
            return false
        #endif
    }
    fileprivate func isReachable(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.reachable)
    }
    fileprivate func isConnectionRequired(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionRequired)
    }
    fileprivate func isInterventionRequired(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.interventionRequired)
    }
    fileprivate func isConnectionOnTraffic(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionOnTraffic)
    }
    fileprivate func isConnectionOnDemand(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionOnDemand)
    }
    func isConnectionOnTrafficOrDemand(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return !flags.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    fileprivate func isTransientConnection(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.transientConnection)
    }
    fileprivate func isLocalAddress(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isLocalAddress)
    }
    fileprivate func isDirect(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isDirect)
    }
    fileprivate func isConnectionRequiredOrTransient(_ flags: SCNetworkReachabilityFlags) -> Bool {
        let testcase: SCNetworkReachabilityFlags = [.connectionRequired, .transientConnection]
        return flags.intersection(testcase) == testcase
    }
    
    fileprivate var reachabilityFlags: SCNetworkReachabilityFlags {
        
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }
        
        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }
        
        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }

    /// :nodoc:
    var description: String {
        var W: String
        if isRunningOnDevice {
            W = isOnWWAN(reachabilityFlags) ? "W" : "-"
        } else {
            W = "X"
        }
        let R = isReachable(reachabilityFlags) ? "R" : "-"
        let c = isConnectionRequired(reachabilityFlags) ? "c" : "-"
        let t = isTransientConnection(reachabilityFlags) ? "t" : "-"
        let i = isInterventionRequired(reachabilityFlags) ? "i" : "-"
        let C = isConnectionOnTraffic(reachabilityFlags) ? "C" : "-"
        let D = isConnectionOnDemand(reachabilityFlags) ? "D" : "-"
        let l = isLocalAddress(reachabilityFlags) ? "l" : "-"
        let d = isDirect(reachabilityFlags) ? "d" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
    
    deinit {
        stopNotifier()
        
        reachabilityRef = nil
        whenReachable = nil
        whenUnreachable = nil
    }
}
