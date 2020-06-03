import Flutter
import UIKit
import Photos

struct AlbumItem: Hashable {
    var name: String
    var identifier: String
    
    static func ==(lhs: AlbumItem, rhs: AlbumItem) -> Bool {
        return (lhs.name, lhs.identifier) == (rhs.name, rhs.identifier)
    }
    
    var hashValue: Int {
        return name.hashValue << 2 | identifier.hashValue
    }
}

public class SwiftAdvImagePickerPlugin: NSObject, FlutterPlugin {
    var controller: FlutterViewController!
    var imagesResult: FlutterResult?
    var messenger: FlutterBinaryMessenger
    
    let genericError = "500"
    
    init(cont: FlutterViewController, messenger: FlutterBinaryMessenger) {
        self.controller = cont;
        self.messenger = messenger;
        super.init();
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "adv_image_picker", binaryMessenger: registrar.messenger())
        
        let app = UIApplication.shared
        let controller : FlutterViewController = app.delegate!.window!!.rootViewController as! FlutterViewController;
        let instance = SwiftAdvImagePickerPlugin.init(cont: controller, messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "getIosStoragePermission":
            getStoragePermission(result: result)
            break;
        case "getAlbums":
            let fetchOptions = PHFetchOptions()

            let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)

            let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            var arr = [Any]();
            let allAlbums: Array<PHFetchResult<PHAssetCollection>> = [smartAlbums, albums]

            for i in 0 ..< allAlbums.count {
                let resultx: PHFetchResult = allAlbums[i]

                resultx.enumerateObjects { (asset, index, stop) -> Void in
                    let opts = PHFetchOptions()

                    if #available(iOS 9.0, *) {
                        opts.fetchLimit = 1
                    }

                    var assetCount = asset.estimatedAssetCount
                    if assetCount == NSNotFound {
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                        assetCount = PHAsset.fetchAssets(in: asset, options: fetchOptions).count
                    }

                    if assetCount > 0 {
                        let item = ["name": asset.localizedTitle!, "assetCount": assetCount, "identifier": asset.localIdentifier] as [String : Any]
                        arr.append(item)
                    }
                }
            }

            result(arr)
            break;
        case "getAlbumAssetsId":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let albumName = arguments["albumName"] as! String
            var resuuuu: [String] = []
            let fetchOptions = PHFetchOptions()
            let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)

            let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

            let allAlbums: Array<PHFetchResult<PHAssetCollection>> = [smartAlbums, albums]

            for i in 0 ..< allAlbums.count {
                let resultx: PHFetchResult = allAlbums[i]
                
                resultx.enumerateObjects { (asset, index, stop) -> Void in
                    if asset.localizedTitle == albumName {
                        let opt = PHFetchOptions()
                        let ass = PHAsset.fetchAssets(in: asset, options: opt)

                        ass.enumerateObjects{(object: AnyObject!,
                            count: Int,
                            stop: UnsafeMutablePointer<ObjCBool>) in
                            if object is PHAsset {
                                let eachass = object as! PHAsset

                                resuuuu.append(eachass.localIdentifier)
                            }
                        }
                    }
                }
            }

            result(resuuuu)
        case "getAlbumThumbnail":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let imagePath = (arguments["imagePath"] ?? "" as AnyObject) as! String
            let quality = arguments["quality"] as! Int
            let reqWidth = (arguments["width"] ?? 0 as AnyObject) as! Int
            let reqHeight = (arguments["height"] ?? 0 as AnyObject) as! Int
            
            if let image = UIImage(contentsOfFile: imagePath) {
                if (reqWidth != 0 && reqHeight != 0) {
                    let initialWidth = image.size.width;
                    let initialHeight = image.size.height;
                    let width: CGFloat = CGFloat(reqWidth);
                    let height: CGFloat = CGFloat(reqHeight);
                    let newSize = CGSize(width: width, height: height);
                    var rectWidth: CGFloat
                    var rectHeight: CGFloat
                
                    //if the request size is landscape
                    if (width > height) {
                        rectHeight = initialHeight / initialWidth * width
                        rectWidth = width
                    } else if (height > width) { //if the request size is portrait
                        rectHeight = height
                        rectWidth = initialWidth / initialHeight * height
                    } else { //if the request size is square
                        if initialWidth > initialHeight {
                            rectHeight = width
                            rectWidth = initialWidth / initialHeight * width
                        } else {
                            rectHeight = initialHeight / initialWidth * width
                            rectWidth = width
                        }
                    }
                    
                    let posX: CGFloat = (width - rectWidth) / 2
                    let posY: CGFloat = (height - rectHeight) / 2
                    
                    let rect = CGRect(x: posX, y: posY, width: rectWidth, height: rectHeight)
                    
                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                    image.draw(in: rect)
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()

                    self.messenger.send(onChannel: "adv_image_picker/image/fetch/thumbnails/\(imagePath)", message: newImage!.jpegData(compressionQuality: CGFloat(quality / 100)))
                } else {
                    result(true)
                    break
                }
            }
            
            result(true)
        case "getAlbumOriginal":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let imagePath = (arguments["imagePath"] ?? "" as AnyObject) as! String
            let quality = arguments["quality"] as! Int
            let maxSize = (arguments["maxSize"] ?? 0 as AnyObject) as! Int
            
            if let image = UIImage(contentsOfFile: imagePath) {
                if (maxSize != 0) {
                    let initialWidth = image.size.width;
                    let initialHeight = image.size.height;
                    let floatMaxSize = CGFloat(maxSize);
                    let width: CGFloat = initialHeight.isLess(than: initialWidth) ? floatMaxSize : (initialWidth / initialHeight * floatMaxSize);
                    let height: CGFloat = initialWidth.isLessThanOrEqualTo(initialHeight) ? floatMaxSize : (initialHeight / initialWidth * floatMaxSize);
                    let newSize = CGSize(width: width, height: height);
                    let rect = CGRect(x: 0, y: 0, width: width, height: height)
                    
                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                    image.draw(in: rect)
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    self.messenger.send(onChannel: "adv_image_picker/image/fetch/original/\(imagePath)", message: newImage!.jpegData(compressionQuality: CGFloat(quality / 100)))
                } else {
                    self.messenger.send(onChannel: "adv_image_picker/image/fetch/original/\(imagePath)", message: image.jpegData(compressionQuality: CGFloat(quality / 100)))
                }
            }
            
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getStoragePermission(result: @escaping FlutterResult) -> Void {
        let hasPermission = checkPermission(permission: "Storage")
        if(!hasPermission) {
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    result(true)
                    break;
                default:
                    result(false)
                    break;
                }
            }
        } else {
            result(true)
        }
    }
    
    private func checkPermission(permission : String) -> Bool {
        var hasPermission: Bool!
        if permission == "Storage" {
            let status = PHPhotoLibrary.authorizationStatus()
            hasPermission = status == PHAuthorizationStatus.authorized
        }
        return hasPermission ?? false
    }
}
