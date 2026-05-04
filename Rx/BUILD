load("@build_bazel_rules_apple//apple:apple.bzl", "apple_static_xcframework")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("@rules_cc//cc:objc_library.bzl", "objc_library")

package(default_visibility = ["//visibility:public"])

swift_library(
    name = "RxSwift",
    module_name = "RxSwift",
    srcs = glob(["RxSwift-6.10.2/RxSwift/**/*.swift"]),
)

apple_static_xcframework(
    name = "RxSwift.xcframework",
    bundle_name = "RxSwift",
    minimum_os_versions = {"ios": "13.0"},
    ios = {
        "simulator": ["x86_64", "arm64"],
        "device": ["arm64"],
    },
    deps = [":RxSwift"],
)

swift_library(
    name = "RxRelay",
    module_name = "RxRelay",
    srcs = glob(["RxSwift-6.10.2/RxRelay/*.swift"]),
    deps = [":RxSwift"],
)

apple_static_xcframework(
    name = "RxRelay.xcframework",
    bundle_name = "RxRelay",
    minimum_os_versions = {"ios": "13.0"},
    ios = {
        "simulator": ["x86_64", "arm64"],
        "device": ["arm64"],
    },
    avoid_deps = [":RxSwift"],
    deps = [":RxRelay"],
)

objc_library(
    name = "RxCocoaRuntime",
    module_name = "RxCocoaRuntime",
    srcs = glob(["RxSwift-6.10.2/RxCocoa/Runtime/*.m"]),
    hdrs = glob(["RxSwift-6.10.2/RxCocoa/Runtime/include/*.h"]),
    includes = ["RxSwift-6.10.2/RxCocoa/Runtime/include"],
    sdk_frameworks = ["Foundation"],
)

apple_static_xcframework(
    name = "RxCocoaRuntime.xcframework",
    bundle_name = "RxCocoaRuntime",
    minimum_os_versions = {"ios": "13.0"},
    ios = {
        "simulator": ["x86_64", "arm64"],
        "device": ["arm64"],
    },
    public_hdrs = glob(["RxSwift-6.10.2/RxCocoa/Runtime/include/*.h"]),
    deps = [":RxCocoaRuntime"],
)

swift_library(
    name = "RxCocoa",
    module_name = "RxCocoa",
    srcs = glob(
        ["RxSwift-6.10.2/RxCocoa/**/*.swift"],
        exclude = ["RxSwift-6.10.2/RxCocoa/macOS/**"],
    ),
    defines = ["SWIFT_PACKAGE"],
    deps = [
        ":RxCocoaRuntime",
        ":RxRelay",
        ":RxSwift",
    ],
)

apple_static_xcframework(
    name = "RxCocoa.xcframework",
    bundle_name = "RxCocoa",
    minimum_os_versions = {"ios": "13.0"},
    ios = {
        "simulator": ["x86_64", "arm64"],
        "device": ["arm64"],
    },
    avoid_deps = [
        ":RxCocoaRuntime",
        ":RxRelay",
        ":RxSwift",
    ],
    deps = [":RxCocoa"],
)
