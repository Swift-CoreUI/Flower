import UIKit

public protocol Navigating: RootControllable, Presenting {
    typealias CleanupCompletion = () -> Void

    init(navigationController: UINavigationController)

    func push(_ vc: UIViewController, animated: Bool, hideBottomBar: Bool, afterPop: CleanupCompletion?)
    func replaceLast(with vc: UIViewController, animated: Bool, hideBottomBar: Bool)
    func pop(animated: Bool)
    func popToRoot(animated: Bool)
    func popToViewController(_ vc: UIViewController, animated: Bool)

    func append(_ viewControllers: [UIViewController], animated: Bool, afterPop completion: CleanupCompletion?)

    var isNavigationBarHidden: Bool { get set }
    var isNavigationControllerEmpty: Bool { get }

    var topViewController: UIViewController? { get }

    @available(*, deprecated, message: "it's forbidden to access internal navigation controller")
    var nc: UINavigationController { get }
}

/// reasonable defaults for functions (to allow coordinators depend on protocol, but not on implementation)
public extension Navigating {
    @inlinable func push(_ vc: UIViewController,
                         animated: Bool = true,
                         hideBottomBar: Bool = false,
                         afterPop completion: CleanupCompletion? = nil
    ) {
        push(vc, animated: animated,
             hideBottomBar: hideBottomBar,
             afterPop: completion)
    }

    @inlinable func replaceLast(with vc: UIViewController, animated: Bool = false, hideBottomBar: Bool = false) {
        replaceLast(with: vc, animated: animated, hideBottomBar: hideBottomBar)
    }

    @inlinable func pop(animated: Bool = true) {
        pop(animated: animated)
    }

    @inlinable func popToRoot(animated: Bool = true) {
        popToRoot(animated: animated)
    }

    @inlinable func popToViewController(_ vc: UIViewController, animated: Bool = true) {
        popToViewController(vc, animated: animated)
    }
}
