//
//  modelViewController.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-19.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit

class modelViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! modelViewTableViewCell
        cell.myImage.image = UIImage(named: "\(modelList[indexPath.row]).png")
        print(modelList[indexPath.row])
        cell.myLabel.text = modelList[indexPath.row]
        return cell
    }
    
    
    @IBOutlet weak var popupView: UIView!
    @IBAction func closeModelModal(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var modelTableView: UITableView!
    let modelList = ["duck","candle","lamp","vase"]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupView.layer.cornerRadius = 6.0
        popupView.layer.masksToBounds = true
        // Do any additional setup after loading the view.
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
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
