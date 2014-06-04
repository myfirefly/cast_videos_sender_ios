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

#import "AppDelegate.h"
#import "DeviceTableViewController.h"
#import "ChromecastDeviceController.h"
#import "SimpleImageFetcher.h"
#import <FireFly/FireFly.h>


NSString *const CellIdForDeviceName = @"deviceName";

@interface DeviceTableViewController ()

@end

@implementation DeviceTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (ChromecastDeviceController *)castDeviceController {
    AppDelegate *delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    return delegate.chromecastDeviceController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (self.castDeviceController.isConnected == NO) {
        self.title = @"Connect to";
        return self.castDeviceController.deviceScanner.devices.count;
    } else {
        self.title =
                [NSString stringWithFormat:@"Connected to %@", self.castDeviceController.deviceName];
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdForDeviceName = @"deviceName";
    static NSString *CellIdForReadyStatus = @"readyStatus";
    static NSString *CellIdForDisconnectButton = @"disconnectButton";
    static NSString *CellIdForPlayerController = @"playerController";

    UITableViewCell *cell;
    if (self.castDeviceController.isConnected == NO) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDeviceName forIndexPath:indexPath];

        // Configure the cell...
        ACKDevice *device = [self.castDeviceController.deviceScanner.devices objectAtIndex:indexPath.row];

        cell.textLabel.text = device.friendlyName;
        cell.detailTextLabel.text = device.modelName;

    } else if (self.castDeviceController.isPlayingMedia == NO) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForReadyStatus
                                                   forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDisconnectButton
                                                   forIndexPath:indexPath];
        }

    } else {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForPlayerController
                                                   forIndexPath:indexPath];
            cell.textLabel.text =
                    [self.castDeviceController.mediaInformation.metadata stringForKey:kACKMetadataKeyTitle];
            cell.detailTextLabel.text = [self.castDeviceController.mediaInformation.metadata
                    stringForKey:kACKMetadataKeySubtitle];

            // Accessory is the play/pause button.
            BOOL playing = (self.castDeviceController.playerState == ACKMediaPlayerStatePlaying ||
                    self.castDeviceController.playerState == ACKMediaPlayerStateBuffering);
            UIImage *playImage = (playing ? [UIImage imageNamed:@"pause_black.png"]
                    : [UIImage imageNamed:@"play_black.png"]);
            CGRect frame = CGRectMake(0, 0, playImage.size.width, playImage.size.height);
            UIButton *button = [[UIButton alloc] initWithFrame:frame];
            [button setBackgroundImage:playImage forState:UIControlStateNormal];
            [button addTarget:self
                       action:@selector(playPausePressed:)
             forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;

            // Asynchronously load the table view image
            if (self.castDeviceController.mediaInformation.metadata.images.count > 0) {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

                dispatch_async(queue, ^{
                    ACKImage *mediaImage =
                            [self.castDeviceController.mediaInformation.metadata.images objectAtIndex:0];
                    UIImage *image =
                            [UIImage imageWithData:[SimpleImageFetcher getDataFromImageURL:mediaImage.URL]];

                    CGSize itemSize = CGSizeMake(40, 40);
                    UIImage *thumbnailImage = [self scaleImage:image toSize:itemSize];

                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UIImageView *mediaThumb = cell.imageView;
                        [mediaThumb setImage:thumbnailImage];
                        [cell setNeedsLayout];
                    });
                });
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDisconnectButton
                                                   forIndexPath:indexPath];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.castDeviceController.isConnected == NO) {
    if (indexPath.row < self.castDeviceController.deviceScanner.devices.count) {
      ACKDevice *device =
          [self.castDeviceController.deviceScanner.devices objectAtIndex:indexPath.row];
      NSLog(@"Selecting device:%@", device.friendlyName);
      [self.castDeviceController connectToDevice:device];
    }
  } else if (self.castDeviceController.isPlayingMedia == YES && indexPath.row == 0) {
    if ([self.castDeviceController.delegate
            respondsToSelector:@selector(shouldPresentPlaybackController)]) {
      [self.castDeviceController.delegate shouldPresentPlaybackController];
    }
    }
    // Dismiss the view.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)                       tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Accesory button tapped");
}

- (IBAction)disconnectDevice:(id)sender {
    [self.castDeviceController disconnectFromDevice];

    // Dismiss the view.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)stopApplication:(id)sender {
    [self.castDeviceController stopApplication];

    // Dismiss the view.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playPausePressed:(id)sender {
    BOOL playing = (self.castDeviceController.playerState == ACKMediaPlayerStatePlaying ||
            self.castDeviceController.playerState == ACKMediaPlayerStateBuffering);
    [self.castDeviceController pauseCastMedia:playing];

    // change the icon.
    UIButton *button = sender;
    UIImage *playImage =
            (playing ? [UIImage imageNamed:@"play_black.png"] : [UIImage imageNamed:@"pause_black.png"]);
    [button setBackgroundImage:playImage forState:UIControlStateNormal];
}

#pragma mark - implementation
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize {
    CGSize scaledSize = newSize;
    float scaleFactor = 1.0;
    if (image.size.width > image.size.height) {
        scaleFactor = image.size.width / image.size.height;
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.height / scaleFactor;
    } else {
        scaleFactor = image.size.height / image.size.width;
        scaledSize.height = newSize.height;
        scaledSize.width = newSize.width / scaleFactor;
    }

    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, 0.0);
    CGRect scaledImageRect = CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height);
    [image drawInRect:scaledImageRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

@end