//
//  Utility.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/3/31.
//

import Foundation


open class Utility {
    
    static let TAG = "Utility"

    // MARK: String & Byte[UInt8] & Data
    /*
    //UInt8 to Data
    let value: UInt8 = 123
    let data = Data([value])

    //Data to UInt8
    let originalValue = data[0]
    print(originalValue) //->123

    //[UInt8] to Data
    let arrValue: [UInt8] = [123, 234]
    let arrData = Data(arrValue)

    //Data to [UInt8]
    let originalValues = Array(arrData)
    print(originalValues) //->[123,234]
     
    //NSData to Data
     let NSData : NSData
     (NSData as Data)
    
    //NSData to [UInt8]
     let NSData : NSData
     ([UInt8](NSData))
     //Array(RxData) , [UInt8](RxData as Data)
    */
    
    
    public static func BytesToHexString(_ byte:[UInt8]) -> String {
        var datainfo = ""
        
        for i in stride(from: 0, through: byte.count-1, by: 1) {
            var HEX_data = String(byte[i], radix: 16)
            if HEX_data.count < 2 {
                HEX_data = "0"+HEX_data
            }
            datainfo += HEX_data
        }
        return datainfo
    }
    
    public static func HexStringToBytes(_ string: String) -> [UInt8] {
        let length = string.count
        var bytes  = [UInt8]()
        bytes.reserveCapacity(length/2)
        
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            }
            index = nextIndex
        }
        return bytes
    }

    public static func UInt8ToHexString(_ Ui8Data: UInt8) -> String {
        let Ui8Data = Ui8Data
        var sUi8 = String(Ui8Data, radix: 16)
        if sUi8.count < 2 { //在轉換時如果是個位數，會少零，所以自己補 0
            sUi8 = "0"+sUi8
        }
        return sUi8
    }
    
//    public static func DataToHexString(_ inData: Data) -> String {
//        let data = inData.hexEncodedString()
//        return data
//    }
    
    public static func DataToUInt8(_ inData: Data) -> [UInt8] {
        let data = inData.hexEncodedString()
        let uInt8data = Utility.HexStringToBytes(data)
        return uInt8data
    }
    
    // ex: chanse(UTF8) to hex
    public static func UTF8ToUInt8(_ inData: String) -> [UInt8] {
        let somedata = inData.data(using: String.Encoding.utf8)
        let out = DataToUInt8(somedata!)
        return out
    }
    
    // hex to UTF8(chanse)
    public static func UInt8TOUTF8(_ inData: Data) -> String {
        let data = String(data: inData, encoding: .utf8)!
        return data
    }
    
    // ex: int to Int8
    public static func IntToHexString(_ inData: Int) -> String {
        var sUInt8 = String(inData, radix: 16)
        if sUInt8.count < 2 { //在轉換時如果是個位數，會少零，所以自己補 0
            sUInt8 = "0"+sUInt8
        }
        return sUInt8
    }
    
    
    // MARK: Byte compare
    // (資料源,起始位置,取多少長)
    public static func arrayCopy(_ aUi8Data: [UInt8], _ DataStarte:Int, _ Datalen:Int) -> [UInt8] {
        var output = ""
        let queue = DispatchQueue(label: "ArrayCopy",attributes: .concurrent)
        queue.sync {
            for i in DataStarte...Datalen-1{  //stride(from: DataStarte, through: Datalen-1, by: 1) {
                var getdata = String(aUi8Data[i], radix: 16)
                if getdata.count < 2 {
                    getdata = "0" + getdata
                }
                output += getdata
            }
        }
        return Utility.HexStringToBytes(output)
    }
    
    // MARK: Get time
    public static func getTime(str:String) -> String
    {
        var stringDate = ""
        autoreleasepool(invoking: { () -> () in
            //DispatchQueue(label: "name",attributes: .concurrent).sync {
                let currentDate = Date()//這樣可以取得系統時間
                let dataFormatter = DateFormatter() //實體化日期格式化物件
                dataFormatter.locale = Locale(identifier: "zh_Hant_TW")
                dataFormatter.dateFormat = str // YYYY年MM月dd日 hh:mm:ss.SSS //參照ISO8601的規則
                
                stringDate = dataFormatter.string(from: currentDate)
            //}
        })
        return stringDate
    }
    
    // MARK: FileManager write / read / checkExist / copyFile
    
    // URL to String
    // 1. let str = String(contentsOf: URL)
    // 2. URL.path
    // String to URL
    // 1. let str = URL(string: String)
    
    public static func copyfile (sourcePath:String, targetPath:String) -> Bool {
        var state = false
        do{
            try FileManager.default.copyItem(atPath: sourcePath, toPath: targetPath)
            Log_("", TAG, "FileManager copyItem success")
            state = true
        }catch{
            Log_("", TAG, "FileManager copyItem fail : \(error.localizedDescription)")
        }
        return state
    }
    
    // 判断是否是文件夹的方法
    public static func directoryIsExists (path: String) -> Bool {
        
        var directoryExists = ObjCBool.init(false)
        let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
        
        return fileExists && directoryExists.boolValue
    }
    
    public static func createfile(_ path:String) -> Bool {
        var state = false
        do{
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            //Log_("", TAG, "createfile success")
            print("createfile success")
            state = true
        }catch{
            //Log_("", TAG, "createfile fail : \(error.localizedDescription)")
            print("createfile fail : \(error.localizedDescription)")
        }
        return state
    }
    
    // File Read & Write 只能一次寫入
    public static func readFile() -> String {
        var str = ""
        do {
            str = try String(contentsOfFile: LogPath, encoding: String.Encoding.utf8)
            Log_("",TAG,"readFile success.")
        } catch {
            Log_("",TAG,"readFile fail : \(error.localizedDescription).")
        }
        return str
    }
    
    // 第一次寫入、建立檔案
    public static func writeTofile(_ text:String){
        do {
            try text.write(toFile: LogPath, atomically: true, encoding: String.Encoding.utf8)
            //Log_("",TAG,"writeTofile(\(String(describing: URL(string:LogPath)?.lastPathComponent))) success.")
        } catch {
            //Log_("",TAG,"writeTofile(\(String(describing: URL(string:LogPath)?.lastPathComponent))) fail : \(error.localizedDescription).")
            print("writeTofile(\(String(describing: URL(string:LogPath)?.lastPathComponent))) fail : \(error.localizedDescription).")
        }
    }
    
    public static func writeMore(_ instr:String,_ status:Bool){
        
        let appendedData = instr.data(using: String.Encoding.utf8, allowLossyConversion: true)

        do {
            let writeHandler = try FileHandle(forWritingTo:(URL(string: LogPath))!)
            
            if (status){
                writeHandler.seekToEndOfFile()
                writeHandler.write(appendedData!)
            }else{
                //close write function
                try? writeHandler.close()
            }
        } catch {
            Log_("",TAG,"writeMore() fail : \(error.localizedDescription).")
        }
    }
    
}
    


// MARK: Data to UInt8
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}


