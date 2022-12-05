import UIKit

open class Navigator: NSObject, Navigating {
    public var nc: UINavigationController { navigationController }

    private let navigationController: UINavigationController
    private var completions: [UIViewController: CleanupCompletion] = [:]

    required public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        super.init()
        self.navigationController.delegate = self
        self.navigationController.presentationController?.delegate = self
    }

    // MARK: - RootControllable protocol
    public var root: UIViewController? {
        get { navigationController.viewControllers.first }
        set { setRoot(newValue, cleanupCompletion: nil) }
    }

    private var rootCompletion: (() -> Void)?

    public func setRoot(_ newRoot: UIViewController?, cleanupCompletion: (() -> Void)?) {
        guard let vc = newRoot else {
            assertionFailure("navigator cannot set nil as root controller")
            return
        }
        resetRoot(to: vc)
        if let completion = cleanupCompletion {
            completions[vc] = completion
        }

        navigationController.presentationController?.delegate = self
    }

    // MARK: - Presenting protocol
    open func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.present(vc, animated: animated, completion: completion)
    }

    public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        if navigationController.presentedViewController == nil {
            // we need to run cleanup only if we are dismissing navigationController
            // if we are dismissing some controller presented from navigationController - we don't need to clean all
            runAllCompletions()
        }

        navigationController.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Navigating protocol
    public var isNavigationBarHidden: Bool {
        get { navigationController.isNavigationBarHidden }
        set { navigationController.isNavigationBarHidden = newValue }
    }

    public var isNavigationControllerEmpty: Bool { navigationController.viewControllers.isEmpty }

    public var topViewController: UIViewController? { nc.topViewController } // or nc.viewControllers.last

    public func push(_ vc: UIViewController,
                     animated: Bool,
                     hideBottomBar: Bool,
                     afterPop completion: CleanupCompletion?
    ) {
        guard !(vc is UINavigationController) else {
            assertionFailure("Cannot push UINavigationController into UINavigationController")
            return
        }

        if let completion = completion {
            completions[vc] = completion
        }

        vc.hidesBottomBarWhenPushed = hideBottomBar
        navigationController.presentationController?.delegate = self
        navigationController.pushViewController(vc, animated: animated)
    }

    public func replaceLast(with vc: UIViewController, animated: Bool, hideBottomBar: Bool) {
        var afterPop: CleanupCompletion?
        if let lastVC = navigationController.viewControllers.last {
            afterPop = completions.removeValue(forKey: lastVC)
            navigationController.popViewController(animated: false) // do not use pop with runCompletion here
        }
        push(vc, animated: animated, hideBottomBar: hideBottomBar, afterPop: afterPop)
    }

    public func append(_ controllers: [UIViewController],
                       animated: Bool,
                       afterPop completion: CleanupCompletion?) {
        guard let first = controllers.first else { return }

        if let completion = completion {
            completions[first] = completion
        }

        navigationController.setViewControllers(navigationController.viewControllers + controllers, animated: animated)
    }

    public func pop(animated: Bool) {
        guard let controller = navigationController.popViewController(animated: animated) else { return }

        runCompletion(for: controller)
    }

    public func popToRoot(animated: Bool = true) {
        guard let controllers = navigationController.popToRootViewController(animated: animated) else { return }

        for controller in controllers.reversed() {
            runCompletion(for: controller)
        }
    }

    public func popToViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let controllers = navigationController.popToViewController(vc, animated: animated) else { return }

        for controller in controllers.reversed() {
            runCompletion(for: controller)
        }
    }

    // MARK: - private helpers
    private func resetRoot(to vc: UIViewController) {
        for (_, completion) in completions {
            completion()
        }
        completions = [:]
        navigationController.viewControllers = [vc]
    }

    private func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else { return }

        completion()
        completions.removeValue(forKey: controller)
    }

    func runAllCompletions() {
        for controller in navigationController.viewControllers.reversed() {
            runCompletion(for: controller)
        }
    }

    deinit {
        navigationController.viewControllers = []
    }
}

extension Navigator: UINavigationControllerDelegate {
    /// This is the main reason to have Navigating
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        guard let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from) else { return }

        if !navigationController.viewControllers.contains(fromVC) { // e.g. we are popping VC, not pushing
            runCompletion(for: fromVC)
        }
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     willShow viewController: UIViewController,
                                     animated: Bool) {
        guard let toVC = navigationController.transitionCoordinator?.viewController(forKey: .to) else { return }

        if navigationController.viewControllers.contains(toVC) { // e.g. we are popping VC, not pushing
            // ...
        }
    }
}

extension Navigator: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        runAllCompletions()
    }
}
