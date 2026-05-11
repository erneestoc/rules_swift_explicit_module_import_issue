import Foundation
import MixedFoundationRuntime

public func exerciseMixed() {
    let _: Date = NSDate() as Date
    let _: NSNull = NSNull()
    let _: NSNumber = NSNumber(value: 1)
    let _: TimeInterval = 1.0
    let _: URLRequest = URLRequest(url: URL(string: "x:")!)
    let paths: [IndexPath] = []
    let _: NSArray = paths as NSArray
    let _: String = MixedFoundationRuntime.hello() as String
}
