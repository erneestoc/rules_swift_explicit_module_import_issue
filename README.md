# RxCocoa static-xcframework link error repro

Reproduces the `Undefined symbols` link error you get when consuming a Carthage-style
RxCocoa.xcframework (`BUILD_LIBRARY_FOR_DISTRIBUTION=YES` + `MACH_O_TYPE=staticlib`)
from a Bazel-built consumer that uses **explicit Swift modules**.

## Repro

1. Build the xcframeworks with the same flags Carthage + the instacart-ios wrapper use:

   ```sh
   ./Scripts/build-rx-xcframeworks.sh
   ```

   Outputs `xcframeworks-source/{RxSwift,RxRelay,RxCocoa}.xcframework`. Sanity check at
   the end prints `current ar archive` for the framework binary, confirming the
   `staticlib` mach-o type.

2. Try to link a consumer that calls the generic `DelegateProxy.init(parentObject:delegateProxy:)`:

   ```sh
   bazel build //:ReproProxy
   ```

   Expected failure:

   ```
   Undefined symbols for architecture arm64:
     "method descriptor for RxCocoa.DelegateProxy.__allocating_init<A where ...>"
     "RxCocoa.DelegateProxy.init<A where ...>(parentObject: A, delegateProxy: A1.Type)"
       referenced from: MinimalDelegateProxy.init(parent:) in libProxy.library.a
   ```

`Proxy.swift` is the minimal subclass; the missing symbols are the resilient
generic init the subclass calls in `super.init`.

## Theory

The bug only manifests under explicit modules. The trigger is the combination of
two build settings on the library side:

- **`BUILD_LIBRARY_FOR_DISTRIBUTION = YES`** — RxCocoa is built with library
  evolution. Generic, non-`@inlinable` public methods like
  `DelegateProxy.init<P>(parentObject:delegateProxy:)` get **resilient ABI**
  symbols (`...Tq` method descriptors plus the init function itself) that are
  meant to live in the library binary so consumers can dispatch through the
  resilient-ABI path.

- **`MACH_O_TYPE = staticlib`** — the framework binary is actually a `.a`. The
  resilient-ABI symbols Swift would normally synthesize for the generic-dispatch
  path are absent (or unreachable to the linker under static-archive linkage).
  The static archive does not contain the descriptor/init symbol the resilient
  call site needs.

What changes with the consumer's module mode:

- **Explicit modules** (Bazel's default in modern rules_swift; Xcode 15+):
  the consumer reads the pre-built `RxCocoa.swiftmodule` as a frozen artifact
  and emits an external `_$s7RxCocoa13DelegateProxyC...Tq` reference. No `.a`
  has it → undefined symbol.

- **Implicit modules**: the consumer hits `import RxCocoa`, finds no pre-built
  `.swiftmodule`, finds the `.swiftinterface`, and re-invokes `swiftc` to
  compile it into the per-consumer module cache *during the consumer's compile
  job*. That recompile re-emits any local helpers/thunks the consumer's
  specialization needs, satisfying the descriptor reference locally — even
  though the static archive itself is exactly the same binary.

That is why this bug only surfaces after turning on explicit modules: the
implicit-rebuild step that papered over the missing symbol is gone.

## Fixes to try

Drop either flag in `Scripts/build-rx-xcframeworks.sh` and rerun:

- Drop `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` — keeps the binary static, drops
  library evolution. Generic bodies get emitted into the static archive
  normally, link succeeds.
- Drop `MACH_O_TYPE = staticlib` — gives a normal dynamic xcframework that
  links fine.

The only path that keeps both flags *and* links is to consume RxCocoa from
source as a `swift_library` (no pre-built xcframework), or to use
`apple_dynamic_xcframework_import` against a dylib build.
