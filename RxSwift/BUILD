load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@rules_cc//cc:objc_library.bzl", "objc_library")

package(default_visibility = ["//visibility:public"])

# RxSwift ships:
#   RxSwift          (Swift)
#   RxRelay          (Swift)            -> RxSwift
#   RxBlocking       (Swift)            -> RxSwift
#   RxCocoaRuntime   (Objective-C)      imported as `import RxCocoaRuntime`
#   RxCocoa          (Swift)            -> RxSwift, RxRelay, RxCocoaRuntime
#   RxTest           (Swift)            -> RxSwift, RxBlocking

swift_library(
    name = "RxSwift",
    module_name = "RxSwift",
    srcs = glob(["RxSwift/**/*.swift"]),
    deps = [
        "@system_sdk//:CoreFoundation",
        "@system_sdk//:Darwin",
        "@system_sdk//:Dispatch",
        "@system_sdk//:Foundation",
        "@system_sdk//:ObjectiveC",
        "@system_sdk//:Swift",
        "@system_sdk//:os"
    ]
)

swift_library(
    name = "RxRelay",
    module_name = "RxRelay",
    srcs = glob(["RxRelay/**/*.swift"]),
    deps = [
        ":RxSwift",
        "@system_sdk//:Foundation",
        "@system_sdk//:Swift"
    ],
)

swift_library(
    name = "RxBlocking",
    module_name = "RxBlocking",
    srcs = glob(["RxBlocking/**/*.swift"]),
    deps = [":RxSwift"],
)

objc_library(
    name = "RxCocoaRuntime",
    module_name = "RxCocoaRuntime",
    srcs = glob(["RxCocoa/Runtime/*.m"]),
    hdrs = glob(["RxCocoa/Runtime/include/*.h"]),
    includes = ["RxCocoa/Runtime/include"],
    sdk_frameworks = ["Foundation"],
)

swift_library(
    name = "RxCocoa",
    module_name = "RxCocoa",
    srcs = glob(
        ["RxCocoa/**/*.swift"],
        exclude = ["RxCocoa/macOS/**"],
    ),
    defines = ["SWIFT_PACKAGE"],
    deps = [
        ":RxCocoaRuntime",
        ":RxRelay",
        ":RxSwift",
        "@system_sdk//:CoreFoundation",
        "@system_sdk//:CoreGraphics",
        "@system_sdk//:Dispatch",
        "@system_sdk//:Foundation",
        "@system_sdk//:NotificationCenter",
        "@system_sdk//:ObjectiveC",
        "@system_sdk//:Swift",
        "@system_sdk//:UIKit",
        "@system_sdk//:WebKit"
    ],
)

swift_library(
    name = "RxTest",
    module_name = "RxTest",
    srcs = glob(["RxTest/**/*.swift"]),
    deps = [
        ":RxBlocking",
        ":RxSwift",
    ],
)
