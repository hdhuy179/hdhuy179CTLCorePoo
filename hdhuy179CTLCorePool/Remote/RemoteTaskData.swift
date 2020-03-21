//
//  RemoteTaskData.swift
//  PegaXPool
//
//  Created by thailinh on 1/5/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import Alamofire

public class RemoteTaskData  {
    var remoteTaskProtocol : RemoteTaskProtocol?
    public var completion: ([String : Any])->Void = {response in }
    public var failure : (Error)->Void = {error in}
    public var url : String
    public var params : [String:Any]
//    var capacity : Int
    public var methodApi : MethodApi
//    public var image : UIImage?
//    public var videoData : Data?
    public var imageUrl : URL?
    public var videoUrl : URL?
    public var mimeType : String?
    public var header = HTTPHeaders()
    public init(url: String, params : [String:Any], methodApi: MethodApi) {
        self.url = url
        self.params = params
        self.methodApi = methodApi
    }
//    public func setImage(image : UIImage){
//        self.image = image
//    }
    public func setImageUrl(path : URL){
        self.imageUrl = path
    }
    public func setVideoUrl(path : URL){
        self.videoUrl = path
    }
//    init(url: String, params : [String:Any], methodApi: MethodApi,completion : @escaping ([String : Any]) ->Void ) {
//        self.url = url
//        self.params = params
//        self.methodApi = methodApi
//        self.completion = completion
//    }
}
