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

#import "MediaListModel.h"

@implementation MediaListModel {
    NSArray *_medias;
}

- (void)loadMedia:(void (^)(void))callbackBlock {
    // Asynchronously load the media json
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

    dispatch_async(queue, ^{
        NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL
                URLWithString:[NSString stringWithFormat:@"%@%@", MEDIA_URL_BASE, MEDIA_URL_FILE]]];

        dispatch_sync(dispatch_get_main_queue(), ^{
            NSError *error;

            NSMutableArray *mediaBuilder = [[NSMutableArray alloc] initWithCapacity:10];
            NSDictionary *mediaData =
                    [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
            if (error) {
                // Handle error here
                NSLog(@"Oh no! We got an error loading up our media data! %@",
                        [error localizedDescription]);
            } else {
                if (mediaData && [mediaData isKindOfClass:[NSDictionary class]]) {
                    NSArray *categories = [mediaData objectForKey:@"categories"];
                    if (categories && [categories isKindOfClass:[NSArray class]]) {
                        for (NSDictionary *category in categories) {
                            NSArray *mediaList = [category objectForKey:@"videos"];
                            if (mediaList && [mediaList isKindOfClass:[NSArray class]]) {
                                self.mediaTitle = [category objectForKey:@"name"];
                                for (NSDictionary *mediaOjbectAsDict in mediaList) {
                                    Media *nextMedia = [Media mediaFromExternalJSON:mediaOjbectAsDict];
                                    [mediaBuilder addObject:nextMedia];
                                }
                                break;
                            }
                        }
                    }
                }
            }
            _medias = [mediaBuilder copy];

            // Call the callback!
            callbackBlock();
        });
    });
}

- (int)numberOfMediaLoaded {
    return [_medias count];
}

- (Media *)mediaAtIndex:(int)index {
    return (Media *) [_medias objectAtIndex:index];
}

@end