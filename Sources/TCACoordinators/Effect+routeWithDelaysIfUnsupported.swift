import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI
import CombineSchedulers

public extension Effect where Action: IndexedRouterAction {
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter scheduler: The scheduler for scheduling delays. E.g. a test scheduler can be used in tests.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
  static func routeWithDelaysIfUnsupported(_ routes: [Route<Action.Screen>], scheduler: AnySchedulerOf<DispatchQueue>, _ transform: (inout [Route<Action.Screen>]) -> Void) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: routes, to: transformedRoutes)
    return .run { send in
      for await step in scheduledSteps(steps: steps, scheduler: scheduler) {
        await send(.updateRoutes(step))
      }
    }
  }
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
  static func routeWithDelaysIfUnsupported(_ routes: [Route<Action.Screen>], _ transform: (inout [Route<Action.Screen>]) -> Void) -> Self {
    routeWithDelaysIfUnsupported(routes, scheduler: .main, transform)
  }
}

public extension Effect where Action: IdentifiedRouterAction {
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter scheduler: The scheduler for scheduling delays. E.g. a test scheduler can be used in tests.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
  static func routeWithDelaysIfUnsupported(_ routes: IdentifiedArrayOf<Route<Action.Screen>>, scheduler: AnySchedulerOf<DispatchQueue>, _ transform: (inout IdentifiedArrayOf<Route<Action.Screen>>) -> Void) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: Array(routes), to: Array(transformedRoutes))

    return .run { send in
      for await step in scheduledSteps(steps: steps, scheduler: scheduler) {
        await send(.updateRoutes(IdentifiedArray(uncheckedUniqueElements: step)))
      }
    }
  }
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
  static func routeWithDelaysIfUnsupported(_ routes: IdentifiedArrayOf<Route<Action.Screen>>, _ transform: (inout IdentifiedArrayOf<Route<Action.Screen>>) -> Void) -> Self {
    routeWithDelaysIfUnsupported(routes, scheduler: .main, transform)
  }
}

func scheduledSteps<Screen>(steps: [[Route<Screen>]], scheduler: AnySchedulerOf<DispatchQueue>) -> AsyncStream<[Route<Screen>]> {
  guard let first = steps.first else { return .finished }
  let second = steps.dropFirst().first
  let remainder = steps.dropFirst(2)

  return AsyncStream { continuation in
    Task {
      do {
        continuation.yield(first)
        if let second {
          continuation.yield(second)
        }

        for step in remainder {
          try await scheduler.sleep(for: .milliseconds(650))
          continuation.yield(step)
        }

        continuation.finish()
      } catch {
        continuation.finish()
      }
    }
  }
}
