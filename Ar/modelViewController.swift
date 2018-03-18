//
//  modelViewController.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-19.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit

protocol MCDelegate {
    func passingModelSelection(modelSelection: String, type: String)
}

class modelViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    var valueToReturn: String?
    var delegate: MCDelegate?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! modelViewTableViewCell
        cell.myImage.image = UIImage(named: "\(modelList[indexPath.row]).png")
        cell.myLabel.text = modelList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.passingModelSelection(modelSelection: modelList[indexPath.row], type: extensionList[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var popupView: UIView!
    @IBAction func closeModelModal(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var modelTableView: UITableView!
    var modelList: Array<String> = []
    var extensionList: Array<String> = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        modelList = listModelFromFiles()
        popupView.layer.cornerRadius = 6.0
        popupView.layer.masksToBounds = true
        // Do any additional setup after loading the view.
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
    }
    
    // Method to list all of the models available in the Models.scnassets folder to be able
    //  to add in the ARScene
    func listModelFromFiles() -> Array<String>{
        var modelListToReturn: Array<String> = []
        var isDir: ObjCBool = false
        let fileManager = FileManager.default
        let objType = ["objassets", "scnassets"]
        for type in objType {
            let Systempath = Bundle.main.resourcePath! + "/Models.\(type)/"
            do {
                let items = try fileManager.contentsOfDirectory(atPath: Systempath)
                for item in items {
                    if(fileManager.fileExists(atPath: Systempath + item, isDirectory:&isDir)) {
                        if(isDir.boolValue) {
                            modelListToReturn.append(item)
                            extensionList.append(type)
                        }
                    }
                }
            }
            catch{
                
            }
        }
        print("MALO_SCANNING FOLDER FOR MODEL")
        var urlObjRunTime = FileMgr.sharedInstance.root() as String
        urlObjRunTime += "/scannerCache/scannedObjs/"
        do {
            let items = try fileManager.contentsOfDirectory(atPath: urlObjRunTime)
            print("MALO_ITEMS")
            for item in items {
                print(item)
                if(fileManager.fileExists(atPath: urlObjRunTime + item))
                {
                    if item.range(of:".zip") != nil {
                        modelListToReturn.append(String(item.dropLast(4)))
                        extensionList.append("objRunTime")
                    }
                }
//                if(fileManager.fileExists(atPath: urlObjRunTime + item, isDirectory:&isDir)) {
//                    if(isDir.boolValue) {
//                        modelListToReturn.append(item)
//                        extensionList.append("objRunTime")
//                    }
//                }
            }
            print("MALO_ITEMS_DONE")
        }
        catch{
            
        }
//        do{
//            let items = try fileManager.contentsOfDirectory(atPath: urlObjRunTime)
//            for item in items {
//                if(fileManager.fileExists(atPath: urlObjRunTime + item))
//                {
//                    if item.range(of:".obj") != nil {
//                        modelListToReturn.append(String(item.dropLast(4)))
//                        extensionList.append("objRunTime")
//                    }
//                }
//            }
//        }
//        catch{
//
//        }
    

        
        return modelListToReturn
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
