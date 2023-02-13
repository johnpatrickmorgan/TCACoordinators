import Combine
import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI
import CombineSchedulers

public extension EffectPublisher where Action: IndexedRouterAction, Failure == Never {
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
  static func routeWithDelaysIfUnsupported(_ routes: [Route<Output.Screen>], scheduler: AnySchedulerOf<DispatchQueue>, _ transform: (inout [Route<Output.Screen>]) -> Void) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: routes, to: transformedRoutes)
    return scheduledSteps(steps: steps, scheduler: scheduler)
      .map { Output.updateRoutes($0) }
      .eraseToEffect()
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
  static func routeWithDelaysIfUnsupported(_ routes: [Route<Output.Screen>], _ transform: (inout [Route<Output.Screen>]) -> Void) -> Self {
    routeWithDelaysIfUnsupported(routes, scheduler: DispatchQueue.main.eraseToAnyScheduler(), transform)
  }
}

public extension EffectPublisher where Action: IdentifiedRouterAction, Failure == Never {
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
  static func routeWithDelaysIfUnsupported(_ routes: IdentifiedArrayOf<Route<Output.Screen>>, scheduler: AnySchedulerOf<DispatchQueue>, _ transform: (inout IdentifiedArrayOf<Route<Output.Screen>>) -> Void) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: Array(routes), to: Array(transformedRoutes))
    return scheduledSteps(steps: steps, scheduler: scheduler)
      .map { Output.updateRoutes(IdentifiedArray(uncheckedUniqueElements: $0)) }
      .eraseToEffect()
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
  static func routeWithDelaysIfUnsupported(_ routes: IdentifiedArrayOf<Route<Output.Screen>>, _ transform: (inout IdentifiedArrayOf<Route<Output.Screen>>) -> Void) -> Self {
    return routeWithDelaysIfUnsupported(routes, scheduler: DispatchQueue.main.eraseToAnyScheduler(), transform)
  }
}

/// Transforms a series of steps into an AnyPublisher of those steps, each one delayed in time.
func scheduledSteps<Screen>(steps: [[Route<Screen>]], scheduler: AnySchedulerOf<DispatchQueue>) -> AnyPublisher<[Route<Screen>], Never> {
  guard let head = steps.first else {
    return Empty().eraseToAnyPublisher()
  }
  let timer = Just(scheduler.now)
    .append(Publishers.Timer(every: 0.65, scheduler: scheduler).autoconnect())
  let tail = Publishers.Zip(steps.dropFirst().publisher, timer)
    .map { $0.0 }
  return Just(head)
    .append(tail)
    .eraseToAnyPublisher()
}
