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
typedef NS_ENUM(NSUInteger, ISMKType) {
    
    /**
     * Show.
     */
    ISMKTypeShow = 1,
    
    /**
     * Movie.
     */
    ISMKTypeMovie = 2,
};

extern NSString *const ISMKKeyType;

extern NSString *const ISMKKeyMovieIdentifier;
extern NSString *const ISMKKeyMovieTitle;
extern NSString *const ISMKKeyMovieThumbnail;
extern NSString *const ISMKKeyMovieBanner;

extern NSString *const ISMKKeyShowIdentifier;
extern NSString *const ISMKKeyShowTitle;
extern NSString *const ISMKKeyShowDescription;
extern NSString *const ISMKKeyShowThumbnail;
extern NSString *const ISMKKeyShowBanner;
extern NSString *const ISMKKeyShowDate;

extern NSString *const ISMKKeyEpisodeIdentifier;
extern NSString *const ISMKKeyEpisodeTitle;
extern NSString *const ISMKKeyEpisodeSeason;
extern NSString *const ISMKKeyEpisodeNumber;
extern NSString *const ISMKKeyEpisodeDescription;
extern NSString *const ISMKKeyEpisodeThumbnail;
