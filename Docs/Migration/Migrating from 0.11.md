#  Migrating from 0.11

Version 0.12 of this library introduced an API change to allow it to work with the latest version of the Composable Architecture (>=0.19). This change improves the way the routes store is scoped into individual screen stores. This change introduced a new requirement: that the screen reducer's state conform to `Hashable`. This allows for more efficient scoping using key paths.

**TL;DR: the screen reducer's' state must now conform to `Hashable`.**
