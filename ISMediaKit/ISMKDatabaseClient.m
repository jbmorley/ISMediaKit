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
    dispatch_async(self.workerQueue, ^{
        self.hasAPIKeys = YES;
        [[TVDbClient sharedInstance] setApiKey:tvdbAPIKey];
        [[ILMovieDBClient sharedClient] setApiKey:mdbAPIKey];
    });
}

- (void)searchWithFilename:(NSString *)filename completionBlock:(void (^)(NSDictionary *))completionBlock
{
    dispatch_async(self.workerQueue, ^{
        ISAssert(self.hasAPIKeys, @"API keys not configured.");
        
        NSString *name = [[filename lastPathComponent] stringByDeletingPathExtension];
        
        // Determine the media type and dispatch as appropriate.
        if ([self.showParser parse:name]) {
            [self metaDataForShow:self.showParser.show
                           season:[self.showParser.season integerValue]
                          episode:[self.showParser.episode integerValue]
                  completionBlock:completionBlock];
        } else {
            [self metaDataForMovie:name
                   completionBlock:completionBlock];
        }
        
    });
}

- (void)metaDataForMovie:(NSString *)movie completionBlock:(void (^)(NSDictionary *))completionBlock
{
    [self searchForMovie:movie completionBlock:^(NSDictionary *movie) {
        
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
    dispatch_async(self.workerQueue, ^{
        
        // TODO Correct the title to account for S.H.I.E.L.D
        
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
    dispatch_async(self.workerQueue, ^{
        
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

- (void)searchForMovie:(NSString *)movie completionBlock:(void (^)(NSDictionary *movie))completionBlock
{
    dispatch_async(self.workerQueue, ^{

        [self.mdbClient GET:kILMovieDBSearchMovie parameters:@{@"query": movie} block:^(id responseObject,
                                                                                        NSError *error) {
            
            // Complete with nil as we were unable to find the movie.
            if (error) {
                dispatch_async(self.completionQueue, ^{
                    completionBlock(nil);
                });
                return;
            }
            
            if (responseObject) {
                NSArray *results = responseObject[@"results"];
                if (results && results.count > 0) {
                    dispatch_async(self.completionQueue, ^{
                        completionBlock(results[0]);
                    });
                }
            }
            
        }];
        
    });
}

@end
