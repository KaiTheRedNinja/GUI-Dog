# BeMyHands
 A blind reader on steroids

## Instructions

Run this app, find where it is in finder and manually add it to accessibility permissions.

I'll eventually figure out a way to prompt the user to do this.


Note that this app is *not sandboxed*, as it makes use of the accessibility API.

It also acts really weirdly with multiple displays due to coordinate systems, so just use one.

## Architecture

BeMyHands relies on three components: the Accessibility API, and the Gemini API.

The Accessibility API is based on https://github.com/Xce-PT/Vosh , while the Gemini API is Google's own
Gemini swift SDK. The Bridge is completely original.

Interactions with the Gemini API follow this process:
1. Decide if the goal is feasible
2. Gather context
3. Decide one of the following:
    - Which tool to use
    - The goal is complete
    - The goal cannot be achieved
4. Use the tool, while indicating if the goal has been achieved or not
4. Repeat 2-4 until the LLM indicates that the goal has been achieved

## Roadmap

This are the things that I need to implement, not nescessarily in order

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
- [ ] Other capabilities
    - [x] Focusing apps
    - [ ] Clicking menu bar items

Gemini API capabilities:
- [x] Trigger API calling (a shortcut probably)
- [x] Obtain goal from user
- [x] First stage
    - [x] Obtain user instruction, focused application, window title
    - [x] Prompt engineering
    - [x] Parse response into list of steps
    - [x] Fail graciously if the action is too complex
- [x] Second stage
    - [x] Function calling definitions
    - [x] Obtain interactable and contextual elements on screen
    - [x] Prompt engineering
    - [x] Response parsing and iterative process
    - [x] Fail graciously if the action cannot be completed
- [x] Interrupt AI midway through

App Capabilities:
- [x] Announce when the AI is doing things
- [x] Clean up steps UI
- [x] Add animations (for sighted people's sake. Make sure it stays accessibility friendly.)
- [ ] Onboarding
    - [x] Obtain accessibility permissions easily
    - [ ] Customise trigger shortcut

## Secrets
This project requires a `Secrets` object, which is gitignored by default. The file is meant to be at
`BeMyHands/App/Secrets.swift`, and only needs to provide a `Secrets.geminiKey` value. If you are building
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

BeMyHands is licensed under the GNU General Public License v3.0.

Explanation for the license of BeMyHands is available [here](LICENSE_Explanation.md)
