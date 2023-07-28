import ComposableArchitecture
@testable import TCACoordinators
import XCTest

@MainActor
final class IndexedRouterTests: XCTestCase {
	func testActionPropagation() async {
		let scheduler = DispatchQueue.test
		let store = TestStore(
			initialState: Parent.State(
				routes: [
					.root(.init(count: 42)),
					.sheet(.init(count: 11))
				]
			)
		) {
			Parent(scheduler: scheduler)
		}
    await store.send(.routeAction(0, action: .increment)) {
      $0.routes[0].screen.count += 1
    }
    await store.send(.routeAction(1, action: .increment)) {
      $0.routes[1].screen.count += 1
    }
  }

  func testActionCancellation() async {
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: Parent.State(
        routes: [
          .root(.init(count: 42)),
          .sheet(.init(count: 11))
        ]
      )
		) {
			Parent(scheduler: scheduler)
		}
    // Expect increment action after 1 second.
    await store.send(.routeAction(1, action: .incrementLaterTapped))
    await scheduler.advance(by: .seconds(1))
    await store.receive(.routeAction(1, action: .increment)) {
      $0.routes[1].screen.count += 1
    }
    // Expect increment action to be cancelled if screen is removed.
    await store.send(.routeAction(1, action: .incrementLaterTapped))
    await store.send(.updateRoutes([.root(.init(count: 42))])) {
      $0.routes = [.root(.init(count: 42))]
    }
  }
  
  @available(iOS 16.0, *)
  func testWithDelaysIfUnsupported() async throws {
    let initialRoutes: [Route<Child.State>] = [
      .root(.init(count: 1)),
      .sheet(.init(count: 2)),
      .sheet(.init(count: 3))
    ]
    let scheduler = DispatchQueue.test
		let store = TestStore(initialState: Parent.State(routes: initialRoutes)) {
			Parent(scheduler: scheduler)
		}
    let goBackToRoot = await store.send(.goBackToRoot)
    await store.receive(.updateRoutes(initialRoutes))
    let firstTwo = Array(initialRoutes.prefix(2))
    await store.receive(.updateRoutes(firstTwo)) {
      $0.routes = firstTwo
    }
    await scheduler.advance(by: .milliseconds(650))
    let firstOne = Array(initialRoutes.prefix(1))
    await store.receive(.updateRoutes(firstOne)) {
      $0.routes = firstOne
    }
		await goBackToRoot.cancel()
  }
}

private struct Child: ReducerProtocol {
  let scheduler: TestSchedulerOf<DispatchQueue>
  struct State: Equatable {
    var count = 0
  }

  enum Action: Equatable {
    case incrementLaterTapped
    case increment
  }

  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .increment:
        state.count += 1
        return .none
      case .incrementLaterTapped:
        return .run { send in
          try await scheduler.sleep(for: .seconds(1))
          await send(.increment)
        }
      }
    }
  }
}

private struct Parent: ReducerProtocol {
  struct State: Equatable, IndexedRouterState {
    var routes: [Route<Child.State>]
  }

  enum Action: IndexedRouterAction, Equatable {
    case routeAction(Int, action: Child.Action)
    case updateRoutes([Route<Child.State>])
    case goBackToRoot
  }
  let scheduler: TestSchedulerOf<DispatchQueue>

  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .goBackToRoot:
        return .routeWithDelaysIfUnsupported(state.routes, scheduler: scheduler.eraseToAnyScheduler()) {
          $0.goBackToRoot()
        }
      default:
        return .none
      }
    }.forEachRoute {
      Child(scheduler: scheduler)
    }
  }
}
