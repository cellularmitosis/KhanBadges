# KhanBadges
The "badges" programming challenge associated with my Khan Academy mobile developer job application.

# The Scenario

Product would like for badges to have more of a mobile presence.  To prevent the UX from becomming bloated, it has been decided that we will focus only on "Challenge Patches" initially, as those are thought to have the greatest potential for engagement on the mobile platform.

Unfortunately, both the UX and UI designers are booked at the moment, but Product needs to get the ball rolling, so Dev has been asked to come up with a prototype: "Just make somthing, you know, mobile-y".

Product would like for Dev to start with a typical master-detail prototype, which will be the basis for further iteration once UX and UI are freed up.

# Source Material

## UI/UX Source Material

First, let's get the context of how badges are currently displayed.

This is how the website displays Challenge Patches:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-11%20at%207.17.16%20PM.png?token=AANopOtsO0bhcQgCrlDy1C8ZyZJXVKcLks5WxnBFwA%3D%3D)

Here's the same but in a mobile width:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-11%20at%207.10.49%20PM.png?token=AANopCx555CMTA1hOLECDRHRcgyn14F9ks5WxnBCwA%3D%3D)

The iOS app does not currently display badges.  It only shows badge categories:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-11%20at%207.24.34%20PM.png?token=AANopGXvvWoSyJR7LBeIIQX5OUTdENQrks5WxnBIwA%3D%3D)

## API Source Material

There are 246 badges organized into 6 categories.

```
$ curl http://www.khanacademy.org/api/v1/badges/categories?format=pretty 2>/dev/null | grep type_label
        "type_label": "Meteorite Badges", 
        "type_label": "Moon Badges", 
        "type_label": "Earth Badges", 
        "type_label": "Sun Badges", 
        "type_label": "Black Hole Badges", 
        "type_label": "Challenge Patches", 
```

```
$ curl http://www.khanacademy.org/api/v1/badges?format=pretty 2>/dev/null | grep relative_url | wc -l
     246
```

# The Plan

## Step 1: Rough (Offline) Prototype for UX

Make a very rough prototype which the UX designer can use to decide if this idea is any good.

Notes:
* No network code.  Just hard-code in enough data to get a sense of the UX.
* Happy-path only.  Worry about errors later
 * (Actually, perhaps the conversation about error-state UX should start here?)

## Step 2: Minimally Functional Demo With Minimal UI

Create a Minimum Viable Product.  This should be something just good enough to use in an A/B test for 5% of your userbase.  This step should verify that the API is workable.

* No hard-coded data.  Fetch everything needed from the API.
  * However, keep it cheap.
    * Dumb dictionaries.
    * No JSON verification.
    * No caching.
* Keep the UI cheap. 
  * Use what Apple gives you "for free".
  * No fancy effects (image fading, etc).
  * Favor storyboards over code.
* Keep the code cheap.
  * [MassiveViewController.](https://wififorce.files.wordpress.com/2009/04/badcable16.jpg?w=1200&h=)
  * [No](https://www.youtube.com/watch?v=WpkDN78P884&t=40m5s) [unit tests](http://i.imgur.com/Mcwm5.jpg).

## Step 3: Refined Product

OK, for reals now.

* Invest in the UI.
  * Fade in images which load from the network.
  * Provide useful "loading" indicators.
* Invest in the UX.
  * Does everything tappable have a down-state? 
  * Handle the Sad-path (deal with errors in a user-friendly way)
* Invest in the code.
  * Performance and reliability
    * Obey the API's `Cache-Control` headers.
    * JSON structure should be verified (Value types, [motherfucker!](http://programming-motherfucker.com/)).
    * Subscription services (corral duplicate network requests)
  * Code quality
    * [Abstractions for healthy bones!](https://www.youtube.com/watch?v=WpkDN78P884)
    * [Immutable data types for shiny hair!](https://www.youtube.com/watch?v=7AqXBuJOJkY)
    * [Functional code where possible.](https://www.destroyallsoftware.com/talks/boundaries)
  * But wait, what minimum iOS version are you targeting?
 

## Step 4: Accessible Product

Check your priviledge.

* [Respect](http://stackoverflow.com/questions/20510094/how-to-use-a-custom-font-with-dynamic-text-sizes-in-ios7) the user's "Larger Text" accessibility setting.
* [accssibilityLabel](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAccessibility_Protocol/index.html#//apple_ref/occ/instp/NSObject/accessibilityLabel)s where appropriate.

# Implementing Step 1

## The "Master" screen

There are two immediately obvious ways we can approach the UI of the "Master" screen.
* **List**: A table of icons with titles.
* **Grid**: A grid of icons (no text).

We will whip up a demo which can do both, and let our UX designer decide which is best.

### Stumbling blocks

* Dragging images into the Asset catalog directly from Chrome

So it turns out that if you grag a PNG directly from your web browser (Chrome) into Xcode, it appears to work, but `UIImage(named:)` will return nil.

If you right-click on the image in the Assets catalog, choose "Show in Finder", then drag the file back into the Assets catalog, **that** image will load just fine.

Argh!!!  I wasted half an hour on this one.
