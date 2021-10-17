import Dispatch

func asyncForEach<T>(in arr: [T], callbackQueue: DispatchQueue = .main, finish: (() -> Void)? = nil, processOne: @escaping (T, @escaping () -> Void) -> Void) {
    var i = 0
    func callback() {
        if i < arr.count {
            processOne(arr[i]) {
                i += 1
                callbackQueue.async(execute: callback)
            }
        }
        else if let finish = finish {
            callbackQueue.async(execute: finish)
        }
    }
    callback()
}

/** Keep retrying `action` until the specified time with the given interval, or until it succeds – whichever is earlier **/
func asyncRetry(every interval: DispatchTimeInterval, until deadline: DispatchTime, onQueue queue: DispatchQueue = .main, tryPerformAction action: @escaping () -> Bool) {
    func callback() {
        let proposedTime: DispatchTime = .now() + interval
        if proposedTime < deadline {
            queue.asyncAfter(deadline: proposedTime) {
                if !action() {
                    callback()
                }
            }
        }
    }
    callback()
}
