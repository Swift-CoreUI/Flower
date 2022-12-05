import XCTest
@testable import Flower

final class CoordinatorTests: XCTestCase {
    static var wasOpenedByCoordinator: TestCoordinator?
    static var openCounter: Int = 0
    static var openPath: [TestCoordinator] = []

    enum DeepLink {
        case c0111
        case c011111
        case c02221
        case unsupportedDeepLink
    }

    class TestCoordinator: FlowCoordinator<DeepLink> {
        func start() {

        }

        typealias CoordinatorOutputType = Void

        static func == (lhs: CoordinatorTests.TestCoordinator, rhs: CoordinatorTests.TestCoordinator) -> Bool {
            lhs === rhs // just comparing refs
        }

        func start(afterFinish: ((CoordinatorOutputType) -> Void)? = nil) {
            print("🚀🚀🚀 starting \(self)")
        }

        override func didOpen(deeplink: DeepLink) -> Bool {
            openCounter += 1
            openPath.append(self)
            //print("🥁🥁🥁 \(self) is trying to open deeplink: \(deeplink)")

            return false
        }

        func printDeepLink(_ deeplink: DeepLink) {
            print("🔗🔗🔗 \(self) got deeplink \(deeplink)")
        }
    }

    // swiftlint:disable:next type_name
    class C0: TestCoordinator {}

    class C01: TestCoordinator {}
    class C02: TestCoordinator {}

    class C011: TestCoordinator {}
    class C012: TestCoordinator {}
    class C021: TestCoordinator {}
    class C022: TestCoordinator {}

    class C0112: TestCoordinator {}
    class C0221: TestCoordinator {}
    class C0222: TestCoordinator {}

    class C01111: TestCoordinator {}
    class C01112: TestCoordinator {}

    class C0111: TestCoordinator {
        override func didOpen(deeplink: DeepLink) -> Bool {
            _ = super.didOpen(deeplink: deeplink)
            guard deeplink == .c0111 else { return false }
            wasOpenedByCoordinator = self
            return true
        }
    }

    class C011111: TestCoordinator {
        override func didOpen(deeplink: DeepLink) -> Bool {
            _ = super.didOpen(deeplink: deeplink)
            guard deeplink == .c011111 else { return false }
            wasOpenedByCoordinator = self
            return true
        }
    }

    class C02221: TestCoordinator {
        override func didOpen(deeplink: DeepLink) -> Bool {
            _ = super.didOpen(deeplink: deeplink)
            guard deeplink == .c02221 else { return false }
            wasOpenedByCoordinator = self
            return true
        }
    }

    let c0 = C0()
    let c01 = C01()
    let c02 = C02()
    let c011 = C011()
    let c012 = C012()
    let c021 = C021()
    let c022 = C022()
    let c0111 = C0111()
    let c0112 = C0112()
    let c01111 = C01111()
    let c01112 = C01112()
    let c011111 = C011111()
    let c0221 = C0221()
    let c0222 = C0222()
    let c02221 = C02221()

    /**
     
     ```
     |                            ___ c0 ___
     |                           /          \
     |                         c01          c02
     |                        /   \       /     \
     |                      c011  c012  c021    c022
     |                     /    \              /    \
     |                 c0111    c0112      c0221     c0222
     |                /     \                        /
     |           c01111     c01112              c02221
     |          /
     |    c011111
     ```
     */

    private func buildTree() {
        c0.add(child: c01)
        c0.add(child: c02)
        c01.add(child: c011)
        c01.add(child: c012)
        c02.add(child: c021)
        c02.add(child: c022)
        c022.add(child: c0221)
        c022.add(child: c0222)
        c0222.add(child: c02221)
        c011.add(child: c0111)
        c011.add(child: c0112)
        c0111.add(child: c01111)
        c0111.add(child: c01112)
        c01111.add(child: c011111)
    }

    private func resetTree() {
        c0.remove(child: c01)
        c0.remove(child: c02)
    }

    override func setUp() {
        Self.wasOpenedByCoordinator = nil
        Self.openCounter = 0
        Self.openPath = []

        buildTree()
    }

    override func tearDown() {
        resetTree()
    }

    func testOpenFromRoot() {
        XCTAssert(c0.open(deeplink: .c02221))
        XCTAssert(Self.wasOpenedByCoordinator === c02221)
        XCTAssertEqual(Self.openCounter, 25)

        // better to test Self.openPath.contains(c01), Self.openPath.contains(c0111) etc
        // but we don't need to test exact traversal order and array compare is is just shorter
        // plus we also testing that we didn't visited nodes which were not on the way
        XCTAssertEqual(Self.openPath, [c0, c01, c011, c0111, c01111, c011111, c01111, c0111, c01112, c0111, c011, c0112,
                                       c011, c01, c012, c01, c0, c02, c021, c02, c022, c0221, c022, c0222, c02221])
    }

    func testOpenFar() {
        XCTAssert(c0112.open(deeplink: .c02221))
        XCTAssert(Self.wasOpenedByCoordinator === c02221)
        XCTAssertEqual(Self.openCounter, 22)
        XCTAssertEqual(Self.openPath, [c0112, c011, c0111, c01111, c011111, c01111, c0111, c01112, c0111, c011, c01, c012,
                                       c01, c0, c02, c021, c02, c022, c0221, c022, c0222, c02221])
    }

    func testOpenNear() {
        XCTAssert(c0112.open(deeplink: .c0111))
        XCTAssert(Self.wasOpenedByCoordinator === c0111)
        XCTAssertEqual(Self.openCounter, 3)
        XCTAssertEqual(Self.openPath, [c0112, c011, c0111])
        XCTAssertFalse(Self.openPath.contains(c011111)) // e.g. we stopped right after target was found
        XCTAssertFalse(Self.openPath.contains(c01))
        XCTAssertFalse(Self.openPath.contains(c02))
    }

}

fileprivate extension String {

}
