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
                if object is PHAsset{
                    let asset = object as! PHAsset
                    
                    let ID: PHImageRequestID = manager.requestImage(
                        for: asset,
                        targetSize: CGSize(width: width, height: height),
                        contentMode: PHImageContentMode.aspectFill,
                        options: options,
                        resultHandler: {
                            (image: UIImage?, info) in
                            print("info => \(info)")
                            if info != nil {
                                self.messenger.send(onChannel: "adv_image_picker/image/fetch/thumbnails/\(albumId)/\(assetId)", message: UIImageJPEGRepresentation(image!, CGFloat(quality / 100)))
                            } else {
                                print("nilllll")
                            }
                    })
                    
                    
                    if (PHInvalidImageRequestID != ID) {
                        result(true);
                    }
                }
            }
        case "getAlbumOriginal":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let albumId = arguments["albumId"] as! String
            let assetId = arguments["assetId"] as! String
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
                if object is PHAsset{
                    let asset = object as! PHAsset
                    
                    let ID: PHImageRequestID = manager.requestImage(
                        for: asset,
                        targetSize: PHImageManagerMaximumSize,
                        contentMode: PHImageContentMode.aspectFill,
                        options: options,
                        resultHandler: {
                            (image: UIImage?, info) in
                            print("info => \(info)")
                            if info != nil {
                                self.messenger.send(onChannel: "adv_image_picker/image/fetch/original/\(albumId)/\(assetId)", message: UIImageJPEGRepresentation(image!, CGFloat(quality / 100)))
                            } else {
                                print("nilllll")
                            }
                    })
                    
                    
                    if (PHInvalidImageRequestID != ID) {
                        result(true);
                    }
                }
            }
            //            let arguments = call.arguments as! Dictionary<String, AnyObject>
            //            let albumId = arguments["albumId"] as! String
            //            let assetId = arguments["assetId"] as! String
            //            let quality = arguments["quality"] as! Int
            //            let manager = PHImageManager.default()
            //            let options = PHImageRequestOptions()
            //
            //            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            //            options.isSynchronous = false
            //            options.isNetworkAccessAllowed = true
            //
            //            let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            //
            //            if (assets.count > 0) {
            //                let asset: PHAsset = assets[0];
            //
            //                let ID: PHImageRequestID = manager.requestImage(
            //                    for: asset,
            //                    targetSize: PHImageManagerMaximumSize,
            //                    contentMode: PHImageContentMode.aspectFill,
            //                    options: options,
            //                    resultHandler: {
            //                        (image: UIImage?, info) in
            //                        self.messenger.send(onChannel: "adv_image_picker/image/fetch/original/\(albumId)/\(assetId)", message: UIImageJPEGRepresentation(image!, CGFloat(quality / 100)))
            //                })
            //
            //                if(PHInvalidImageRequestID != ID) {
            //                    result(true);
            //                }
            //            }
            //    case "pickImages":
            //        let vc = BSImagePickerViewController()
            //        let arguments = call.arguments as! Dictionary<String, AnyObject>
            //        let maxImages = arguments["maxImages"] as! Int
            //        let enableCamera = arguments["enableCamera"] as! Bool
            //        let options = arguments["iosOptions"] as! Dictionary<String, String>
            //        vc.maxNumberOfSelections = maxImages
            //
            //        if (enableCamera) {
            //            vc.takePhotos = true
            //        }
            //
            //        if let backgroundColor = options["backgroundColor"] {
            //            if (!backgroundColor.isEmpty) {
            //                vc.backgroundColor = hexStringToUIColor(hex: backgroundColor)
            //            }
            //        }
            //
            //        if let selectionFillColor = options["selectionFillColor"] {
            //            if (!selectionFillColor.isEmpty) {
            //                vc.selectionFillColor = hexStringToUIColor(hex: selectionFillColor)
            //            }
            //        }
            //
            //        if let selectionShadowColor = options["selectionShadowColor"] {
            //            if (!selectionShadowColor.isEmpty) {
            //                vc.selectionShadowColor = hexStringToUIColor(hex: selectionShadowColor)
            //            }
            //        }
            //
            //        if let selectionStrokeColor = options["selectionStrokeColor"] {
            //            if (!selectionStrokeColor.isEmpty) {
            //                vc.selectionStrokeColor = hexStringToUIColor(hex: selectionStrokeColor)
            //            }
            //        }
            //
            //        if let selectionTextColor = options["selectionTextColor"] {
            //            if (!selectionTextColor.isEmpty) {
            //                vc.selectionTextAttributes[NSAttributedStringKey.foregroundColor] = hexStringToUIColor(hex: selectionTextColor)
            //            }
            //        }
            //
            //        if let selectionCharacter = options["selectionCharacter"] {
            //            if (!selectionCharacter.isEmpty) {
            //                vc.selectionCharacter = Character(selectionCharacter)
            //            }
            //        }
            //
            //        controller!.bs_presentImagePickerController(vc, animated: true,
            //                                                    select: { (asset: PHAsset) -> Void in
            //
            //        }, deselect: { (asset: PHAsset) -> Void in
            //
            //        }, cancel: { (assets: [PHAsset]) -> Void in
            //            result([])
            //        }, finish: { (assets: [PHAsset]) -> Void in
            //            var results = [NSDictionary]();
            //            for asset in assets {
            //                results.append([
            //                    "identifier": asset.localIdentifier,
            //                    "width": asset.pixelWidth,
            //                    "height": asset.pixelHeight
            //                    ]);
            //            }
            //            print("result pickImages => \(results)")
            //            result(results);
            //        }, completion: nil)
            //    case "requestThumbnail":
            //        let arguments = call.arguments as! Dictionary<String, AnyObject>
            //        let identifier = arguments["identifier"] as! String
            //        let width = arguments["width"] as! Int
            //        let height = arguments["height"] as! Int
            //        let quality = arguments["quality"] as! Int
            //
            //        let manager = PHImageManager.default()
            //        let options = PHImageRequestOptions()
            //
            //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            //        options.resizeMode = PHImageRequestOptionsResizeMode.exact
            //        options.isSynchronous = false
            //        options.isNetworkAccessAllowed = true
            //
            //        let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            //
            //        //            print("count => \(assets.objects)")
            //        assets.enumerateObjects{(object: AnyObject!,
            //            count: Int,
            //            stop: UnsafeMutablePointer<ObjCBool>) in
            //            print("count => \(count)")
            //            if object is PHAsset{
            //                let asset = object as! PHAsset
            //
            //                //                    let ID: PHImageRequestID = manager.requestImage(
            //                //                        for: asset,
            //                //                        targetSize: CGSize(width: width, height: height),
            //                //                        contentMode: PHImageContentMode.aspectFill,
            //                //                        options: options,
            //                //                        resultHandler: {
            //                //                            (image: UIImage?, info) in
            //                //                            print("info => \(info)")
            //                //                            if info != nil {
            //                //                                self.messenger.send(onChannel: "adv_image_picker/image/" + identifier, message: UIImageJPEGRepresentation(image!, CGFloat(quality / 100)))
            //                //                            } else {
            //                //                                print("nilllll")
            //                //                            }
            //                //                    })
            //
            //
            //                //                    if (PHInvalidImageRequestID != ID) {
            //                //                        result(true);
            //                //                    }
            //            }
            //        }
            //    case "requestOriginal":
            //        let arguments = call.arguments as! Dictionary<String, AnyObject>
            //        let identifier = arguments["identifier"] as! String
            //        let quality = arguments["quality"] as! Int
            //        let manager = PHImageManager.default()
            //        let options = PHImageRequestOptions()
            //
            //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            //        options.isSynchronous = false
            //        options.isNetworkAccessAllowed = true
            //
            //        let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            //
            //        if (assets.count > 0) {
            //            let asset: PHAsset = assets[0];
            //
            //            let ID: PHImageRequestID = manager.requestImage(
            //                for: asset,
            //                targetSize: PHImageManagerMaximumSize,
            //                contentMode: PHImageContentMode.aspectFill,
            //                options: options,
            //                resultHandler: {
            //                    (image: UIImage?, info) in
            //                    self.messenger.send(onChannel: "adv_image_picker/image/" + identifier, message: UIImageJPEGRepresentation(image!, CGFloat(quality / 100)))
            //            })
            //
            //            if(PHInvalidImageRequestID != ID) {
            //                result(true);
            //            }
            //        }
            //    case "refreshImage":
            //        result(true) ;
            //        break ;
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
