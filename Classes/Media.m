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

#import "Media.h"

#define KEY_TITLE @"title"
#define KEY_DESCRIP @"subtitle"
#define KEY_URL @"sources"
#define KEY_MIME @"mimeType"
#define KEY_THUMBNAIL @"image-480x270"
#define KEY_POSTER @"image-780x1200"
#define KEY_OWNER @"studio"

@implementation Media

- (id)initWithExternalJSON:(NSDictionary *)jsonAsDict {
    self = [super init];
    if (self) {
        _title = [jsonAsDict objectForKey:KEY_TITLE];
        _descrip = [jsonAsDict objectForKey:KEY_DESCRIP];
        _mimeType = @"video/mp4";
        _subtitle = [jsonAsDict objectForKey:KEY_OWNER];

        NSString *URL = [[jsonAsDict objectForKey:KEY_URL] objectAtIndex:0];
        if ([URL hasPrefix:@"http"]) {
            _URL = [NSURL URLWithString:URL];
        } else {
            _URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", MEDIA_URL_BASE, URL]];
        }

        NSString *thumbnailPath = [jsonAsDict objectForKey:KEY_THUMBNAIL];
        if ([thumbnailPath hasPrefix:@"http://"]) {
            _thumbnailURL = [NSURL URLWithString:thumbnailPath];
        } else {
            _thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", MEDIA_URL_BASE, thumbnailPath]];
        }

        NSString *posterPath = [jsonAsDict objectForKey:KEY_POSTER];
        if ([posterPath hasPrefix:@"http://"]) {
            _posterURL = [NSURL URLWithString:posterPath];
        } else {
            _posterURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", MEDIA_URL_BASE, posterPath]];
        }
    }
    return self;

}

+ (id)mediaFromExternalJSON:(NSDictionary *)jsonAsDict {
    Media *newMedia = [[Media alloc] initWithExternalJSON:jsonAsDict];
    return newMedia;
}

@end