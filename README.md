# KhanBadges
The "badges" programming challenge associated with my Khan Academy mobile developer job application.

# The Scenario

(I have made up the following narrative to drive this process).

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
