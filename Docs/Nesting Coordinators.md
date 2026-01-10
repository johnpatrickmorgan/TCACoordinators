# Nesting Coordinators

Sometimes, it can be useful to break your app's screen flows into several distinct flows of related screens. `TCACooordinators` supports nesting coordinators, though there are some limitations to keep in mind. 'Coordinator' here is used to describe a view that contains a `TCARouter` to manage a flow of screens. Coordinators are just SwiftUI views, so they can be shown in all the normal ways views can. They can even be appended to a parent coordinator's `FlowStack`, allowing you to break out parts of your flow into distinct child coordinators.

### Limitation 1: Avoid branching navigation paths 

It is best that the child coordinator is only ever the last element of the parent's routes array, as it will take over responsibility for showing new screens until dismissed. Otherwise, the parent might attempt to present screen(s) when the child is already presenting its own, causing a conflict.

### Limitation 2: Child coordinators should be presented, not pushed.

Because a `NavigationStack` manages its entire navigation path in a single piece of state, it is not currently possible to _push_ a child coordinator (with its own routes) onto a parent coordinator's routes. Child coordinators should only be presented, either as a sheet or a full-screen cover. It may be possible to overcome this limitation in future versions of the library.
