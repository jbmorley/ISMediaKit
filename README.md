ISMediaKit
==========

Utilities for managing media.

Classes
-------

### ISMediaLibrary

The following code:

```objc
#import <ISMediaKit/ISMediaKit.h>

ISMKDatabaseClient *databaseClient = [ISMKDatabaseClient sharedInstance];
[databaseClient searchWithFilename:@"jeeves.&.wooster.s01e01.mp4" completionBlock:^(NSDictionary *media) {
    NSLog(@"%@", media);
}];
```

Will output:

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