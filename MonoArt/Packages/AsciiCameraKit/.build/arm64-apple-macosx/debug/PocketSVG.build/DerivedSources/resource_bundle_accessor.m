#import <Foundation/Foundation.h>

NSBundle* PocketSVG_SWIFTPM_MODULE_BUNDLE() {
    NSURL *bundleURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"PocketSVG_PocketSVG.bundle"];

    NSBundle *preferredBundle = [NSBundle bundleWithURL:bundleURL];
    if (preferredBundle == nil) {
      return [NSBundle bundleWithPath:@"/Users/barryalien/Documents/code/MonoArt/MonoArt/Packages/AsciiCameraKit/.build/arm64-apple-macosx/debug/PocketSVG_PocketSVG.bundle"];
    }

    return preferredBundle;
}