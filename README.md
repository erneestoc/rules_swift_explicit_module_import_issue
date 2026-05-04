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

## Root cause

This is a **Swift symbol-mangling divergence** between the library and any
consumer that compiles against the library's `.swiftinterface` (i.e. the
distributable form library evolution produces). It is not specifically a
static-archive or Bazel issue — it reproduces with vanilla `swiftc` against
the same xcframeworks.

The trigger is in `RxCocoa/Common/DelegateProxy.swift`:

```swift
public init<Proxy: DelegateProxyType>(parentObject: ParentObject, delegateProxy: Proxy.Type)
    where Proxy: DelegateProxy<ParentObject, Delegate>,
          Proxy.ParentObject == ParentObject,    // (*)
          Proxy.Delegate == Delegate              // (*)
```

The two `==` requirements marked `(*)` are *technically* redundant — `Proxy:
DelegateProxy<ParentObject, Delegate>` plus the typealiases `ParentObject = P`
and `Delegate = D` declared on the class already imply them. But Swift's
type-checker does not propagate same-type information across the typealias /
subclass-conformance chain when checking the body, so removing them produces a
real type error (`cannot assign value of type '(Proxy.ParentObject) -> AnyObject?'
to type '(P) -> AnyObject?'`).

The two compilation paths disagree on whether to mangle them in:

- **Library compile** (RxCocoa's own source build, with library evolution):
  emits `_$s7RxCocoa13DelegateProxyC...mtc06ParentF0Qyd__Rsz0C0Qyd__Rs_AFRbd__AA0cD4TypeRd__lufC`
  — the `06ParentF0Qyd__Rsz0C0Qyd__Rs_` chunk is the two redundant `==`
  requirements.

- **Consumer compile from `.swiftinterface`** (any caller of the prebuilt
  framework): the requirement-minimizer drops the `==` requirements and emits
  the shorter `_$s7RxCocoa13DelegateProxyC...mtcAFRbd__AA0cD4TypeRd__lufCTq`.

The library defines one symbol; the consumer references the other. The link
fails with "undefined symbol".

## Why implicit modules masks it

- **Explicit modules** (Bazel's default; Xcode 15+): the consumer reads the
  pre-built `RxCocoa.swiftmodule` / `.swiftinterface`, mangles the call site
  with the requirement-minimized signature, and emits an external reference.
  No archive has that symbol → undefined.

- **Implicit modules**: on `import RxCocoa`, `swiftc` recompiles the
  `.swiftinterface` into the per-consumer module cache *as part of the
  consumer's compile job*. That recompile happens in the same process as the
  consumer's body-typecheck, so the call site dispatches to the locally
  re-emitted body rather than to the prebuilt symbol. The mangling mismatch
  never reaches the linker.

That is why this bug only surfaces after turning on explicit modules: the
implicit-rebuild step that papered over the missing symbol is gone.

## What does *not* fix it

Verified empirically against this repro:

- `-Xfrontend -experimental-allow-non-resilient-access` on the **library**
  side — library still emits the long-mangled symbol; consumer still references
  the short one.
- `-Xfrontend -experimental-allow-non-resilient-access` on the **consumer**
  side — same.
- `SWIFT_OPTIMIZATION_LEVEL = -Onone` on the library side — same. It's not
  optimization stripping anything; the symbols are present, just under a
  different name.
- Dropping `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` — `xcodebuild
  -create-xcframework` refuses to package a Swift framework without a
  `.swiftinterface`, so this path can't produce a usable xcframework at all.

## What does fix it

- Consume RxCocoa **from source** (`swift_library` against the RxCocoa sources,
  no pre-built xcframework). The consumer compiles the same translation unit
  that defines the init, so both sides agree on the mangling.
- Switch the consumer to **implicit modules** (works around the mismatch as
  described above; not always possible — Bazel's modern rules_swift defaults
  to explicit).
- Patch RxCocoa to remove the redundancy at the source level, e.g. by changing
  the init body so the two `==` requirements aren't needed (the obvious
  one-line removal breaks the body's type-check; a real fix needs a refactor
  of `_currentDelegateFor` / `_setCurrentDelegateTo` to take `Proxy.ParentObject`
  rather than `P`, or to bridge through an `as!` cast).
- File / wait on a Swift compiler fix that keeps the requirement-minimizer in
  agreement with the body-typecheck mangling, or that emits the symbol under
  both manglings.
