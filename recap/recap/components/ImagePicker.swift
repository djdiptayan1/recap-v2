//
//  ImagePicker.swift
//  recap
//
//  Created by Diptayan Jash on 08/12/25.
//

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var showConfirmation = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppConfig.Colors.accent, lineWidth: 2)
                    )
                    .onTapGesture {
                        showConfirmation = true
                    }
            } else {
                Button {
                    showConfirmation = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppConfig.Colors.textSecondary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(AppConfig.Colors.accent)
                            Text("Add Photo")
                                .font(.caption)
                                .foregroundColor(AppConfig.Colors.accent)
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(AppConfig.Colors.accent)
                    )
                }
            }
        }
        .confirmationDialog("Choose Photo", isPresented: $showConfirmation) {
            Button("Camera") {
                showCamera = true
            }
            Button("Photo Library") {
                showPhotosPicker = true
            }
            if selectedImage != nil {
                Button("Remove Photo", role: .destructive) {
                    selectedImage = nil
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage)
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ImagePicker(selectedImage: .constant(nil))
}
