# WebSpigot

WebSpigot is an image-go-getter. It first scrapes data from a random section of
news.google.com, then uses a random headline to find images (at bing, ironically).

By default it creates a 1920x1080 composite image `/tmp/spigot-composite.png`.

```
$ webspigot -h

Usage: webspigot

WebSpigot fetches random images based on Google News searches.

    -h, --help                       Display this message
        --height PIXELS              The height of the output image
        --width PIXELS               The width of the output image
        --blur-amount AMOUNT         When using --blur-previous, the amount of blurring to do
        --blur-previous              Blur the previous images each time a new image is displayed
        --max-retries RETRIES        The number of times to retry getting an image
        --monochrome-previous        Convert the previous images to monochrome each time a new image is displayed
        --outfile OUTFILE            The filename for the composite image
        --safe-mode MODE             Set safe mode to MODE (OFF, DEMOTE, STRICT)
```

### Some example usages:

```
$ webspigot --blur-previous --safe-mode OFF
$ webspigot --blur-previous --blur-amount 0x10 --monochrome-previous --delay 5
```
