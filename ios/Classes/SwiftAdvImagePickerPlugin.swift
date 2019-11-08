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
        // Combine the hash values for the name and department
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
        case "getIosCameraPermission":
            getCameraPermission(result: result)
            break;
        case "getIosStoragePermission":
            getStoragePermission(result: result)
            break;
        case "getAlbums":
//            let vs = BSImagePickerViewController();
//
//            controller!.bs_presentImagePickerController(vs, animated: true,
//                                                        select: { (asset: PHAsset) -> Void in
//
//            }, deselect: { (asset: PHAsset) -> Void in
//
//            }, cancel: { (assets: [PHAsset]) -> Void in
//                result([])
//            }, finish: { (assets: [PHAsset]) -> Void in
////                var results = [NSDictionary]();
////                for asset in assets {
////                    results.append([
////                        "identifier": asset.localIdentifier,
////                        "width": asset.pixelWidth,
////                        "height": asset.pixelHeight,
////                        "name": asset.originalFilename!
////                        ]);
////                }
////                result(results);
//            }, completion: nil)
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
            //            let arguments = call.arguments as! Dictionary<String, AnyObject>
            //            let albumName = arguments["albumName"] as! String
            //
            //            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            //
            //            var album: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
            //            album.enumerateObjects{(asset, index, stop) -> Void in
            //                if (asset.localizedTitle)
            //            }
            //            if album.count == 0 {
            //                album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            //            }
            //
            //            let options = PHImageRequestOptions()
            //
            //            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            //            options.resizeMode = PHImageRequestOptionsResizeMode.exact
            //            options.isSynchronous = true
            //            options.isNetworkAccessAllowed = true
            //            var resuuuu: [String] = []
            //            album.enumerateObjects { (asset, index, stop) -> Void in
            //                let opt = PHFetchOptions()
            //                let ass = PHAsset.fetchAssets(in: asset, options: opt)
            //
            //                ass.enumerateObjects{(object: AnyObject!,
            //                    count: Int,
            //                    stop: UnsafeMutablePointer<ObjCBool>) in
            //                    if object is PHAsset {
            //                        let eachass = object as! PHAsset
            //
            //                        resuuuu.append(eachass.localIdentifier)
            //                    }
            //                }
            //            }
        //            result(resuuuu)
        case "getAlbumThumbnail":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let albumId = arguments["albumId"] as! String
            let assetId = arguments["assetId"] as! String
            let width = arguments["width"] as! Int
            let height = arguments["height"] as! Int
            let quality = arguments["quality"] as! Int

            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()

            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.resizeMode = PHImageRequestOptionsResizeMode.exact
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

            //            print("count => \(assets.objects)")
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                print("count => \(count)")
//                if object is PHAsset{
//                    let asset = object as! PHAsset
//
//                    let ID: PHImageRequestID = manager.requestImage(
//                        for: asset,
//                        targetSize: CGSize(width: width, height: height),
//                        contentMode: PHImageContentMode.aspectFill,
//                        options: options,
//                        resultHandler: {
//                            (image: UIImage?, info) in
//                            print("info => \(info)")
//                            if info != nil {
//                                self.messenger.send(onChannel: "adv_image_picker/image/fetch/thumbnails/\(albumId)/\(assetId)", message: UIImageJPEGRepresentation(image!, CGFloat(quality / 100)))
//                            } else {
//                                print("nilllll")
//                            }
//                    })
//
//
//                    if (PHInvalidImageRequestID != ID) {
//                        result(true);
//                    }
//                }
            }
        case "getAlbumOriginal":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let albumId = arguments["albumId"] as! String
            let assetId = arguments["assetId"] as! String
            let quality = arguments["quality"] as! Int
            let maxSize = (arguments["maxSize"] ?? 0 as AnyObject) as! Int
            
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.resizeMode = PHImageRequestOptionsResizeMode.exact
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            
            let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
            
            //            print("count => \(assets.objects)")
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                print("count => \(count)")
                if object is PHAsset{
                    let asset = object as! PHAsset
                    
                    let targetSize = CGSize(width:asset.pixelWidth, height:asset.pixelHeight)
                    let ID: PHImageRequestID = manager.requestImage(
                        for: asset,
                        targetSize: targetSize,
                        contentMode: PHImageContentMode.aspectFill,
                        options: options,
                        resultHandler: {
                            (image: UIImage?, info) in
                            print("info => \(info)")
                            if info != nil {
                                if (maxSize != 0) {
                                    let initialWidth = image?.size.width ?? 0.0;
                                    let initialHeight = image?.size.height ?? 0.0;
                                    let floatMaxSize = CGFloat(maxSize);
                                    let width: CGFloat = initialHeight.isLess(than: initialWidth) ? floatMaxSize : (initialWidth / initialHeight * floatMaxSize);
                                    let height: CGFloat = initialWidth.isLessThanOrEqualTo(initialHeight) ? floatMaxSize : (initialHeight / initialWidth * floatMaxSize);
                                    let newSize = CGSize(width: width, height: height);
                                    let rect = CGRect(x: 0, y: 0, width: width, height: height)
                                    
                                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                                    image!.draw(in: rect)
                                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                                    UIGraphicsEndImageContext()
                                    
                                    self.messenger.send(onChannel: "adv_image_picker/image/fetch/original/\(albumId)/\(assetId)", message: newImage!.jpegData(compressionQuality: CGFloat(quality / 100)))
                                } else {
                                    self.messenger.send(onChannel: "adv_image_picker/image/fetch/original/\(albumId)/\(assetId)", message: image!.jpegData(compressionQuality: CGFloat(quality / 100)))
                                }
                            } else {
                                print("nilllll")
                            }
                    })
                    
                    
                    if (PHInvalidImageRequestID != ID) {
                        result(true);
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    private func getCameraPermission(result: @escaping FlutterResult)-> Void {
        let hasPermission = checkPermission(permission: "Camera")
        if (!hasPermission) {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                if granted {
                    result(true)
                } else {
                    result(false)
                }
            }
        } else {
            result(true)
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
        } else if (permission == "Camera"){
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            hasPermission = status == AVAuthorizationStatus.authorized
        }
        return hasPermission
    }
}
