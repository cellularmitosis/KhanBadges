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

152 of the badges are Challenge Patches:

```
$ cat badges.json | grep '"badge_category": 5' | wc -l
     152
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
    * No JSON validation.
    * No caching.
* Keep the UI cheap. 
  * Use what Apple gives you "for free".
  * No fancy effects (image fading, etc).
  * Favor storyboards over code.
  * Just target one device width.
* Keep the code cheap.
  * [MassiveViewController.](https://wififorce.files.wordpress.com/2009/04/badcable16.jpg?w=1200&h=)
  * [No](https://www.youtube.com/watch?v=WpkDN78P884&t=40m5s) [unit tests](http://i.imgur.com/Mcwm5.jpg).

## Step 3: Refined Product

OK, for reals now.

* Invest in the UI.
  * Fade in images which load from the network.
  * Provide useful "loading" indicators.
  * Handle 320, 375 and 414 widths appropriately.
* Invest in the UX.
  * Does everything tappable have a down-state? 
  * Handle the Sad-path (deal with errors in a user-friendly way)
* Invest in the code.
  * Performance and reliability
    * Obey the API's `Cache-Control` headers.
    * JSON structure should be validated (Value types, [motherfucker!](http://programming-motherfucker.com/)).
    * Subscription services (corral duplicate network requests)
  * Code quality
    * [Abstractions for healthy bones!](https://www.youtube.com/watch?v=WpkDN78P884)
    * [Immutable data types for shiny hair!](https://www.youtube.com/watch?v=7AqXBuJOJkY)
    * [Functional code for strong teeth!](https://www.destroyallsoftware.com/talks/boundaries)
  * But wait, what minimum iOS version are you targeting?
 

## Step 4: Accessible Product

* All strings localized
* [Respect](http://stackoverflow.com/questions/20510094/how-to-use-a-custom-font-with-dynamic-text-sizes-in-ios7) the user's "Larger Text" accessibility setting.
* [accssibilityLabel](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAccessibility_Protocol/index.html#//apple_ref/occ/instp/NSObject/accessibilityLabel)s where appropriate.

# Implementing Step 1

## The "Master" screen

There are two immediately obvious ways we can approach the UI of the "Master" screen.
* **List**: A table of icons with titles.
* **Grid**: A grid of icons (no text).

We will whip up a demo which can do both, and let our UX designer decide which is best.

### Line length

How long can the badge titles be?  We need to make sure our design can account for the longest one.

```
$ cat badges.json  | grep '"description":' | awk '{ print length, $0 }' | sort -n | tail -n 10
85         "description": "7th grade (U.S.): Expressions, equations, and inequalities", 
85         "description": "Algebra II: Rational expressions, equations, and functions", 
86         "description": "Algebra I: Expressions with rational exponents and radicals", 
87         "description": "7th grade (U.S.): Negative numbers: addition and subtraction", 
87         "description": "Algebra II: Polynomial expressions, equations, and functions", 
87         "description": "Probability and statistics: Independent and dependent events", 
90         "description": "7th grade (U.S.): Negative numbers: multiplication and division", 
91         "description": "Integral calculus: Sequences, series, and function approximation", 
96         "description": "Trigonometry: The unit circle definition of sine, cosine, and tangent", 
101         "description": "Probability and statistics: Random variables and probability distributions", 
```

(Thanks to [neillb](http://stackoverflow.com/a/5917762)).

Were this a real project, we would also have to consider other languages as well.  The German translation typically ends up being the longest string you need to cater for.

**Question for the UI designer**: Wrap to a second line, or shrink the font until it fits on a single line?

### Stumbling blocks

* Dragging images into the Asset catalog directly from Chrome.  [Ugh](http://stackoverflow.com/a/14737744).

So it turns out that if you grag a PNG directly from your web browser (Chrome) into Xcode, it appears to work, but `UIImage(named:)` will return nil.

If you right-click on the image in the Assets catalog, choose "Show in Finder", then drag the file back into the Assets catalog, **that** image will load just fine.

Argh!!!  I wasted half an hour on this one.

* [Blargh](http://stackoverflow.com/a/9898238).

## Detail screen

Here I chose to go with a simple Title/Image/Description vertical layout.

**Question for the UX designer**: Present detail VC modally or via nav stack?

Here again, we have to account for the longest line length possible.

```
$ cat badges.json | grep translated_safe_extended_description | awk '{ print length, $0 }' | sort -n | tail -n 1
159         "translated_safe_extended_description": "Achieve mastery in all skills in Probability and statistics: Random variables and probability distributions",
```

We will just target the iPhone 6 screen size for layout purposes.

## Results of Step 1

The list and grid options:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-12%20at%2012.02.04%20AM.png?token=AANopIfw_tL0wps4KW_f5Tqa79QotoYMks5WxrH4wA%3D%3D) ![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-12%20at%2012.02.07%20AM.png?token=AANopOJc9ZXyjuEjB14g03wWz8pQH-K6ks5WxrH7wA%3D%3D)

and the detail screen:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-12%20at%2012.02.21%20AM.png?token=AANopGQl01AT9-kPTqA-6uOGcCaFEwR-ks5WxrH-wA%3D%3D)

**The UX designer has decided to go with the "List" option**, and would like to present the detail view **modally**, as that would later allow for the detail view to become a "gallery" where the user could swipe right or left to view the details of other patches.

# Implementing Step 2

* To keep things simple, we will just fetch the largest image size for each patch and use that image throughout.
* Again, we will only layout for the iPhone 6 screen size.  Our A/B test will need to target iPhone 6 users specifically.
* The JSON and all images are stored in memory, which is flushed upon didRecieveMemoryWarning.  This is "good enough" for a small scale A/B test.

## Analytics

For the A/B test, we will record how many times user access the Challenge Patch list view (event name: "ListController.viewDidLoad") and how many times users view the details of patches (event name: "DetailViewController.viewDidLoad").

## Results of Step 2

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/step2.gif?token=AANopMo9yITQ2BpgJ8JYSEUwFYElsaSSks5WyOpJwA%3D%3D)

The data from the A/B test shows that 45% of users accessed the new feature at least once ("ListController.viewDidLoad"), and that on average each user looked at the details of 8 patches ("DetailsViewController.viewDidLoad").

Product thinks this is enough egagement to justify giving Dev the resources they need to in order to ["Do it right"](http://memesvault.com/wp-content/uploads/Meme-Faces-Challenge-Accepted-03.png).

# Implementing Step 3

## Image asset sizing

The Khan API makes badge images available in four sizes:
* small: 40x40
* compact: 60x60
* email: 70x70
* large: 512x512

Here's how that translates into "points":

|         |  px | pt (2x Retina) | pt (3x Retina) |
|---------|:---:|:--------------:|:--------------:|
| small   |  40 |       20       |      13.3      |
| compact |  60 |       30       |       20       |
| email   |  70 |       45       |      23.3      |
| large   | 512 |       256      |      170.7     |

As you can see, the reduces sizes are too small to be useful on Retina screens.  This means that for now **we will continue using the "large" size for everything**.

### Opportunity to improve Khan's image asset workflow

I would recomment that Khan consider using an [image resizing proxy](https://github.com/willnorris/imageproxy).  This has multiple benefits:
* The UI designer only needs to produce art at a single (large) resolution.
* Clients always get the optimal resolution for their layout.
* Mistakes associated with doing this by hand are eliminated
  * An example of one such mistake in the Khan API is the "email" size of the "Arithmetic: Addition and subtraction" badge:
    * small: addition-subtraction-40x40.png
    * compact: addition-subtraction-60x60.png
    * email: **master-challenge-blue-70x70.png**
    * large: addition-subtraction-250x250.png


## Detail layout: Targeting multiple screen sizes

Now that we need to target all screen sizes from the 4s up through the 6+, we need to revisit the layout of our detail view.

Here's what the result of **Step 2** looks like on various phones:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/v1%20240/Screen%20Shot%202016-02-13%20at%2012.11.50%20PM.png?token=AANopDwgzzPWPKPY-DqJMHHtDKLG91Dmks5WyKzqwA%3D%3D)

We need a layout strategy which will look reasonable on all supported screen sizes.

### Layout strategy A

Here's a vertical layout strategy which should produce reasonable results.  Consider this Autolayout diagram:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/Screen%20Shot%202016-02-13%20at%203.52.54%20PM.png?token=AANopC_Rgl78hipA3wv9vsrSPN_TQ1gnks5WyOJOwA%3D%3D)

(Here, the cyan square represents the title label, gray represents the patch image, and magenta represents the description label)

If we used fixed vertical spacing between the patch image and the text labels (24pt), then set a minimum spacing from the text labels to the screen edges (8pt), and finally, slightly reduce the patch images height priority (750), we get the following behavior as the title grows:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/cyan.gif?token=AANopFddICK4L5ir_iQ5cI7QhduYBJdpks5WyONGwA%3D%3D)

and similar behavior when the description grows:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/magenta.gif?token=AANopE5ziJZh4Gztvy9zT68Em52yyrZsks5WyONrwA%3D%3D)

With a little additional AutoLayout tweaking, we can apply this to UILabels and a UIImageView:

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/title2.gif?token=AANopKrJbusHPPKOLSM2CLZTX0ZCfk4bks5WyRbcwA%3D%3D)

![](https://raw.githubusercontent.com/cellularmitosis/KhanBadges/master/media/description2.gif?token=AANopMEYnYXT5aj6Y_reCCMbhzrFv8ffks5WyRbZwA%3D%3D)


### Patch image size

Visually, it would be nice to have the patch image occupy the same relative screen proportion across all phones.  Let's go with the golden ratio:

* iPhone 5 (320pt screen width): 198pt patch width
* iPhone 6 (375pt screen width): 232pt patch width
* iPhont 6+ (414pt screen width): 256pt patch width
