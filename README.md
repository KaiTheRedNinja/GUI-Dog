# GUI Dog
A guide dog for your graphical user interface
 
## Motivation

Sighted people use computer mouses and cursors to interact with their computer's graphical user interface. However, this 
relies on knowing where UI elements are on screen. The visually impaired can't use these methods of input. Instead, most
use blind reader tools, such as macOS's VoiceOver. Blind reader tools usually allow them to move around the screen, hear 
a description of the item where the cursor is located and interact with the item.

However, most blind readers use sound to convey information. This means that users of blind readers are typically only able
to focus on one on-screen item at a time. This can make navigating screens with large numbers of UI elements, such as the
file manager, tabs, or web pages, extremely tedious.

GUI Dog aims to fix this problem, by using new LLM technology to level the playing field between the sighted and visually
impaired.

## What it Does

Similar to how a guide dog helps a visually impaired user locate specific objects such as doors, stairs, kerbs, or bus stops,
GUI Dog (pronounced gooey-dog) helps a visually impaired user locate interactable elements on the screen.

GUI Dog uses the macOS accessibility API (the same one that powers VoiceOver) to identify interactable elements on screen.
It takes instructions from the user, and uses the Google Gemini Large Language Model to identify how to interact with the 
user interface to complete the task.

## Using GUI Dog

You need a macOS device with macOS 14.5 or newer to run GUI Dog.

1. Launch the app
    - GUI Dog is *not sandboxed*, as it makes use of the accessibility API. This means that it may show an warning when you 
    launch it the first time. If this happens, quit GUI Dog, then right-click the app, and press Open. You will only need to 
    do this the first time.
2. Follow the instructions in the setup window
    - Inform GUI Dog about your level of visibility. Selecting "impaired" or "blind" will activate audio cues.
    - Grant accessibility permissions
    - Choose a trigger shortcut
3. Open GUI Dog by triggering the shortcut
4. Give GUI Dog a task. This task must be _simple_, _precise_, and can be accomplished with only clicking.
    - ✅ "Open my Pictures folder in Downloads"
    - ✅ "Mark my Buy Tissue reminder as done in Reminders"
    - ❌ "Buy me a coffee" (too complex and vague)
    - ❌ "Pay using my credit card" (GUI Dog cannot type, and does not have access to information that you do not specify in the task)
5. GUI Dog will use the user interface to navigate the UI to try and accomplish the task
    - GUI Dog will highlight elements that it identifies as clickable on your device's main display
    - GUI Dog informs the user of every action it takes, in audio cues for the visually impaired, and visually for the sighted.
    - Sometimes, GUI Dog will be unable to perform the task. This might be due to issues with the underlying Gemini LLM, the 
    accessibility API, or the task being too complex.

## Architecture

GUI Dog relies on three components: the Accessibility API, the Gemini API, and a "bridge" system that coordinates between them.

The Accessibility API interface is modified, based on https://github.com/Xce-PT/Vosh . The Gemini API is Google's own Gemini 
swift SDK. The bridge system that coordinates between the Accessibility API and Gemini API is completely original.

Interactions with the Gemini API follow this process:
1. Gather context
2. Decide one of the following:
    - A tool to use
        - Uses function calling to use the tool
    - The goal is complete
    - The goal cannot be achieved
3. Use the tool, if specified
3. Repeat 1-3 until the LLM indicates that the goal has been achieved

## Roadmap

This list is mainly for me, the things that I need to implement, not nescessarily in order.

Accessibility API capabilities:
- [x] Accessibility API (read-only)
- [x] Obtain pressable UI elements
- [x] Obtain all interactable UI elements
- [x] Obtain contextual information of UI elements
- [x] Display all interactable UI elements using an overlay
    - [x] Display the window
    - [x] Move the window to the right position
    - [x] Prepare the interactable UI elements data
    - [x] Display the interactable UI elements
    - [x] Make it update when the focused window changes, or every few seconds
- [x] LLM-Friendly descriptions of interactable elements
- [x] Easy-to-use API for executing actions
    - [x] Make it possible to execute actions
    - [x] Create a clean API
- [x] Other capabilities
    - [x] Focusing apps
    - [x] Clicking menu bar items

Gemini API capabilities:
- [x] Trigger API calling (a shortcut probably)
- [x] Obtain goal from user
- [x] Gather accessibility context
- [x] Determine which tool to use, or if the goal is impossible/complete
    - [x] Prompt engineering
    - [x] Parse response
- [x] Use the tool
    - [x] Function calling definitions
    - [x] Prompt engineering
    - [x] Parse response
    - [x] Fail graciously if the action cannot be completed
- [x] Repeatedly execute actions until done
- [x] Interrupt AI midway through

App Capabilities:
- [x] Announce when the AI is doing things
- [x] Clean up steps UI
- [x] Add animations (for sighted people's sake. Make sure it stays accessibility friendly.)
- [x] Onboarding
    - [x] Obtain accessibility permissions easily
    - [x] Customise trigger shortcut

## Building and Running from Source

1. Clone this project
2. Open the `GUIDog.xcodeproj` file in Xcode 15.4 or newer
3. Add the `Secrets.swift` file (see below)
4. Change all occurences of "com.kaithebuilder" to your own developer ID
5. Build with Cmd-B, or run with Cmd-R

### Secrets
This project requires a `Secrets` object, which is gitignored by default. The file is meant to be at
`GUIDog/App/Secrets.swift`, and only needs to provide a `Secrets.geminiKey` value. If you are building
from source, feel free to copy this template code into your own `Secrets.swift` file:

```swift
enum Secrets {
    /// API key for the Gemini Large Language Model
    static var geminiKey: String = "MY_API_KEY_HERE"
}
```

### Structure

- `GUIDogKit`: The Bridge and Accessibility API 
    - `Access`: High-level Accessibility API interface
    - `Element`: Low-level Accessibility API interface
    - `Input`: IOKit to watch for keyboard shortcuts
    - `Output`: Speech synthesizer
    - `HandsBot`: Bridge, which defines the protocols for the Accessibility API and Gemini API to communicate with each other
- `GUIDog`: The app itself
    - `App`: Files pertaining to the app that isn't UI, model, or controller, such as Secrets
    - `UI`: The UI of the app
        - `Components`: Reusable UI components
        - `Setup`: UI related to the setup process
        - `Settings`: UI related to the settings window
        - `Overlay`: UI that is overlayed over other macOS content
            - `Status`: UI related to displaying GUI Dog's internal status to the user
            - `Frames`: UI related to highlighting interactable elements on screen
            - `Goals`: UI related to the task input text field, triggered when the keyboard shortcut is pressed
    - `Model`: Functionality that ties `UI` to `GUIDogKit`
        - `LLM`: Provides the interface between the Accessibility API and the Bridge, and the Bridge to the Gemini API
        - Others: Misc managers used for preferences and the file system

### Convention

- "GUI Dog" (with a space) is used as the app name and to refer to the app itself
- "GUI-Dog" (with a dash) is used in the bundle ID, or anywhere else that the app name should be used but spaces are disallowed
- "GUIDog" (with no delimiter) is used in code as part of object or package names

GUI Dog uses [SwiftLint](https://github.com/realm/SwiftLint/) to enforce Swift style and conventions

## Google AI Competition

GUI Dog was written for the [Google AI competition](https://ai.google.dev/competition/submission). These are my answers to the questions:

**App tagline or elevator pitch: Explain your app in 1 sentence**

> GUI Dog is a digital "guide dog" powered by Gemini, helping the visually impaired interact with their computers more efficiently.

**App description: Describe what your app does and how you used the Gemini API in 1500 characters or less**

> You want to access a specific file. For a sighted user, you simply click to enter the Documents folder and click again to open 
the file. Done.

> But what if you're visually impaired? You'd use a blind reader, such as macOS's VoiceOver. So you open a file manager window, 
and VoiceOver describes, in detail, what it is and can do (every time you use it!). You use complex keyboard actions to navigate 
to the sidebar. Whenever you interact with your device, VoiceOver repeats information about the focused UI element. You then go 
down the list of folders, one by one, with VoiceOver announcing every folder's name until you finally hear the correct folder. 
The process is repeated inside the folder until you find your desired file. Wasn't that exasperating?

> A quiet two-click task turns into a yakking, tiresome dozen-action operation.

> What if you could complete the same task simply by instructing, "In the Documents folder, open my vaccination document"? My app, 
GUI Dog, does that.

> The user gives GUI Dog precise instructions for a task. GUI Dog provides Gemini with the task to achieve and a list of UI 
elements it can manipulate. Gemini then specifies what actions to take, and GUI Dog uses the macOS accessibility system to execute 
them. Together, they work towards completing the task.

> GUI Dog aims to be the "seeing eye" for the visually impaired, using Large Language Model technologies to help uplift the 
disadvantaged, enhancing their interactions with the digital world.

**What Google Developer tools/products did you use in addition to the Gemini APl?**

> None

**YouTube URL: Add a link to your public video**

> Not Yet

**Website or web app URL: If your app is live, please share the URL**

> _question left blank, GUI Dog is not a live web app_

**Is it a game app?**

> No

**Give judges access to your code! If your code is public, please add your GitHub link below. Otherwise, upload a zip file to 
Google Drive, set the sharing to 'Anyone with the link,' and share the link below.**

> This github repo, or a zip link. Haven't decided yet.

**Testing instructions**

> Provide instructions so judges can test it out the best way possible

**Country of residence**

> Singapore

**Team name**

> Kaisol

## Credits

Accessibility API: Vosh (https://github.com/Xce-PT/Vosh)

## License

GUI Dog is licensed under the GNU General Public License v3.0.

Explanation for the license of GUI Dog is available [here](LICENSE_Explanation.md)
