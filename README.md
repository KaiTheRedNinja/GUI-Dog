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

## Credits and Implementation Details

- Accessibility API: Vosh (https://github.com/Xce-PT/Vosh)
- UI library: Luminare (https://github.com/MrKai77/Luminare)

## License

GUI Dog is licensed under the GNU General Public License v3.0.

Explanation for the license of GUI Dog is available [here](LICENSE_Explanation.md)
