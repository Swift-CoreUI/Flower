import UIKit

public protocol Presenting: AnyObject {
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?)

    func dismiss(animated: Bool, completion: (() -> Void)?)
}

/// reasonable defaults for functions (to allow coordinators depend on protocol, not on implementation)
public extension Presenting {
    @inlinable func present(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        present(vc, animated: animated, completion: completion)
    }

    @inlinable func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(animated: animated, completion: completion)
    }
}
