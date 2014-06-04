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
#import "LocalPlayerViewController.h"
#import "MediaTableViewController.h"
#import "SimpleImageFetcher.h"
#import "Media.h"
#import "MediaListModel.h"
#import <FireFly/FireFly.h>

@interface MediaTableViewController () {
    __weak ChromecastDeviceController *_chromecastController;
}

@property(nonatomic, strong) MediaListModel *mediaList;
@end

@implementation MediaTableViewController

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
    }
    return self;
}

- (void)dealloc {
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Store a reference to the chromecast controller.
    AppDelegate *delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    _chromecastController = delegate.chromecastDeviceController;

    // Show stylized application title in the titleview.
    self.navigationItem.titleView =
            [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_castvideos.png"]];

    // Display cast icon in the right nav bar button, if we have devices.
    if (_chromecastController.deviceScanner.devices.count > 0) {
        self.navigationItem.rightBarButtonItem = _chromecastController.chromecastBarButton;
    }

    // Asynchronously load the media json
    self.mediaList = [[MediaListModel alloc] init];
    [self.mediaList loadMedia:^{
        self.title = self.mediaList.mediaTitle;
        [self.tableView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Assign ourselves as delegate ONLY in viewWillAppear of a view controller.
    _chromecastController.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [_chromecastController updateToolbarForViewController:self];
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.mediaList numberOfMediaLoaded];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Media *media = [self.mediaList mediaAtIndex:indexPath.row];

    UILabel *mediaTitle = (UILabel *) [cell viewWithTag:1];
    mediaTitle.text = media.title;

    UILabel *mediaOwner = (UILabel *) [cell viewWithTag:2];
    mediaOwner.text = media.subtitle;

    // Asynchronously load the table view image
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

    dispatch_async(queue, ^{
        UIImage *image =
                [UIImage imageWithData:[SimpleImageFetcher getDataFromImageURL:media.thumbnailURL]];

        dispatch_sync(dispatch_get_main_queue(), ^{
            UIImageView *mediaThumb = (UIImageView *) [cell viewWithTag:3];
            [mediaThumb setImage:image];
            [cell setNeedsLayout];
        });
    });

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Display the media details view.
    [self performSegueWithIdentifier:@"playMedia" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"castMedia"] ||
            [[segue identifier] isEqualToString:@"playMedia"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Media *media = [self.mediaList mediaAtIndex:indexPath.row];
        [[segue destinationViewController] setMediaToPlay:media];
    }
}

#pragma mark - ChromecastControllerDelegate

/**
 * Called when chromecast devices are discoverd on the network.
 */
- (void)didDiscoverDeviceOnNetwork {
    // Add the chromecast icon if not present.
    self.navigationItem.rightBarButtonItem = _chromecastController.chromecastBarButton;
}

/**
 * Called when connection to the device was established.
 *
 * @param device The device to which the connection was established.
 */
- (void)didConnectToDevice:(ACKDevice *)device {
    [_chromecastController updateToolbarForViewController:self];
}

/**
 * Called when connection to the device was closed.
 */
- (void)didDisconnect {
    [_chromecastController updateToolbarForViewController:self];
}

/**
 * Called when the playback state of media on the device changes.
 */
- (void)didReceiveMediaStateChange {
    [_chromecastController updateToolbarForViewController:self];
}

/**
 * Called to display the modal device view controller from the cast icon.
 */
- (void)shouldDisplayModalDeviceController {
    [self performSegueWithIdentifier:@"listDevices" sender:self];
}

/**
 * Called to display the remote media playback view controller.
 */
- (void)shouldPresentPlaybackController {
    // Select the item being played in the table, so prepareForSegue can find the
    // associated Media object.
    NSString *title =
            [_chromecastController.mediaInformation.metadata stringForKey:kACKMetadataKeyTitle];
    for (int i = 0; i < self.mediaList.numberOfMediaLoaded; i++) {
        Media *media = [self.mediaList mediaAtIndex:i];
        if ([media.title isEqualToString:title]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionNone];
            [self performSegueWithIdentifier:@"castMedia" sender:self];
            break;
        }
    };
}

@end