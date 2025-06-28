import SwiftUI
import PhotosUI
import UIKit

/// SwiftUI wrapper for PHPickerViewController to enable ChatGPT-style image selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    /// Maximum number of images that can be selected at once
    let selectionLimit: Int
    
    init(selectedImages: Binding<[UIImage]>, selectionLimit: Int = 5) {
        self._selectedImages = selectedImages
        self.selectionLimit = selectionLimit
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // Only allow images
        configuration.selectionLimit = selectionLimit // Allow multiple selection like ChatGPT
        configuration.preferredAssetRepresentationMode = .current // Use current format
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator to handle PHPickerViewController delegate methods
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            // Process selected images
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        return
                    }
                    
                    if let image = object as? UIImage {
                        // Resize image if too large to prevent memory issues
                        let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))
                        DispatchQueue.main.async {
                            images.append(resizedImage)
                        }
                    }
                }
            }
            
            // Update binding when all images are loaded
            group.notify(queue: .main) {
                self.parent.selectedImages.append(contentsOf: images)
            }
        }
    }
}

/// Extension to resize images for better performance and API limits
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        // Calculate aspect ratio preserving resize
        let aspectRatio = self.size.width / self.size.height
        var newSize = size
        
        if aspectRatio > 1 {
            // Landscape
            newSize.height = size.width / aspectRatio
        } else {
            // Portrait or square
            newSize.width = size.height * aspectRatio
        }
        
        // Don't upscale - only downscale if needed
        if newSize.width > self.size.width || newSize.height > self.size.height {
            return self
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Convert UIImage to base64 string for API transmission
    func toBase64String() -> String? {
        guard let imageData = self.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
}

/// Preview wrapper for ImagePicker
struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(selectedImages: .constant([]), selectionLimit: 3)
    }
}