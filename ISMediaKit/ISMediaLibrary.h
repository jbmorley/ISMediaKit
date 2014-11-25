//
// Copyright (c) 2013-2014 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import <Foundation/Foundation.h>

/**
 * The media type.
 */
typedef NS_ENUM(NSUInteger, ISMediaLibraryType) {
    
    /**
     * TV Show.
     */
    ISMediaLibraryTypeTVShow = 1,
    
    /**
     * Movie.
     */
    ISMediaLibraryTypeMovie = 2,
};

extern NSString *const ISMediaLibraryKeyType;

extern NSString *const ISMediaLibraryKeyMovieIdentifier;
extern NSString *const ISMediaLibraryKeyMovieTitle;
extern NSString *const ISMediaLibraryKeyMovieThumbnail;
extern NSString *const ISMediaLibraryKeyMovieBanner;

extern NSString *const ISMediaLibraryKeyShowIdentifier;
extern NSString *const ISMediaLibraryKeyShowTitle;
extern NSString *const ISMediaLibraryKeyShowDescription;
extern NSString *const ISMediaLibraryKeyShowThumbnail;
extern NSString *const ISMediaLibraryKeyShowBanner;
extern NSString *const ISMediaLibraryKeyShowDate;

extern NSString *const ISMediaLibraryKeyEpisodeIdentifier;
extern NSString *const ISMediaLibraryKeyEpisodeTitle;
extern NSString *const ISMediaLibraryKeyEpisodeSeason;
extern NSString *const ISMediaLibraryKeyEpisodeNumber;
extern NSString *const ISMediaLibraryKeyEpisodeDescription;
extern NSString *const ISMediaLibraryKeyEpisodeThumbnail;


@interface ISMediaLibrary : NSObject

+ (instancetype)new __attribute__((unavailable("new not available")));
- (instancetype)init __attribute__((unavailable("init not available")));

+ (instancetype)sharedInstance;

- (void)setTVDBAPIKey:(NSString *)tvdbAPIKey mdbAPIKey:(NSString *)mdbAPIKey;
- (void)metaDataForTitle:(NSString *)title completionBlock:(void (^)(NSDictionary *metaData))completionBlock;

@end
