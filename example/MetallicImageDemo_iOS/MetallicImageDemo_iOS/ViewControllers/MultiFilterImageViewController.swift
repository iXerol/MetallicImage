import MetallicImage
import Photos
import UIKit

#if canImport(PhotosUI)
import PhotosUI
#endif

class MultiFilterImageViewController: UIViewController {
    private let imageView = ImageView(frame: .zero)
    private let selectImageButton = UIButton()
    private let sourceSegmentedControl = UISegmentedControl(items: [NSLocalizedString("Photo", comment: "Still Photo"),
                                                                    NSLocalizedString("Camera", comment: "Camera")])
    lazy var saveButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(saveImage))

    private var sourceImage = #imageLiteral(resourceName: "Tokyo_Tower") {
        didSet {
            imageInput = PictureInput(image: sourceImage)
            if let filter = filters.first {
                imageInput => filter
            } else {
                imageInput => imageView
            }
            imageInput.processImage()
        }
    }

    private let dispatchQueue = DispatchQueue(label: "com.MetallicImageDemo.saveImageProcess")
    private lazy var imageInput = PictureInput(image: sourceImage)
    private var camera: Camera?
    private lazy var saveImageOutput: PictureOutput = {
        let output = PictureOutput()
        output.imageAvailableCallback = { [weak self] image in
            guard let self = self else {
                return
            }
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                let alertController: UIAlertController
                if success {
                    alertController = UIAlertController(title: NSLocalizedString("Save_Image_Success", comment: "Save Image Success Title"),
                                                        message: NSLocalizedString("Save_Image_Message", comment: "Save Image Success Message"),
                                                        preferredStyle: .alert)
                } else {
                    alertController = UIAlertController(title: NSLocalizedString("Save_Image_Error", comment: "Save Image Error Title"),
                                                        message: error?.localizedDescription,
                                                        preferredStyle: .alert)
                }
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"), style: .default))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        return output
    }()

    private let filters: [BasicFilter]

    init(filters: [BasicFilter]) {
        self.filters = filters
        if filters.count >= 2 {
            for index in 0 ... filters.count - 2 {
                filters[index] => filters[index + 1]
            }
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func selectImage() {
        #if XCODE_12
        if #available(iOS 14, *) {
            presentPHPicker()
        } else {
            presentUIImagePicker()
        }
        #else
        presentUIImagePicker()
        #endif
    }

    #if XCODE_12
    @available(iOS 14.0, *)
    func presentPHPicker() {
        var configutation = PHPickerConfiguration()
        configutation.filter = .any(of: [.images, .livePhotos])
        let pickerViewController = PHPickerViewController(configuration: configutation)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true, completion: nil)
    }
    #endif

    func presentUIImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }

    @objc
    func saveImage() {
        dispatchQueue.sync {
            if let filter = self.filters.last {
                filter.transmitPreviousImage(to: saveImageOutput)
            } else {
                if sourceSegmentedControl.selectedSegmentIndex == 0 {
                    imageInput.transmitPreviousImage(to: saveImageOutput)
                } else {
                    camera?.transmitPreviousImage(to: saveImageOutput)
                }
            }
        }
    }

    @objc
    func segmentedControlDidChangeValue(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            camera?.removeAllTargets()
            selectImageButton.isHidden = false
            camera?.stopCapture()
            if let filter = filters.first {
                imageInput => filter
            } else {
                imageInput => imageView
            }
            imageInput.processImage()
        case 1:
            imageInput.removeAllTargets()
            selectImageButton.isHidden = true
            setCamera()
        default:
            fatalError()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = saveButton

        navigationItem.titleView = sourceSegmentedControl
        sourceSegmentedControl.selectedSegmentIndex = 0
        sourceSegmentedControl.addTarget(self, action: #selector(segmentedControlDidChangeValue(sender:)), for: .valueChanged)

        selectImageButton.setTitle(NSLocalizedString("Select Image", comment: "Select Image Button"), for: .normal)
        selectImageButton.setTitleColor(.link, for: .normal)
        selectImageButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        selectImageButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.addSubview(selectImageButton)
        selectImageButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectImageButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            selectImageButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])

        imageView.backgroundColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])

        if let firstFilter = filters.first, let lastFilter = filters.last {
            imageInput => firstFilter
            lastFilter => imageView
        } else {
            imageInput => imageView
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageInput.processImage()
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
                camera.orientation = camera.inputCamera.position == .front ? .landscapeRightMirrored : .landscapeLeft
            case .portraitUpsideDown:
                camera.orientation = camera.inputCamera.position == .front ? .landscapeLeftMirrored : .landscapeRight
            case .landscapeLeft:
                camera.orientation = camera.inputCamera.position == .front ? .portraitMirrored : .portraitUpsideDown
            case .landscapeRight:
                camera.orientation = camera.inputCamera.position == .front ? .portraitUpsideDownMirrored : .portrait
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }

    func setCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if camera == nil {
                do {
                    camera = try Camera(sessionPreset: .vga640x480)
                    setCameraOrientation()
                } catch Camera.CameraError.noCameraDevice {
                    #if targetEnvironment(macCatalyst)
                    let message = NSLocalizedString("Not_Support_Catalyst", comment: "Mac apps built with Mac Catalyst can’t use the AVFoundation Capture classes.")
                    #else
                    let message = NSLocalizedString("No_Camera", comment: "There's no camera")
                    #endif
                    let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                            message: message,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"),
                                                            style: .default) { _ in
                        self.sourceSegmentedControl.selectedSegmentIndex = 0
                        self.segmentedControlDidChangeValue(sender: self.sourceSegmentedControl)
                    })
                    DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
                    }
                } catch {
                    let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                            message: error.localizedDescription,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"),
                                                            style: .default) { _ in
                        self.sourceSegmentedControl.selectedSegmentIndex = 0
                        self.segmentedControlDidChangeValue(sender: self.sourceSegmentedControl)
                    })
                    DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }

            guard let camera = camera else { return }
            if let filter = filters.first {
                camera => filter
            } else {
                camera => imageView
            }
            camera.runBenchmark = true
            camera.startCapture()
        case .denied, .restricted:
            let alertController = UIAlertController(title: NSLocalizedString("Camera_Error", comment: "Cannot access camera"),
                                                    message: NSLocalizedString("Authorize_Camera", comment: "Authorize to access camera"),
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Confirm"),
                                                    style: .default) { _ in
                self.sourceSegmentedControl.selectedSegmentIndex = 0
                self.segmentedControlDidChangeValue(sender: self.sourceSegmentedControl)
            })
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                self.setCamera()
            }
        @unknown default:
            fatalError("Undefined Photo Library Authorization Status")
        }
    }
}

extension MultiFilterImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.editedImage] as? UIImage {
            sourceImage = selectedImage
        } else if let selectedImage = info[.originalImage] as? UIImage {
            sourceImage = selectedImage
        }
        if let cropRect = info[.cropRect] as? CGRect,
           let croppedImage = sourceImage.cgImage?.cropping(to: cropRect) {
            sourceImage = UIImage(cgImage: croppedImage, scale: sourceImage.scale, orientation: sourceImage.imageOrientation)
        }
        dismiss(animated: true, completion: nil)
    }
}

#if XCODE_12
@available(iOS 14.0, *)
extension MultiFilterImageViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            let previousImage = sourceImage
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage, self.sourceImage == previousImage else { return }
                    self.sourceImage = image
                }
            }
        }
    }
}
#endif
