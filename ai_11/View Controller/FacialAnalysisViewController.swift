//
//  FacialAnalysisViewController.swift
//  ai_11
//
//  Created by JunHyuk on 2017. 12. 8..
//  Copyright © 2017년 com.JunHyuk. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class FacialAnalysisViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let emotionsDic = [
        "Sad" : "슬픔",
        "Fear" : "두려움",
        "Happy" : "기쁨",
        "Angry" : "분노",
        "Neutral" : "중립",
        "Surprise" : "놀람",
        "Disgust" : "혐오감"]
    
    let genderDic = ["Male" : "남성", "Female" : "여성"]
    
    var selectedImage: UIImage? {
        didSet {
            self.blurredImageView.image = selectedImage
            self.selectedImageView.image = selectedImage
        }
    }
    
    var selectedCiImage: CIImage? {
        get {
            if let selectedImage = self.selectedImage {
                return CIImage(image: selectedImage)
            } else {
                return nil
            }
        }
    }
    
    var selectedFace: UIImage? {
        didSet {
            if let selectedFace = self.selectedFace {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.performFaceAnalysis(on: selectedFace)
                }
            }
        }
    }
    var faceImageViews = [UIImageView]()
    var requests = [VNRequest]()

    @IBOutlet weak var blurredImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var facesScrollView: UIScrollView!
    
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderIdentiLabel: UILabel!
    @IBOutlet weak var genderConfiLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var ageIdentiLabel: UILabel!
    @IBOutlet weak var ageConfiLabel: UILabel!
    
    @IBOutlet weak var emotionLabel: UILabel!
    @IBOutlet weak var emotionIdentiLabel: UILabel!
    @IBOutlet weak var emotionConfiLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideAllLabels()
        
        do {
            let genderModel = try VNCoreMLModel(for: GenderNet().model)
            self.requests.append(VNCoreMLRequest(model: genderModel, completionHandler: handleGenderClassification))
            
            let ageModel = try VNCoreMLModel(for: AgeNet().model)
            self.requests.append(VNCoreMLRequest(model: ageModel, completionHandler: handleAgeClassification))
            
            let emotionModel = try VNCoreMLModel(for: CNNEmotions().model)
            self.requests.append(VNCoreMLRequest(model: emotionModel, completionHandler: handleEmotionClassification))
            
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func addPhoto(_ sender: UIBarButtonItem) {        //사진 추가하기
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let importFromAlbum = UIAlertAction(title: "앨범에서 가져오기", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        }
        // 앨범에서 가져오는 메소드
        
        let takePhoto = UIAlertAction(title: "카메라로 찍기", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        }
        // 직접 카메라로 사진을 찍는 메소드
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        actionSheet.addAction(importFromAlbum)
        actionSheet.addAction(takePhoto)
        actionSheet.addAction(cancel)
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }   //취소하기     ObjectDetectViewController에 있는 기능을 그대로 가져옴.

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let uiImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.selectedImage = uiImage
            self.removeRectangles()
            self.removeFaceImageViews()
            self.hideAllLabels()

            DispatchQueue.global(qos: .userInitiated).async {
                self.detectFaces()
            }
            //작업이 오래걸리기 때문에 백그라운드 스레드 이용 - DispatchQueue
        }
    }
    
    func detectFaces() {
        if let ciImage = self.selectedCiImage {
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            do {
                try requestHandler.perform([detectFaceRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func handleFaces(request: VNRequest, error: Error?) {
        if let faces = request.results as? [VNFaceObservation] {
            DispatchQueue.main.async {
                self.displayUI(for: faces)
            }
        }
    }
    
    func displayUI(for faces: [VNFaceObservation]) {
        if let faceImage = self.selectedImage {
            let imageRect = AVMakeRect(aspectRatio: faceImage.size, insideRect: self.selectedImageView.bounds)
            
            for (index, face) in faces.enumerated() {
                let w = face.boundingBox.size.width * imageRect.width
                let h = face.boundingBox.size.height * imageRect.width
                let x = face.boundingBox.origin.x * imageRect.width
                let y = imageRect.maxY - (face.boundingBox.origin.y * imageRect.height) - h
                
                let layer = CAShapeLayer()
                layer.frame = CGRect(x: x, y: y, width: w, height: h)
                layer.borderColor = UIColor.red.cgColor
                layer.borderWidth = 1
                self.selectedImageView.layer.addSublayer(layer)
                
                let w2 = face.boundingBox.size.width * faceImage.size.width
                let h2 = face.boundingBox.size.height * faceImage.size.height
                let x2 = face.boundingBox.origin.x * faceImage.size.width
                let y2 = (1 - face.boundingBox.origin.y) * faceImage.size.height - h2
                
                let cropRect = CGRect(x: x2 * faceImage.scale, y: y2 * faceImage.scale, width: w2 * faceImage.scale, height: h2 * faceImage.scale)
                
                if let faceCgImage = faceImage.cgImage?.cropping(to: cropRect) {
                    
                    let faceUiImage = UIImage(cgImage: faceCgImage, scale: faceImage.scale, orientation: .up)
                    let faceImageView = UIImageView(frame: CGRect(x: 90*index, y: 0, width: 80, height: 80))
                    faceImageView.image = faceUiImage
                    faceImageView.isUserInteractionEnabled = true
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(FacialAnalysisViewController.handleFaceImageViewTap(_:)))
                    faceImageView.addGestureRecognizer(tap)
                    
                    self.faceImageViews.append(faceImageView)
                    self.facesScrollView.addSubview(faceImageView)
                }
            }
            
            self.facesScrollView.contentSize = CGSize(width: 90*faces.count - 10, height: 80)
            
        }
    }
    
    func removeRectangles() {
        
        if let sublayers = self.selectedImageView.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    func removeFaceImageViews() {
        
        for faceImageView in self.faceImageViews {
            faceImageView.removeFromSuperview()
        }
        
        self.faceImageViews.removeAll()
    }
    
    @objc func handleFaceImageViewTap(_ sender: UITapGestureRecognizer) {
        
        if let tappedImageView = sender.view as? UIImageView {
            for faceImageView in self.faceImageViews {
                faceImageView.layer.borderWidth = 0
                faceImageView.layer.borderColor = UIColor.clear.cgColor
            }
            
            tappedImageView.layer.borderWidth = 3
            tappedImageView.layer.borderColor = UIColor.blue.cgColor
            
            self.selectedFace = tappedImageView.image
        }
    }
    //objective-c와의 언어 호환성. 같이 공부를 해야한다.
    
    func performFaceAnalysis(on image: UIImage) {
        
        do {
            for request in self.requests {
                let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                try handler.perform([request])
            }
        } catch {
            print(error)
        }
    }
    
    func handleGenderClassification(request: VNRequest, error: Error?) {
        
        if let genderObservation = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.sync {
                self.showGenderLabels(identifier: self.genderDic[genderObservation.identifier]!, confidence: genderObservation.confidence)
            }
            print("gender : \(genderObservation.identifier), confidence : \(genderObservation.confidence)")
        }
    }
    
    func handleAgeClassification(request: VNRequest, error: Error?) {
        
        if let ageObservation = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.sync {
                self.showAgeLabels(identifier: ageObservation.identifier, confidence: ageObservation.confidence)
            }
            print("age : \(ageObservation.identifier), confidence : \(ageObservation.confidence)")
        }
    }
    
    func handleEmotionClassification(request: VNRequest, error: Error?) {
        
        if let emotionObservation = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.sync {
                self.showEmotionLabels(identifier: self.emotionsDic[emotionObservation.identifier]!, confidence: emotionObservation.confidence)
            }
            print("emotion : \(emotionObservation.identifier), confidence : \(emotionObservation.confidence)")
        }
    }
    
    func hideGenderLabes() {
        self.genderLabel.isHidden = true
        self.genderIdentiLabel.isHidden = true
        self.genderConfiLabel.isHidden = true
    }
    
    func showGenderLabels(identifier: String, confidence: Float) {
        self.genderIdentiLabel.text = identifier
        self.genderConfiLabel.text = "\(String(format: "%.1f", confidence * 100))%"
        self.genderLabel.isHidden = false
        self.genderIdentiLabel.isHidden = false
        self.genderConfiLabel.isHidden = false
    }
    
    func hideAgeLabels() {
        self.ageLabel.isHidden = true
        self.ageIdentiLabel.isHidden = true
        self.ageConfiLabel.isHidden = true
    }
    
    func showAgeLabels(identifier: String, confidence: Float) {
        self.ageIdentiLabel.text = identifier
        self.ageConfiLabel.text = "\(String(format: "%.1f", confidence * 100))%"
        self.ageLabel.isHidden = false
        self.ageIdentiLabel.isHidden = false
        self.ageConfiLabel.isHidden = false
    }
    
    func hideEmotionLabels() {
        self.emotionLabel.isHidden = true
        self.emotionIdentiLabel.isHidden = true
        self.emotionConfiLabel.isHidden = true
    }
    
    func showEmotionLabels(identifier: String, confidence: Float) {
        self.emotionIdentiLabel.text = identifier
        self.emotionConfiLabel.text = "\(String(format: "%.1f", confidence * 100))%"
        self.emotionLabel.isHidden = false
        self.emotionIdentiLabel.isHidden = false
        self.emotionConfiLabel.isHidden = false
    }
    
    func hideAllLabels() {
        self.hideAgeLabels()
        self.hideGenderLabes()
        self.hideEmotionLabels()
    }
}
