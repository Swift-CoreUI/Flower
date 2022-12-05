import Foundation
import os.log

public protocol StartableCoordinator: AnyObject {
    var flowFinished: (() -> Void)? { get set }

    func start()
    func start(afterFinish: @escaping () -> Void)
    func finish()
}

extension StartableCoordinator {
    public func start(afterFinish: @escaping () -> Void) {
        flowFinished = afterFinish
        start()
    }
}

public protocol Deeplinkable: AnyObject {
    associatedtype DeeplinkType

    func open(deeplink: DeeplinkType) -> Bool
    func open(deeplink: DeeplinkType, ignore: [CoordinatorDependable]) -> Bool

    func didOpen(deeplink: DeeplinkType) -> Bool
}

public protocol CoordinatorDependable: AnyObject {
    func add(child coordinator: CoordinatorDependable)
    func remove(child coordinator: CoordinatorDependable)
    func attach(to parent: CoordinatorDependable) -> Self

    func removeFromParent()
    func removeAllChildren()

    func childCoordinator<T>(withType: T.Type) -> T? where T: CoordinatorDependable
    func hasChildCoordinator<T>(withType: T.Type) -> Bool where T: CoordinatorDependable

    var childCoordinators: [CoordinatorDependable] { get set }
    var parentCoordinator: CoordinatorDependable? { get set }
}

extension CoordinatorDependable {
    public func add(child coordinator: CoordinatorDependable) {
        guard !childCoordinators.contains(where: { $0 === coordinator }) else { return }
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }

    public func remove(child coordinator: CoordinatorDependable) {
        guard !childCoordinators.isEmpty else { return }

        // remove from hierarchy recursively first if any
        for child in coordinator.childCoordinators where child !== coordinator {
            coordinator.remove(child: child)
        }

        for (index, child) in childCoordinators.enumerated() where child === coordinator {
            child.parentCoordinator = nil
            childCoordinators.remove(at: index)
            break
        }
    }

    @discardableResult
    public func attach(to parent: CoordinatorDependable) -> Self {
        parent.add(child: self)
        return self
    }

    /**
     Just a shortcut for convenience
     */
    @inlinable public func removeFromParent() {
        parentCoordinator?.remove(child: self)
    }

    public func removeAllChildren() {
        for child in childCoordinators {
            remove(child: child)
        }
    }

    public func childCoordinator<T>(withType: T.Type) -> T? where T: CoordinatorDependable {
        return childCoordinators.first(where: { $0 is T }) as? T
    }

    @inlinable public func hasChildCoordinator<T>(withType type: T.Type) -> Bool where T: CoordinatorDependable {
        return childCoordinator(withType: type) != nil
    }
}

extension CoordinatorDependable {
    public func run(_ flowCoordinator: StartableCoordinator & CoordinatorDependable) {
        flowCoordinator.attach(to: self)
            .start()
    }

    public func run(_ flowCoordinator: StartableCoordinator & CoordinatorDependable, afterFinish: @escaping () -> Void) {
        flowCoordinator.attach(to: self)
            .start(afterFinish: afterFinish)
    }
}

open class HierarchyContainer<DeepLinkType>: NSObject, Deeplinkable, CoordinatorDependable {
    // MARK: - Startable
    public var flowFinished: (() -> Void)?

    open func finish() {
        flowFinished?()

        removeFromParent()
    }

    // MARK: - Dependable
    open var childCoordinators: [CoordinatorDependable] = []
    open weak var parentCoordinator: CoordinatorDependable?

    // MARK: - Deeplinkable

    /**
     NB: `open` implementatino should be public, not open! should not be overriden in child classes
     */
    @discardableResult
    public final func open(deeplink: DeepLinkType, ignore ignoredChildren: [CoordinatorDependable]) -> Bool {
        if didOpen(deeplink: deeplink) {
            return true
        }

        // direct and not performant algoritm, but that's ok for now: coordinator tree should not be large
        for coordinator in childCoordinators where !ignoredChildren.contains(where: { $0 === coordinator }) {
            if let coordinator = coordinator as? HierarchyContainer {
               if coordinator.open(deeplink: deeplink, ignore: ignoredChildren) {
                    return true
               }
            }
        }

        if let parent = parentCoordinator as? HierarchyContainer {
            return parent.open(deeplink: deeplink, ignore: [self] + ignoredChildren)
        }

        return false
    }

    /**
     Convenience method for easier starting
    
     We should not use open(deeplink:, ignore:) with default value for ignoredChildren
     because it is easy to miss ignoredChildren in override.
     
     Method should be `public`, not `open` and should not be overriden by mistake!
     */
    @discardableResult
    public final func open(deeplink: DeepLinkType) -> Bool {
        return open(deeplink: deeplink, ignore: [])
    }

    /**
     Child should override this method to process some deep links by yourself, otherwise it will be processed by other coordinators.
     */
    open func didOpen(deeplink: DeepLinkType) -> Bool {
        return false
    }

    deinit {
        #if DEBUG
        if #available(iOS 12.0, *) {
            os_log(.debug, "✋🏽💣 %@ %@", #function, String(describing: self))
        }
        #endif
    }
}

public typealias FlowCoordinator<DeeplinkType> = HierarchyContainer<DeeplinkType> & StartableCoordinator

open class LaunchingContainer<DeepLinkType>: HierarchyContainer<DeepLinkType> {
    public let launcher: Launching

    public init(with launcher: Launching) {
        self.launcher = launcher
    }
}

public typealias LaunchingCoordinator<DeepLinkType> = LaunchingContainer<DeepLinkType> & StartableCoordinator

open class NavigatingContainer<DeeplinkType>: HierarchyContainer<DeeplinkType> {
    public let navigator: Navigating

    public init(with navigator: Navigating) {
        self.navigator = navigator
    }
}

public typealias NavigatingCoordinator<DeepLinkType> = NavigatingContainer<DeepLinkType> & StartableCoordinator
