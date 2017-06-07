//
//  ConcurrentOperation.swift
//
//  Created by Robert Ryan on 9/20/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//

import Foundation

/// Concurrent Operation base class
///
/// This class performs all of the necessary KVN of `isFinished` and
/// `isExecuting` for a concurrent `NSOperation` subclass. So, to developer
/// a concurrent NSOperation subclass, you instead subclass this class which:
///
/// - must override `main()` with the tasks that initiate the asynchronous task;
///
/// - must call `completeOperation()` function when the asynchronous task is done;
///
/// - optionally, periodically check `self.cancelled` status, performing any clean-up
///   necessary and then ensuring that `completeOperation()` is called; or
///   override `cancel` method, calling `super.cancel()` and then cleaning-up
///   and ensuring `completeOperation()` is called.

class ConcurrentOperation : Operation {
    
    override var isAsynchronous: Bool {
        return true
    }
    
    fileprivate var _executing: Bool = false
    override var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            if (_executing != newValue) {
                self.willChangeValue(forKey: "isExecuting")
                _executing = newValue
                self.didChangeValue(forKey: "isExecuting")
            }
        }
    }
    
    fileprivate var _finished: Bool = false;
    override var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if (_finished != newValue) {
                self.willChangeValue(forKey: "isFinished")
                _finished = newValue
                self.didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    /// Complete the operation
    ///
    /// This will result in the appropriate KVN of isFinished and isExecuting
    
    func completeOperation() {
        isExecuting = false
        isFinished  = true
    }
    
    override func start() {
        if (isCancelled) {
            isFinished = true
            return
        }
        
        isExecuting = true
        
        main()
    }


}

class PendingOperations: NSObject {

//    lazy var uploadsInProgress = [Int:NSOperation]()
    lazy var opQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Upload queue"
        queue.maxConcurrentOperationCount = 5
        return queue
    }()
    
}
