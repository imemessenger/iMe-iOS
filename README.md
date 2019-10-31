# iMe

## General

iMe Messenger uses Telegram environment to develop additional functionality not loosing accustomed speed.

Additional features:
- Automated chat sorting by Unread, Personal, Channels, Chat-bots, All chats tabs;
- Chat grouping in folders;
- Telegram channel lists;
- Neurobots which help users in their day-to-day conversations.

If you have any requests, questions or complaints, feel free to contact us at support@imem.app

For cooperation: `info@imem.app`

## Project Setup

**Important!**
You need to obtain app `APP_CONFIG_API_ID` and `APP_CONFIG_API_HASH` prior setting up project environment. Visit [here](https://core.telegram.org/api/obtaining_api_id) for more info.

1. Install the brew package manager, if you haven’t already.
2. Install the packages pkg-config, yasm:
```bash
brew install pkg-config yasm
```
3. Clone the project from GitHub:

```bash
git clone https://github.com/ime-messenger/iMe-iOS.git
```
4. Open Telegram-iOS.workspace.
5. Open the Telegram-iOS-AppStoreLLC scheme.
6. Start the compilation process.
7. To run the app on your device, you will need to set the correct values for the signature, .entitlements files and package IDs in accordance with your developer account values.
