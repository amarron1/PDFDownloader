//
//  ViewController.swift
//  PDFDownloader
//
//  Created by amarron on 2015/11/25.
//  Copyright © 2015年 amarron. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSURLSessionDownloadDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var urlTextField: UITextField!
    @IBOutlet var pdfTableView: UITableView!
    
    let dir = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory,
        .UserDomainMask, true)
    
    var dic:UIDocumentInteractionController?
    var files:NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pdfTableView.delegate = self
        self.pdfTableView.dataSource = self
        self.urlTextField.delegate = self
        
        do {
            self.files = try NSMutableArray(array: NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.dir[0]))
        } catch {
            print("error:\(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func download(sender: AnyObject) {
        
        if let url = NSURL(string: urlTextField!.text!) {
            // Add files
            self.files.addObject(url.lastPathComponent!)
            
            // Download
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config,
                delegate: self,
                delegateQueue: NSOperationQueue.mainQueue())
            let task = session.downloadTaskWithURL(url)
            task.resume()
        } else {
            // Alert
            let alert = UIAlertController(title: "Error", message: "url is invalid.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        self.urlTextField.resignFirstResponder()
        return true
    }
    
    
    // MARK: UITableViewDataSourceDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.files[indexPath.row] as? String
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let path = NSURL(fileURLWithPath: self.dir[0]).URLByAppendingPathComponent(self.files[indexPath.row] as! String).path {
            dic = UIDocumentInteractionController(URL: NSURL(fileURLWithPath: path))
            dic?.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
        // Delete
        if(editingStyle == UITableViewCellEditingStyle.Delete){
            if let path = NSURL(fileURLWithPath: self.dir[0]).URLByAppendingPathComponent(self.files[indexPath.row] as! String).path {
                do {
                    // Remove file
                    try NSFileManager().removeItemAtPath(path)
                    self.files.removeObjectAtIndex(indexPath.row)
                    // Reload table
                    self.pdfTableView.reloadData()
                } catch {
                    // Alert
                    let alert = UIAlertController(title: "Failed", message: "\(error)", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }

    
    // MARK: - NSURLSessionDownloadDelegate
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL){
        let data = NSData(contentsOfURL: location)!
        if data.length > 0 {
            let path =
            NSURL(fileURLWithPath: self.dir[0]).URLByAppendingPathComponent(self.files[self.files.count-1] as! String).path
            data.writeToFile(path!, atomically: true)
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        var result = "Success"
        var message = ""
        if error == nil{
            session.finishTasksAndInvalidate()
        } else {
            session.invalidateAndCancel()
            self.files.removeLastObject()
            result = "Failed"
            message = (error?.description)!
        }
        // Alert
        let alert = UIAlertController(title: result, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        // Reload table
        self.pdfTableView.reloadData()
    }
}

