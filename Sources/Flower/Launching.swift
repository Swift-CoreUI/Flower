import UIKit

public protocol Launching: RootControllable, Presenting {
    init(window: UIWindow)
}
