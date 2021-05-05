//
//  MIImageViewController.swift
//  MetallicImageDemo_iOS
//
//  Created by Xerol Wong on 3/31/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetallicImage
import Photos
import UIKit
import PhotosUI

class ImageViewController: UIViewController {
    private let imageView = ImageView(frame: .zero)
    private let selectImageButton = UIButton()
    private var sliderStackViews: [UIStackView] = []
    private let sourceSegmentedControl = UISegmentedControl(items: [NSLocalizedString("Photo", comment: "Still Photo"),
                                                                    NSLocalizedString("Camera", comment: "Camera")])
    lazy var saveButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(saveImage))

    private var sourceImage = #imageLiteral(resourceName: "Tokyo_Tower") {
        didSet {
            imageInput = PictureInput(image: sourceImage)
            if let filter = filter {
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

    private let filter: BasicFilter?
    private let filterProperties: [(propertyName: String, min: Float, max: Float, inPercentage: Bool)]

    init(filter: BasicFilter? = nil, properties: [(propertyName: String, min: Float, max: Float)]) {
        self.filter = filter
        filterProperties = properties.map {
            let inPercentage = $0.min == 0 && $0.max == .infinity
            return ($0.propertyName, $0.min, $0.max, inPercentage)
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func selectImage() {
        var configutation = PHPickerConfiguration()
        configutation.filter = .any(of: [.images, .livePhotos])
        let pickerViewController = PHPickerViewController(configuration: configutation)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true, completion: nil)
    }

    @objc
    func saveImage() {
        dispatchQueue.sync {
            if let filter = self.filter {
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
    func sliderDidChangeValue(sender: UISlider) {
        if filterProperties[sender.tag].inPercentage {
            if sourceSegmentedControl.selectedSegmentIndex == 0 {
                guard let image = sourceImage.cgImage else {
                    return
                }
                let minLength = Float(min(image.width, image.height))
                filter?.setValue(sender.value * minLength, forKey: filterProperties[sender.tag].propertyName)
            } else {
                filter?.setValue(sender.value * 480, forKey: filterProperties[sender.tag].propertyName)
            }
        } else {
            filter?.setValue(sender.value, forKey: filterProperties[sender.tag].propertyName)
        }
        imageInput.processImage()
    }

    @objc
    func segmentedControlDidChangeValue(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            camera?.removeAllTargets()
            selectImageButton.isHidden = false
            camera?.stopCapture()
            updateAllFilters()
            if let filter = filter {
                imageInput => filter
            } else {
                imageInput => imageView
            }
            imageInput.processImage()
        case 1:
            imageInput.removeAllTargets()
            selectImageButton.isHidden = true
            updateAllFilters()
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

        if let filter = filter {
            for (reversedIndex, property) in filterProperties.reversed().enumerated() {
                let index = filterProperties.count - 1 - reversedIndex
                let slider = UISlider()
                slider.tag = index
                slider.addTarget(self, action: #selector(sliderDidChangeValue(sender:)), for: .valueChanged)
                slider.isContinuous = false

                let minValueLabel = UILabel()
                let maxValueLabel = UILabel()
                if filterProperties[index].inPercentage {
                    slider.minimumValue = 0
                    slider.maximumValue = 1
                    slider.value = 0
                    minValueLabel.text = "\(property.propertyName): 0%"
                    maxValueLabel.text = "100%"
                } else {
                    slider.minimumValue = filterProperties[index].min
                    slider.maximumValue = filterProperties[index].max
                    slider.value = filter.value(forKey: property.propertyName) as! Float
                    minValueLabel.text = "\(property.propertyName): \(slider.minimumValue)"
                    maxValueLabel.text = "\(slider.maximumValue)"
                }

                let stackView = UIStackView(arrangedSubviews: [minValueLabel, slider, maxValueLabel])
                stackView.axis = .horizontal
                stackView.spacing = 5
                sliderStackViews.append(stackView)
                view.addSubview(stackView)
                stackView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    stackView.bottomAnchor.constraint(equalTo: reversedIndex == 0 ? view.safeAreaLayoutGuide.bottomAnchor : sliderStackViews[reversedIndex - 1].topAnchor, constant: -10),
                    stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
                    stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
                ])
            }
        }

        imageView.backgroundColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            imageView.bottomAnchor.constraint(equalTo: sliderStackViews.last?.topAnchor ?? view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])

        if let filter = filter {
            imageInput => filter => imageView
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
                    let message = NSLocalizedString("No_Camera", comment: "There's no camera")
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
            if let filter = filter {
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

    func updateAllFilters() {
        for stackView in sliderStackViews {
            guard let slider = stackView.arrangedSubviews.compactMap({ $0 as? UISlider }).first else { return }
            sliderDidChangeValue(sender: slider)
        }
    }
}

extension ImageViewController: PHPickerViewControllerDelegate {
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
