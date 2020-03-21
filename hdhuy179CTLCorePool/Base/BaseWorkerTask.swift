//
//  BaseWorkerTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/4/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation

/// BaseWorkerTask for DispatchQueue
class  BaseWorkerTask {
    let id : TaskID
    init(_id :TaskID) {
        self.id = _id
    }
    
    /// abstract func run
    func run(){
        print("call run at BaseWorkerTask")
        fatalError("implement thang run vao")
    }
}

/// BaseWokerOperationTask for OperationQueues
class BaseWokerOperationTask : Operation{
    let id : TaskID
    var taskProtocol : TaskProtocol?
    init(_id :TaskID) {
        self.id = _id
    }
    
    /// override func main
    override func main() {
        print("Operation call main at BaseWokerOperationTask")
    }
}
