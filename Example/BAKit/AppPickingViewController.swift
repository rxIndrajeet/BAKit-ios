//
//  AppPickingViewController.swift
//  BAKit
//
//  Created by Ed Salter on 7/31/19.
//  Copyright © 2019 BoardActive. All rights reserved.
//

import UIKit
import BAKit

class AppPickingViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        self.navigationController?.navigationBar.isHidden = false
        self.tableView.tableFooterView = UIView()
        
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.1716355085, green: 0.7660725117, blue: 0.9729360938, alpha: 1)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StorageObject.container.apps!.count
        // BoardActive.client.userDefaults?.array(forKey: String.ConfigKeys.Apps) as! [App]
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = StorageObject.container.apps![indexPath.row].name
        
//        cell.detailTextLabel?.text = (BoardActive.client.userDefaults?.array(forKey: String.ConfigKeys.Apps) as! [App])[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appId = String(StorageObject.container.apps![indexPath.row].id)
//        String((BoardActive.client.userDefaults?.array(forKey: String.ConfigKeys.Apps) as! [App])
        let appKey = (BoardActive.client.userDefaults?.string(forKey: String.ConfigKeys.AppKey))!
        
        BoardActive.client.userDefaults?.set(appId, forKey: String.ConfigKeys.AppId)
        BoardActive.client.userDefaults?.synchronize()
        
        BoardActive.client.setupEnvironment(appID: appId, appKey: appKey)
        
        (UIApplication.shared.delegate! as! AppDelegate).setupSDK()
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = storyBoard.instantiateViewController(withIdentifier: "HomeViewController")
        self.navigationController?.pushViewController(homeViewController, animated: true)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}