import UIKit

// no actual need to have this as separate protocol: Launcher and Navigator could not be swapped 
public protocol RootControllable: AnyObject {
    var root: UIViewController? { get set }
    func setRoot(_ newRoot: UIViewController?, cleanupCompletion: (() -> Void)?)
}
