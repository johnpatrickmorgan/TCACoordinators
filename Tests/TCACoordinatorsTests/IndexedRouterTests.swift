import ComposableArchitecture
@testable import TCACoordinators
import XCTest

@MainActor
final class IndexedRouterTests: XCTestCase {
  func testActionPropagation() {
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: Parent.State(routes: [.root(.init(count: 42)), .sheet(.init(count: 11))]),
      reducer: Parent(scheduler: scheduler)
    )
    store.send(.routeAction(0, action: .increment)) {
      $0.routes[0].screen.count += 1
    }
    store.send(.routeAction(1, action: .increment)) {
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
      ),
      reducer: Parent(scheduler: scheduler)
    )
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

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .increment:
        state.count += 1
        return .none
      case .incrementLaterTapped:
        return .task {
          try await scheduler.sleep(for: .seconds(1))
          return .increment
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
  }
  let scheduler: TestSchedulerOf<DispatchQueue>

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer().forEachRoute {
      Child(scheduler: scheduler)
    }
  }
}
