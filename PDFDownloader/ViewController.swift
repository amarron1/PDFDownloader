//
//  ViewController.swift
//  PDFDownloader
//
//  Created by amarron on 2015/11/25.
//  Copyright © 2015年 amarron. All rights reserved.
//

import UIKit

class ViewController: UIViewController, URLSessionDownloadDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var urlTextField: UITextField!
    @IBOutlet var pdfTableView: UITableView!
    
    let dir = NSSearchPathForDirectoriesInDomains(
        .documentDirectory,
        .userDomainMask, true)
    
    var dic:UIDocumentInteractionController?
    var files:NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pdfTableView.delegate = self
        self.pdfTableView.dataSource = self
        self.urlTextField.delegate = self
        
        do {
            self.files = try NSMutableArray(array: FileManager.default.contentsOfDirectory(atPath: self.dir[0]))
        } catch {
            print("error:\(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func download(_ sender: AnyObject) {
        
        if let url = URL(string: urlTextField!.text!) {
            // Add files
            self.files.add(url.lastPathComponent)
            
            // Download
            let config = URLSessionConfiguration.default
            let session = Foundation.URLSession(configuration: config,
                delegate: self,
                delegateQueue: OperationQueue.main)
            let task = session.downloadTask(with: url)
            task.resume()
        } else {
            // Alert
            let alert = UIAlertController(title: "Error", message: "url is invalid.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        self.urlTextField.resignFirstResponder()
        return true
    }
    
    
    // MARK: UITableViewDataSourceDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.files[indexPath.row] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let path = URL(fileURLWithPath: self.dir[0]).appendingPathComponent(self.files[indexPath.row] as! String).path  as String!{
            dic = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
            dic?.presentOpenInMenu(from: CGRect.zero, in: self.view, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        // Delete
        if(editingStyle == UITableViewCellEditingStyle.delete){
            if let path = URL(fileURLWithPath: self.dir[0]).appendingPathComponent(self.files[indexPath.row] as! String).path as String! {
                do {
                    // Remove file
                    try FileManager().removeItem(atPath: path)
                    self.files.removeObject(at: indexPath.row)
                    // Reload table
                    self.pdfTableView.reloadData()
                } catch {
                    // Alert
                    let alert = UIAlertController(title: "Failed", message: "\(error)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    
    // MARK: - NSURLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL){
        let data = try! Data(contentsOf: location)
        if data.count > 0 {
            let path =
            URL(fileURLWithPath: self.dir[0]).appendingPathComponent(self.files[self.files.count-1] as! String).path
            try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var result = "Success"
        var message = ""
        if error == nil{
            session.finishTasksAndInvalidate()
        } else {
            session.invalidateAndCancel()
            self.files.removeLastObject()
            result = "Failed"
            message = (error.debugDescription)
        }
        // Alert
        let alert = UIAlertController(title: result, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        // Reload table
        self.pdfTableView.reloadData()
    }
}

