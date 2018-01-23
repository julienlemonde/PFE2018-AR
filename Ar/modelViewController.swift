//
//  modelViewController.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-19.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit

protocol MCDelegate {
    func passingModelSelection(modelSelection: String)
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
        delegate?.passingModelSelection(modelSelection: modelList[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var popupView: UIView!
    @IBAction func closeModelModal(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var modelTableView: UITableView!
    var modelList: Array<String> = []
    

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
        let path = Bundle.main.resourcePath! + "/Models.scnassets/"
        do {
            let items = try fileManager.contentsOfDirectory(atPath: path)
            for item in items {
                if(fileManager.fileExists(atPath: path + item, isDirectory:&isDir))
                {
                    modelListToReturn.append(item)
                }
            }
        }
        catch{
            
        }
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
