//
//  modelViewController.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-19.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit
import ARKit

protocol MCDelegate {
    func passingModelSelection(modelSelection: String, type: String)
}

class modelViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    var valueToReturn: String?
    var delegate: MCDelegate?
    var urlObjRunTime = FileMgr.sharedInstance.root() as String + "/scannerCache/scannedObjs/"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! modelViewTableViewCell
        let fileManager = FileManager.default
        var tmpDirectory = NSTemporaryDirectory() as String
        tmpDirectory += "\(modelList[indexPath.row])"
        if(fileManager.fileExists(atPath: tmpDirectory)){
            cell.myImage.image = UIImage(named: tmpDirectory + "/\(modelList[indexPath.row]).jpg")
        }
        else{
            cell.myImage.image = UIImage(named: "\(modelList[indexPath.row]).png")
        }
        
        cell.myLabel.text = modelList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.passingModelSelection(modelSelection: modelList[indexPath.row], type: extensionList[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let fileName = self.modelList[indexPath.row] + ".zip"
        let fileManager = FileManager.default
        let fileToEdit = self.urlObjRunTime + fileName
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            do{
                // Delete the file from disk
                if (fileManager.fileExists(atPath: fileToEdit)){
                    try fileManager.removeItem(atPath: fileToEdit)
                    
                    // if delete is sucessful
                    self.modelList.remove(at: indexPath.row)
                    self.extensionList.remove(at: indexPath.row)
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                    tableView.endUpdates()
                    
                }
            }
            catch let error as NSError {
                self.showToast(message: "Could not delete file, doesn't exist")
                print("Could not delete item, file not existant: \(error.description)")
            }
            
            
            
        }
        
        let share = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            // share item at indexPath
            // set up activity view controller
            if(fileManager.fileExists(atPath: fileToEdit)){
                let url = NSURL.fileURL(withPath: fileToEdit)
                let activityViewController = UIActivityViewController(activityItems:[url], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                // present the view controller
                self.present(activityViewController, animated: true, completion: nil)
            }
            else {
                self.showToast(message: "Cannot share default models")
            }
            
        }
        
        share.backgroundColor = UIColor.blue
        
        return [delete, share]
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
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 150, y: self.view.frame.size.height-100, width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }

}
