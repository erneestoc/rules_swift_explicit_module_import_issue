import RxCocoa
import UIKit

@objc protocol ProxyDelegate: NSObjectProtocol {}

class ProxyParent: NSObject, HasDelegate {
    typealias Delegate = ProxyDelegate
    weak var delegate: ProxyDelegate?
}

final class MinimalDelegateProxy:
    DelegateProxy<ProxyParent, ProxyDelegate>,
    DelegateProxyType {

    init(parent: ProxyParent) {
        super.init(parentObject: parent, delegateProxy: MinimalDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { MinimalDelegateProxy(parent: $0) }
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = MinimalDelegateProxy(parent: ProxyParent())
        return true
    }
}
