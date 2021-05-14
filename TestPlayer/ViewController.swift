//
//  ViewController.swift
//  TestPlayer
//
//  Created by admin on 11.05.2021.
//  Copyright © 2021 admin. All rights reserved.
//

import UIKit

/*
 {
     audioLink = "https://a.clyp.it/iv1xl24p.mp3";
     author =         {
         name = Aleks;
         picture =             {
             l = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/1024x1024";
             m = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/640x640";
             s = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/360x360";
             url = "https://bandlab-test-images.azureedge.net/v1.0/users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/";
             xs = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/100x100";
         };
     };
     createdOn = "2016-09-23T08:15:13Z";
     id = 0;
     modifiedOn = "2016-09-23T08:15:13Z";
     name = "Song 1";
     picture =         {
         l = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/1024x1024";
         m = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/640x640";
         s = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/360x360";
         url = "https://bandlab-test-images.azureedge.net/v1.0/users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/";
         xs = "https://bandlab-test-images.azureedge.net/v1.0/Users/71c81538-4e88-e511-80c6-000d3aa03fb0/636016633463395803/100x100";
     };
 },
 */
class MyTableViewCell: UITableViewCell{
    
    var cascade=[String:String]()
    var hash_name:String?
    static var hash_images=[String:UIImage]()
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    static func getNextCascade(_ cur:String)->String?{
        switch cur {
        case "xs":
            return "m"
        case "m":
            return "l"
        case "l":
            return "f"//"finish"
        default:
            return nil
        }
    }
    
    func downloadCascade(current cur1:String?){
        guard let cur = cur1
            else {return}
        if let str = self.cascade[cur]  {
            if let url = URL(string:str){
                DispatchQueue.global().async { [weak self] in
                    if let data = try? Data(contentsOf: url) {
                        if let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.myImageView.image = image
                            }
                            let next = MyTableViewCell.getNextCascade(cur)
                            if next != nil {
                                if next == "f"{
                                    DispatchQueue.main.async {
                                        self?.activityIndicator.stopAnimating()
                                        self?.activityIndicator.isHidden = true
                                    }
                                    self?.saveImage(image:image);
                                    if let name = self?.hash_name{
                                        MyTableViewCell.hash_images[name] = image
                                    }
                                }
                                else{
                                    self?.downloadCascade(current:next)
                                }
                            }//next
                            
                            
                        }
                    }
                }
            }
        }
    }
    
    func saveImage(image: UIImage){
        guard self.hash_name != nil else {return}
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return
        }
        do {
            try data.write(to: directory.appendingPathComponent(self.hash_name!)!)
            return
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    func loadImage() -> UIImage? {
        guard self.hash_name != nil else {return nil}
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(self.hash_name!).path)
        }
        return nil
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tracks:NSArray = NSArray()
    let kTracksFile = "tracks.json"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        // Do any additional setup after loading the view.
        if self.jsonFromFile(){
            self.tableView.reloadData()
        }
        else{
            jsonDownload()
        }
        
//        self.tableView.rowHeight = UITableView.automaticDimension
//        self.tableView.estimatedRowHeight = 417
    }

    
    
// MARK: - TableViewSource delegate
    func tableView(_ tableView: UITableView,
                      willDisplay cell: UITableViewCell,
                      forRowAt indexPath: IndexPath){
        cell.backgroundColor = UIColor.clear
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 25.0
        cell.layer.borderWidth = 5
        cell.layer.borderColor = UIColor.systemBackground.cgColor
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return tableView.contentSize.width//UIScreen.main.bounds.width
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyTableViewCell
        
        //setup height
        //let frameWidth = view.bounds.size.width
        let cellFrame = CGRect(x: 0, y: 0, width: tableView.contentSize.width, height: tableView.contentSize.width )
        cell.frame = cellFrame
        
        var songName = "No name"
        var authorName = "Unknown author"
        //var url_img:String?
        if let dd = tracks[indexPath[1]] as? NSDictionary{
            if let n = dd["name"] as? String{
                songName = n
            }
            if let pp = dd["picture"] as? NSDictionary{
                if let p = pp["xs"] as? String {
                    cell.cascade["xs"] = p
                }
                if let p = pp["m"] as? String {
                    cell.cascade["m"] = p
                }
                if let p = pp["l"] as? String {
                    cell.cascade["l"] = p
                }
            }
            if let aa = dd["author"] as? NSDictionary, let n = aa["name"] as? String{
                authorName = n
            }
        }
        
        cell.songLabel?.text = songName
        cell.authorLabel?.text = authorName
        cell.hash_name = authorName+"_"+songName+".jpg"
        
        if let image = MyTableViewCell.hash_images[cell.hash_name!]{
            cell.myImageView.image = image
        }
        else if let image = cell.loadImage(){
            cell.myImageView.image = image
            cell.activityIndicator.isHidden = true
        }
        else{
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
            cell.downloadCascade(current: "xs")
        }
//        if url_img != nil {
//            if let url = URL(string:url_img!){
//                DispatchQueue.global().async { [weak cell] in
//                    if let data = try? Data(contentsOf: url) {
//                        if let image = UIImage(data: data) {
//                            DispatchQueue.main.async {
//                                cell?.myImageView.image = image
//                            }
//                        }
//                    }
//                }
//            }
//        }
        
        //cell.textLabel?.text = songName
        return cell
    }
// MARK: - json download/writting,reading
    func jsonToFile() {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileUrl = documentDirectoryUrl.appendingPathComponent(kTracksFile)

        do {
            let data = try JSONSerialization.data(withJSONObject: tracks, options: [])
            try data.write(to: fileUrl, options: [])
        } catch {
            print(error)
        }
    }
    func jsonFromFile()->Bool {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return false}
        let fileUrl = documentsDirectoryUrl.appendingPathComponent(kTracksFile)
        
        do {
            let data = try Data(contentsOf: fileUrl, options: [])
            guard let arr = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray
                else { return false}
            self.tracks = arr;
        } catch {
            print(error)
            return false
        }
        return true
    }
    func jsonDownload() {

        let urlPath = "https://gist.githubusercontent.com/anonymous/fec47e2418986b7bdb630a1772232f7d/raw/5e3e6f4dc0b94906dca8de415c585b01069af3f7/57eb7cc5e4b0bcac9f7581c8.json"
        
//        let url = URL(string:urlPath)
//        url_dict = NSDictionary(contentsOf: url!) ?? NSDictionary()
//        print(url_dict)
        
        let session = URLSession.shared
        let url = URL(string: urlPath)!

        let task = session.dataTask(with: url) { data, response, error in

            if error != nil || data == nil {
                print("Client error!")
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                //print(type(of:json))
                //print(json)
                if let d = json as? [String : Any] {
                    if let arr = d["data"] as? NSArray{
                        self.tracks = arr
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        self.jsonToFile()
                    }
                }
                //print(d["data"]!)
//                let arr = d["data"] as! NSArray
//                print(arr)
////                for a in arr {
////                    let dd = a as! NSDictionary
////                    print(dd["audioLink"]!)
////                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        }

        task.resume()
        
    }

}

