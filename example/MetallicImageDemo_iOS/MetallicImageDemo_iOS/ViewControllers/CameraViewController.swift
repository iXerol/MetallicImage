import AVFoundation
import MetallicImage
import Photos
import UIKit

class CameraViewController: UIViewController {
    let imageView = ImageView(frame: .zero)
    var camera: Camera?

    var isRecording = false
    var movieOutput: MovieOutput?

    let recordButton = UIButton(type: .custom)
    let fileURL = URL(string: "recorded.mov", relativeTo: try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true))!
    private let dispatchQueue = DispatchQueue(label: "com.MetallicImageDemo.saveVideoProcess")

    lazy var devices: [AVCaptureDevice] = {
        var devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
                                                       mediaType: .video,
                                                       position: .back).devices
        devices.append(contentsOf: AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices)
        return devices
    }()

    lazy var cameraSegmentedControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: devices.map { $0.localizedName })
        segmentControl.selectedSegmentIndex = 0
        segmentControl.apportionsSegmentWidthsByContent = true
        return segmentControl
    }()

    func generateRedSquare(slideLength: Int) -> UIImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: slideLength, height: slideLength))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    @objc
    func segmentedControlDidChangeValue(sender: UISegmentedControl) {
        setCamera(device: devices[sender.selectedSegmentIndex])
        camera?.runBenchmark = true
        camera?.addTarget(imageView)
        camera?.startCapture()
    }

    @objc
    func recordButtonTapped(sender: UIButton) {
        if !isRecording {
            do {
                isRecording = true
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {}
                (navigationController as? NavigationController)?.autoRotate = false
                guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                    return
                }
                switch orientation {
                case .unknown:
                    break
                case .portrait, .portraitUpsideDown:
                    movieOutput = try MovieOutput(URL: fileURL, width: 1080, height: 1920, videoCodec: .hevc)
                case .landscapeLeft, .landscapeRight:
                    movieOutput = try MovieOutput(URL: fileURL, width: 1920, height: 1080, videoCodec: .hevc)
                @unknown default:
                    break
                }
                camera?.addTarget(movieOutput!)
                movieOutput?.startRecording()
                let redImage: UIImage! = generateRedSquare(slideLength: 5)
                sender.setImage(redImage, for: .normal)
                cameraSegmentedControl.isEnabled = false
            } catch {
                fatalError("Couldn't initialize movie, error: \(error)")
            }
        } else {
            movieOutput?.finishRecording { [weak self] in
                guard let self = self else {
                    return
                }
                self.isRecording = false
                DispatchQueue.main.async {
                    let redImage: UIImage! = self.generateRedSquare(slideLength: 25)
                    sender.setImage(redImage, for: .normal)
                    self.cameraSegmentedControl.isEnabled = true
                    (self.navigationController as? NavigationController)?.autoRotate = true
                }
                self.movieOutput = nil
                self.saveVideo()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = NSLocalizedString("Camera", comment: "Camera")

        view.addSubview(cameraSegmentedControl)
        cameraSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        cameraSegmentedControl.addTarget(self, action: #selector(segmentedControlDidChangeValue(sender:)), for: .valueChanged)
        NSLayoutConstraint.activate([
            cameraSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            cameraSegmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cameraSegmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        imageView.backgroundColor = .gray
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cameraSegmentedControl.bottomAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])

        let redImage: UIImage! = generateRedSquare(slideLength: 25)
        recordButton.clipsToBounds = true
        recordButton.layer.cornerRadius = 25
        recordButton.layer.borderColor = UIColor.white.cgColor
        recordButton.layer.borderWidth = 3
        recordButton.setImage(redImage, for: .normal)
        recordButton.addTarget(self, action: #selector(recordButtonTapped(sender:)), for: .touchUpInside)
        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -25),
            recordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 50),
            recordButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        guard !devices.isEmpty else {
            #if targetEnvironment(macCatalyst)
            let message = NSLocalizedString("Not_Support_Catalyst", comment: "Mac apps built with Mac Catalyst can’t use the AVFoundation Capture classes.")
            #else
            let message = NSLocalizedString("No_Camera", comment: "There's no camera")
            #endif
            let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
            present(alertController, animated: true, completion: nil)
            return
        }
        setCamera(device: devices[0])
        camera?.addTarget(imageView)
        camera?.runBenchmark = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera?.startCapture()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setCameraOrientation()
    }

    func setCameraOrientation() {
        DispatchQueue.main.async {
            guard let camera = self.camera,
                let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                    return
            }
            switch orientation {
            case .portrait:
                camera.orientation = .landscapeLeft
            case .portraitUpsideDown:
                camera.orientation = .landscapeRight
            case .landscapeLeft:
                camera.orientation = .portraitUpsideDown
            case .landscapeRight:
                camera.orientation = .portrait
            case .unknown:
                break
            @unknown default:
                break
            }
            self.imageView.orientation = camera.inputCamera.position == .front ? .portraitMirrored : .portrait
        }
    }

    func setCamera(device: AVCaptureDevice) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            do {
                camera = try Camera(sessionPreset: .hd1920x1080, cameraDevice: device)
                setCameraOrientation()
            } catch Camera.CameraError.noCameraDevice {
                camera = nil
                #if targetEnvironment(macCatalyst)
                let message = NSLocalizedString("Not_Support_Catalyst", comment: "Mac apps built with Mac Catalyst can’t use the AVFoundation Capture classes.")
                #else
                let message = NSLocalizedString("No_Camera", comment: "There's no camera")
                #endif
                let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            } catch {
                camera = nil
                let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                        message: error.localizedDescription,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        case .denied, .restricted:
            let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                    message: NSLocalizedString("Authorize_Camera", comment: "Authorize to access camera"),
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                self.setCamera(device: device)
            }
        @unknown default:
            fatalError("Undefined Photo Library Authorization Status")
        }
    }

    func saveVideo() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            dispatchQueue.sync {
                PHPhotoLibrary.shared().performChanges({
                    _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.fileURL)
                }) { success, error in
                    let alertController: UIAlertController
                    if success {
                        alertController = UIAlertController(title: NSLocalizedString("Save_Video_Success", comment: "Save Video Success Title"),
                                                            message: NSLocalizedString("Save_Video_Message", comment: "Save Video Success Message"),
                                                            preferredStyle: .alert)
                    } else {
                        alertController = UIAlertController(title: NSLocalizedString("Save_Video_Error", comment: "Save Video Error Title"),
                                                            message: error?.localizedDescription,
                                                            preferredStyle: .alert)
                    }
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
                    DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        case .denied, .restricted:
            let alertController = UIAlertController(title: NSLocalizedString("Save_Video_Error", comment: "Save Video Error Title"),
                                                    message: NSLocalizedString("Authorize_Save_Video", comment: "Authorize to save Video"),
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
            present(alertController, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in
                DispatchQueue.main.async {
                    self.saveVideo()
                }
            }
        @unknown default:
            fatalError("Undefined Photo Library Authorization Status")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera?.stopCapture()
        (navigationController as? NavigationController)?.autoRotate = true
    }
}
