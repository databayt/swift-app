import SwiftUI
import AVFoundation

/// QR code scanner for student check-in
/// Mirrors: src/components/platform/attendance/qr-scanner.tsx
struct QRScannerView: View {
    @Bindable var viewModel: AttendanceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPermissionGranted = false
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                if cameraPermissionGranted {
                    QRCodeScannerRepresentable(
                        onCodeScanned: handleScannedCode
                    )
                    .ignoresSafeArea()
                } else {
                    // Permission request view
                    PermissionRequestView(
                        onRequestPermission: requestCameraPermission
                    )
                }

                // Overlay
                VStack {
                    Spacer()

                    // Scanner state
                    scannerStateView
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()

                    // Scan frame
                    if cameraPermissionGranted {
                        ScanFrameView()
                            .frame(width: 250, height: 250)
                    }

                    Spacer()

                    // Instructions
                    Text(String(localized: "attendance.qr.instructions"))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                }
            }
            .navigationTitle(String(localized: "attendance.qr.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert(
                String(localized: "attendance.qr.permissionRequired"),
                isPresented: $showPermissionAlert
            ) {
                Button(String(localized: "common.settings")) {
                    openSettings()
                }
                Button(String(localized: "common.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "attendance.qr.permissionMessage"))
            }
            .onAppear {
                checkCameraPermission()
            }
        }
    }

    @ViewBuilder
    private var scannerStateView: some View {
        switch viewModel.qrScannerState {
        case .idle, .scanning:
            HStack(spacing: 12) {
                ProgressView()
                Text(String(localized: "attendance.qr.scanning"))
                    .font(.subheadline)
            }

        case .processing:
            HStack(spacing: 12) {
                ProgressView()
                Text(String(localized: "attendance.qr.processing"))
                    .font(.subheadline)
            }

        case .success(let attendance):
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)

                Text(String(localized: "attendance.qr.success"))
                    .font(.headline)
                    .foregroundStyle(.green)

                Text(attendance.attendanceStatus.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(String(localized: "common.done")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }

        case .error(let error):
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)

                Text(String(localized: "attendance.qr.error"))
                    .font(.headline)
                    .foregroundStyle(.red)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(String(localized: "attendance.qr.tryAgain")) {
                    viewModel.qrScannerState = .scanning
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
    }

    // MARK: - Methods

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            viewModel.qrScannerState = .scanning

        case .notDetermined:
            requestCameraPermission()

        case .denied, .restricted:
            showPermissionAlert = true

        @unknown default:
            break
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraPermissionGranted = granted
                if granted {
                    viewModel.qrScannerState = .scanning
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        // Prevent multiple scans
        guard case .scanning = viewModel.qrScannerState else { return }

        // Validate QR code format
        let validation = AttendanceValidation.validateQRCode(code)
        guard validation.isValid else {
            viewModel.qrScannerState = .error(AttendanceError.qrInvalid)
            return
        }

        // Process the code
        Task {
            await viewModel.processQRCode(code)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Permission Request View

struct PermissionRequestView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(String(localized: "attendance.qr.cameraAccess"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "attendance.qr.cameraAccessMessage"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(String(localized: "attendance.qr.enableCamera")) {
                onRequestPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Scan Frame View

struct ScanFrameView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Corner brackets
            GeometryReader { geometry in
                let size = geometry.size
                let cornerLength: CGFloat = 30
                let lineWidth: CGFloat = 4

                // Top left
                Path { path in
                    path.move(to: CGPoint(x: 0, y: cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                }
                .stroke(.white, lineWidth: lineWidth)

                // Top right
                Path { path in
                    path.move(to: CGPoint(x: size.width - cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: size.width, y: 0))
                    path.addLine(to: CGPoint(x: size.width, y: cornerLength))
                }
                .stroke(.white, lineWidth: lineWidth)

                // Bottom left
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size.height - cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.addLine(to: CGPoint(x: cornerLength, y: size.height))
                }
                .stroke(.white, lineWidth: lineWidth)

                // Bottom right
                Path { path in
                    path.move(to: CGPoint(x: size.width - cornerLength, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height - cornerLength))
                }
                .stroke(.white, lineWidth: lineWidth)

                // Scanning line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .green.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .offset(y: isAnimating ? size.height - 10 : 10)
                    .animation(
                        .linear(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - QR Code Scanner Representable

struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

// MARK: - QR Scanner View Controller

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.captureSession?.isRunning == false {
                self?.captureSession?.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.captureSession?.isRunning == true {
                self?.captureSession?.stopRunning()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let captureSession = captureSession else {
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill

        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        // Prevent multiple scans
        guard !hasScanned else { return }

        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {

            hasScanned = true

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            onCodeScanned?(stringValue)
        }
    }

    func resetScanner() {
        hasScanned = false
    }
}

// MARK: - Teacher QR Generator View

struct QRGeneratorView: View {
    let qrSession: QRSession

    var body: some View {
        VStack(spacing: 24) {
            // QR Code image
            if let qrImage = generateQRCode(from: qrSession.code) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Session info
            VStack(spacing: 8) {
                Text(String(localized: "attendance.qr.sessionCode"))
                    .font(.headline)

                Text(qrSession.code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Expiry countdown
                if !qrSession.isExpired {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(qrSession.expiresAt, style: .relative)
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                } else {
                    Text(String(localized: "attendance.qr.expired"))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Instructions
            Text(String(localized: "attendance.qr.showToStudents"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 10.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#Preview {
    QRScannerView(viewModel: AttendanceViewModel())
}
