// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ChromecastDeviceController.h"
#import "Media.h"

/**
 * A view to play media locally, when not connected to the Chromecast device.
 */
@interface LocalPlayerViewController : UIViewController<ChromecastControllerDelegate>

/** The media object being played on Chromecast device. Set this before presenting the view. */
@property(strong, nonatomic) Media *mediaToPlay;

/** An outlet to bind to media description. */
@property(weak, nonatomic) IBOutlet UITextView *mediaDescription;

/** An outlet to bind to media title. */
@property(weak, nonatomic) IBOutlet UILabel *mediaTitle;

/** An outlet to bind to media subtitle. */
@property(weak, nonatomic) IBOutlet UILabel *mediaSubtitle;

@end