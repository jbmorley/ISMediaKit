//
//  ISMediaKitTests.m
//  ISMediaKitTests
//
//  Created by Jason Barrie Morley on 04/12/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <ISMediaKit/ISMediaKit.h>

@interface ISMediaKitTests : XCTestCase

@property (nonatomic, readwrite, strong) ISMKDatabaseClient *client;

@end

@implementation ISMediaKitTests

- (void)configureDatabaseClient:(NSString *)path
{
    // TODO Movie this into a loadConfiguration: call.
    
    // Check the configuration exists.
    NSString *configurationPath = [path stringByExpandingTildeInPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:configurationPath]) {
        XCTFail(@"Configuration file not found at '%@'.\n", configurationPath);
    }
    
    // Load the configuration.
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfFile:configurationPath];
    if (configuration == nil) {
        XCTFail(@"Unable to load configuration file at '%@'.\n", configurationPath);
    }
    
    // Check the tvdb-api-key exists.
    NSString *tvdbAPIKey = configuration[@"tvdb-api-key"];
    if (tvdbAPIKey == nil) {
        XCTFail(@"Unable to find 'tvdb-api-key' in the configuration file.\n");
    }
    
    // Check the mdb-api-key exists.
    NSString *mdbAPIKey = configuration[@"mdb-api-key"];
    if (mdbAPIKey == nil) {
        XCTFail(@"Unable to find 'mdb-api-key' in the configuration file.\n");
    }

    // Configure the client.
    [self.client setTVDBAPIKey:tvdbAPIKey
                     mdbAPIKey:mdbAPIKey];
}

- (void)setUp
{
    [super setUp];
    self.client = [ISMKDatabaseClient sharedInstance];
    XCTAssertNotNil(self.client, @"Unable to get the shared client instance");
    // TODO This currently shares the configuration file with add-to-itunes and needs to be changed.
    [self configureDatabaseClient:@"~/.add-to-itunes.plist"];
}

- (void)tearDown
{
    [super tearDown];
}

- (NSDictionary *)searchForFilename:(NSString *)filename
{
    __block NSDictionary *result = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [self.client searchWithFilename:filename completionBlock:^(NSDictionary *media) {
        result = media;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return result;
}

- (void)testArrowS01E01
{
    NSDictionary *media = [self searchForFilename:@"arrow.s01e01.m4v"];
    XCTAssertEqualObjects(media[ISMKKeyShowTitle], @"Arrow");
    XCTAssertEqualObjects(media[ISMKKeyEpisodeTitle], @"Pilot");
    XCTAssertEqualObjects(media[ISMKKeyEpisodeSeason], @1);
    XCTAssertEqualObjects(media[ISMKKeyEpisodeNumber], @1);
}

- (void)testJeevesAndWooster
{
    NSDictionary *media = nil;
    
    media = [self searchForFilename:@"jeeves.&.wooster.s01e03.m4v"];
    XCTAssertEqualObjects(media[ISMKKeyShowTitle], @"Jeeves and Wooster");
    XCTAssertEqualObjects(media[ISMKKeyEpisodeTitle], @"The Purity of the Turf");
    XCTAssertEqualObjects(media[ISMKKeyEpisodeSeason], @1);
    XCTAssertEqualObjects(media[ISMKKeyEpisodeNumber], @3);
    
    media = [self searchForFilename:@"jeeves.and.wooster.s01e03.m4v"];
    XCTAssertEqualObjects(media[ISMKKeyShowTitle], @"Jeeves and Wooster");
    XCTAssertEqualObjects(media[ISMKKeyEpisodeTitle], @"The Purity of the Turf");
    XCTAssertEqualObjects(media[ISMKKeyEpisodeSeason], @1);
    XCTAssertEqualObjects(media[ISMKKeyEpisodeNumber], @3);
}

@end
