
**_Welcome to $(PRODUCT_NAME)_**

Installing fonts on iOS is much harder than it needs to be.

At some point, you’ll probably need to refer to this page. Maybe it’s after you download the font installer and don’t know to proceed. Maybe it’s when you’re prompted to enter your passcode and having second thoughts after a security warning. When this happens, the information below should help you sort things out.


**_Overview_**

The approach here is to copy font files from either iCloud Drive or Dropbox onto your device using the **Add** button. Once they’re stored locally, you’ll use **Install** to create a mobile device configuration profile. That profile lets the _Settings_ app store the fonts in a way that makes them available to all iOS apps.

The fonts you add to $(PRODUCT_NAME) can also be previewed by tapping on the name. When you add a new font to the list, it will be highlighted and you will be prompted to create a new installer: the new faces won’t be available to the system until they are registered with _Settings_.


**_Add Your Fonts_**

iOS can use fonts that are in the Open Type or True Type formats (look for .otf and .ttf file extensions). You can download these fonts directly to your Files using Safari or you can copy them into cloud storage from another device, including a Mac or PC.

When you tap the **Add** button in the top-left corner of the Fonts list, a file browser will open that lets you navigate to the folder where fonts are stored. You can tap on a single font to import it into $(PRODUCT_NAME) – use _Select_ and _Open_ to get multiple files at once.

After import, the fonts will appear in the list and can be previewed. If you change your mind about a font, just swipe left to delete it (this won’t affect the original fonts in Files).

You’re now ready to install the fonts so other apps can use them.


**_Install and Download_**

When you tap the **Install** button in the top-right corner of the Fonts list, a web browser will open with a prominent **Download Fonts** button. After tapping that button you’ll see a warning that “This website is trying to download a configuration profile”. You just put the fonts on your device but now you have to download them. What the heck is going on?

$(PRODUCT_NAME) created a “mobile device configuration profile” that contains a copy of each font you want to use. The app also started a webserver on your device to give Safari access to that configuration file. When you tap the download link, you’re essentially copying the fonts into your settings.

Normally, you should be very careful about downloading configuration profiles. You’re giving a developer the ability to [update your device settings](https://developer.apple.com/business/documentation/Configuration-Profile-Reference.pdf). This includes [embedding identity trackers](https://twitter.com/sandofsky/status/1172200578207772672) in the font, adding risky certificates and network configurations, and even changing the apps on your home screen.

This is the first instance where you need to trust $(PRODUCT_NAME). You should only tap _Allow_ if you have confidence in both the contents and source of the configuration profile.

To establish this trust, the source code of this app is [available for review](https://github.com/manolosavi/xFonts). $(PRODUCT_NAME) is also being distributed by a company that has been treating customers with respect for [over 20 years](https://iconfactory.com/20years). The [Iconfactory](https://iconfactory.com) contributed their expertise to the xFonts open source project because they couldn’t trust any app whose inner workings weren’t completely transparent. If that's not enough, you can even build and run the app using Xcode.

If you do decide to tap _Allow_ you’ll see a dialog that tells you to review the profile in _Settings_ and no other information. Tap _Close_ and you’re ready for the next phase of installation.


**_Update Settings_**

Open the _Settings_ app and you’ll see _Profile Downloaded_ button above the Airplane Mode switch. (If not, navigate to _General_ > _Profiles_ > _Downloaded Profile_ > _$(PRODUCT_NAME) Installation_.) After tapping the button, the first thing you’ll see is “Not Signed” highlighted in red.

This is another instance where you need to trust the source of the profile and its contents. Since the profile was generated on your device, there’s no risk that it was modified in transit. But unfortunately there’s no way to sign a profile locally without exposing a secret: the private key would have to be in the app’s source code or resources.

If you tap on _More Details_ you’ll be able to verify that only fonts are included in the profile. The integrity of those fonts can only be determined by reviewing source code or trusting the developer providing the app. Tap the _back button_ and then tap on _Install_ in the upper-right corner.

Enter your passcode, then you will be warned that the profile is unsigned. Tap _Install_, then tap _Install_ again.

If you see “Profile Installed” at the top of the screen, congratulations! You now have more choices for text in [iWork](https://www.apple.com/iwork/) or apps like [Tot](https://tot.rocks) that support custom fonts.

iOS takes some time to get things sorted out so you may not see the fonts immediately. If you’re having problems, try checking again in a few minutes or restarting an app so it re-checks for available fonts.


**_Conclusion_**

Remember that you’ll need to go through the whole installation process again if you add any fonts to $(PRODUCT_NAME). Your original profile will be replaced after the download, but you still need to authorize the new fonts with a passcode.

If you’ve made it this far, you now understand warning at the top of this page. If you think this process should be easier, [please give Apple some feedback](https://www.apple.com/feedback/iphone.html).
