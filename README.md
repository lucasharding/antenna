[![Antenna](https://raw.githubusercontent.com/lucasharding/antenna/master/Screenshots/wordmark.png)](https://lucasharding.github.io/antenna/)

[![Release](https://img.shields.io/github/release/lucasharding/antenna.svg)](https://github.com/lucasharding/antenna/releases/latest)
![Swift](https://img.shields.io/badge/swift-3.0-green.svg)
[![License](https://img.shields.io/github/license/lucasharding/antenna.svg)](https://github.com/lucasharding/antenna/blob/master/COPYING)
[![Downloads](https://img.shields.io/github/downloads/lucasharding/antenna/total.svg)](https://github.com/lucasharding/antenna/releases)
[![Donate](https://img.shields.io/badge/donate-on%20paypal-orange.svg)](https://paypal.me/lucasharding/5usd)

## What is it?

Antenna (formerly NTNA) is a live TV app for Apple TV powered by (but not affiliated with) [**USTVnow**](http://watch.ustvnow.com/refu/3EvqFs74RhoknoEGQzhpZL7zfcowiiQk). Unfortunately, since USTVnow operates in a 'grey area', Apple will not accept Antenna to the official tvOS App Store.

###[Sign up for a free USTVnow account here.](http://watch.ustvnow.com/refu/3EvqFs74RhoknoEGQzhpZL7zfcowiiQk)

PS. I haven't really touched this code in a while, and it's gone through some Xcode Swift auto-migrations, so there might be some oddities.

![Screenshot](https://raw.githubusercontent.com/lucasharding/antenna/master/Screenshots/01_streaming.png)
![Screenshot](https://raw.githubusercontent.com/lucasharding/antenna/master/Screenshots/02_guide.png)

## Requirements

- A Mac, preferably running the latest version of OS X (currently 10.12.x Sierra)
- Xcode 8+
- iOS 10 SDK / tvOS 10 SDK
- Apple Developer Account (You can use a free account, but you will need to re-install every 7 days)
- USB-C cable for building to Apple TV

## Installing

### Option 1 (Recommended): Sign the prebuilt .ipa

1. Download the .ipa file from the [releases page](https://github.com/lucasharding/antenna/releases/latest).
2. Follow the instructions [here](https://dantheman827.github.io/ios-app-signer/) to resign the app with your developer certificate. Of course substitute any references to kodi with antenna. The YouTube video will explain how to get the Top Shelf working as well.

**Note on how to get top shelf working**: Your main 'bundle identifier' and your 'app group identifiers' must be identical. And your top shelf's 'bundle identifier' must also be identical but with '.topshelf' appended.

```
Example:
bundle identifier: com.johnsmith.antenna
top shelf bundle identifier: com.johnsmith.antenna.topshelf
app group bundle identifiers: com.johnsmith.antenna
```

### Option 2: Build from source

#### Initial Setup

You'll need a few things before we get started. Make sure you have Xcode 8+ installed from the App Store. Then run the following two commands to install Xcode's command line tools and bundler, if you don't have those installed.

```
xcode-select --install
sudo gem install bundler
```
Then run the following to download and setup the project.

```
git clone https://github.com/lucasharding/antenna.git
cd antenna
bundle install
bundle exec pod install
```

Now that we have the code downloaded, you can run the app using Xcode 8. Make sure to open the **antenna.xcworkspace** workspace, and not the antenna.xcodeproj project.

To be able to run on device you will need to change the App IDs. Follow these instructions:

```
1. In Xcode select the menu 'Find > Find and Replace in Workspace...'
2. Enter 'com.lucasharding' into the search field
3. Enter 'com.{youruniquename}' into the replace field
4. Click 'Replace All'
```

You should be able to run and

#### Updating

Substitute ``~/development/antenna`` with the path to the project code

```
cd ~/development/antenna
git pull origin master
bundle exec pod install
```

## Questions

If you have questions about any aspect of this project, please feel free to [open an issue](https://github.com/lucasharding/antenna/issues/new).

## Contributing

The main motivation for releasing the source of Antenna was a ways of distribution since Apple won't accept it to the App Store, so I'm not expecting many contributions. With that said, if you encounter any bugs, feel free to submit a pull request. If you are considering any larger feature development, please [open an issue](https://github.com/lucasharding/antenna/issues/new) first so we can discuss implementation.

