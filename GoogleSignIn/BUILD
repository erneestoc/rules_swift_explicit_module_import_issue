load("@build_bazel_rules_apple//apple:apple.bzl", "apple_static_xcframework_import")

apple_static_xcframework_import(
    name = "GTMAppAuth",
    deps = [
        ":GTMSessionFetcher",
        ":AppAuth"
    ],
    has_swift = True,
    xcframework_imports = glob(["GoogleSignIn/GTMAppAuth.xcframework/**"], exclude = ["**/*.abi.json", "**/*.dSYM/**/*.swiftinterface", "**/*/.DS_Store"]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "AppAuth",
    deps = [],
    has_swift = True,
    xcframework_imports = glob(["GoogleSignIn/AppAuth.xcframework/**"], exclude = ["**/*.abi.json", "**/*.dSYM/**/*.swiftinterface", "**/*/.DS_Store"]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "GTMSessionFetcher",
    deps = [],
    has_swift = True,
    xcframework_imports = glob(["GoogleSignIn/GTMSessionFetcher.xcframework/**"], exclude = ["**/*.abi.json", "**/*.dSYM/**/*.swiftinterface", "**/*/.DS_Store"]),
    visibility = ["//visibility:public"]
)
