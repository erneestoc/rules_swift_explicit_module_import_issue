Claude's theory:

### Symptom

Bazel build (with explicit modules under Xcode 26.4 / Swift 6.3) fails compiling
`GTMAppAuth.swiftinterface`:

```
'GTMSessionFetcherAuthorizer' is not a member type of class
'GTMSessionFetcher.GTMSessionFetcher'
```

with a note pointing at `@interface GTMSessionFetcher` in
`GTMSessionFetcher.framework/Headers/GTMSessionFetcher.h`.

### Root cause

`GTMSessionFetcher` is *both* a Swift module name and a class name inside that
module. The pre-built `GTMAppAuth.swiftinterface` (emitted by Swift 6.0.3 in
upstream Carthage builds) references protocols as fully qualified
`GTMSessionFetcher.GTMSessionFetcherAuthorizer` and
`GTMSessionFetcher.GTMSessionFetcherServiceProtocol`.

Under Swift 6.0 the qualified-name resolver picked the *module* first
(top-level type lookup → protocol found → fine). Under Swift 6.3 it picks the
*class* first (nested-type lookup → not found → error).

There is no precompiled `.swiftmodule` binary fallback in the GTMAppAuth XCF —
only `.swiftinterface` / `.private.swiftinterface` text — so swiftc must
re-parse the textual interface, and re-parse fails.

Headers and modulemap on `GTMSessionFetcher` are correct; the protocols *are*
exported. The bug is purely the dotted-name resolver hitting the
module-vs-class collision.
