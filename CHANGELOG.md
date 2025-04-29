# Changelog

All notable changes to the Heyllo Chat Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2+1] - 2025-04-02

### Changed
- Updated README documentation.

## [0.0.2] - 2025-04-01

### Changed
- Updated README documentation.

## [0.0.1] - 2025-03-30

### Added
- Initial public release


## [0.0.3] - 2025-04-14

### Added
- **Markdown Support:** Bot responses are now rendered as Markdown using `flutter_markdown`, allowing for richer text formatting (bold, italics, lists, links, etc.).
- **Citation Handling:** Added support for receiving citation data from the backend.
- **Citation Toggle:** Added `showCitations` parameter to `ChatWidget` to allow developers to show/hide citation information in the UI.
- **Enable/Disable Toggle:** Added `isEnabled` parameter to `ChatWidget` to allow developers to enable or disable the chat functionality dynamically.
- **Thread ID Context:** Implemented handling for `thread_id` received from the backend (`metadata` type response) and sending it back on subsequent requests to maintain conversation context.
- **New Callbacks:** Added optional `onCitationsReceived` and `onThreadIdReceived` callbacks to `ChatWidget`.
- **Error Message Type:** Introduced an explicit `error` message type for better error handling and display.

### Changed
- **Backend Response Handling:** Refactored `ChatService` and `MethodChannelChatPlugin` to process structured JSON responses from the backend with distinct `type` fields (`content`, `metadata`, `citations`, `error`) instead of just plain text streams.
- **Stream Finalization:** Improved stream handling in `ChatService` to correctly identify the end of a response (including handling custom `stream_end` events) and update the message state (`isWaiting=false`) reliably.
- **API Signatures:** Updated `streamResponse` method signature across `ChatPlugin`, `ChatPluginPlatform`, and `MethodChannelChatPlugin` to accept `threadId` and return `Stream<Map<String, dynamic>>`.
- **ChatMessage Model:** Updated `ChatMessage` to include `type`, `threadId`, and `citations` fields.

### Fixed
- **Persistent Loading Indicator:** Fixed an issue where the loading indicator on bot messages would not disappear after the response was fully received.
- **Type Errors:** Corrected type mismatches in `ChatBubble` related to `BorderRadiusGeometry`/`BorderRadius` and `EdgeInsetsGeometry`/`EdgeInsets`.

### Changed
- Updated README documentation.

## [0.0.3+1] - 2025-04-29

### Changed
- Updated README documentation.
