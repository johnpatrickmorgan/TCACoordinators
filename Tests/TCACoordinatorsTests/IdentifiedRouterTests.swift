import ComposableArchitecture
@testable import TCACoordinators
import XCTest

@MainActor
final class IdentifiedRouterTests: XCTestCase {
  func testActionPropagation() async {
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: Parent.State(routes: [
        .root(.init(id: "first", count: 42)),
        .sheet(.init(id: "second", count: 11))
      ])
    ) {
      Parent(scheduler: scheduler)
    }

    await store.send(\.router[id: "first"].increment) {
      $0.routes[id: "first"]?.screen.count += 1
    }

    await store.send(\.router[id: "second"].increment) {
      $0.routes[id: "second"]?.screen.count += 1
    }
  }

  func testActionCancellation() async {
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: Parent.State(
        routes: [
          .root(.init(id: "first", count: 42)),
          .sheet(.init(id: "second", count: 11))
        ]
      )
    ) {
      Parent(scheduler: scheduler)
    }

    // Expect increment action after 1 second.
    await store.send(\.router[id: "second"].incrementLaterTapped)
    await scheduler.advance(by: .seconds(1))
    await store.receive(\.router[id: "second"].increment) {
      $0.routes[id: "second"]?.screen.count += 1
    }
    // Expect increment action to be cancelled if screen is removed.
    await store.send(\.router[id: "second"].incrementLaterTapped)
    await store.send(\.router.updateRoutes, [.root(.init(id: "first", count: 42))]) {
      $0.routes = [.root(.init(id: "first", count: 42))]
    }
  }

  @available(iOS 16.0, *)
  func testWithDelaysIfUnsupported() async throws {
    let initialRoutes: IdentifiedArrayOf<Route<Child.State>> = [
      .root(.init(id: "first", count: 1)),
      .sheet(.init(id: "second", count: 2)),
      .sheet(.init(id: "third", count: 3))
    ]
    let scheduler = DispatchQueue.test
    let store = TestStore(initialState: Parent.State(routes: initialRoutes)) {
      Parent(scheduler: scheduler)
    }
    let goBackToRoot = await store.send(.goBackToRoot)
    await store.receive(\.router.updateRoutes, initialRoutes.elements)
    let firstTwo = IdentifiedArrayOf(initialRoutes.prefix(2))
    await store.receive(\.router.updateRoutes, firstTwo.elements) {
      $0.routes = firstTwo
    }
    await scheduler.advance(by: .milliseconds(650))
    let firstOne = IdentifiedArrayOf(initialRoutes.prefix(1))
    await store.receive(\.router.updateRoutes, firstOne.elements) {
      $0.routes = firstOne
    }
    await goBackToRoot.finish()
  }
}

@Reducer
private struct Child: Reducer {
  let scheduler: TestSchedulerOf<DispatchQueue>
  struct State: Equatable, Identifiable {
    var id: String
    var count = 0
  }

  enum Action {
    case incrementLaterTapped
    case increment
  }

  var body: some ReducerOf<Self> {
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

@Reducer
private struct Parent: Reducer {
  let scheduler: TestSchedulerOf<DispatchQueue>
  struct State: Equatable {
    var routes: IdentifiedArrayOf<Route<Child.State>>
  }

  enum Action {
    case router(IdentifiedRouterAction<Child.State, Child.Action>)
    case goBackToRoot
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .goBackToRoot:
        return .routeWithDelaysIfUnsupported(state.routes, action: \.router, scheduler: scheduler.eraseToAnyScheduler()) {
          $0.goBackToRoot()
        }
      default:
        return .none
      }
    }
    .forEachRoute(\.routes, action: \.router) {
      Child(scheduler: scheduler)
    }
  }
}
