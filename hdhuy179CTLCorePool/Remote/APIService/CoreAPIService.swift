//
//  APIService.swift
//  Ringtones
//
//  Created by Trương Thắng on 10/7/18.
//  Copyright © 2018 Trương Thắng. All rights reserved.
//

import Foundation
import Alamofire
import UIKit


open class CoreAPIService {
    
    let headers: HTTPHeaders = [
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    public static let sharedInstance = CoreAPIService()
    public typealias CompletionHandler = (_ response: [String: Any]) -> Void
    public typealias ErrorHandler = (_ response: Error) -> Void
    public typealias ProgressHandler = (_ percent: Float) -> Void
    
    open func ctlUpLoadApi(path url : String, params : [String : Any]?,image : UIImage?,videoData : Data?,header : HTTPHeaders?, completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler){
        print("url = \(url) param = \(params) header \(header) image = \(image?.size) ")
        var formParams: Dictionary<String, Data> = Dictionary<String, Data>()
        if let mparams = params {
            if PoolConstants.Debug.debugLog {print(" tao formParams")}
            for key in Array(mparams.keys) {
                if let dataAny: Any = mparams[key]{
                    var data: Data?
                    if(dataAny is String || dataAny is NSString){
                        data = String(dataAny as! NSString).data(using: String.Encoding.utf8)
                    }else if(dataAny is NSNumber){
                        let _dataAny = dataAny as! NSNumber
                        data = String(_dataAny.stringValue).data(using: String.Encoding.utf8)
                    }else if(dataAny is Int){
                        data = String("\((dataAny as! Int))").data(using: String.Encoding.utf8)
                    }else if(dataAny is CGFloat){
                        data = String("\((dataAny as! CGFloat))").data(using: String.Encoding.utf8)
                    }else if(dataAny is Double){
                        data = String("\((dataAny as! Double))").data(using: String.Encoding.utf8)
                    }else {
                        data = try? JSONSerialization.data(withJSONObject: dataAny, options: .prettyPrinted)
                    }
                    
                    formParams[key] = data
                }
            }
        }
        if PoolConstants.Debug.debugLog {print(" Kết thúc tao formParams. tao header")}
        var headers: HTTPHeaders
        if let headerLast = header{
            headers = headerLast
        }else{
            headers = [
                "Content-type": "multipart/form-data"
            ]
        }
        if PoolConstants.Debug.debugLog {print(" Starting upload")}
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            if PoolConstants.Debug.debugLog {print("Starting multipartFormData param")}
            for key in Array(formParams.keys){
                if PoolConstants.Debug.debugLog {print("key = \(key)")}
                if let data = formParams[key as String] as? Data{
                    if PoolConstants.Debug.debugLog {print("data = \(data)")}
                    multipartFormData.append(data, withName: key)
                }
            }
            if PoolConstants.Debug.debugLog {print("Starting multipartFormData image")}
            let now = Date().timeIntervalSince1970*1000
            if let imageFile = image{
                let imageName = "image\(now).jpeg"
                let imageKey = "image"
                if PoolConstants.Debug.debugLog {print("imageFile = \(imageFile). start append imageFile ")}
                multipartFormData.append(imageFile.jpegData(compressionQuality: 1.0)!, withName: imageKey, fileName: imageName, mimeType: "image/*")
            }
            
            if let dataVideo = videoData{
                let video = "video\(now)"
                multipartFormData.append(dataVideo, withName: "file", fileName: video, mimeType: "video/*")
            }
            
//            if let videoPatha = videoPath,let dataVideo = try? Data(contentsOf: URL(fileURLWithPath: videoPatha)){
//                let video = "video\(now)"
//                multipartFormData.append(dataVideo, withName: "file", fileName: video, mimeType: "video/mov")
//            }
        }, usingThreshold: UInt64.init(), to: url, method: HTTPMethod.post, headers: headers) { (result) in
            switch result {
            case .success(let upload, _, _):
//                                upload.responseString(completionHandler: { (response) in
//                                    print("dit me may")
//                                    print(response.value)
//                                    print(response.response?.statusCode)
//                                })
                upload.responseJSON(completionHandler: { (response) in
                    if PoolConstants.Debug.debugLog{print("ctlUpLoadApi upload image responseJSON \(response.value)")}
                    if let status = response.response?.statusCode
                    {
                        if status == 200{
                            let dicResponse = response.value as! [String: Any]
                            if let statusSv = dicResponse["status"] as? Int {
                                if statusSv == 1{
                                    completionHandler (dicResponse  )
                                    return
                                }
                                var errorTemp = NSError(domain:"err \(statusSv)", code:0, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }else if let statusSv = dicResponse["success"] as? Int {
                                if statusSv == 1{
                                    if let dataLast = dicResponse["data"] as? [String: Any]{
                                        completionHandler (dicResponse  )
                                        return
                                    }
                                }
                                var errorTemp = NSError(domain:"err \(statusSv)", code:0, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }
                            var errorTemp = NSError(domain:"err status ko co hoac ko phai int", code:0, userInfo:nil)
                            failure(errorTemp as Error)
//                            completionHandler(response.value as! [String : Any])
                        }else{
                            if let error = response.error{
                                failure(error)
                            }else{
                                var errorTemp = NSError(domain:"", code:status, userInfo:nil)
                                failure(errorTemp as Error)
                            }
                        }
                    }else{
                        if let error = response.error{
                            failure(error)
                        }else{
                            var errorTemp = NSError(domain:"", code:0, userInfo:nil)
                            failure(errorTemp as Error)
                        }
                    }
                    
                })
            case .failure(let error):
                if PoolConstants.Debug.debugLog{print("Error in upload: \(error.localizedDescription)")}
                failure(error)
            }
        }
    }
    //MARK: - upload image by upload data
    open func ctlUpLoadApiImageData(path url : String, params : [String : Any]?,image : UIImage?,videoData : Data?,header : HTTPHeaders?, completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler, progress_Handler : @escaping ProgressHandler){
        print("url = \(url) param = \(params) header \(header) image = \(image?.size) ")
        var formParams: Dictionary<String, Data> = Dictionary<String, Data>()
        if let mparams = params {
            if PoolConstants.Debug.debugLog {print(" tao formParams")}
            for key in Array(mparams.keys) {
                if let dataAny: Any = mparams[key]{
                    var data: Data?
                    if(dataAny is String || dataAny is NSString){
                        data = String(dataAny as! NSString).data(using: String.Encoding.utf8)
                    }else if(dataAny is NSNumber){
                        let _dataAny = dataAny as! NSNumber
                        data = String(_dataAny.stringValue).data(using: String.Encoding.utf8)
                    }else if(dataAny is Int){
                        data = String("\((dataAny as! Int))").data(using: String.Encoding.utf8)
                    }else if(dataAny is CGFloat){
                        data = String("\((dataAny as! CGFloat))").data(using: String.Encoding.utf8)
                    }else if(dataAny is Double){
                        data = String("\((dataAny as! Double))").data(using: String.Encoding.utf8)
                    }else {
                        data = try? JSONSerialization.data(withJSONObject: dataAny, options: .prettyPrinted)
                    }
                    
                    formParams[key] = data
                }
            }
        }
        if PoolConstants.Debug.debugLog {print(" Kết thúc tao formParams. tao header")}
        var headers: HTTPHeaders
        if let headerLast = header{
            headers = headerLast
        }else{
            headers = [
                "Content-type": "multipart/form-data"
            ]
        }
        if PoolConstants.Debug.debugLog {print(" Starting upload")}
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            if PoolConstants.Debug.debugLog {print("Starting multipartFormData param")}
            for key in Array(formParams.keys){
                if PoolConstants.Debug.debugLog {print("key = \(key)")}
                if let data = formParams[key as String] as? Data{
                    if PoolConstants.Debug.debugLog {print("data = \(data)")}
                    multipartFormData.append(data, withName: key)
                }
            }
            if PoolConstants.Debug.debugLog {print("Starting multipartFormData image")}
            let now = Date().timeIntervalSince1970*1000
            if let imageFile = image{
                let imageName = "image\(now).jpeg"
                let imageKey = "image"
                if PoolConstants.Debug.debugLog {print("imageFile = \(imageFile). start append imageFile ")}
                multipartFormData.append(imageFile.jpegData(compressionQuality: 1.0)!, withName: imageKey, fileName: imageName, mimeType: "image/*")
            }
            
            if let dataVideo = videoData{
                let video = "video\(now)"
                multipartFormData.append(dataVideo, withName: "file", fileName: video, mimeType: "video/*")
            }
            
            //            if let videoPatha = videoPath,let dataVideo = try? Data(contentsOf: URL(fileURLWithPath: videoPatha)){
            //                let video = "video\(now)"
            //                multipartFormData.append(dataVideo, withName: "file", fileName: video, mimeType: "video/mov")
            //            }
        }, usingThreshold: UInt64.init(), to: url, method: HTTPMethod.post, headers: headers) { (result) in
            switch result {
            case .success(let upload, _, _):
                //                                upload.responseString(completionHandler: { (response) in
                //                                    print("dit me may")
                //                                    print(response.value)
                //                                    print(response.response?.statusCode)
                //                                })
                upload.uploadProgress(closure: { (progress) in
                    let floatProgress = Float(progress.fractionCompleted) ?? 0.0
                    //                    print("progress \(floatProgress)")
                    progress_Handler(floatProgress)
                })
                upload.responseJSON(completionHandler: { (response) in
                    if PoolConstants.Debug.debugLog{print("ctlUpLoadApi upload image responseJSON \(response.value)")}
                    if let status = response.response?.statusCode
                    {
                        if status == 200{
                            let dicResponse = response.value as! [String: Any]
                            if let statusSv = dicResponse["status"] as? Int {
                                if statusSv == 1{
                                    completionHandler (dicResponse  )
                                    return
                                }
                                var errorTemp = NSError(domain:"err \(statusSv)", code:0, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }else if let statusSv = dicResponse["success"] as? Int {
                                if statusSv == 1{
                                    if let dataLast = dicResponse["data"] as? [String: Any]{
                                        completionHandler (dicResponse  )
                                        return
                                    }
                                }
                                var errorTemp = NSError(domain:"err \(statusSv)", code:0, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }
                            var errorTemp = NSError(domain:"err status ko co hoac ko phai int", code:0, userInfo:nil)
                            failure(errorTemp as Error)
                            //                            completionHandler(response.value as! [String : Any])
                        }else{
                            if let error = response.error{
                                failure(error)
                            }else{
                                var errorTemp = NSError(domain:"", code:status, userInfo:nil)
                                failure(errorTemp as Error)
                            }
                        }
                    }else{
                        if let error = response.error{
                            failure(error)
                        }else{
                            var errorTemp = NSError(domain:"", code:0, userInfo:nil)
                            failure(errorTemp as Error)
                        }
                    }
                    
                })
            case .failure(let error):
                if PoolConstants.Debug.debugLog{print("Error in upload: \(error.localizedDescription)")}
                failure(error)
            }
        }
    }
    func httpRequestAPI(url:String,params:[String:Any],meThod:MethodApi,completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler) {
        if PoolConstants.Debug.debugLog{print("Httprequest url = \(url) param = \(params)")}
        if meThod == .PostApi {
            //            let request = NSMutableURLRequest(url: URL(string: url)!)
            //            request.httpMethod = "POST"
            //            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            //            request.timeoutInterval = 10 // 10 secs
            //            let values = params
            //            request.httpBody = try! JSONSerialization.data(withJSONObject: values, options: [])
            
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default, headers: nil).responseJSON { (response:DataResponse<Any>) in
                
                switch(response.result) {
                case .success(let JSON):
                    if response.result.value != nil{
                        completionHandler (JSON  as! [String: Any])
                    }
                    break
                    
                case .failure(let error):
                    failure(error)
                    break
                }
            }
        }else if meThod == .GetApi {
            
            
            Alamofire.request(url, method: .get, parameters: params, encoding: URLEncoding.default, headers: nil).responseJSON { (response:DataResponse<Any>) in
                
                switch(response.result) {
                case .success(let JSON):
                    if response.result.value != nil{
                        completionHandler (JSON  as! [String: Any])
                    }
                    break
                    
                case .failure(let error):
                    failure(error)
                    break
                }
            }
        }else if meThod == .PutApi {
            Alamofire.request(url, method: .put, parameters: params, encoding: URLEncoding.default, headers: nil).responseJSON { (response:DataResponse<Any>) in
                
                switch(response.result) {
                case .success(let JSON):
                    if response.result.value != nil{
                        completionHandler (JSON  as! [String: Any])
                    }
                    break
                    
                case .failure(let error):
                    failure(error)
                    break
                }
            }
        }
        
    }
    open func ctlRequestAPIAll(url:String,params:[String:Any],meThod:MethodApi,header : HTTPHeaders, isRaw : Bool ,completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler) {
        if PoolConstants.Debug.debugLog{print("crlRequestAll url = \(url) param = \(params) header = \(header)")}
        if isRaw{
            let json = try! JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let string = String(data: json, encoding: String.Encoding.utf8) {
                if PoolConstants.Debug.debugLog{print("Param raw \(string)")}
            }
            self.ctlRequestAPIRaw(url: url, params: json, meThod: meThod, header: header, completionHandler: { (response) in
                completionHandler(response)
            }) { (error) in
                failure(error)
            }
        }else{
            self.ctlRequestAPI(url: url, params: params, meThod: meThod, header: header, completionHandler: { (response) in
                completionHandler(response)
            }) { (error) in
                failure(error)
            }
        }
    }
    
    func ctlRequestAPIRaw(url:String,params:Data,meThod:MethodApi,header : HTTPHeaders,completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler) {
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for item in header{
            request.setValue(item.value, forHTTPHeaderField: item.key)
        }
        request.httpBody = params
        
        Alamofire.request(request).responseJSON { (response) in
            
            switch(response.result) {
            case .success(let JSON):
                if response.result.value != nil{
                    if let statusCode = response.response?.statusCode{
                        if PoolConstants.Debug.debugLog{print("raw response \(JSON)")}
                        if statusCode == 200{
                            let dicResponse = response.value as! [String: Any]
                            if let statusSv = dicResponse["status"] as? Int{
                                if statusSv == 1{
                                    completionHandler (JSON  as! [String: Any])
                                    return
                                }
                                var errorTemp = NSError(domain:"err status of request = \(statusSv) content = \(dicResponse)", code:statusSv, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }
                        }
                    }
                }
                var errorTemp = NSError(domain:"err response value = \(response.value) ", code:0, userInfo:nil)
                failure(errorTemp as Error)
                return
                
            case .failure(let error):
                failure(error)
                return
            }
            
            if PoolConstants.Debug.debugLog{print(response.result)}
            
        }
    }
    
    
    func ctlRequestAPI(url:String,params:[String:Any],meThod:MethodApi,header : HTTPHeaders,completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler) {
        if PoolConstants.Debug.debugLog{print("CTLRequest url = \(url) param = \(params) header = \(header)")}
        if meThod == .PostApi {
            //            let request = NSMutableURLRequest(url: URL(string: url)!)
            //            request.httpMethod = "POST"
            //            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            //            request.timeoutInterval = 10 // 10 secs
            //            let values = params
            //            request.httpBody = try! JSONSerialization.data(withJSONObject: values, options: [])
            
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default, headers: header).responseJSON { (response:DataResponse<Any>) in
                if PoolConstants.Debug.debugLog{
//                    print("ctlUpLoadApi responseJSON \(response.value)")
                }
                switch(response.result) {
                case .success(let JSON):

//                    if PoolConstants.Debug.debugLog{CoreUltilies.printJson(byObject: JSON)}
                    if response.result.value != nil{
                        completionHandler (JSON  as! [String: Any])
                    }
                    break
                    
                case .failure(let error):
                    failure(error)
                    break
                }
            }
        }else if meThod == .GetApi {
            Alamofire.request(url, method: .get, parameters: params, encoding: URLEncoding.default, headers: header).responseJSON { (response:DataResponse<Any>) in
//                if PoolConstants.Debug.debugTask{
//                    print("ctlRequestAPI response get :  \(params)")
//                    
//                }
                if PoolConstants.Debug.debugLog{
//                    print("ctlUpLoadApi responseJSON \(response.value)")
                }
                switch(response.result) {
                case .success(let JSON):
                    if response.result.value != nil{
                        completionHandler (JSON  as! [String: Any])
                    }
                    break
                    
                case .failure(let error):
                    failure(error)
                    break
                }
                
            }
        }else if meThod == .PutApi {
            Alamofire.request(url, method: .put, parameters: params, encoding: URLEncoding.default, headers: header).responseJSON { (response:DataResponse<Any>) in
                
                switch(response.result) {
                case .success(let JSON):
                    
                    if response.result.value != nil{
                        completionHandler (JSON  as! [String: Any])
                    }
                    break
                    
                case .failure(let error):
                    failure(error)
                    break
                }
            }
        }
        
    }
    func parserData(response : [String : Any],completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler ){
        
    }
    
    open func ctlUpLoadApiLarge(path url : String, params : [String : Any]?,pathImage : URL?, pathVideo : URL?,now : TimeInterval ,videoName : String?,header : HTTPHeaders?, completionHandler: @escaping CompletionHandler,failure:@escaping ErrorHandler, progressHandler : @escaping ProgressHandler ){
        print("url = \(url) param = \(params) header \(header)")
        var formParams: Dictionary<String, Data> = Dictionary<String, Data>()
        if let mparams = params {
            for key in Array(mparams.keys) {
                if let dataAny: Any = mparams[key]{
                    var data: Data?
                    if(dataAny is String || dataAny is NSString){
                        data = String(dataAny as! NSString).data(using: String.Encoding.utf8)
                    }else if(dataAny is NSNumber){
                        let _dataAny = dataAny as! NSNumber
                        data = String(_dataAny.stringValue).data(using: String.Encoding.utf8)
                    }else if(dataAny is Int){
                        data = String("\((dataAny as! Int))").data(using: String.Encoding.utf8)
                    }else if(dataAny is CGFloat){
                        data = String("\((dataAny as! CGFloat))").data(using: String.Encoding.utf8)
                    }else if(dataAny is Double){
                        data = String("\((dataAny as! Double))").data(using: String.Encoding.utf8)
                    }else {
                        data = try? JSONSerialization.data(withJSONObject: dataAny, options: .prettyPrinted)
                    }
                    
                    formParams[key] = data
                }
            }
        }
        var headers: HTTPHeaders
        if let headerLast = header{
            headers = headerLast
        }else{
            headers = [
                "Content-type": "multipart/form-data"
            ]
        }
        //,
        //"User-Agent" : "iOS/8.0"
//        Alamofire.upload(multipartFormData: <#T##(MultipartFormData) -> Void#>, to: <#T##URLConvertible#>, encodingCompletion: <#T##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##(SessionManager.MultipartFormDataEncodingResult) -> Void#>)
//        Alamofire.upload(multipartFormData: <#T##(MultipartFormData) -> Void#>, with: <#T##URLRequestConvertible#>, encodingCompletion: <#T##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##(SessionManager.MultipartFormDataEncodingResult) -> Void#>)
//        Alamofire.upload(multipartFormData: <#T##(MultipartFormData) -> Void#>, usingThreshold: <#T##UInt64#>, with: <#T##URLRequestConvertible#>, encodingCompletion: <#T##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##(SessionManager.MultipartFormDataEncodingResult) -> Void#>)
//        Alamofire.upload(multipartFormData: <#T##(MultipartFormData) -> Void#>, usingThreshold: <#T##UInt64#>, to: <#T##URLConvertible#>, method: <#T##HTTPMethod#>, headers: <#T##HTTPHeaders?#>, encodingCompletion: <#T##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##((SessionManager.MultipartFormDataEncodingResult) -> Void)?##(SessionManager.MultipartFormDataEncodingResult) -> Void#>)
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for key in Array(formParams.keys){
                if let data = formParams[key as String]{
                    multipartFormData.append(data, withName: key)
                }
            }
//            let now = Date().timeIntervalSince1970*1000
            if let imageFileUrl = pathImage{
                let imageName = "image\(now).jpeg"
                let imageKey = "image"
                multipartFormData.append(imageFileUrl, withName: imageKey, fileName: imageName, mimeType: "image/*")
            }
            
            if let dataVideoUrl = pathVideo{
                let video = videoName ?? "video\(now).mp4"
//                let split = video.split(separator: ".")
                let mime = "video/*"
//                if let m = split.last{
//                    mime = "video/\(m)"
//                }
//                print("linh \(video) \(mime)")
                multipartFormData.append(dataVideoUrl, withName: "filedata", fileName: video, mimeType: mime)
            }
        }, usingThreshold: UInt64.init(), to: url, method: HTTPMethod.post, headers: headers) { (result) in
            switch result {
            case .success(let upload, _, _):
                
                //                                upload.responseString(completionHandler: { (response) in
                //                                    print(response.value)
                //                                    print(response.response?.statusCode)
                //                                })
                upload.uploadProgress(closure: { (progress) in
                    let floatProgress = Float(progress.fractionCompleted) ?? 0.0
//                    print("progress \(floatProgress)")
                    progressHandler(floatProgress)
                })
                upload.responseJSON(completionHandler: { (response) in
                    if PoolConstants.Debug.debugLog{print("ctlUpLoadApi responseJSON \(response.value)")}
                    if let status = response.response?.statusCode
                    {
                        if status == 200{
                            let dicResponse = response.value as! [String: Any]
                            completionHandler (dicResponse)
                            /*
                            if let statusSv = dicResponse["status"] as? Int {
                                if statusSv == 1{
                                    completionHandler (dicResponse  )
                                    return
                                }
                                var errorTemp = NSError(domain:"err \(statusSv)", code:0, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }else if let statusSv = dicResponse["success"] as? Int {
                                if statusSv == 1{
                                    if let dataLast = dicResponse["data"] as? [String: Any]{
                                        completionHandler (dicResponse  )
                                        return
                                    }
                                }
                                var errorTemp = NSError(domain:"err \(statusSv)", code:0, userInfo:nil)
                                failure(errorTemp as Error)
                                return
                            }
                            var errorTemp = NSError(domain:"err status ko co hoac ko phai int", code:0, userInfo:nil)
                            failure(errorTemp as Error)
                            */
                        }else{
                            if let error = response.error{
                                failure(error)
                            }else{
                                var errorTemp = NSError(domain:"", code:status, userInfo:nil)
                                failure(errorTemp as Error)
                            }
                        }
                    }else{
                        if let error = response.error{
                            failure(error)
                        }else{
                            var errorTemp = NSError(domain:"", code:0, userInfo:nil)
                            failure(errorTemp as Error)
                        }
                    }
                    
                })
            case .failure(let error):
                if PoolConstants.Debug.debugLog{print("Error in upload: \(error.localizedDescription)")}
                failure(error)
            }
        }
    }
}

/*
 {
 "success": true,
 "data": {
 "name": "video1552314494289.235",
 "description": "video1552314494289.235",
 "embed": "https://ovp.sohatv.vn/embed?v=abusHNGphCvDntVA",
 "vid": "abusHNGphCvDntVA",
 "mimetype": "image/*",
 "bucketName": "kingcontent",
 "objectKey": "1000360/2019/03/11/1552314500609-video1552314494289.235",
 "metadata": null,
 "size": 2097619,
 "url": "https://x3.sohatv.vn/kingcontent/1000360/2019/03/11/1552314500609-video1552314494289.235?AWSAccessKeyId=Zq7UsFGqCJnv1yOJ&Expires=1552315401&Signature=ABCcvPEsEKqCi53xG5iebMRxwdc%3D"
 }
 }
 */
 */
