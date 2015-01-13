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

#import <iTVDb/iTVDb.h>
#import <ILMovieDB/ILMovieDBClient.h>
#import <ISUtilities/ISUtilities.h>

#import "ISMKDatabaseClient.h"
#import "ISMKShowParser.h"
#import "ISMediaKit.h"

@interface ISMKDatabaseClient ()

/**
 * Internal serial queue for performing fetches and (currently) synchronizing all properties.
 */
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

/**
 * Dispatch queue for performing completion callbacks to avoid leaking the internal worker queue.
 */
@property (nonatomic, readonly, strong) dispatch_queue_t completionQueue;

/**
 * Synchronized on workerQueue.
 */
@property (nonatomic, readonly, strong) NSMutableDictionary *showCache;

/**
 * Synchronized on workerQueue.
 */
@property (nonatomic, readonly, strong) ISMKShowParser *showParser;

/**
 * Synchronized on workerQueue.
 */
@property (nonatomic, readwrite, strong) NSDictionary *movieConfiguration;

/**
 * NSMutableArray for storing any pending completion blocks awaiting the movie configuration.
 *
 * Synchronized on workerQueue.
 */
@property (nonatomic, readonly, strong) NSMutableArray *movieConfigurationCompletionBlocks;

/**
 * Indicates whether the TMDB API key has been set.
 *
 * Synchronized on workerQueue.
 */
@property (nonatomic, readwrite, assign) BOOL hasAPIKeys;

/**
 * Indicates whether the TVDB API key has been set.
 */
@property (nonatomic, readwrite, assign) BOOL hasTVDBAPIKey;

/**
 * BOOL flag indicating whether we're currently fetching the movie configuration or not.
 *
 * YES if we're fetching the configuration, NO otherwise.
 *
 * Synchronized on workerQueue.
 */
@property (nonatomic, readwrite, assign) BOOL fetchingMovieConfiguration;

@property (nonatomic, readonly, strong) ILMovieDBClient *mdbClient;

@end

@implementation ISMKDatabaseClient

+ (NSString *)titleForFilenameFormatedTitle:(NSString *)filenameFormatedTitle
{
    NSArray *components = [filenameFormatedTitle componentsSeparatedByString:@"."];
    
    enum {
        StateScanning,
        StateSingleCharacter,
    };
    
    NSMutableArray *words = [NSMutableArray array];
    
    __block int state = StateScanning;
    __block NSMutableString *word = nil;
    
    [components enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
        
        if (state == StateScanning) {
            
            word = [component mutableCopy];
            [words addObject:word];
            
            if ([component length] == 1) {
                state = StateSingleCharacter;
            }
            
        } else if (state == StateSingleCharacter) {
            
            if ([component length] == 1) {
                [word appendString:component];
            } else {
                word = [component mutableCopy];
                [words addObject:word];
                
                state = StateScanning;
            }
            
        }
        
    }];
    
    return [words componentsJoinedByString:@" "];
}

+ (instancetype)sharedInstance
{
    static ISMKDatabaseClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ISMKDatabaseClient alloc] initInt];
    });
    return sharedInstance;
}

/**
 * Internal initializer.
 *
 * Not exposed to force all accesses through the sharedInstance. This is required to match the API key lifecycle of both
 * the TVDB and MDB client libraries.
 */
- (instancetype)initInt
{
    self = [super init];
    if (self) {
        _workerQueue = ISDispatchQueueCreate(@"uk.co.inseven", self, @"workerQueue", DISPATCH_QUEUE_SERIAL);
        _completionQueue = ISDispatchQueueCreate(@"uk.co.inseven", self, @"completionQueue", DISPATCH_QUEUE_CONCURRENT);
        _showCache = [NSMutableDictionary dictionary];
        _showParser = [ISMKShowParser new];
        _movieConfiguration = nil;
        _movieConfigurationCompletionBlocks = [NSMutableArray array];
        _fetchingMovieConfiguration = NO;
        _hasAPIKeys = NO;
        _mdbClient = [ILMovieDBClient sharedClient];
        _mdbClient.completionQueue = _completionQueue;
    }
    return self;
}

- (void)setTVDBAPIKey:(NSString *)tvdbAPIKey mdbAPIKey:(NSString *)mdbAPIKey
{
    __weak ISMKDatabaseClient *weakSelf = self;
    dispatch_async(self.workerQueue, ^{
        
        ISMKDatabaseClient *self = weakSelf;
        if (self == nil) {
            return;
        }
        
        self.hasAPIKeys = YES;
        [[TVDbClient sharedInstance] setApiKey:tvdbAPIKey];
        [[ILMovieDBClient sharedClient] setApiKey:mdbAPIKey];
        
    });
}

- (BOOL)configureWithFileAtPath:(NSString *)path error:(NSError **)error
{
    // Check the configuration exists.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        if (error) {
            NSString *reason = [NSString stringWithFormat:@"Configuration file not found at '%@'.", path];
            *error = [NSError errorWithDomain:ISMediaKitErrorDomain
                                         code:ISMediaKitErrorFileNotFound
                                     userInfo:@{ISMediaKitFailureReasonErrorKey: reason}];
            return NO;
        }
    }
    
    // Load the configuration.
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfFile:path];
    if (configuration == nil) {
        if (error) {
            NSString *reason = [NSString stringWithFormat:@"Unable to load configuration file at '%@'.", path];
            *error = [NSError errorWithDomain:ISMediaKitErrorDomain
                                         code:ISMediaKitErrorInvalidConfigurationFile
                                     userInfo:@{ISMediaKitFailureReasonErrorKey: reason}];
            return NO;
        }
    }
    
    // Check the tvdb-api-key exists.
    NSString *tvdbAPIKey = configuration[@"tvdb-api-key"];
    if (tvdbAPIKey == nil) {
        if (error) {
            NSString *reason = @"Unable to find 'tvdb-api-key' in the configuration file.";
            *error = [NSError errorWithDomain:ISMediaKitErrorDomain
                                         code:ISMediaKitErrorMissingKey
                                     userInfo:@{ISMediaKitFailureReasonErrorKey: reason}];
            return NO;
        }
    }
    
    // Check the mdb-api-key exists.
    NSString *mdbAPIKey = configuration[@"mdb-api-key"];
    if (mdbAPIKey == nil) {
        if (error) {
            NSString *reason = @"Unable to find 'mdb-api-key' in the configuration file.";
            *error = [NSError errorWithDomain:ISMediaKitErrorDomain
                                         code:ISMediaKitErrorMissingKey
                                     userInfo:@{ISMediaKitFailureReasonErrorKey: reason}];
            return NO;
        }
    }
    
    // Configure the client.
    [self setTVDBAPIKey:tvdbAPIKey mdbAPIKey:mdbAPIKey];
    
    return YES;
}

- (void)searchWithFilename:(NSString *)filename completionBlock:(void (^)(NSDictionary *))completionBlock
{
    __weak ISMKDatabaseClient *weakSelf = self;
    dispatch_async(self.workerQueue, ^{
        
        ISMKDatabaseClient *self = weakSelf;
        if (self == nil) {
            return;
        }
        
        ISAssert(self.hasAPIKeys, @"API keys not configured.");
        
        NSString *name = [[filename lastPathComponent] stringByDeletingPathExtension];
        
        // Determine the media type and dispatch as appropriate.
        if ([self.showParser parse:name]) {
            NSString *title = [ISMKDatabaseClient titleForFilenameFormatedTitle:self.showParser.show];
            [self metaDataForShow:title
                           season:[self.showParser.season integerValue]
                          episode:[self.showParser.episode integerValue]
                  completionBlock:completionBlock];
        } else {
            name = [ISMKDatabaseClient titleForFilenameFormatedTitle:name];

            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+?)( ((\\d{4})|\\((\\d{4})\\)))?$"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
            if ([regex numberOfMatchesInString:name options:0 range:NSMakeRange(0, name.length)] > 0) {
                
                NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:name
                                                                             options:0
                                                                               range:NSMakeRange(0, name.length)];
                
                NSLog(@"Number of ranges: %ld", [textCheckingResult numberOfRanges]);
                NSRange matchRange;
                
                // Title.
                matchRange = [textCheckingResult rangeAtIndex:1];
                NSString *title = [name substringWithRange:matchRange];
                
                // Year.
                NSInteger releaseYear = ISMediaKitUnknown;
                
                matchRange = [textCheckingResult rangeAtIndex:4];
                if (matchRange.location != NSNotFound) {
                    NSString *year = [name substringWithRange:matchRange];
                    releaseYear = [year integerValue];
                }
                
                matchRange = [textCheckingResult rangeAtIndex:5];
                if (matchRange.location != NSNotFound) {
                    NSString *year = [name substringWithRange:matchRange];
                    releaseYear = [year integerValue];
                }
                
                [self metaDataForMovie:title
                           releaseYear:releaseYear
                       completionBlock:completionBlock];

            } else {
                
                dispatch_async(self.completionQueue, ^{
                    completionBlock(nil);
                });
                
            }
            
            
        }
        
    });
}

- (void)metaDataForMovie:(NSString *)movie
             releaseYear:(NSInteger)releaseYear
         completionBlock:(void (^)(NSDictionary *))completionBlock
{
    __weak ISMKDatabaseClient *weakSelf = self;
    [self searchForMovie:movie releaseYear:releaseYear completionBlock:^(NSDictionary *movie) {
        
        ISMKDatabaseClient *self = weakSelf;
        if (self == nil) {
            return;
        }
        
        if (movie == nil) {
            dispatch_async(self.completionQueue, ^{
                completionBlock(nil);
            });
            return;
        }
        
        [self mdbConfigurationWithCompletionBlock:^(id configuration) {
            
            NSMutableDictionary *mutableMovie = [movie mutableCopy];
            
            if (configuration != nil) {
                
                NSString *baseURL = configuration[@"images"][@"base_url"];
                
                NSString *posterPath = mutableMovie[@"poster_path"];
                if (posterPath) {
                    mutableMovie[@"poster_path"] = [NSString stringWithFormat:@"%@original%@", baseURL, posterPath];
                }
                
                NSString *backdropPath = mutableMovie[@"backdrop_path"];
                if (backdropPath) {
                    mutableMovie[@"backdrop_path"] = [NSString stringWithFormat:@"%@original%@", baseURL, backdropPath];
                }
                
            }
            
            NSMutableDictionary *results = [NSMutableDictionary dictionary];
            
            ISSafeSetDictionaryKey(results, ISMKKeyType, @(ISMKTypeMovie));
            
            ISSafeSetDictionaryKey(results, ISMKKeyMovieIdentifier, mutableMovie[@"id"]);
            ISSafeSetDictionaryKey(results, ISMKKeyMovieTitle, mutableMovie[@"title"]);
            ISSafeSetDictionaryKey(results, ISMKKeyMovieThumbnail, mutableMovie[@"poster_path"]);
            ISSafeSetDictionaryKey(results, ISMKKeyMovieBanner, mutableMovie[@"backdrop_path"]);
            
            // Decode the release date.
            NSString *releaseDate = mutableMovie[@"release_date"];
            if (releaseDate) {
                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                [format setDateFormat:@"yyyy-MM-dd"];
                results[ISMKKeyMovieDate] = [format dateFromString:releaseDate];
            }
            
            dispatch_async(self.completionQueue, ^{
                completionBlock(results);
            });

            
        }];
        
    }];
}

- (void)metaDataForShow:(NSString *)show
                 season:(NSUInteger)season
                episode:(NSUInteger)episode
        completionBlock:(void (^)(NSDictionary *metaData))completionBlock
{
    __weak ISMKDatabaseClient *weakSelf = self;
    dispatch_async(self.workerQueue, ^{
        
        ISMKDatabaseClient *self = weakSelf;
        if (self == nil) {
            return;
        }
        
        // Find the TVDbEpisode.
        TVDbShow *tvdbShow = [self tvdbShowForTitle:show];
        if (tvdbShow == nil) {
            dispatch_async(self.completionQueue, ^{
                completionBlock(nil);
            });
            return;
        }
        
        TVDbEpisode *tvdbEpisode = nil;
        for (TVDbEpisode *e in tvdbShow.episodes) {
            if ([e.seasonNumber integerValue] == season &&
                [e.episodeNumber integerValue] == episode) {
                tvdbEpisode = e;
                break;
            }
        }
        
        // Fallback search.
        // Sometimes it seems this finds shows we can't find with the previous method.
        if (tvdbEpisode == nil) {
            tvdbEpisode
            = [TVDbEpisode findByShowId:tvdbShow.showId
                           seasonNumber:@(season)
                          episodeNumber:@(episode)];
        }
        
        // Exit if we weren't able to find a matching episode.
        if (tvdbEpisode == nil) {
            dispatch_async(self.completionQueue, ^{
                completionBlock(nil);
            });
            return;
        }
        
        NSMutableDictionary *results = [NSMutableDictionary dictionary];
        
        // Copy the properties.
        
        ISSafeSetDictionaryKey(results, ISMKKeyType, @(ISMKTypeShow));
        
        ISSafeSetDictionaryKey(results, ISMKKeyShowIdentifier, tvdbShow.showId);
        ISSafeSetDictionaryKey(results, ISMKKeyShowTitle, tvdbShow.title);
        ISSafeSetDictionaryKey(results, ISMKKeyShowDescription, tvdbShow.description);
        ISSafeSetDictionaryKey(results, ISMKKeyShowDate, tvdbShow.premiereDate);
        ISSafeSetDictionaryKey(results, ISMKKeyShowThumbnail, tvdbShow.poster);
        ISSafeSetDictionaryKey(results, ISMKKeyShowBanner, tvdbShow.fanart);
        
        ISSafeSetDictionaryKey(results, ISMKKeyEpisodeIdentifier, tvdbEpisode.episodeId);
        ISSafeSetDictionaryKey(results, ISMKKeyEpisodeTitle, tvdbEpisode.title);
        ISSafeSetDictionaryKey(results, ISMKKeyEpisodeSeason, @(season));
        ISSafeSetDictionaryKey(results, ISMKKeyEpisodeNumber, @(episode));
        ISSafeSetDictionaryKey(results, ISMKKeyEpisodeDescription, tvdbEpisode.description);
        ISSafeSetDictionaryKey(results, ISMKKeyEpisodeThumbnail, tvdbEpisode.bannerThumbnail);
        
        // Complete with the results.
        dispatch_async(self.completionQueue, ^{
            completionBlock(results);
        });
        
    });
}

- (TVDbShow *)tvdbShowForTitle:(NSString *)title
{
    // Check in the cache.
    TVDbShow *cachedShow =
    [self.showCache objectForKey:title];
    if (cachedShow) {
        return cachedShow;
    }
    
    // Find the show.
    NSMutableArray *shows = [TVDbShow findByName:title];
    if (shows.count == 0) {
        return nil;
    }
    
    // Accept the first match.
    TVDbShow *tvdbShow = shows[0];
    
    // We re-fetch the show by ID to get the full data.
    tvdbShow = [TVDbShow findById:tvdbShow.showId];
    
    // Check the show is valid.
    if (tvdbShow == nil ||
        tvdbShow.imdbId == nil) {
        return nil;
    }
    
    // Cache the show.
    self.showCache[title] = tvdbShow;
    
    return tvdbShow;
}

- (void)mdbConfigurationWithCompletionBlock:(void (^)(id configuration))completionBlock
{
    __weak ISMKDatabaseClient *weakSelf = self;
    dispatch_async(self.workerQueue, ^{
        
        ISMKDatabaseClient *self = weakSelf;
        if (self == nil) {
            return;
        }
        
        // Return the configuration if we have one.
        if (self.movieConfiguration) {
            dispatch_async(self.completionQueue, ^{
                completionBlock(self.movieConfiguration);
            });
            return;
        }
        
        // Cache the completion block.
        [self.movieConfigurationCompletionBlocks addObject:completionBlock];
        
        // Don't attempt to fetch if we're already fetching.
        if (self.fetchingMovieConfiguration) {
            return;
        }
        
        self.fetchingMovieConfiguration = YES;

        // Fetch the configuration.
        [self.mdbClient GET:kILMovieDBConfiguration parameters:nil block:^(id responseObject, NSError *error) {
            dispatch_async(self.workerQueue, ^{
                
                if (error == nil && responseObject) {
                    self.movieConfiguration = responseObject;
                }

                // Call any pending completion blocks.
                // N.B. This will complete all blocks with nil in the case of failure.
                for (void (^completionBlock)(id) in self.movieConfigurationCompletionBlocks) {
                    dispatch_async(self.completionQueue, ^{
                        completionBlock(self.movieConfiguration);
                    });
                }
                
                self.fetchingMovieConfiguration = NO;
                
            });
            
        }];
    });
}

- (void)searchForMovie:(NSString *)movie
           releaseYear:(NSInteger)releaseYear
       completionBlock:(void (^)(NSDictionary *movie))completionBlock
{
    __weak ISMKDatabaseClient *weakSelf = self;
    dispatch_async(self.workerQueue, ^{
        
        ISMKDatabaseClient *self = weakSelf;
        if (self == nil) {
            return;
        }

        __weak ISMKDatabaseClient *weakSelf = self;
        [self.mdbClient GET:kILMovieDBSearchMovie parameters:@{@"query": movie} block:^(id responseObject,
                                                                                        NSError *error) {
            
            ISMKDatabaseClient *self = weakSelf;
            if (self == nil) {
                return;
            }
            
            // Complete with nil as we were unable to find the movie.
            if (error) {
                dispatch_async(self.completionQueue, ^{
                    completionBlock(nil);
                });
                return;
            }
            
            NSDictionary *result = nil;
            
            if (responseObject) {
                
                NSArray *results = responseObject[@"results"];
                if (results && results.count > 0) {
                    
                    // Check the release year if one has been specified.

                    if (releaseYear == ISMediaKitUnknown) {
                        
                        result = results[0];
                        
                    } else {
                        
                        for (int i = 0; i < [results count]; i++) {
                            
                            // Decode the release date.
                            NSString *releaseDate = results[i][@"release_date"];
                            if (releaseDate) {
                                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                                [format setDateFormat:@"yyyy-MM-dd"];
                                NSDate *date = [format dateFromString:releaseDate];
                                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:date];
                                NSInteger year = [components year];
                                if (year == releaseYear) {
                                    result = results[i];
                                    break;
                                }
                                
                            }
                            
                        }
                        
                    }
                
                }
            }
            
            dispatch_async(self.completionQueue, ^{
                completionBlock(result);
            });
            
        }];
        
    });
}

@end
