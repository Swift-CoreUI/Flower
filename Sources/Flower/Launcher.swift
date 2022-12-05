import UIKit

open class Launcher: Launching {
    private let window: UIWindow
    private var rootCompletion: (() -> Void)?

    required public init(window: UIWindow) {
        self.window = window
        self.window.makeKeyAndVisible()
    }

    // MARK: - RootControllable protocol
    public var root: UIViewController? {
        get { window.rootViewController }
        set { setRoot(newValue, cleanupCompletion: nil) }
    }

    public func setRoot(_ newRoot: UIViewController?, cleanupCompletion: (() -> Void)?) {
        rootCompletion?()
        window.rootViewController = newRoot
        rootCompletion = cleanupCompletion
    }

    // MARK: Presenting protocol
    open func present(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard var topController = root else { return }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        topController.present(vc, animated: animated, completion: completion)
    }

    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        root?.dismiss(animated: animated, completion: completion)
    }

}
