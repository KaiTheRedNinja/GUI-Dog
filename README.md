# BeMyHands
 A blind reader on steroids

## Instructions

Run this app, find where it is in finder and manually add it to accessibility permissions.

I'll eventually figure out a way to prompt the user to do this.


Note that this app is *not sandboxed*, as it makes use of the accessibility API.

It also acts really weirdly with multiple displays due to coordinate systems, so just use one.

## Architecture

BeMyHands relies on three components: the Accessibility API, and the Gemini API.

The Accessibility API is based on https://github.com/Xce-PT/Vosh/tree/main , while the Gemini API is Google's own
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
- [ ] LLM-Friendly descriptions of interactable elements
- [ ] Easy-to-use API for executing actions
    - [x] Make it possible to execute actions
    - [ ] Create a clean API

Gemini API capabilities:
- [ ] Trigger API calling (a shortcut probably)
- [ ] First stage: Obtain user instruction, focused application, window title
- [ ] First stage: Prompt engineering 
- [ ] First stage: Parse response into list of steps
- [ ] Second stage: Function calling definitions
- [ ] Second stage: Obtain interactable and contextual elements on screen
- [ ] Second stage: Prompt engineering
- [ ] Second stage: Response parsing and iterative process
