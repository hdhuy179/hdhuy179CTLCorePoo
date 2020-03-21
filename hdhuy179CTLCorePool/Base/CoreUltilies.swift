//
//  CoreUltilies.swift
//  PegaXPool
//
//  Created by thailinh on 3/26/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
public class CoreUltilies{
    public class func encodeForSocket(data: [String : Any]) -> [String : Any]{
        if PoolConstants.Configure.SocketVersion2{
            return data
        }
        guard let json = try? JSONSerialization.data(withJSONObject: data, options: []) else{
            
            return data
        }
        if var string = String(data: json, encoding: String.Encoding.utf8) {
            //            print("printJson byObject  \(string)")
            string = string.ctlStringByRemovingEmoji()
            if let dataLatin1 = string.data(using: String.Encoding.isoLatin1){
                if let strEncodeUtf8 = String(data: dataLatin1, encoding: String.Encoding.utf8){
                    if let dataL = strEncodeUtf8.data(using: String.Encoding.utf8){
                        if let dic = try! JSONSerialization.jsonObject(with: dataL, options: []) as? [String : Any]{
                            return dic
                        }
                        //                        print("kq1 = \(dic)")
                        
                    }
                }else{
                    //                    print("nhu cac")
                    
                }
            }else{
                //                print("kq2 = \(string)")
            }
        }else{
            //            print("printJson byObject  can not parser")
        }
        return data
    }
    public class func encodeStringForSocket(text : String)  -> String{
        let stringOriginal = text.ctlStringByRemovingEmoji()
        if let dataLatin1 = stringOriginal.data(using: String.Encoding.isoLatin1){
//            print("1 \(dataLatin1)")
            if let strEncodeUtf8 = String(data: dataLatin1, encoding: String.Encoding.utf8){
//                print("2 \(strEncodeUtf8)")
                return strEncodeUtf8
            }
        }
        return stringOriginal
    }
    
    public class func printJson(byData data : Data){
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            print("printJson byData  \(string)")
        }else{
            print("printJson byData  can not parser")
        }
    }
    
    public class func printJson(byObject JSON : Any){
        guard let json = try? JSONSerialization.data(withJSONObject: JSON, options: JSONSerialization.WritingOptions.prettyPrinted) else{
            print("printJson byObject  can not parser")
            return
        }
        if let string = String(data: json, encoding: String.Encoding.utf8) {
            print("printJson byObject  \(string)")
        }else{
            print("printJson byObject  can not parser")
        }
    }
    
    public class func convertString(byObject JSON : Any) ->String{
        guard let json = try? JSONSerialization.data(withJSONObject: JSON, options: []) else{
//            print("printJson byObject  can not parser")
            return ""
        }
        if let string = String(data: json, encoding: String.Encoding.utf8) {
//            print("printJson byObject  \(string)")
            return string
        }
//        print("printJson byObject  can not parser")
        return ""
    }
    public class func checkJailBreak() -> Bool{
        if TARGET_IPHONE_SIMULATOR != 1
        {
            // Check 1 : existence of files that are common for jailbroken devices
            if FileManager.default.fileExists(atPath: "/Applications/Cydia.app")
                || FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib")
                || FileManager.default.fileExists(atPath: "/bin/bash")
                || FileManager.default.fileExists(atPath: "/usr/sbin/sshd")
                || FileManager.default.fileExists(atPath: "/etc/apt")
                || FileManager.default.fileExists(atPath: "/private/var/lib/apt/")
                || UIApplication.shared.canOpenURL(URL(string:"cydia://package/com.example.package")!)
                    {
                    return true
            }
            // Check 2 : Reading and writing in system directories (sandbox violation)
            let stringToWrite = "Jailbreak Test"
            do
            {
                try stringToWrite.write(toFile:"/private/JailbreakTest.txt", atomically:true, encoding:String.Encoding.utf8)
                //Device is jailbroken
                return true
            }catch
            {
                return false
            }
        }else
        {
            return false
        }
    }
}
class VerifyPost{
    class func loadDataVerify()->[String]{

        //?.path(forResource: "VerifyPost", ofType: "json")
        guard let frameWorkBundlePath = Bundle.main.path(forResource: "CorePoolResource", ofType: "bundle") else{
            
            return [String]()
        }
        let frameWorkBundle = Bundle(path: frameWorkBundlePath)
        if let path = frameWorkBundle?.path(forResource: "VerifyPost", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonArray = jsonResult as? Array<String>{
                    return jsonArray
                }
                return [String]()

            } catch {
                return [String]()
            }
        }
        return [String]()
        
    }
    class func verifyPost(forTextContent content : String)->[Range<String.Index>]{
        return [Range<String.Index>]()
        let listBanned = loadDataVerify()
        var listRange = [Range<String.Index>]()
        let contentAf = content.folding(options: .diacriticInsensitive, locale: nil)
        for item in listBanned{
            if let ranges = getRangeOfString(subString: item, fromString: content){
                listRange.append(contentsOf: ranges)
            }
        }
        return listRange
    }
    class func getRangeOfString(subString subString : String,fromString currentString : String)-> [Range<String.Index>]?{
//        let range = currentString.range(of: subString)
        var ranges: [Range<String.Index>] = []
        while ranges.last.map({ $0.upperBound < currentString.endIndex }) ?? true,
            let range = currentString.range(of: subString, options: [.caseInsensitive], range: (ranges.last?.upperBound ?? currentString.startIndex)..<currentString.endIndex, locale: nil)
        {
            ranges.append(range)
        }
        return ranges
    }
}
extension String {
    func ctlStringByRemovingEmoji() -> String {
        if #available(iOS 10.2, *) {
            return String(self.filter { !$0.isEmoji2 })
        } else {
            // Fallback on earlier versions
            return String(self.filter { !$0.ctlIsEmoji()})
        }
        
    }
    
}

extension Character {
    fileprivate func ctlIsEmoji() -> Bool {
        return Character(UnicodeScalar(UInt32(0x1d000))!) <= self && self <= Character(UnicodeScalar(UInt32(0x1f77f))!)
            || Character(UnicodeScalar(UInt32(0x2100))!) <= self && self <= Character(UnicodeScalar(UInt32(0x26ff))!)
    }
    @available(iOS 10.2, *)
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else {
            return false
        }
        return unicodeScalars.count == 1 &&
            (firstProperties.isEmojiPresentation ||
                firstProperties.generalCategory == .otherSymbol)
    }
    
    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool {
        return unicodeScalars.count > 1 &&
            unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }
    @available(iOS 10.2, *)
    var isEmoji2: Bool {
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}

