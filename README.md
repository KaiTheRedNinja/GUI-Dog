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

Interactions with the Gemini API are defined in two stages:

1. First stage: Discovery and planning
    a. Receive the user request, focused application, and window title
    b. Respond with clarification request, or list of steps
2. Second stage: Detailed execution
    a. Receive the current step, plus interactable and contextual elements on the screen
    b. Use function calling to respond with a list of interactions, and if the step is complete after the actions are done
    c. If the step is not complete, the second stage is re-run with the list of past actions, and the current elements
    d. If the step is complete, the second stage is re-run with the next step

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
    - [ ] Focusing apps
    - [ ] Clicking menu bar items

Gemini API capabilities:
- [x] Trigger API calling (a shortcut probably)
- [ ] First stage
    - [x] Obtain user instruction, focused application, window title
    - [x] Prompt engineering 
    - [x] Parse response into list of steps
    - [ ] Fail graciously if the action is too complex
- [ ] Second stage
    - [x] Function calling definitions
    - [x] Obtain interactable and contextual elements on screen
    - [x] Prompt engineering
    - [x] Response parsing and iterative process
    - [ ] Fail graciously if the action cannot be completed
- [ ] Interrupt AI

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
- Global keyboard shortcuts: KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts)
    - KeyboardShortcuts only works with the default (usually QWERTY) layout of the device, even if the user is using DVORAK or another layout
