# TGCrawl
![Play Store Screenshots](assets/bundle_android.jpg)
Project for Indexing of Telegram Channel Connections

[![PlayStore](assets/PlayStoreButton.png)](https://play.google.com/store/apps/details?id=page.puzzak.tgcrawl)[![GitHub](assets/GHButton.png)](https://github.com/Puzzaks/tgcrawl/releases)
### Features
 - [WiP] Crowdsoursing
 - Indexing
 - Relations map
 - Multilinguality
 - Community-orientation
 - Statistics
 - No ads for contributors
 - Security

### [WiP] Crowdsoursing
This app is made with croudsoursing in mind. This means that after we finish our backend and iron it out, all users will be able not only to participate in indexing the full map of Telegram channels, but to view data collected by other users.

### Indexing
This app helps you analyze what connections do channels have. This is possible due to continuous process of analyzing messages and resolving connections on reposts.
When you index channel, the app reads up to 50 messages from the channel, starting at the latest message and checks if between those messages there is a repost of any channel. If the repost is found, then the app checks if it "knows" that channel (i.e. if this is the first repost from this channel among all indexed channels), if not - gets info about the channel and it's icon, if yes - increments amount of reposts for the connection.
In the end it results in list of connections that this channel has against all other channels, and you can then go and index another channel to get connections of the connection and so on.

### Relations map
After indexing is done, app creates the map of the indexed channels. If you have one channel indexed, it will look like a central node with connections radiating from it. 
If you have multiple channels that repost same channels, or cross-repost, you will see a complicated web of relations that you can watch and check if they are connected through other channels.

### Multilinguality
This app aims to be available in all possible languages. You can see the list of languages in [languages.json](assets/config/languages.json). We thank our contributors for their support. The only two languages, maintained by the developers are English and Ukrainian, for all other languages, we ask our community for help. Please, create a fork of the repo, add translated language as JSON in [config folder](assets/config/), then create merge request to finish this. You will be added to contributors automatically and we will later make app display thanks for our contributors.

### Community-orientation
This app is being developed by a single person with backend and overall project idea coming from @hampta. We encourage anyone to open new issues and report bugs, crashes, translation errors, bad UX, incorrect UI and submit any proposal you might have. We will read it and react to it, and this app won't be possible wihtout the help from you, the community members. Thank you.

### Statistics
You can see stats for what you have indexed, like total amount of messages, reposts, connections and channels. These stats are available both overall per your work and per each channel. 

### No ads for contributors
By enabling analysis sharing you automatically remove all ads from the app. For the project's sake we want to encourage everyone to share indexed data to create crowdsourced map of Telegram channels, but if you don't want to participate, it is your decision. But you may see ads appear in the app if you are viewing our data without contributing :)

### Security
We take security very seriously. There is no jokes, as this app requires your Telegram account to even function. While we can't guarantee that your account won't be banned for using this app, it is true that that did not happen for anyone yet. 
Your Telegram channel is always local, we are not receiving and the app is not sending any of your data anywhere, EXCEPT for what Telegram Library (TDLib) does. We are not responsible for TDLibs data handling, but the app itself does not send or save any of you login credentials, session keys or any of your information.
Crowdsoursing is always anonymous, if you are opting in to share analyzed data, the only info app will be senging is the analysis results for the channels you have indexed and known channels that were discovered. No other data will be sent. PERIOD.
