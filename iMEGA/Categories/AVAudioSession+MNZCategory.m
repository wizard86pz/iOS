
#import "AVAudioSession+MNZCategory.h"

@implementation AVAudioSession (MNZCategory)

- (void)mnz_setSpeakerEnabled:(BOOL)enabled {
    MEGALogDebug(@"[AVAudioSession] Set speaker enabled %@", enabled ? @"YES" : @"NO");
    if (AVAudioSession.sharedInstance.currentRoute.outputs.count > 0) {
        AVAudioSessionPortDescription *audioSessionPortDestription = AVAudioSession.sharedInstance.currentRoute.outputs.firstObject;
        NSError *error;
        if (enabled) {
            if ([audioSessionPortDestription.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
                MEGALogDebug(@"[AVAudioSession] Override output audio port from receiver to speaker");
                if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
                    MEGALogError(@"[AVAudioSession] Error %@ overriding output audio port to AVAudioSessionPortOverrideSpeaker", error);
                }
            }
        } else {
            if ([audioSessionPortDestription.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
                MEGALogDebug(@"[AVAudioSession] Override output audio port from speaker to receiver");
                if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
                    MEGALogError(@"[AVAudioSession] Error %@ overriding output audio port to AVAudioSessionPortOverrideNone", error);
                }
            }
        }
    } else {
        MEGALogWarning(@"[AVAudioSession] Array of audio outputs is empty");
    }
}

- (BOOL)mnz_isOutputEqualToPortType:(AVAudioSessionPort)portType {
    BOOL ret = NO;
    if (AVAudioSession.sharedInstance.currentRoute.outputs.count > 0) {
        AVAudioSessionPortDescription *audioSessionPortDestription = AVAudioSession.sharedInstance.currentRoute.outputs.firstObject;
        if ([audioSessionPortDestription.portType isEqualToString:portType]) {
            ret = YES;
        }
    } else {
        MEGALogWarning(@"[AVAudioSession] Array of audio outputs is empty");
    }
    
    MEGALogDebug(@"[AVAudioSession] Is the output equal to %@? %@", portType, ret ? @"YES" : @"NO");
    return ret;
}

- (BOOL)mnz_isBluetoothAudioConnected {
    BOOL ret = NO;
    NSArray *outputs = AVAudioSession.sharedInstance.currentRoute.outputs;
    for (AVAudioSessionPortDescription *port in outputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP] ||
            [port.portType isEqualToString:AVAudioSessionPortBluetoothLE] ||
            [port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            ret = YES;
            break;
        }
    }
    
    MEGALogDebug(@"[AVAudioSession] Is there any bluetooth audio connected? %@", ret ? @"YES" : @"NO");
    return ret;
}

- (BOOL)mnz_isBluetoothAudioRouteAvailable {
    __block BOOL isBluetoothAudioRouteAvailable = NO;
    [AVAudioSession.sharedInstance.availableInputs enumerateObjectsUsingBlock:^(AVAudioSessionPortDescription *description, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([@[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP] containsObject:description.portType]) {
            isBluetoothAudioRouteAvailable = YES;
            *stop = YES;
        }
    }];
    
    MEGALogDebug(@"[AVAudioSession] Is there any bluetooth audio available? %@", isBluetoothAudioRouteAvailable ? @"YES" : @"NO");
    return isBluetoothAudioRouteAvailable;
}

@end
