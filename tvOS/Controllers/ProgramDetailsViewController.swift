//
//  ProgramDetailsViewController.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-25.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit
import AlamofireImage

class ProgramDetailsViewController : UIViewController {
    
    //MARK: IBOutlets
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var imageViewHeight: NSLayoutConstraint?
    
    @IBOutlet var logoImageView: UIImageView?
    @IBOutlet var logoImageViewWidth: NSLayoutConstraint?
    @IBOutlet var logoImageViewHeight: NSLayoutConstraint?
    @IBOutlet var backgroundImageView: UIImageView?
    
    @IBOutlet var containerView: UIView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var timesLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var recordButton: UIButton?
    
    @IBOutlet var loadingIndicatorView: UIActivityIndicatorView?
    
    var program: TVProgram? { didSet { self.updateView() } }
    
    //MARK: View
    
    weak override internal var preferredFocusedView: UIView? { get { return self.view } }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recordButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        self.logoImageView?.layer.shadowRadius = 5.0
        self.logoImageView?.layer.shadowOpacity = 0.7
        self.logoImageView?.layer.shadowColor = UIColor.black.cgColor
        self.logoImageView?.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.imageView?.layer.shadowRadius = 15.0
        self.imageView?.layer.shadowOpacity = 0.7
        self.imageView?.layer.shadowColor = UIColor.black.cgColor
        self.imageView?.layer.shadowOffset = CGSize(width: 0, height: 1)

        self.setLoading(true, animated: false)
        self.updateView()
    }
    
    func updateView() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        if let program = self.program {
            self.timesLabel?.text = "\(dateFormatter.string(from: program.startDate as Date)) • \(timeFormatter.string(from: program.startDate as Date)) • \(Int(program.runtime / 60))mins"
            
            if program.episodeTitle.characters.count > 0 {
                let string = NSMutableAttributedString(string: program.episodeTitle, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30)])

                string.append(NSAttributedString(string: "\n" + program.description))
                self.descriptionLabel?.attributedText = string
            }
            else {
                self.descriptionLabel?.text = program.description
            }

            self.recordButton?.setTitle(program.isDVRScheduled ? "Cancel Recording" : "Record" , for: UIControlState())

            //Images
            TVImageService.sharedInstance.fillProgramImages([program]) { _ in
                //Poster
                
                if let imageURL = (program.images?.posterImageURL ?? program.images?.thumbImageURL ?? program.imageURL) {
                    self.imageView?.af_setImage(withURL: imageURL, placeholderImage: nil, filter: nil, imageTransition: UIImageView.ImageTransition.noTransition) {
                        response in
                        if let image = response.result.value {
                            self.view.setNeedsLayout()
                            self.view.layoutIfNeeded()
                            
                            self.imageView?.image = image
                            self.imageViewHeight?.constant = image.size.height / image.size.width * self.imageView!.frame.size.width
                            
                            if (imageURL == program.imageURL && program.images?.backgroundImageURL == nil) {
//                                self.backgroundImageView?.runImageTransition(.crossDissolve(0.3), withImage: image)
                            }
                        }
                    }
                }
                
                //Background
                if let imageURL = program.images?.backgroundImageURL {
                    self.backgroundImageView?.af_setImage(withURL: imageURL, placeholderImage: nil, filter: nil, imageTransition: .crossDissolve(0.3), completion: nil)
                }
                
                //Logo
                if let imageURL = program.images?.logoImageURL {
                    self.titleLabel?.isHidden = true
                    self.logoImageView?.af_setImage(withURL: imageURL, placeholderImage: nil, filter: nil, imageTransition: UIImageView.ImageTransition.noTransition) {
                        response in
                        if let image = response.result.value?.trimmedImaged() {
                            self.logoImageView?.image = image
                            self.logoImageViewHeight?.constant = min(150, image.size.height)
                            self.logoImageViewWidth?.constant = image.size.width / image.size.height * self.logoImageViewHeight!.constant
                            self.titleLabel?.isHidden = true
                        }
                        else {
                            self.logoImageViewHeight?.constant = self.titleLabel!.frame.size.height
                            self.titleLabel?.text = program.title
                        }
                        
                        self.setLoading(false, animated: true)
                    }
                }
                else {
                    self.titleLabel?.text = program.title
                    self.titleLabel?.sizeToFit()
                    self.logoImageViewHeight?.constant = self.titleLabel!.frame.size.height
                    self.setLoading(false, animated: true)
                }
            }
        }
    }
    
    func setLoading(_ loading: Bool, animated: Bool) {
        if (animated) {
            UIView.animate(withDuration: 0.3, animations: {
                self.loadingIndicatorView?.alpha = loading ? 1.0 : 0.0
                self.containerView?.alpha = loading ? 0.0 : 1.0
                self.imageView?.alpha = self.containerView?.alpha ?? 1.0
            }) 
        }
        else {
            self.loadingIndicatorView?.alpha = loading ? 1.0 : 0.0
            self.containerView?.alpha = loading ? 0.0 : 1.0
            self.imageView?.alpha = self.containerView?.alpha ?? 1.0
        }
    }
    
    //MARK: Actions
    
    @IBAction func didPressRecord() -> Void {
        if let program = self.program {
            TVService.sharedInstance.toggleProgramRecording(!program.isDVRScheduled, program: program) { success, error in
                if success {
                    self.recordButton?.setTitle(program.isDVRScheduled ? "Cancel Recording" : "Record" , for: UIControlState())
                }
                else {
                    let controller = UIAlertController(title: "An Error Occured", message: error?.localizedDescription, preferredStyle: .alert)
                    controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(controller, animated: true, completion: nil)
                }
            }
        }
    }
    
}

extension UIImage {
    func trimmedRect() -> CGRect {
        guard let cgImage = self.cgImage, let context = self.RGBABitmapContext() else { return CGRect.zero }
        
        let height = Int(cgImage.height)
        let width = Int(cgImage.width)
        
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        context.draw(cgImage, in: rect)
        
        guard let data = context.data?.assumingMemoryBound(to: UInt8.self) else { return CGRect.zero }

        var minX = width, minY = height, maxX = 0, maxY = 0
        
        //Filter through data and look for non-transparent pixels.
        for y in 0 ..< height {
            for x in 0 ..< width {
                let pixelIndex = ((width * y + x) * 4) /* 4 is length of RGBA */
                if data[pixelIndex + 3] != 0 { //Alpha value is not 0/transparent. 3 is index in RGBA
                    minX = min(x, minX)
                    maxX = max(x, maxX)
                    minY = min(y, minY)
                    maxY = max(y, maxY)
                }
            }
        }
        
        return CGRect(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX-minX), height: CGFloat(maxY-minY))
    }
    
    func RGBABitmapContext() -> CGContext? {
        guard let image = self.cgImage else { return nil }

        let width = image.width
        let height = image.height
        let bitmapBytesPerRow = width * 4
        let bitmapByteCount = bitmapBytesPerRow * height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapData = malloc(bitmapByteCount)
        if bitmapData == nil {
            return nil
        }
        return CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

    func trimmedImaged() -> UIImage? {
        guard let imageRef = self.cgImage!.cropping(to: self.trimmedRect()) else { return nil }
        return UIImage(cgImage: imageRef)
    }
}
