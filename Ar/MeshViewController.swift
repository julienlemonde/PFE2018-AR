//
//	This file is a Swift port of the Structure SDK sample app "Scanner".
//	Copyright © 2016 Occipital, Inc. All rights reserved.
//	http://structure.io
//
//  MeshViewController.swift
//
//  Ported by Christopher Worley on 8/20/16.
//

import MessageUI
import ImageIO

protocol MeshViewDelegate: class {
    
    func meshViewWillDismiss()
    func meshViewDidDismiss()
    func meshViewDidRequestColorizing(mesh: STMesh,  previewCompletionHandler: @escaping () -> Void, enhancedCompletionHandler: @escaping () -> Void) -> Bool
}

public class MeshViewController: UIViewController, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate {
	
    weak var delegate : MeshViewDelegate?

	// force the view to redraw.
    var needsDisplay: Bool = false
    var colorEnabled: Bool = false
	
	private var _mesh: STMesh? = nil
    var mesh: STMesh? {
        get {
            return _mesh
        }
        set {
            _mesh = newValue
            
            if _mesh != nil {
                
                self.renderer!.uploadMesh(mesh: _mesh!)
                self.trySwitchToColorRenderingMode()
                self.needsDisplay = true
            }
        }
    }

	var projectionMatrix: GLKMatrix4 = GLKMatrix4Identity
    {
		didSet {
            setCameraProjectionMatrix(projection: projectionMatrix)
		}
	}
    
	var volumeCenter = GLKVector3Make(0,0,0)
    {
		didSet {
            resetMeshCenter(center: volumeCenter)
		}
	}
    
	@IBOutlet weak var eview: EAGLView!
	@IBOutlet weak var displayControl: UISegmentedControl!
	@IBOutlet weak var meshViewerMessageLabel: UILabel!
	
    var displayLink: CADisplayLink?
    var renderer: MeshRenderer!
    var viewpointController: ViewpointController!
    var viewport = [GLfloat](repeating: 0, count: 4)
    var modelViewMatrixBeforeUserInteractions: GLKMatrix4?
    var projectionMatrixBeforeUserInteractions: GLKMatrix4?
	
    var mailViewController: MFMailComposeViewController?
	
    required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

    }

    override public func viewDidLoad() {
		
        super.viewDidLoad()

        renderer = MeshRenderer.init()
        
		viewpointController = ViewpointController.init(screenSizeX: Float(self.view.frame.size.width), screenSizeY: Float(self.view.frame.size.height))
		
        let font = UIFont.boldSystemFont(ofSize: 14)
        let attributes: [NSObject : AnyObject] = [NSAttributedStringKey.font as NSObject : font]
        
        displayControl.setTitleTextAttributes(attributes, for: .normal)
		
        renderer.setRenderingMode(mode: .LightedGray)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
        if displayLink != nil {
            displayLink!.invalidate()
            displayLink = nil
        }
        
        displayLink = CADisplayLink(target: self, selector: #selector(MeshViewController.draw))
        displayLink!.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
		
        viewpointController.reset()
		
        if !colorEnabled {
            displayControl.removeSegment(at: 2, animated: false)
        }
    }
    
    // Make sure the status bar is disabled (iOS 7+)
    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

    override public func didReceiveMemoryWarning () {
        
    }
    
    func setupGL (context: EAGLContext) {

        (self.view as! EAGLView).context = context

        EAGLContext.setCurrent(context)

        renderer.initializeGL( defaultTextureUnit: GLenum(GL_TEXTURE3))

        self.eview.setFramebuffer()
        
        let framebufferSize: CGSize = self.eview.getFramebufferSize()
		
        var imageAspectRatio: CGFloat = 1
		
        // The iPad's diplay conveniently has a 4:3 aspect ratio just like our video feed.
        // Some iOS devices need to render to only a portion of the screen so that we don't distort
        // our RGB image. Alternatively, you could enlarge the viewport (losing visual information),
        // but fill the whole screen.
        if abs(framebufferSize.width / framebufferSize.height - 640.0 / 480.0) > 1e-3 {
            imageAspectRatio = 480.0 / 640.0
        }
		
        viewport[0] = Float(framebufferSize.width - framebufferSize.width * imageAspectRatio) / 2
        viewport[1] = 0
        viewport[2] = Float(framebufferSize.width * imageAspectRatio)
        viewport[3] = Float(framebufferSize.height)
    }
    
	@IBAction func dismissView(_ sender: AnyObject) {

		displayControl.selectedSegmentIndex = 1
        renderer.setRenderingMode(mode: .LightedGray)
		
        if delegate?.meshViewWillDismiss != nil {
            delegate?.meshViewWillDismiss()
        }
		
        renderer.releaseGLBuffers()
        renderer.releaseGLTextures()
		
        displayLink!.invalidate()
        displayLink = nil
		
        mesh = nil

        self.eview.context = nil

        dismiss(animated: true, completion: {
			if self.delegate?.meshViewDidDismiss != nil {
				self.delegate?.meshViewDidDismiss()
			}
		})
    }
	
	//MARK: - MeshViewer setup when loading the mesh
    
    func setCameraProjectionMatrix (projection: GLKMatrix4) {

        viewpointController.setCameraProjection(projRt: projection)
        projectionMatrixBeforeUserInteractions = projection
    }
    
    func resetMeshCenter (center: GLKVector3) {

        viewpointController.reset()
        viewpointController.setMeshCenter(center: center)
        modelViewMatrixBeforeUserInteractions = viewpointController.currentGLModelViewMatrix()
    }
	
	func saveJpegFromRGBABuffer( filename: String, src_buffer: UnsafeMutablePointer<Void>, width: Int, height: Int)
	{
		let file: UnsafeMutablePointer<FILE>? = fopen(filename, "w")
		if file == nil {
			return
		}
        
		var colorSpace: CGColorSpace?
		var alphaInfo: CGImageAlphaInfo!
		var bmcontext: CGContext?
		colorSpace = CGColorSpaceCreateDeviceRGB()
        alphaInfo = .noneSkipLast

        bmcontext = CGContext(data: src_buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace!, bitmapInfo: alphaInfo.rawValue)!
        var rgbImage: CGImage? = bmcontext!.makeImage()

		bmcontext = nil
		colorSpace = nil
		
		var jpgData: CFMutableData? = CFDataCreateMutable(nil, 0)
        var imageDest: CGImageDestination? = CGImageDestinationCreateWithData(jpgData!, "public.jpeg" as CFString, 1, nil)

		var kcb = kCFTypeDictionaryKeyCallBacks
		var vcb = kCFTypeDictionaryValueCallBacks
		
        // Our empty IOSurface properties dictionary
		var options: CFDictionary? = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, &kcb, &vcb)
		
		CGImageDestinationAddImage(imageDest!, rgbImage!, options!)
		CGImageDestinationFinalize(imageDest!)
		
		imageDest = nil
		rgbImage = nil
		options = nil

		fwrite(CFDataGetBytePtr(jpgData!), 1, CFDataGetLength(jpgData!), file!)
		fclose(file!)
		
		jpgData = nil
	}
	
    //MARK: Email Mesh OBJ File
	public func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        mailViewController?.dismiss(animated: true, completion: nil)
	}

    func prepareScreenShot (screenshotPath: String) {
		
        let width: Int32 = 320
        let height: Int32 = 240
        var currentFrameBuffer: GLint = 0
		
        glGetIntegerv( GLenum(GL_FRAMEBUFFER_BINDING), &currentFrameBuffer)
		
        // Create temp texture, framebuffer, renderbuffer
        glViewport(0, 0, width, height)
		
        var outputTexture: GLuint = 0
        glActiveTexture( GLenum(GL_TEXTURE0))
        glGenTextures(1, &outputTexture)
        glBindTexture( GLenum(GL_TEXTURE_2D), outputTexture)
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexImage2D( GLenum(GL_TEXTURE_2D), 0, GL_RGBA, width, height, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
		
        var colorFrameBuffer: GLuint = 0
        var depthRenderBuffer: GLuint = 0

        glGenFramebuffers(1, &colorFrameBuffer)
        glBindFramebuffer( GLenum(GL_FRAMEBUFFER), colorFrameBuffer)
        glGenRenderbuffers(1, &depthRenderBuffer)
		glBindRenderbuffer( GLenum(GL_RENDERBUFFER), depthRenderBuffer)
		
        glRenderbufferStorage( GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), width, height)
        glFramebufferRenderbuffer( GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthRenderBuffer)
        glFramebufferTexture2D( GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), outputTexture, 0)
        
        // Keep the current render mode
        let previousRenderingMode: MeshRenderer.RenderingMode = renderer!.getRenderingMode()
		
        let meshToRender: STMesh = self.mesh!
        
        // Screenshot rendering mode, always use colors if possible.
        if meshToRender.hasPerVertexUVTextureCoords() && meshToRender.meshYCbCrTexture() != nil {
			
            renderer!.setRenderingMode(mode: .Textured)
			
        } else if meshToRender.hasPerVertexColors() {
			
            renderer!.setRenderingMode(mode: .PerVertexColor)
        
        } else {
            // meshToRender can be nil if there is no available color mesh.
            renderer!.setRenderingMode(mode: .LightedGray)
        }
        
        // Render from the initial viewpoint for the screenshot.
        renderer!.clear()

        withUnsafeMutablePointer(to: &projectionMatrixBeforeUserInteractions, { proj in withUnsafePointer(to: &modelViewMatrixBeforeUserInteractions, { viewP in
            renderer!.render(projectionMatrix: UnsafeRawPointer(proj).assumingMemoryBound(to: GLfloat.self), modelViewMatrix: UnsafeRawPointer(viewP).assumingMemoryBound(to: GLfloat.self))
        }) } )
		
        // Back to current render mode
        renderer!.setRenderingMode(mode: previousRenderingMode)
        
        var screenShotRgbaBuffer = [UInt32](repeating: 0, count: Int(width*height))

        var screenTopRowBuffer = [UInt32](repeating: 0, count: Int(width))
        
        var screenBottomRowBuffer = [UInt32](repeating: 0, count: Int(width))
        
        glReadPixels(0, 0, width, height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &screenShotRgbaBuffer)

        // flip the buffer
		for h in 0..<height/2 {
            
            glReadPixels(0, h, width, 1, UInt32(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), &screenTopRowBuffer)
            
            glReadPixels(0, (height - h - 1), width, 1, UInt32(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), &screenBottomRowBuffer)
            
            let topIdx = Int(width * h)
            let bottomIdx = Int(width * (height - h - 1))

            withUnsafePointer(to: &screenShotRgbaBuffer[topIdx], { fristP in withUnsafePointer(to: &screenBottomRowBuffer[0], { lastP in
                memcpy(UnsafeMutableRawPointer(mutating: fristP).assumingMemoryBound(to: Void.self), UnsafeMutableRawPointer(mutating: lastP).assumingMemoryBound(to: Void.self), Int(width) * MemoryLayout<UInt32>.size)
            })})
            
            withUnsafePointer(to: &screenShotRgbaBuffer[bottomIdx], { fristP in withUnsafePointer(to: &screenTopRowBuffer[0], { lastP in
                memcpy(UnsafeMutableRawPointer(mutating: fristP).assumingMemoryBound(to: Void.self), UnsafeMutableRawPointer(mutating: lastP).assumingMemoryBound(to: Void.self), Int(width) * MemoryLayout<UInt32>.size)
            })})
		}

        saveJpegFromRGBABuffer(filename: screenshotPath, src_buffer: &screenShotRgbaBuffer, width: Int(width), height: Int(height))

        // Back to the original frame buffer
        glBindFramebuffer( GLenum(GL_FRAMEBUFFER), GLenum(currentFrameBuffer))
        glViewport( GLint(viewport[0]), GLint(viewport[1]), GLint(viewport[2]), GLint(viewport[3]))
		
        // Free the data
        glDeleteTextures(1, &outputTexture)
        glDeleteFramebuffers(1, &colorFrameBuffer)
        glDeleteRenderbuffers(1, &depthRenderBuffer)
    }

	@IBAction func emailMesh(_ sender: AnyObject) {
        
		mailViewController = MFMailComposeViewController.init()
		
		if mailViewController == nil {
            let alert = UIAlertController.init(title: "The email could not be sent.", message: "Please make sure an email account is properly setup on this device.", preferredStyle: .alert)

            let defaultAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
			
			alert.addAction(defaultAction)
	
            present(alert, animated: true, completion: nil)
			
			return
		}
		
		mailViewController!.mailComposeDelegate = self
		
        if UIDevice.current.userInterfaceIdiom == .pad {
            mailViewController!.modalPresentationStyle = .formSheet
		}
        
        //ALERT TO ASK NAME NEW OF MODEL
        var modelName = ""
        let alert = UIAlertController(title: "Save Model", message: "Please choose a unique name for your new model", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = "NewModel"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            modelName = (textField?.text?.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))!
            print("MALO-MODELNAME_ENTERED")
            print(modelName)
            if(!modelName.isEmpty){
                //var modelPath = FileMgr.sharedInstance.root() as String
                var modelPath = FileMgr.sharedInstance.root() as String
                modelPath += "/scannerCache/scannedObjs"
                do {
                    try FileManager.default.createDirectory(atPath: modelPath, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("MALO_FAILED_TO_ADD_DIRECTORY_ScannedObjs")
                    print(error.localizedDescription);
                }
//                modelPath += "/"
//                modelPath += modelName
//                print("MALO-MODELFULLPATH")
//                print(modelPath)
//                do {
//                    try FileManager.default.createDirectory(atPath: modelPath, withIntermediateDirectories: true, attributes: nil)
//                } catch let error as NSError {
//                    print("MALO_FAILED_TO_ADD_DIRECTORY_FULLPATH")
//                    print(error.localizedDescription);
//                }
                var modelPath2 = "/scannedObjs/"
                var modelFileName = modelPath2
                modelFileName += "\(modelName).zip"
                print("MALO-MODELFULLPATH_OBJMODEL")
                print(modelFileName)
                print("MALO-SAVING_ZIP")
                //ileMgr.sharedInstance.saveMeshObj(name: modelFileName, data: self.mesh!)
                if let meshToSend = self.mesh {
                    let zipfile = FileMgr.sharedInstance.saveMesh(name: modelFileName, data: meshToSend)
                    print("Unzipping...")
                    var tmpDirectory = NSTemporaryDirectory() as String
                    tmpDirectory += "/\(modelName)"
                    let url = modelPath + "/\(modelName).zip"
                    let unzipSuccess: Bool = SSZipArchive.unzipFile(atPath: url, toDestination: tmpDirectory)
                    print(unzipSuccess)
                }
                print("MALO-SAVED_ZIP")
                
                // Return to the ARScene
                let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainAr") as UIViewController
                
                self.present(viewController, animated: true, completion: nil)
//
            }
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
		// Setup paths and filenames.
		let zipFilename = "Model.zip"
		let screenshotFilename = "Preview.jpg"

        let fullPathFilename = FileMgr.sharedInstance.full(name: screenshotFilename)
  
        FileMgr.sharedInstance.del(name: screenshotFilename)
		
		// Take a screenshot and save it to disk.
		
        prepareScreenShot(screenshotPath: fullPathFilename)

		// since file is save in prepareScreenShot() need to getData() here
		
		if let sshot = NSData(contentsOfFile: fullPathFilename) {
		
            mailViewController?.addAttachmentData(sshot as Data, mimeType: "image/jpeg", fileName: screenshotFilename)
		}
		else {
            let alert = UIAlertController.init(title: "Error", message: "no pic", preferredStyle: .alert)
			
            let defaultAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
			
			alert.addAction(defaultAction)
			
            present(alert, animated: true, completion: nil)
		}
		
		mailViewController!.setSubject("3D Model")
		
		let messageBody = "This model was captured with the open source Scanner sample app in the Structure SDK.\n\nCheck it out!\n\nMore info about the Structure SDK: http://structure.io/developers";
		
		mailViewController?.setMessageBody(messageBody, isHTML: false)

		if let meshToSend = mesh {
            let zipfile = FileMgr.sharedInstance.saveMesh(name: zipFilename, data: meshToSend)
            
            if zipfile != nil {
                mailViewController?.addAttachmentData(zipfile! as Data, mimeType: "application/zip", fileName: zipFilename)
            }
        }
		else {

			mailViewController = nil
			
            let alert = UIAlertController.init(title: "The email could not be sent", message: "Exporting the mesh failed", preferredStyle: .alert)
			
            let defaultAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
			
			alert.addAction(defaultAction)
			
            present(alert, animated: true, completion: nil)
			
			return
		}

        present(mailViewController!, animated: true, completion: nil)
    }
	
    //MARK: Rendering
	
    @objc func draw () {
        
        self.eview.setFramebuffer()
		
        glViewport(GLint(viewport[0]), GLint(viewport[1]), GLint(viewport[2]), GLint(viewport[3]))
        
        let viewpointChanged = viewpointController.update()
		
        // If nothing changed, do not waste time and resources rendering.
        if !needsDisplay && !viewpointChanged {
            return
        }
		
        var currentModelView = viewpointController.currentGLModelViewMatrix()
        var currentProjection = viewpointController.currentGLProjectionMatrix()
        
        renderer!.clear()
        
        withUnsafeMutablePointer(to: &currentProjection, { proj in withUnsafePointer(to: &currentModelView, { viewP in
            renderer!.render(projectionMatrix: UnsafeRawPointer(proj).assumingMemoryBound(to: GLfloat.self), modelViewMatrix: UnsafeRawPointer(viewP).assumingMemoryBound(to: GLfloat.self))
        }) } )
 
        needsDisplay = false
		
        self.eview.presentFramebuffer()
    }
	
    //MARK: Touch & Gesture Control
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            viewpointController.onTouchBegan()
        }
    }
	
	@IBAction func pinchScaleGesture(_ sender: UIPinchGestureRecognizer) {

        // Forward to the ViewpointController.
        if sender.state == .began {
            viewpointController.onPinchGestureBegan(scale: Float(sender.scale))
        }
        else if sender.state == .changed {
            viewpointController.onPinchGestureChanged(scale: Float(sender.scale))
        }
    }
    
	@IBAction func oneFingerPanGesture(_ sender: UIPanGestureRecognizer) {

        let touchPos = sender.location(in: view)
        let touchVel = sender.velocity(in: view)
        let touchPosVec = GLKVector2Make(Float(touchPos.x), Float(touchPos.y))
        let touchVelVec = GLKVector2Make(Float(touchVel.x), Float(touchVel.y))
		
        if sender.state == .began {
            viewpointController.onOneFingerPanBegan(touch: touchPosVec)
        }
        else if sender.state == .changed {
            viewpointController.onOneFingerPanChanged(touch: touchPosVec)
        }
        else if sender.state == .ended {
            viewpointController.onOneFingerPanEnded(vel: touchVelVec)
        }
    }
	
	@IBAction func twoFingersPanGesture(_ sender: UIPanGestureRecognizer) {

        if sender.numberOfTouches != 2 {
            return
        }
	
        let touchPos = sender.location(in: view)
        let touchVel = sender.velocity(in: view)
		let touchPosVec = GLKVector2Make(Float(touchPos.x), Float(touchPos.y))
		let touchVelVec = GLKVector2Make(Float(touchVel.x), Float(touchVel.y))
		
        if sender.state == .began {
            viewpointController.onTwoFingersPanBegan(touch: touchPosVec)
        }
        else if sender.state == .changed {
            viewpointController.onTwoFingersPanChanged(touch: touchPosVec)
        }
        else if sender.state == .ended {
            viewpointController.onTwoFingersPanEnded(vel: touchVelVec)
        }
    }

    //MARK: UI Control
    
    func trySwitchToColorRenderingMode() {
   
        // Choose the best available color render mode, falling back to LightedGray
        // This method may be called when colorize operations complete, and will
        // switch the render mode to color, as long as the user has not changed
        // the selector.
		
        if displayControl.selectedSegmentIndex == 2 {
			
			if	mesh!.hasPerVertexUVTextureCoords() {
              
                renderer.setRenderingMode(mode: .Textured)
			}
			else if mesh!.hasPerVertexColors() {
             
                renderer.setRenderingMode(mode: .PerVertexColor)
			}
			else {
            
                renderer.setRenderingMode(mode: .LightedGray)
			}
		}
    }
    
    @IBAction func displayControlChanged(_ sender: AnyObject) {

        switch displayControl.selectedSegmentIndex {
		case 0: // x-ray
          
            renderer.setRenderingMode(mode: .XRay)
			
		case 1: // lighted-gray
         
            renderer.setRenderingMode(mode: .LightedGray)
			
        case 2: // color
            
            trySwitchToColorRenderingMode()
			
            let meshIsColorized: Bool = mesh!.hasPerVertexColors() || mesh!.hasPerVertexUVTextureCoords()
			
            if !meshIsColorized {
              
                colorizeMesh()
			}

			default:
				break
		}
		
		needsDisplay = true
	}
    
    func colorizeMesh() {
        
        delegate?.meshViewDidRequestColorizing(mesh: self.mesh!, previewCompletionHandler: {
            }, enhancedCompletionHandler: {
                
                // Hide progress bar.
                self.hideMeshViewerMessage()
        })
    }
    
    func hideMeshViewerMessage() {
        
        UIView.animate(withDuration: 0.5, animations: {
            self.meshViewerMessageLabel.alpha = 0.0
            }, completion: { _ in
                self.meshViewerMessageLabel.isHidden = true
        })
    }
    
    func showMeshViewerMessage(msg: String) {
        
        meshViewerMessageLabel.text = msg
        
        if meshViewerMessageLabel.isHidden == true {
            
            meshViewerMessageLabel.alpha = 0.0
            meshViewerMessageLabel.isHidden = false
            
            UIView.animate(withDuration: 0.5, animations: {
                self.meshViewerMessageLabel.alpha = 1.0
            })
        }
    }
}

