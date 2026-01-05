//
//  ImagePicker.swift
//  recap
//
//  Created by Diptayan Jash on 08/12/25.
//

// import SwiftUI
// import PhotosUI

// struct ImagePicker: View {
//     @Binding var selectedImage: UIImage?
//     @State private var showConfirmation = false
//     @State private var showCamera = false
//     @State private var showPhotosPicker = false
//     @State private var selectedItem: PhotosPickerItem?

//     var body: some View {
//         VStack {
//             if let selectedImage {
//                 Image(uiImage: selectedImage)
//                     .resizable()
//                     .scaledToFill()
//                     .frame(width: 120, height: 120)
//                     .clipShape(Circle())
//                     .overlay(
//                         Circle()
//                             .stroke(AppConfig.Colors.accent, lineWidth: 2)
//                     )
//                     .onTapGesture {
//                         showConfirmation = true
//                     }
//             } else {
//                 Button {
//                     showConfirmation = true
//                 } label: {
//                     ZStack {
//                         Circle()
//                             .fill(AppConfig.Colors.textSecondary.opacity(0.1))
//                             .frame(width: 120, height: 120)

//                         VStack {
//                             Image(systemName: "camera.fill")
//                                 .font(.system(size: 30))
//                                 .foregroundColor(AppConfig.Colors.accent)
//                             Text("Add Photo")
//                                 .font(.caption)
//                                 .foregroundColor(AppConfig.Colors.accent)
//                         }
//                     }
//                     .overlay(
//                         Circle()
//                             .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
//                             .foregroundColor(AppConfig.Colors.accent)
//                     )
//                 }
//             }
//         }
//         .confirmationDialog("Choose Photo", isPresented: $showConfirmation) {
//             Button("Camera") {
//                 showCamera = true
//             }
//             Button("Photo Library") {
//                 showPhotosPicker = true
//             }
//             if selectedImage != nil {
//                 Button("Remove Photo", role: .destructive) {
//                     selectedImage = nil
//                 }
//             }
//             Button("Cancel", role: .cancel) { }
//         }
//         .fullScreenCover(isPresented: $showCamera) {
//             CameraPicker(selectedImage: $selectedImage)
//         }
//         .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
//         .onChange(of: selectedItem) { newItem in
//             Task {
//                 if let data = try? await newItem?.loadTransferable(type: Data.self),
//                    let image = UIImage(data: data) {
//                     selectedImage = image
//                 }
//             }
//         }
//     }
// }

// // MARK: - Camera Picker
// struct CameraPicker: UIViewControllerRepresentable {
//     @Binding var selectedImage: UIImage?
//     @Environment(\.dismiss) private var dismiss

//     func makeUIViewController(context: Context) -> UIImagePickerController {
//         let picker = UIImagePickerController()
//         picker.delegate = context.coordinator
//         picker.sourceType = .camera
//         picker.allowsEditing = true
//         return picker
//     }

//     func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }

//     class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//         let parent: CameraPicker

//         init(_ parent: CameraPicker) {
//             self.parent = parent
//         }

//         func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//             if let editedImage = info[.editedImage] as? UIImage {
//                 parent.selectedImage = editedImage
//             } else if let originalImage = info[.originalImage] as? UIImage {
//                 parent.selectedImage = originalImage
//             }
//             parent.dismiss()
//         }

//         func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//             parent.dismiss()
//         }
//     }
// }

// #Preview {
//     ImagePicker(selectedImage: .constant(nil))
// }
import AVFoundation
import PhotosUI
import SwiftUI

// MARK: - Configuration
// UI Display radius (Avatar button)
private let displayCornerRadius: CGFloat = 24

// MARK: - Main Image Picker View

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    
    // UI State
    @State private var showConfirmation = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var isProcessing = false
    
    // Selection State
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageToCrop: UIImage?

    var body: some View {
        ZStack {
            // Main Avatar Button
            avatarButton
                .disabled(isProcessing)
            
            // Loading Overlay
            if isProcessing {
                ZStack {
                    RoundedRectangle(cornerRadius: displayCornerRadius, style: .continuous)
                        .fill(.white.opacity(0.7))
                    ProgressView()
                }
                .frame(width: 130, height: 130)
            }
        }
        // Action Sheet
        .confirmationDialog("Update Photo", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Take Photo") {
                if isCameraAccessible { showCamera = true }
            }
            Button("Choose from Library") { showPhotosPicker = true }
            
            if selectedImage != nil {
                Button("Remove Current Photo", role: .destructive) {
                    withAnimation { selectedImage = nil }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        // Photos Picker
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            processSelectedPhoto(newItem)
        }
        // Camera Full Screen
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(imageToCrop: $imageToCrop)
                .ignoresSafeArea()
        }
        // Cropper Full Screen
        .fullScreenCover(isPresented: Binding(get: { imageToCrop != nil }, set: { if !$0 { imageToCrop = nil } })) {
            if let img = imageToCrop {
                // Using the new Square Cropper
                SquareImageCropper(image: img) { croppedImage in
                    finalizeImage(croppedImage)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var avatarButton: some View {
        Button {
            showConfirmation = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                // The Image Area
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        // UI Styling: Rounded Corners for display
                        .clipShape(RoundedRectangle(cornerRadius: displayCornerRadius, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: displayCornerRadius, style: .continuous)
                                .stroke(Color.white, lineWidth: 3)
                        )
                } else {
                    // Empty State
                    ZStack {
                        RoundedRectangle(cornerRadius: displayCornerRadius, style: .continuous)
                            .fill(Color(uiColor: .systemGray6))
                        
                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 130, height: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: displayCornerRadius, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundColor(.gray.opacity(0.5))
                    )
                }
                
                // The Edit Badge
                Circle()
                    .fill(AppConfig.Colors.accent)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: selectedImage == nil ? "plus" : "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 3)
                    .offset(x: 4, y: 4)
            }
        }
    }
    
    // MARK: - Logic
    
    private var isCameraAccessible: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized ||
        AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
    }
    
    private func processSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isProcessing = true
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    imageToCrop = image.normalized
                    isProcessing = false
                }
            } else {
                await MainActor.run { isProcessing = false }
            }
        }
    }
    
    private func finalizeImage(_ image: UIImage) {
        withAnimation {
            self.selectedImage = image
        }
        self.imageToCrop = nil
        self.selectedItem = nil
    }
}

// MARK: - Square Cropper UI (No Corner Radius)

struct SquareImageCropper: View {
    let image: UIImage
    let onCropped: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Gesture State
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let cropSize: CGFloat = 300
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. The Manipulatable Image
            VStack {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(width: lastOffset.width + value.translation.width,
                                                        height: lastOffset.height + value.translation.height)
                                    }
                                    .onEnded { _ in lastOffset = offset },
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(1, lastScale * value)
                                    }
                                    .onEnded { _ in lastScale = scale }
                            )
                        )
                }
                // IMPORTANT: Frame matches crop size so image centers correctly
                .frame(width: cropSize, height: cropSize)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. The Dark Overlay with a Square Hole
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .mask(
                    ZStack {
                        Rectangle().fill(Color.white)
                        // Punch a sharp square hole
                        Rectangle()
                            .frame(width: cropSize, height: cropSize)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // 3. Grid Lines & Border (Square)
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropSize, height: cropSize)
                .overlay(
                    // Rule of thirds grid
                    ZStack {
                        Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.3)).offset(x: cropSize/3)
                        Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.3)).offset(x: -cropSize/3)
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3)).offset(y: cropSize/3)
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3)).offset(y: -cropSize/3)
                    }
                )
                .allowsHitTesting(false)
            
            // 4. Instructions
            VStack {
                Text("Move and Scale")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 60)
                Spacer()
            }
            
            // 5. Floating Controls
            VStack {
                Spacer()
                HStack(spacing: 60) {
                    Button {
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 22, weight: .bold))
                            Text("Cancel").font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // Crop Logic
                        let cropped = image.croppedImage(
                            size: cropSize,
                            scale: scale,
                            offset: offset
                        )
                        onCropped(cropped)
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .shadow(radius: 10)
                    .offset(y: -10)
                    
                    Button {
                        withAnimation {
                            scale = 1
                            offset = .zero
                            lastScale = 1
                            lastOffset = .zero
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 22, weight: .bold))
                            Text("Reset").font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - UIImage Utilities

extension UIImage {
    var normalized: UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }

    func compressed(maxKB: Int) -> Data? {
        var quality: CGFloat = 0.9
        var data = jpegData(compressionQuality: quality)
        while let d = data, d.count > maxKB * 1024, quality > 0.1 {
            quality -= 0.1
            data = jpegData(compressionQuality: quality)
        }
        return data
    }

    // FIXED: Correct aspect ratio math to prevent distortion
    func croppedImage(size: CGFloat, scale: CGFloat, offset: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { _ in
            // 1. Calculate the base dimensions (fitting the crop box like scaledToFill)
            let aspectRatio = self.size.width / self.size.height
            var drawWidth: CGFloat
            var drawHeight: CGFloat
            
            if aspectRatio > 1 {
                // Landscape: Height matches box, Width scales
                drawHeight = size
                drawWidth = size * aspectRatio
            } else {
                // Portrait/Square: Width matches box, Height scales
                drawWidth = size
                drawHeight = size / aspectRatio
            }
            
            // 2. Apply User Zoom
            let scaledWidth = drawWidth * scale
            let scaledHeight = drawHeight * scale
            
            // 3. Center the image in the context
            // Start at center of context (size/2)
            // Move back by half of image size (-scaledWidth/2)
            // Add user offset
            let x = (size - scaledWidth) / 2 + offset.width
            let y = (size - scaledHeight) / 2 + offset.height
            
            // 4. Draw image (No clipping path = Rectangle)
            draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
    }
}

// MARK: - Camera Picker (Unchanged)
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var imageToCrop: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.imageToCrop = image.normalized }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack(spacing: 30) {
            ImagePicker(selectedImage: .constant(nil))
            ImagePicker(selectedImage: .constant(UIImage(systemName: "photo")))
        }
    }
}
