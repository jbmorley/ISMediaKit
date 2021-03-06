ISMediaKit
==========

Utilities for managing media.

[![Build Status](https://travis-ci.org/jbmorley/ISMediaKit.svg)](https://travis-ci.org/jbmorley/ISMediaKit)

Installation
------------

ISMediaKit is available through [CocoaPods](http://cocoapods.org/):

```
source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '10.9'
pod 'ISMediaKit', '~> 1.0'
```

Documentation
-------------

Documentation is available on [CocoaDocs](http://cocoadocs.org/docsets/ISMediaKit/).

Classes
-------

### ISMKDatabaseClient

The database client is configured as follows:

```objc
#import <ISMediaKit/ISMediaKit.h>

ISMKDatabaseClient *databaseClient = [ISMKDatabaseClient sharedInstance];
[databaseClient setTVDBAPIKey:@"0123456789ABCDEF"
                    mdbAPIKey:@"0123456789abcdef0123456789abcdef"];
```

TV shows can be searched for using the `searchWithFilename:completionBlock:` method:

```objc
[databaseClient searchWithFilename:@"jeeves.&.wooster.s01e01.mp4" completionBlock:^(NSDictionary *media) {
    NSLog(@"%@", media);
}];
```

This will output:

```
{
    EpisodeDescription = "Aunt Agatha wants Bertie to marry Honoria Glossop so that she will mold his character and infuse much needed strong blood in the Wooster line.  But old chum Bingo Little is in love with her, so Bertie hatches a scheme to set things straight. Luckily, Jeeves has arrived to save Bertie from his own schemes (and hangovers).";
    EpisodeIdentifier = 220723;
    EpisodeNumber = 1;
    EpisodeSeason = 1;
    EpisodeThumbnail = "http://www.thetvdb.com/banners/_cache/episodes/76934/220723.jpg";
    EpisodeTitle = "Jeeves Takes Charge";
    ShowBanner = "http://www.thetvdb.com/banners/fanart/original/76934-2.jpg";
    ShowDate = "1990-04-21 22:00:00 +0000";
    ShowDescription = "Bertram Wooster, a well-intentioned, wealthy layabout, has a habit of getting himself into trouble and it's up to his brilliant valet, Jeeves, to get him out.";
    ShowIdentifier = 76934;
    ShowThumbnail = "http://www.thetvdb.com/banners/posters/76934-4.jpg";
    ShowTitle = "Jeeves and Wooster";
    Type = 1;
}
```

Movies can be searched for using the exact same method:

```objc
[databaseClient searchWithFilename:@"back to the future.mp4" completionBlock:^(NSDictionary *media) {
    NSLog(@"%@", media);
}];
```

This will output:

```
{
    MovieBanner = "http://image.tmdb.org/t/p/original/x4N74cycZvKu5k3KDERJay4ajR3.jpg";
    MovieIdentifier = 105;
    MovieThumbnail = "http://image.tmdb.org/t/p/original/pTpxQB1N0waaSc3OSn0e9oc8kx9.jpg";
    MovieTitle = "Back to the Future";
    Type = 2;
}
```

Changelog
---------

### Version 1.0.1

- Support for shows of the format `show.title.123.ext` and `show.title.1221.ext`

### Version 1.0.0

- Initial release

Thanks
------

Many thanks to:

- [Gustavo Leguizamon](https://github.com/goopi) for [ILMovieDB](https://github.com/WatchApp/ILMovieDB)
- [Kevin Tuhumury](https://github.com/kevintuhumury) for [iTVDb](https://github.com/kevintuhumury/itvdb)

License
-------

ISMediaKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
