import Cocoa
import CoreImage

let inputPath = "/Users/enriquelozano/.gemini/antigravity/brain/3b720503-c904-4e39-8257-cffe7e7a2a80/media__1777767557998.jpg"
let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsDir = currentDir.appendingPathComponent("Assets")

do {
    try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("Failed to create Assets dir")
    exit(1)
}

guard let image = NSImage(contentsOfFile: inputPath),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Failed to load image")
    exit(1)
}

let width = cgImage.width
let height = cgImage.height

print("Image size: \(width)x\(height)")

// 1. Process Right Half -> AppIcon (Square with Squircle Mask)
// Crop tighter to remove the white border (approx 45px inset)
let cropInset: CGFloat = 45
let appIconRect = CGRect(x: 512 + cropInset, y: 256 + cropInset, width: 512 - (cropInset * 2), height: 512 - (cropInset * 2))

if let appIconCg = cgImage.cropping(to: appIconRect) {
    let targetSize = NSSize(width: 512, height: 512)
    let appIconImage = NSImage(size: targetSize)
    
    appIconImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    
    // Create macOS continuous rounded rectangle (squircle) mask
    let radius: CGFloat = 512 * 0.225 // Standard Apple icon radius proportion
    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: targetSize), xRadius: radius, yRadius: radius)
    path.addClip()
    
    // Draw the cropped image scaled up to fill the 512x512 space
    let rep = NSBitmapImageRep(cgImage: appIconCg)
    rep.draw(in: NSRect(origin: .zero, size: targetSize))
    
    appIconImage.unlockFocus()
    
    // Save to AppIcon.png
    let appIconUrl = assetsDir.appendingPathComponent("AppIcon.png")
    if let tiffData = appIconImage.tiffRepresentation,
       let bitmapRep = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: appIconUrl)
        print("Saved AppIcon.png")
    }
}

// 2. Process Left Half -> MenuBarIcon (Template)
// The left side is x from 0 to 512.
let menuIconRect = CGRect(x: 0, y: 256, width: 512, height: 512)
if let menuIconCg = cgImage.cropping(to: menuIconRect) {
    // Create a bitmap context to manipulate pixels
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * 512
    var pixelData = [UInt8](repeating: 0, count: 512 * 512 * 4)
    
    if let context = CGContext(data: &pixelData,
                               width: 512,
                               height: 512,
                               bitsPerComponent: 8,
                               bytesPerRow: bytesPerRow,
                               space: colorSpace,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
        
        context.draw(menuIconCg, in: CGRect(x: 0, y: 0, width: 512, height: 512))
        
        // Thresholding to extract the white ghost shape and convert to solid black with alpha
        for i in 0..<(512 * 512) {
            let offset = i * 4
            let r = pixelData[offset]
            let g = pixelData[offset + 1]
            let b = pixelData[offset + 2]
            
            // The ghost is very white (e.g. > 240)
            if r > 240 && g > 240 && b > 240 {
                // Ghost body: Make solid black with full alpha
                pixelData[offset] = 0     // R
                pixelData[offset + 1] = 0 // G
                pixelData[offset + 2] = 0 // B
                pixelData[offset + 3] = 255 // A
            } else {
                // Background/Shadows: Make transparent
                pixelData[offset] = 0
                pixelData[offset + 1] = 0
                pixelData[offset + 2] = 0
                pixelData[offset + 3] = 0
            }
        }
        
        if let outputCg = context.makeImage() {
            // Resize to 44x44 for @2x menu bar icon
            let targetSize = NSSize(width: 44, height: 44)
            let menuImage = NSImage(size: targetSize)
            menuImage.lockFocus()
            NSGraphicsContext.current?.imageInterpolation = .high
            let rep = NSBitmapImageRep(cgImage: outputCg)
            rep.draw(in: NSRect(x: 0, y: 0, width: 44, height: 44))
            menuImage.unlockFocus()
            
            if let tiffData = menuImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                let menuIconUrl = assetsDir.appendingPathComponent("MenuBarIcon.png")
                try? pngData.write(to: menuIconUrl)
                print("Saved MenuBarIcon.png")
            }
        }
    }
}
