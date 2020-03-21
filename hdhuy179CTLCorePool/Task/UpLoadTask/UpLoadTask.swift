//
//  UpLoadTask.swift
//  PegaXPool
//
//  Created by thailinh on 3/12/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import Alamofire
class UpLoadTask: BaseWokerOperationTask {
    weak var clientConfig : ClientUpLoadConfig?
    weak var clientCreatePostConfig : ClientPostConfig?
    var progressFloatOneUpload : Float = 0.0
    init(_id: TaskID, config : ClientUpLoadConfig, postConfig : ClientPostConfig?) {
        self.clientConfig = config
        self.clientCreatePostConfig = postConfig
        super.init(_id: _id)
        
    }
    override func main() {
        let beginTime  = Timestamp.getTimeStamp()
        if PoolConstants.Debug.debugTask {print(" Task Begin id : \(String(describing: self.id)) ",beginTime)}
        if isCancelled {
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id))")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        
        //do task
        
        //        var dicJson = [String : Any]()
        
        
        
        //get upload co status pending or success
        var statusUpload = [Int]()
        statusUpload.append(UploadStatus.PENDING.rawValue)
        statusUpload.append(UploadStatus.UPLOAD_SUCCESS.rawValue)
        let uploads = LocalDatabase.shareInstance.getUploadByStatus(status:statusUpload)
        if uploads.count == 0{
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) uploads count == 0. no data for upload")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        // dpg de biet khi nao upload xong
        // cho chay tung upload 1
        // moi upload cho chay tung url 1.
        // muon multi request thi sua o day. ko biet sua nua thi gg hoac hoi t.
        // de send request single cho de xu ly va ko bi nang khi user upload cuc suc
        let dpg = DispatchGroup()
        let dpgAll = DispatchGroup()
        // Bat dau thuc hien upload. 1upload for 1 bai post hoac  1 comment
        for (idx,itemUpload) in uploads.enumerated(){
            
            // itemUpload != null && item.local != null && item.link != null. always this
            // check connection
            if PoolConstants.Debug.debugLog {
                print("Upload with current retry = \(itemUpload.retryCount)")
            }
            guard let status = self.taskProtocol?.getNetworkState() else{
                if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) status connect = null")}
                self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.Network, idTemp: itemUpload.cardID)
                self.taskProtocol?.fail(task: self, isValid: false)
                return
            }
            if !status.isConnected{
                if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) isconnect = false. tuc deo co mang")}
                self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.Network, idTemp: itemUpload.cardID)
                self.taskProtocol?.fail(task: self, isValid: false)
                return
            }
            
            let locals = itemUpload.local
            var datas = itemUpload.link
            //Progress
            var postProgress : Float = 0.0
            let uploadProgressPeicePercent = 100.0/Float(locals.count + 1)
            
            //            if (locals.count <= 0 && datas.count <= 0){
            //                break
            //            }
            dpgAll.enter()
            // check so luong link local .
            // neu co link local thi upload, neu ko co thi chuyen sang create post hoac create comment
            if locals.count <= 0{
                if PoolConstants.Debug.debugTask {print(" No file need uploaded")}
            }else if datas.count < locals.count{
                // datas luu link da upload thanh cong. khi chua upload xong
                // thi datas.count < locals.count
                let ss = locals.count - datas.count
                var isBreak = false
                for index in datas.count..<locals.count{
                    if PoolConstants.Debug.debugLog {print("prepare upload locals \(locals.count) datas \(datas.count)")}
                    dpg.enter()
                    // Upload file image hoac video len sv
                    self.uploadFile(item: itemUpload, linkIndex: index,mediaType : itemUpload.typeMedia[index], path: locals[index], completion: { (data) in
                        if PoolConstants.Debug.debugLog {
//                            if data != nil && data is extUploadDataTask{
//                                let cc = data as! extUploadDataTask
//                                print("label \(cc.label)")
//                            }
                            print("upload FILE success id \(data?.id) local \(data?.local) link \(data?.link) type \(data?.mediaType) width \(data?.width) height \(data?.height)")
                        }
                        if let dataR = data{
                            datas.append(dataR)
                            postProgress = Float(datas.count) * uploadProgressPeicePercent
                            self.clientCreatePostConfig?.postProgress(progress: postProgress, idPost: itemUpload.cardID)
                            self.clientConfig?.uploadFileSuccess(id: dataR.id, path: locals[index], link: dataR)
                            LocalDatabase.shareInstance.updateUploadLinkById(upload: itemUpload , links: datas)
                            self.clientConfig?.updateExtPostForSend(id: itemUpload.cardID, local: locals[index], editValues: dataR.wrapToDictionary())
                        }else{
                            if PoolConstants.Debug.debugLog {
                                print("data response UploadFile Nil define parseUploadData() ")
                            }
                        }
                        if PoolConstants.Debug.debugLog {
                            print("dpg.leave() when sucess")
                        }
                        dpg.leave()
                    }) {
                        if PoolConstants.Debug.debugLog {
                            print("dpg.leave() fail.UploadDataTask = nil after get from func uploadFile")
                        }
                        isBreak = true
                        dpg.leave()
                    }
                    if PoolConstants.Debug.debugLog {
                        print("dpg.wait()1")
                    }
                    dpg.wait()
                    if PoolConstants.Debug.debugLog {
                        print("dpg.wait()2")
                    }
                    if isBreak{
                        break
                    }
                }
            }
            
            // check neu isNeedRequest == false tuc la chi can upload ma ko can create post, create comment. thoat luon
            if itemUpload.isNeedRequest == 0{
                if PoolConstants.Debug.debugTask {print("isNeedRequest == 0. only Upload. not send")}
                if datas.count == locals.count {
                    LocalDatabase.shareInstance.updateUploadStatusById(upload: itemUpload, status: UploadStatus.COMPELE.rawValue)
                    dpgAll.leave()
                }else{
                    if PoolConstants.Debug.debugTask {print(" links size != local size, something error \(itemUpload.cardID) ")}
                    let retry = itemUpload.retryCount + 1
                    LocalDatabase.shareInstance.updateUploadRetryById(upload: itemUpload, retry: retry)
                    if retry >= PoolConstants.Configure.UPLOAD_RETRY_LIMIT{
                        if PoolConstants.Debug.debugLog {
                            print("retry > 3. chuan bi delete")
                            for lo in locals {
                                print("local \(lo)")
                            }
                        }
//                        self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.CreatePostComment, idTemp: itemUpload.cardID)
                    }
                    dpgAll.leave()
                }
                
            }else{
                if datas.count == locals.count{
                    if PoolConstants.Debug.debugTask {print("datas.count == locals.count. UPLOAD POST")}
                    clientConfig?.uploadSuccess(type: itemUpload.uploadType, cardID: itemUpload.cardID, links: datas)
                    LocalDatabase.shareInstance.updateUploadStatusById(upload: itemUpload, status: UploadStatus.UPLOAD_SUCCESS.rawValue)
                    
                    if let extPost = self.clientConfig?.getExtPostForSend(followTempID: itemUpload.cardID, upload: itemUpload){
                        //                    let params = [
                        //                        "posts" : [extPost.wrapToDictionary()]
                        //                    ]
                        let task = self.clientCreatePostConfig?.getRequest(model: itemUpload, postCommentModel: extPost)
                        
                        CoreAPIService.sharedInstance.ctlRequestAPIAll(url: task!.url, params: task!.params, meThod: task!.methodApi, header: task!.header, isRaw: true, completionHandler: { (response) in
                            if PoolConstants.Debug.debugTask {print("create Post thanh cong")}
                            //                        self.clientConfig?.parseUploadData(type: itemUpload.uploadType, response: response)
                            let typeForCheck = itemUpload.uploadType
                            if let listRankingModel = self.clientCreatePostConfig?.parseRequestData(type: itemUpload.uploadType, response: response){
                                if listRankingModel.count > 0{
                                    if PoolConstants.Debug.debugTask {print("create Post add ranking )")}
                                    self.taskProtocol?.localAddRank(taskID: self.id, data: listRankingModel)
                                    LocalDatabase.shareInstance.updateUploadStatusById(upload: itemUpload, status: UploadStatus.COMPELE.rawValue)
                                }else{
                                    if typeForCheck == 1{
                                        if PoolConstants.Debug.debugTask {print("Create Post not having CardID for ranking. check ParseRequest")}
                                        if PoolConstants.Debug.debugTask {print("parseRequestData status !=1 hoac ko tra ve 200. hoac ko co data")}
                                        let retry = itemUpload.retryCount + 1
                                        LocalDatabase.shareInstance.updateUploadRetryById(upload: itemUpload, retry: retry)
                                        if retry >= PoolConstants.Configure.UPLOAD_RETRY_LIMIT{
                                            if PoolConstants.Debug.debugTask {
                                                print("retry > 3. chuan bi delete")
                                                for lo in locals {
                                                    print("local \(lo)")
                                                }
                                            }
                                            
                                            self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.CreatePostComment, idTemp: itemUpload.cardID)
                                        }
                                    }else{
                                        LocalDatabase.shareInstance.updateUploadStatusById(upload: itemUpload, status: UploadStatus.COMPELE.rawValue)
                                    }
                                }
                            }else{
                                if PoolConstants.Debug.debugTask {print("parseRequestData status !=1 hoac ko tra ve 200. hoac ko co data")}
                                let retry = itemUpload.retryCount + 1
                                LocalDatabase.shareInstance.updateUploadRetryById(upload: itemUpload, retry: retry)
                                if retry >= PoolConstants.Configure.UPLOAD_RETRY_LIMIT{
                                    if PoolConstants.Debug.debugTask {
                                        print("retry > 3. chuan bi delete")
                                        for lo in locals {
                                            print("local \(lo)")
                                        }
                                    }
                                    
                                    self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.CreatePostComment, idTemp: itemUpload.cardID)
                                }
                            }
                            
                            dpgAll.leave()
                        }) { (error) in
                            if PoolConstants.Debug.debugTask {print("create Post that bai")}
                            self.clientCreatePostConfig?.requestDataFail(error: error)
                            let retry = itemUpload.retryCount + 1
                            LocalDatabase.shareInstance.updateUploadRetryById(upload: itemUpload, retry: retry)
                            if retry >= PoolConstants.Configure.UPLOAD_RETRY_LIMIT{
                                if PoolConstants.Debug.debugTask {
                                    print("retry > 3. chuan bi delete")
                                    for lo in locals {
                                        print("local \(lo)")
                                    }
                                }
                                
                                self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.CreatePostComment, idTemp: itemUpload.cardID)
                            }
                            dpgAll.leave()
                        }
                    }else{
                        if PoolConstants.Debug.debugTask {
                            print("extPost == nil. can not send request")
                        }
                        let retry = itemUpload.retryCount + 1
                        LocalDatabase.shareInstance.updateUploadRetryById(upload: itemUpload, retry: retry)
                        if retry >= PoolConstants.Configure.UPLOAD_RETRY_LIMIT{
                            if PoolConstants.Debug.debugTask {
                                print("retry > 3. chuan bi delete")
                                for lo in locals {
                                    print("local \(lo)")
                                }
                            }
                            self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.CreatePostComment, idTemp: itemUpload.cardID)
                        }
                        dpgAll.leave()
                    }
                }else{
                    if PoolConstants.Debug.debugTask {print(" links size != local size, something error \(itemUpload.cardID) ")}
                    let retry = itemUpload.retryCount + 1
                    LocalDatabase.shareInstance.updateUploadRetryById(upload: itemUpload, retry: retry)
                    if retry >= PoolConstants.Configure.UPLOAD_RETRY_LIMIT{
                        if PoolConstants.Debug.debugLog {
                            print("retry > 3. chuan bi delete")
                            for lo in locals {
                                print("local \(lo)")
                            }
                        }
                        self.clientCreatePostConfig?.createPostCommentFail(reason: CreatePostCommentReasonFail.CreatePostComment, idTemp: itemUpload.cardID)
                    }
                    dpgAll.leave()
                }
                //
            }
            
            dpgAll.wait()
            postProgress = 100.0
            self.clientCreatePostConfig?.postProgress(progress: postProgress, idPost: itemUpload.cardID)
        }
        
        //end task
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.complete(taskID: self.id)
    }
    func uploadFile(item : UpLoadModel, linkIndex : Int,mediaType : Int, path : String, completion : @escaping (UploadDataTask?)->(),failure : @escaping ()->() ){
        if PoolConstants.Debug.debugTask {print(" uploadFile start")}
        if path == "" {
            if PoolConstants.Debug.debugTask {print(" Path = null")}
            failure()
            return
        }
        guard let status = self.taskProtocol?.getNetworkState() else{
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) status connect = null")}
            self.taskProtocol?.fail(task: self, isValid: false)
            failure()
            return
        }
        if !status.isConnected{
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) isconnect = false. tuc deo co mang")}
            self.taskProtocol?.fail(task: self, isValid: false)
            failure()
            return
        }
        
        //        let typeData  = self.clientConfig?.getType(ofPath: path)
        if mediaType == UpLoadMediaType.Image.rawValue{
            //image
            if path.contains("SendDataImage"){
                guard let imageData = self.clientConfig?.getImageDataOfUrl(url: path) else {
                    if PoolConstants.Debug.debugTask {print(" imageData get NULL from url = \(path)")}
                    failure()
                    return
                }
                if PoolConstants.Debug.debugTask {print(" uploadFile Image by Data")}
                if let uploadImageData = self.clientConfig?.getUpLoadImage(cardId: item.cardID, position: linkIndex){
                    self.upLoadImageData(data: uploadImageData, linkIndex: linkIndex, path: path, dataImage: imageData, item: item, completion: { (dataTask) in
                        if PoolConstants.Debug.debugTask{print("upfile Image data sucess")}
                        //                    failure()
                        completion(dataTask)
                    }) {
                        self.clientConfig?.uploadFileFail(id: item.id, path: path)
                        if PoolConstants.Debug.debugTask{print("upfile Image data fail")}
                        failure()
                    }
                    
                }else{
                    if PoolConstants.Debug.debugTask {print("self.clientConfig?.getUpLoadImage data return nil")}
                    failure()
                }
            }else{
                guard let imageData = self.clientConfig?.getImageOfUrl(url: path) else {
                    if PoolConstants.Debug.debugTask {print(" imageData get NULL from url = \(path)")}
                    failure()
                    return
                }
                
                if PoolConstants.Debug.debugTask {print(" uploadFile Image by url")}
                if let uploadImageData = self.clientConfig?.getUpLoadImage(cardId: item.cardID, position: linkIndex){
                    uploadImageData.imageUrl = imageData
                    self.upLoadImage(data: uploadImageData,linkIndex : linkIndex, path : path, item: item, completion: { (dataTask) in
                        if PoolConstants.Debug.debugTask{print("upfile Image url sucess")}
                        //                    failure()
                        completion(dataTask)
                    }) {
                        self.clientConfig?.uploadFileFail(id: item.id, path: path)
                        if PoolConstants.Debug.debugTask{print("upfile Image url fail")}
                        failure()
                    }
                }else{
                    if PoolConstants.Debug.debugTask {print("self.clientConfig?.getUpLoadImage url return nil")}
                    failure()
                }
            }
            
        }else{
            // video
//            guard let videoData = self.clientConfig?.getVideoOfUrl(path: path) else {
//                if PoolConstants.Debug.debugTask {print(" Video data  get NULL from url = \(path)")}
//                failure()
//                return
//            }
            guard let videoInfo = self.clientConfig?.getVideoOfUrlAndMineType(path: path) else {
                if PoolConstants.Debug.debugTask {print(" Video data  get NULL from url = \(path)")}
                failure()
                return
            }
            let videoData = videoInfo.0
            let videoMineType = videoInfo.1
            
            if PoolConstants.Debug.debugTask {print(" uploadFile Video")}
            if let uploadVideoData = self.clientConfig?.getUploadVideo(cardId: item.cardID, position: linkIndex, isUseBlackTuanService: false){
                uploadVideoData.videoUrl = videoData
                if let mimeType = videoMineType{
                    uploadVideoData.mimeType = mimeType
                }else{
                    uploadVideoData.mimeType = "mp4"
                }
                
//                print("linh mime \(videoMineType) \(videoData)")
                self.uploadVideo(data: uploadVideoData,linkIndex : linkIndex, path : path, item: item, completion: { (dataTask) in
                    if PoolConstants.Debug.debugTask{print("upfile Video sucess")}
                    completion(dataTask)
                }) {
                    self.clientConfig?.uploadFileFail(id: item.id, path: path)
                    if PoolConstants.Debug.debugTask{print("upfile Video fail")}
                    failure()
                }
            }else{
                if PoolConstants.Debug.debugTask {print("self.clientConfig?.getUploadVideo return nil")}
                failure()
            }
        }
    }
    func upLoadImage(data : RemoteTaskData,linkIndex : Int, path : String, item : UpLoadModel, completion : @escaping (UploadDataTask?)->(),failure : @escaping ()->() ){
        print("upLoadImage CoreAPIService")
        let now = Date().timeIntervalSince1970*1000
        self.progressFloatOneUpload = 0.0
        CoreAPIService.sharedInstance.ctlUpLoadApiLarge(path: data.url, params: data.params, pathImage: data.imageUrl, pathVideo: nil, now: now, videoName: nil, header: data.header, completionHandler: { (response) in
            if PoolConstants.Debug.debugTask{print("upLoadImage success \(response)")}
            var idM =  ""
            if linkIndex < item.listIDMedia.count{
                idM = item.listIDMedia[linkIndex]
            }
            let uploadDataTask = self.clientConfig?.parseUploadData(idMediaUpload : idM, localPath : path, type: item.uploadType, typeData: UpLoadMediaType.Image.rawValue, response: response)
            if PoolConstants.Debug.debugTask {
                print("upload IMAGE success id \(uploadDataTask?.id) local \(uploadDataTask?.local) link \(uploadDataTask?.link) type \(uploadDataTask?.mediaType) width \(uploadDataTask?.width) height \(uploadDataTask?.height)")
            }
            completion(uploadDataTask)
        }, failure: { (error) in
            if PoolConstants.Debug.debugTask{print("upLoadImage fail \(error)")}
            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Image.rawValue, error: error)
            failure()
        }) { (progressFloat) -> Void in
            if PoolConstants.Debug.debugTask {print("progress image \(progressFloat)")}
            self.progressFloatOneUpload = progressFloat
        }
//        CoreAPIService.sharedInstance.ctlUpLoadApiLarge(path: data.url, params: data.params, pathImage: data.imageUrl, pathVideo: nil, now: now, videoName: nil, header: data.header, completionHandler: { (response) in
//            if PoolConstants.Debug.debugTask{print("upLoadImage success \(response)")}
//            var idM =  ""
//            if linkIndex < item.listIDMedia.count{
//                idM = item.listIDMedia[linkIndex]
//            }
//            let uploadDataTask = self.clientConfig?.parseUploadData(idMediaUpload : idM, localPath : path, type: item.uploadType, typeData: UpLoadMediaType.Image.rawValue, response: response)
//            if PoolConstants.Debug.debugTask {
//                print("upload IMAGE success id \(uploadDataTask?.id) local \(uploadDataTask?.local) link \(uploadDataTask?.link) type \(uploadDataTask?.mediaType) width \(uploadDataTask?.width) height \(uploadDataTask?.height)")
//            }
//            completion(uploadDataTask)
//        }) { (error) in
//            if PoolConstants.Debug.debugTask{print("upLoadImage fail \(error)")}
//            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Image.rawValue, error: error)
//            failure()
//        }

    }
    
    func upLoadImageData(data : RemoteTaskData,linkIndex : Int, path : String,dataImage : UIImage, item : UpLoadModel, completion : @escaping (UploadDataTask?)->(),failure : @escaping ()->() ){
        print("upLoadImage CoreAPIService")        
        progressFloatOneUpload = 0.0
        CoreAPIService.sharedInstance.ctlUpLoadApiImageData(path: data.url, params: data.params, image: dataImage, videoData: nil, header: data.header, completionHandler: { (response) in
            if PoolConstants.Debug.debugTask{print("upLoadImage success \(response)")}
            var idM =  ""
            if linkIndex < item.listIDMedia.count{
                idM = item.listIDMedia[linkIndex]
            }
            let uploadDataTask = self.clientConfig?.parseUploadData(idMediaUpload : idM, localPath : path, type: item.uploadType, typeData: UpLoadMediaType.Image.rawValue, response: response)
            if PoolConstants.Debug.debugTask {
                print("upload IMAGE success id \(uploadDataTask?.id) local \(uploadDataTask?.local) link \(uploadDataTask?.link) type \(uploadDataTask?.mediaType) width \(uploadDataTask?.width) height \(uploadDataTask?.height)")
            }
            completion(uploadDataTask)
        }, failure: { (error) in
            if PoolConstants.Debug.debugTask{print("upLoadImage fail \(error)")}
            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Image.rawValue, error: error)
            failure()
        }) { (progressFloat) in
            if PoolConstants.Debug.debugTask {print("progress image data \(progressFloat)")}
            self.progressFloatOneUpload = progressFloat
        }
    }
    
    
    func uploadVideo(data : RemoteTaskData,linkIndex : Int, path : String, item : UpLoadModel, completion : @escaping (UploadDataTask?)->() ,failure : @escaping ()->() ){
        if PoolConstants.Debug.debugTask {print("uploadVideo CoreAPIService")}
        let now = Date().timeIntervalSince1970*1000
        let videoName = "video\(now).\(data.mimeType!)"
//        print("linh video name \(videoName)")
        let policyRemoteData = self.clientConfig?.getPolicy(name: videoName, isConvert: true)
        if policyRemoteData == nil{
            if PoolConstants.Debug.debugTask {
                print("policyRemoteData == nil")
            }
            failure()
            return
        }

        var isFail = false
        var policy = ""
        var signature = ""
        let dpg = DispatchGroup()
        dpg.enter()
        CoreAPIService.sharedInstance.ctlRequestAPIAll(url: policyRemoteData!.url, params: policyRemoteData!.params, meThod: MethodApi.GetApi, header: policyRemoteData!.header, isRaw: false, completionHandler: { (response) in
            if PoolConstants.Debug.debugTask {
                print("get policy video with reponse \(response) ")
            }
            let dicResponse = response
            if let statusSv = dicResponse["status"] as? Int {
                if statusSv == 1{
                    if let dicPolicy = dicResponse["policy"] as? [String : Any]{
                        if let encoded_policy = dicPolicy["encoded_policy"] as? String, let _signature = dicPolicy["signature"] as? String{
                            policy = encoded_policy
                            signature = _signature
                        }else{
                            isFail = true
                        }
                        
                    }else{
                       isFail = true
                    }
                }else{
                    isFail = true
                }
                
            }
            dpg.leave()
        }) { (error) in
            if PoolConstants.Debug.debugTask {
                print("get policy video fail \(error)")
            }
            isFail = true
            dpg.leave()
        }
        dpg.wait()
        if isFail{
            let errorTemp = NSError(domain:"uploadVideo fail because of Policy not get", code:0, userInfo:nil)
            if PoolConstants.Debug.debugTask{print("uploadVideo fail because of Policy not get")}
            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Video.rawValue, error: errorTemp)
            failure()
            return
        }
        
        var paramLast : [String : Any] = data.params
        
        paramLast["policy"] = policy
        paramLast["signature"] = signature
        paramLast["filename"] = videoName
        
        let dpg2 = DispatchGroup()
        dpg2.enter()
        var isUpLoadVideoFail = false
        var filePath = ""
        if PoolConstants.Debug.debugTask {print("UPload video process  start")}
        self.progressFloatOneUpload = 0.0
        CoreAPIService.sharedInstance.ctlUpLoadApiLarge(path: data.url, params: paramLast, pathImage: nil, pathVideo: data.videoUrl, now: now, videoName: videoName, header: data.header, completionHandler: { (reponseData) in
            if PoolConstants.Debug.debugTask{print("uploadVideo success \(reponseData)")}
            if let _filePath = reponseData["file_path"] as? String{
                filePath = _filePath
                isUpLoadVideoFail = false
            }else{
                isUpLoadVideoFail = true
            }
            //            completion(uploadDataTask)
            dpg2.leave()
        }, failure: { (error) in
            if PoolConstants.Debug.debugTask{print("uploadVideo fail \(error)")}
            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Video.rawValue, error: error)
            isUpLoadVideoFail = true
            dpg2.leave()
        }) { (progressFloat) -> Void in
            if PoolConstants.Debug.debugTask {print("progress video \(progressFloat)")}
            self.progressFloatOneUpload = progressFloat
        }
        /*
        CoreAPIService.sharedInstance.ctlUpLoadApiLarge(path: data.url, params: paramLast, pathImage: nil, pathVideo: data.videoUrl, now: now, videoName: videoName, header: data.header, completionHandler: { (reponseData) in
            if PoolConstants.Debug.debugTask{print("uploadVideo success \(reponseData)")}
            if let _filePath = reponseData["file_path"] as? String{
                filePath = _filePath
                isUpLoadVideoFail = false
            }else{
               isUpLoadVideoFail = true
            }
//            completion(uploadDataTask)
            dpg2.leave()
        }) { (error) in
            if PoolConstants.Debug.debugTask{print("uploadVideo fail \(error)")}
            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Video.rawValue, error: error)
            isUpLoadVideoFail = true
            dpg2.leave()
//            failure()
        }
        
        */
        dpg2.wait()
        
        if isUpLoadVideoFail{
            let errorTemp = NSError(domain:"uploadVideo fail because of UPloading", code:0, userInfo:nil)
            if PoolConstants.Debug.debugTask{print("uploadVideo fail because of UPloading")}
            self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Video.rawValue, error: errorTemp)
            failure()
            return
        }
        
        let getInfoRemoteTask = self.clientConfig?.getVideoInfoRemoteTask(filePath: filePath)
        if getInfoRemoteTask == nil{
            if PoolConstants.Debug.debugTask {
                print("getInfoRemoteTask == nil")
            }
            failure()
            return
        }
        if PoolConstants.Debug.debugTask {
            print("get Info Video")
        }
        CoreAPIService.sharedInstance.ctlRequestAPIAll(url: getInfoRemoteTask!.url, params: getInfoRemoteTask!.params, meThod: getInfoRemoteTask!.methodApi, header: getInfoRemoteTask!.header, isRaw: false, completionHandler: { (reponseData) in
            var idM =  ""
            if linkIndex < item.listIDMedia.count{
                idM = item.listIDMedia[linkIndex]
            }
            let uploadDataTask = self.clientConfig?.parseUploadData(idMediaUpload : idM, localPath : path,type: item.uploadType, typeData: UpLoadMediaType.Video.rawValue, response: reponseData)
            if PoolConstants.Debug.debugTask {
                print("upload VIDEO success id \(uploadDataTask?.id) local \(uploadDataTask?.local) link \(uploadDataTask?.link) type \(uploadDataTask?.mediaType) width \(uploadDataTask?.width) height \(uploadDataTask?.height)")
            }
            completion(uploadDataTask)
        }) { (error) in
            if PoolConstants.Debug.debugTask {
                print("getInfo fail")
            }
            failure()
        }
        
        
    }
    
}

/*
 CoreAPIService.sharedInstance.ctlUpLoadApi(path: data.url, params: data.params, image: nil, videoData: data.videoData, header: data.header, completionHandler: { (reponseData) in
 if PoolConstants.Debug.debugTask{print("uploadVideo success \(reponseData)")}
 var idM =  ""
 if linkIndex < item.listIDMedia.count{
 idM = item.listIDMedia[linkIndex]
 }
 let uploadDataTask = self.clientConfig?.parseUploadData(idMediaUpload : idM, localPath : path,type: item.uploadType, typeData: UpLoadMediaType.Video.rawValue, response: reponseData)
 if PoolConstants.Debug.debugTask {
 print("upload VIDEO success id \(uploadDataTask?.id) local \(uploadDataTask?.local) link \(uploadDataTask?.link) type \(uploadDataTask?.mediaType) width \(uploadDataTask?.width) height \(uploadDataTask?.height)")
 }
 completion(uploadDataTask)
 }) { (error) in
 if PoolConstants.Debug.debugTask{print("uploadVideo fail \(error)")}
 self.clientConfig?.requestUploadFail(type: UpLoadMediaType.Video.rawValue, error: error)
 failure()
 }
 */
