import ComposableArchitecture
@testable import TCACoordinators
import XCTest

@MainActor
final class IdentifiedRouterTests: XCTestCase {
  func testActionPropagation() {
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: Parent.State(routes: [.root(.init(id: "first", count: 42)), .sheet(.init(id: "second", count: 11))]),
      reducer: Parent(scheduler: scheduler)
    )
    store.send(.routeAction("first", action: .increment)) {
      $0.routes[id: "first"]?.screen.count += 1
    }
    store.send(.routeAction("second", action: .increment)) {
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
      ),
      reducer: Parent(scheduler: scheduler)
    )
    // Expect increment action after 1 second.
    await store.send(.routeAction("second", action: .incrementLaterTapped))
    await scheduler.advance(by: .seconds(1))
    await store.receive(.routeAction("second", action: .increment)) {
      $0.routes[id: "second"]?.screen.count += 1
    }
    // Expect increment action to be cancelled if screen is removed.
    await store.send(.routeAction("second", action: .incrementLaterTapped))
    await store.send(.updateRoutes([.root(.init(id: "first", count: 42))])) {
      $0.routes = [.root(.init(id: "first", count: 42))]
    }
  }
}

private struct Child: ReducerProtocol {
  let scheduler: TestSchedulerOf<DispatchQueue>
  struct State: Equatable, Identifiable {
    var id: String
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
  let scheduler: TestSchedulerOf<DispatchQueue>
  struct CancellationID {}
  struct State: Equatable, IdentifiedRouterState {
    var routes: IdentifiedArrayOf<Route<Child.State>>
  }

  enum Action: IdentifiedRouterAction, Equatable {
    case routeAction(Child.State.ID, action: Child.Action)
    case updateRoutes(IdentifiedArrayOf<Route<Child.State>>)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { _, _ in
      .none
    }
    .forEachIdentifiedRoute(coordinatorIdType: CancellationID.self) {
      Child(scheduler: scheduler)
    }
  }
}
