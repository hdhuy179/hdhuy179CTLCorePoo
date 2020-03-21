//
//  ClientConfig.swift
//  PegaXPool
//
//  Created by thailinh on 1/23/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
open class PostCommentModel{
    var nothing : String?
    public init(nothing : String) {
        self.nothing = nothing
    }
}
public protocol ClientConfig  : class{
    func getData(isOpen : Bool) -> RemoteTaskData
    func scheduleGetDataMobile() -> RemoteTaskData
    func scheduleGetDataWifi() -> RemoteTaskData
    func receiveData( response : [String : Any]) -> [RankingModel]
    func deleteListCardId(ids : [String])
    func getActionRequest(actions : [ActionModel])->RemoteTaskData
    func parserActionResponse(response : [String : Any]) -> Bool
    func actionFail(error : Error)
}

public protocol ClientPostConfig : class{
    func createPost(params : [String : Any]) -> RemoteTaskData
    func createPosts(params : [String : Any]) -> RemoteTaskData
    func parseRequestData(type : Int, response : [String : Any])->[RankingModel]
    func requestDataFail(error : Error)
    func getRequest(model : UpLoadModel, postCommentModel : PostCommentModel) -> RemoteTaskData?
    func createPostCommentFail(reason : CreatePostCommentReasonFail ,idTemp : String)
    func postProgress(progress : Float, idPost : String)
//    func updatePost(params : [String : Any])->RemoteTaskData
//    func deletePost(postID : String)->RemoteTaskData
//    func getPost(postId : String)->RemoteTaskData
//    func getAllPost(userId : String)-> RemoteTaskData
}
public protocol ClientUpLoadConfig : class{
    func getUpLoadImage(cardId : String, position : Int) -> RemoteTaskData
    func getUploadVideo(cardId : String, position : Int, isUseBlackTuanService : Bool) -> RemoteTaskData
    func uploadFileSuccess(id : String, path : String, link : UploadDataTask)
    func uploadFileFail(id : String, path : String)
    func uploadSuccess(type : Int, cardID : String, links : [UploadDataTask])
    func parseUploadData(idMediaUpload : String, localPath : String, type : Int, typeData : Int,  response : [String : Any]) -> UploadDataTask?
    func getImageOfUrl(url :String)-> URL?
    func getImageDataOfUrl(url :String)-> UIImage?
    func getExtPostForSend(followTempID tempID : String, upload : UpLoadModel)-> PostCommentModel?
    func updateExtPostForSend(id: String, local: String, editValues: [String:Any])
    func getType(ofPath path : String )->Int
    func getVideoOfUrl(path : String)->URL?
    func getVideoOfUrlAndMineType(path : String)->(URL?, String?)
    func requestUploadFail(type : Int, error : Error)
    func getPolicy(name : String , isConvert : Bool)->RemoteTaskData
    func getVideoInfoRemoteTask(filePath :String)-> RemoteTaskData
}
