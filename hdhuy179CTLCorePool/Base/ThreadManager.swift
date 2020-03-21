//
//  ThreadManager.swift
//  PegaXPool
//
//  Created by thailinh on 1/4/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class ThreadManager {
    
    /// shareInstance Singelton of ThreadManager
    static let shareInstance =  ThreadManager()
    /// list Tasks run for DispatchQueue
    var tasks = [BaseWorkerTask]()
    /// queues use for OperationQueue
    var queues : OperationQueue = {
        var queue = OperationQueue()
        queue.name = PoolConstants.BackgroundConfig.nameOfQueues
        queue.maxConcurrentOperationCount = PoolConstants.BackgroundConfig.maxConcurrentOperationCount
        return queue
    }()
    private var penddingTasks : [BaseWokerOperationTask] = [BaseWokerOperationTask]()
    private var runningTasks : [TaskID] = [TaskID]()
    private var runningTaskCount = 0
    private var maximumThread = PoolConstants.BackgroundConfig.maxConcurrentOperationCount
    var callBack : TaskProtocol?
    var isRunTaskOperation = false
    /// AddTask in tasks for run
    ///
    /// - Parameter task: extend BaseWorkerTask
    func addTask( task : BaseWorkerTask){
        tasks.append(task)
        runTask()
    }
    
    /// RunTask by DispatchQueue
    func runTask() {
        let queue = DispatchQueue(
            label: "com.CanThaiLinh.runTaskDisPatch",
            attributes: .concurrent)
        for worker in self.tasks {
            queue.async {
                worker.run()
            }
        }
    }
    
    /// add task to queues for run
    ///
    /// - Parameter task:  extend BaseWokerOperationTask
    func addTaskOperation( task : BaseWokerOperationTask){
        if PoolConstants.Debug.usingThreadManager{
            if callBack?.checkIsLogin() ?? false{
                self.addTaskOperationForQueues(task: task)
            }
        }else{
            queues.addOperation(task)
        }
    }
    
    // check xem co trong pending chua. chua thi add
    func addTaskOperationForQueues( task : BaseWokerOperationTask){
        var isNeedAdd = true
        // kiem tra co task trong Running chua. co roi thi deo cho chay nua
        if runningTasks.contains(task.id){
            isNeedAdd = false
        }
        // neu task chua run thi check trong pending xem da co chua. co roi thi thoi vi cho vao thi cha de lam cai lon gi ca
        if isNeedAdd && penddingTasks.count > 0{
            switch task.id{
            case .Get_Data,
                 .Upload_Task,
                 .Upload_Add_Task,
                 .Ranking,
                 .Remote_Long_Term,
                 .Action_Add,
                 .Local_Cache_Update,
                 .Remote_Short_Term,
                 .Delete_Task,
                 .Action_Remote_Task,
                 .Hidden_Delete_Task,
                 .Local_Insert_Rank :
                
                print("")
                for itemTask in penddingTasks{
                    if itemTask.id == task.id{
                        isNeedAdd = false
                        break
                    }
                }
            case .None:
                break
            case .Pre_Order:
                break
            }
        }
        if isNeedAdd{
            penddingTasks.append(task)
            if PoolConstants.Debug.debugTask{ print( "Add task %@",task.id )}
        }else{
            if PoolConstants.Debug.debugTask{ print( "Khong add task %@",task.id )}
        }
        self.runTaskOperation()
    }
    
    func completeTask(id : TaskID){
        runningTaskCount -= 1
        runningTasks = runningTasks.filter{$0 != id}
        self.runTaskOperation()
        if PoolConstants.Debug.debugTask{ print( "completeTask : task %@",id )}
        if PoolConstants.Debug.debugTask{ print( "runningTaskCount-- = ",runningTaskCount )}
    }
    
    /// runTaskOperation for checking which task allowed run
    /// run rask when a task complete or add
    func runTaskOperation(){
        if isRunTaskOperation{
            return
        }
        isRunTaskOperation = true
        //check xem trong pending co thang nao chua
        if (penddingTasks.count > 0){
            // khi pending dang co thang de add vao thi bat dau check thread. neu chua max thread thi co the cho run
            if (runningTaskCount < maximumThread){
                var worker : BaseWokerOperationTask?
                for taskPending in penddingTasks{
                    var isValid = false
                    switch taskPending.id{
                    case .None:
                        break
                    case .Remote_Short_Term,
                         .Remote_Long_Term:
                        let networkStatus = self.callBack?.getNetworkState()
                        if networkStatus != nil && networkStatus!.isConnected && !runningTasks.contains(TaskID.Remote_Long_Term) && !runningTasks.contains(TaskID.Remote_Short_Term){
                            isValid = true
                        }
                        break
                    case .Get_Data, .Action_Add, .Ranking, .Local_Cache_Update :
                        if !runningTasks.contains(taskPending.id) && !runningTasks.contains(TaskID.Delete_Task) && !runningTasks.contains(TaskID.Hidden_Delete_Task){
                            isValid = true
                        }
                        break
                    case .Delete_Task:
                        if !runningTasks.contains(TaskID.Get_Data) && !runningTasks.contains(TaskID.Ranking) && !runningTasks.contains(TaskID.Local_Cache_Update) && !runningTasks.contains(TaskID.Hidden_Delete_Task) && !runningTasks.contains(TaskID.Delete_Task) && !runningTasks.contains(TaskID.Action_Add) && !runningTasks.contains(TaskID.Action_Remote_Task) && !runningTasks.contains(TaskID.Upload_Task){
                            isValid = true
                        }
                        break
                    case .Hidden_Delete_Task:
                        if !runningTasks.contains(TaskID.Get_Data) && !runningTasks.contains(TaskID.Ranking) && !runningTasks.contains(TaskID.Local_Cache_Update) && !runningTasks.contains(TaskID.Delete_Task) && !runningTasks.contains(TaskID.Hidden_Delete_Task){
                            isValid = true
                        }
                        break
                    case .Upload_Task:
                        if !runningTasks.contains(TaskID.Upload_Add_Task){
                            isValid = true
                        }
                        break
                    case .Action_Remote_Task:
                        if !runningTasks.contains(TaskID.Action_Add){
                            isValid = true
                        }
                        break
                    default :
                        isValid = true
                        break
                    }
                    if isValid{
                        worker = taskPending
                        //                        if let workerFinal = worker{
                        //                            //check piority
                        ////                            if worker.priority < taskPending.priority {
                        //                                worker = taskPending
                        ////                            }
                        //                        }else{
                        //                            // check piority
                        //                            worker = taskPending
                        //                        }
                    }
                }
                if let _worker = worker{
                    
                    //                    check xem reference co bi khong
                    
                                        for queueItem in queues.operations{
                                            if queueItem is BaseWokerOperationTask{
                                                if let queueBase = queueItem as? BaseWokerOperationTask{
                                                    if queueBase.id == worker?.id{
                                                        if PoolConstants.Debug.debugLog{
                                                            print( "Task \(worker!.id) is already contains of queues 2. ")
                    
                                                        }
                                                        isRunTaskOperation = false
                                                        return
                                                    }
                                                }
                    
                                            }
                                        }
                    if PoolConstants.Debug.debugLog{
                        print("worker \(_worker.id) _worker.isExecuting == \(_worker.isExecuting ? "true" : "false")")
                        print("worker \(_worker.id) _worker.isFinished == \(_worker.isFinished ? "true" : "false")")
                    }
                    if _worker.isExecuting{
                        if PoolConstants.Debug.debugLog{
                            print( "Task \(_worker.id) is already contains of queues1. ")
                            
                            
                        }
                        isRunTaskOperation = false
                        return;
                    }
                    if _worker.isReady{
//                        let serialQueue = DispatchQueue(label: "myqueue")
//
//                        serialQueue.sync {
                            if queues.operations.contains(_worker){
                                
                                if PoolConstants.Debug.debugLog{
                                    print( "Task \(_worker.id) is already contains of queues. ")
                                    
                                }
                                isRunTaskOperation = false
                                return;
                            }
                            penddingTasks = penddingTasks.filter{$0 != _worker}
                            runningTasks.append(_worker.id)
                            self.doRunTaskOperation(task: _worker)
                            
                            if PoolConstants.Debug.debugTask{ print( "running task : task %@",_worker.id )}
                            runningTaskCount += 1
                            if PoolConstants.Debug.debugTask{ print( "runningTaskCount++ = ",runningTaskCount )}
                        
                            isRunTaskOperation = false
                            return;
                            
//                        }
                    }else{
                        if PoolConstants.Debug.debugLog{
                            print( "Task \(_worker.id) is NOT ready for add. ")
                            
                        }
                        isRunTaskOperation = false
                        return;
                    }
                    
                }else{
                    if PoolConstants.Debug.debugTask{ print( "Not valid task ")}
                }
            }else{
                if PoolConstants.Debug.debugTask{ print( "full thread. wait")}
            }
        }else{
            if PoolConstants.Debug.debugTask{ print( "No task to run")}
        }
        isRunTaskOperation = false
    }
    func doRunTaskOperation( task : BaseWokerOperationTask){
        queues.addOperation(task)
    }
    
}

