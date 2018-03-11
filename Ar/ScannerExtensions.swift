//
//	Extensions for Swift port of the Structure SDK sample app "Scanner".
//	Copyright © 2016 Christopher Worley. All rights reserved.
//
//  ScannerExtensions.swift
//
//  Ported by Christopher Worley on 8/20/16.
//


extension Timer {
    class func schedule(delay: TimeInterval, handler: @escaping (Timer!) -> Void) -> Timer {
        let fireDate = delay + CFAbsoluteTimeGetCurrent()
		let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, CFRunLoopMode.commonModes)
        return timer!
	}
}

public extension Float {
	public static let epsilon: Float = 1e-8
	func nearlyEqual(b: Float) -> Bool {
		return abs(self - b) < Float.epsilon
	}
}

public class FileMgr: NSObject {
    
    private var rootPath: String!
    private var basePath: NSString!
    
    class var sharedInstance: FileMgr {
        struct Static {
            static let instance: FileMgr? = { FileMgr.init() }()
        }
        return Static.instance!
    }

    private override init() {
        super.init()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.rootPath = paths[0].path
        self.basePath = (self.rootPath as NSString)
    }
    
    private func mksubdir( subpath: String) -> Bool {
        
        let fullPath = self.full(name: subpath)
        
        if !self.exists(name: fullPath) {
            
            do {
                try FileManager.default.createDirectory(atPath: fullPath, withIntermediateDirectories: true, attributes: nil)
                return true
            }
            catch {
                return false
            }
        }
        
        return true
    }
    
    func useSubpath( subPath: String) {
        
        mksubdir(subpath: subPath)
        self.basePath = (rootPath as NSString).appendingPathComponent(subPath) as NSString
    }
    
    func root() -> NSString {
        
        return self.rootPath as NSString
    }
    
    func full( name: String) -> String {
        
        return self.basePath.appendingPathComponent(name)
    }
    
    func del( name: String) {
        
        let name = self.basePath.appendingPathComponent(name)
        
        do {
            try FileManager.default.removeItem(atPath: name)
        }
        catch {
            print("Error deleting \(name) \(error)")
        }
    }
    
    func getData( name: String) -> NSData? {
        
        let fullPathFile = self.basePath.appendingPathComponent(name)
        
        if self.exists(name: fullPathFile) {
            
            if let data = NSData(contentsOfFile: fullPathFile) {
                return data
            }
            
            print("Error reading data")
            return nil
        }
        
        print("Error no file \(name)")
        return nil
    }
    
    func saveData( name: String, data: NSData) -> NSData? {
        
        let fullPathFile = self.basePath.appendingPathComponent(name)
        
        if self.exists(name: fullPathFile) {
            self.del(name: fullPathFile)
        }
        
        do {
            try  data.write( toFile: fullPathFile, options:NSData.WritingOptions.atomicWrite )
            return data
        }
        catch {
            print("Error writing file \(error)")
            return nil
        }
    }
    
    func saveMesh( name: String, data: STMesh) -> NSData? {
        
        let options: [NSObject : AnyObject] = [ kSTMeshWriteOptionFileFormatKey as NSObject : STMeshWriteOptionFileFormat.objFileZip.rawValue as AnyObject]
        
        let fullPathFile = self.basePath.appendingPathComponent(name)
        
        if self.exists(name: fullPathFile) {
            self.del(name: fullPathFile)
        }
        
        do {
            try data.write(toFile: fullPathFile, options: options)
            
            if let zipData = NSData(contentsOfFile: fullPathFile) {
                return zipData
            }
            print("Error reading mesh")
            return nil
        }
        catch {
            print("Error writing mesh \(error)")
            return nil
        }
    }
    func saveMeshObj( name: String, data: STMesh) -> NSData? {
        
        let options: [NSObject : AnyObject] = [ kSTMeshWriteOptionFileFormatKey as NSObject : STMeshWriteOptionFileFormat.objFile.rawValue as AnyObject]
        
        let fullPathFile = self.basePath.appendingPathComponent(name)
        
        if self.exists(name: fullPathFile) {
            self.del(name: fullPathFile)
        }
        
        do {
            try data.write(toFile: fullPathFile, options: options)
            
            if let zipData = NSData(contentsOfFile: fullPathFile) {
                return zipData
            }
            print("Error reading mesh")
            return nil
        }
        catch {
            print("Error writing mesh \(error)")
            return nil
        }
    }
    
    func filepath( subdir: String, name: String) -> String? {
        
        let fullPathFile = self.full(name: subdir)
        
        if !self.exists(name: fullPathFile) {
            
            do {
                try FileManager.default.createDirectory(atPath: fullPathFile, withIntermediateDirectories: true, attributes: nil)
                
                return (fullPathFile as NSString).appendingPathComponent(name)
            }
            catch {
                return nil
            }
        }
        
        return (fullPathFile as NSString).appendingPathComponent(name)
        
    }
    
    func exists( name: String) -> Bool {
        
        let fullPath = self.basePath.appendingPathComponent(name)
        
        return FileManager.default.fileExists(atPath: fullPath)
    }
}

