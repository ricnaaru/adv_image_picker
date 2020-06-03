#import "AdvImagePickerPlugin.h"
#import <adv_image_picker/adv_image_picker-Swift.h>

@implementation AdvImagePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAdvImagePickerPlugin registerWithRegistrar:registrar];
}
@end
