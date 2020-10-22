//
//  ViewController.swift
//  nous Review
//
//  Created by Γιώργος Βαράνος on 31/1/20.
//  Copyright © 2020 Γιώργος Βαράνος. All rights reserved.
//

import SceneKit
import MessageUI
import SwiftyJSON

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let productions = ["Advertisment","New Movie","Video Game"]
    let models = ["Android","Horse","Space Cruiser"]
    let canvas = Canvas()
    var works = [Work]()
    // 1: Load .obj file -- later on switch based on pickerview selection
    var scene:SCNScene!
    
    @IBOutlet weak var modelPicker: UIPickerView!
    @IBOutlet weak var productionPicker: UIPickerView!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var descriptionField: UITextField!
    @IBOutlet weak var scene3D: SCNView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet var secButtonsStack: UIStackView!
    @IBOutlet var tableWorks: UITableView!
    @IBOutlet var reviewButton: UIButton!
    @IBOutlet var sortingSegment: UISegmentedControl!
    
    @IBAction func viewClick(_ sender: UIButton) {
        makeButtonDisabled(editButton)
        makeButtonEnabled(viewButton)
        secButtonsStack.isHidden = true
        disableDraw()
    }
    
    @IBAction func editClick(_ sender: UIButton) {
        makeButtonDisabled(viewButton)
        makeButtonEnabled(editButton)
        secButtonsStack.isHidden = false
        enableDraw()
    }
    
    @IBAction func cancelClick(_ sender: UIButton) {
        makeButtonDisabled(editButton)
        makeButtonEnabled(viewButton)
        secButtonsStack.isHidden = true
        disableDraw()
    }
    
    @IBAction func sorting(_ sender: UISegmentedControl) {
        if sortingSegment.selectedSegmentIndex == 0 {
            works.sort(by:  { $0.name < $1.name })
            tableWorks.reloadData()
        }
        else if sortingSegment.selectedSegmentIndex == 1 {
            works.sort(by:  { $0.upload_Date < $1.upload_Date })
            tableWorks.reloadData()
        }
        else if sortingSegment.selectedSegmentIndex == 2 {
            works.sort(by:  { $0.production < $1.production })
            tableWorks.reloadData()
        }
    }
    
    @IBAction func acceptClick(_ sender: UIButton) {
        //Screenshot and send
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        sendMail(imageView: image)
        
        makeButtonDisabled(editButton)
        makeButtonEnabled(viewButton)
        secButtonsStack.isHidden = true
        
        disableDraw()
    }
    
    @IBAction func browseClick(_ sender: UIButton) {
        UserDefaults.standard.set(modelPicker.selectedRow(inComponent: 0), forKey: "selectedRow")
        
        if nameField.text! == "" {
            if descriptionField.text! == "" {
                saveWork(productionID: productionPicker.selectedRow(inComponent: 0), name: "unassigned", date: dateField.text!,description: "unassigned", modelID: modelPicker.selectedRow(inComponent: 0))
            }
            else {
                saveWork(productionID: productionPicker.selectedRow(inComponent: 0), name: "unassigned", date: dateField.text!,description: descriptionField.text!, modelID: modelPicker.selectedRow(inComponent: 0))
            }
        }
        else if descriptionField.text! == "" {
            if nameField.text! != "" {
                saveWork(productionID: productionPicker.selectedRow(inComponent: 0), name: nameField.text!, date: dateField.text!,description: "unassigned", modelID: modelPicker.selectedRow(inComponent: 0))
            }
        }
        else {
            saveWork(productionID: productionPicker.selectedRow(inComponent: 0), name: nameField.text!, date: dateField.text!,description: descriptionField.text!, modelID: modelPicker.selectedRow(inComponent: 0))
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadWorksArray()

        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "MM/dd/yyyy"
        let formattedDate = format.string(from: date)
        
        if dateField != nil {
            dateField.text = formattedDate
        }
        
        if productionPicker != nil {
            productionPicker.delegate = self
            productionPicker.dataSource = self
        }
        
        if modelPicker != nil {
            modelPicker.delegate = self
            modelPicker.dataSource = self
        }
        
        if tableWorks != nil {
            tableWorks.delegate = self
            tableWorks.dataSource = self
            tableWorks.register(UITableViewCell.self, forCellReuseIdentifier: "customcell")
            works.sort(by:  { $0.name < $1.name })
            tableWorks.reloadData()
        }

        // 2: Add camera node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // 3: Place camera
        cameraNode.position = SCNVector3(x: 10, y: 10, z: 100)
        // 4: Set camera on scene
        scene?.rootNode.addChildNode(cameraNode)
                
        
        if scene3D != nil {
            // If you don't want to fix manually the lights
            scene3D.autoenablesDefaultLighting = true
            
            // Allow user to manipulate camera
            scene3D.allowsCameraControl = true
                    
            // Set background color
            scene3D.backgroundColor = UIColor.lightGray
                    
            // Allow user translate image
            scene3D.cameraControlConfiguration.allowsTranslation = false
            
            if UserDefaults.standard.string(forKey: "selectedModel") != nil {
                scene = SCNScene(named: "objects3D.scnassets/" + UserDefaults.standard.string(forKey: "selectedModel")!)
            }
            else {
                switch UserDefaults.standard.integer(forKey: "selectedRow") {
                case 0:
                    scene = SCNScene(named: "objects3D.scnassets/android.obj")
                case 1:
                    scene = SCNScene(named: "objects3D.scnassets/horse.obj")
                case 2:
                    scene = SCNScene(named: "objects3D.scnassets/space_cruiser.obj")
                default:
                    break
                }
            }
            
            // Set scene settings
            scene3D.scene = scene
            UserDefaults.standard.set(nil, forKey: "selectedModel")
            UserDefaults.standard.set(nil, forKey: "selectedRow")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if tableWorks != nil {
            tableWorks.reloadData()
        }
    }
    
    func enableDraw() {
        view.viewWithTag(5)?.insertSubview(canvas, belowSubview: viewButton)
        canvas.backgroundColor = .clear
        canvas.frame = view.frame
    }
    
    func disableDraw() {
        canvas.lines.removeAll()
        canvas.setNeedsDisplay()
        canvas.removeFromSuperview()
    }
    
    func sendMail(imageView: UIImage) {
      if MFMailComposeViewController.canSendMail() {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self;
        mail.setToRecipients(["georgevaranos@gmail.com"])
        mail.setSubject("nousReview New Review")
        mail.setMessageBody("These are some errors", isHTML: false)

        mail.addAttachmentData(imageView.jpegData(compressionQuality: 1.0)!, mimeType: "image/jpeg", fileName: "test.jpeg")
        present(mail, animated: true, completion: nil)
      }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return productions.count
        }
        else {
            return models.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return productions[row]
        }
        else {
            return models[row]
        }
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count
    }

    func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       // Ask for a cell of the appropriate type.
        let cell = tableView.dequeueReusableCell(withIdentifier: "workcell", for: indexPath)
            
       // Configure the cell’s contents with the row and section number.
       // The Basic cell style guarantees a label view is present in textLabel.
        cell.textLabel!.text = works[indexPath.row].name
        cell.detailTextLabel!.text = works[indexPath.row].description + " | " + works[indexPath.row].upload_Date
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        reviewButton.isEnabled = true
        UserDefaults.standard.set(works[tableView.indexPathForSelectedRow!.row].fileName, forKey: "selectedModel")
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            self.works.remove(at: index[1])
            self.saveWorksArray()
            tableView.reloadData()
            
        }
        delete.backgroundColor = .red

        return [delete]
    }
    
    func makeButtonEnabled(_ theBtn: UIButton) {
        theBtn.alpha = 1.0
    }
    
    func makeButtonDisabled(_ theBtn: UIButton) {
        theBtn.alpha = 0.5
    }
    
    func saveWork(productionID:Int, name:String, date:String, description:String,  modelID:Int) {
        let tempWork = Work(name: name, production: productions[productionID], upload_Date: date, fileName: models[modelID].replacingOccurrences(of: " ", with: "_").lowercased() + ".obj", description: description)
        works.append(tempWork)
        saveWorksArray()
    }
    
    func loadWorksArray() {
        do {
            let storedObjItem = UserDefaults.standard.object(forKey: "worksArray")
            let tempWorks = try JSONDecoder().decode([Work].self, from: storedObjItem as! Data)
            if !tempWorks.isEmpty {
                works = tempWorks
            }
        } catch let error {
            print(error)
        }
    }
    
    
     func saveWorksArray() {
        if let encoded = try? JSONEncoder().encode(works) {
            UserDefaults.standard.set(encoded, forKey: "worksArray")
        }
    }
}
