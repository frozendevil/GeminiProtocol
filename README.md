# GeminiProtocol

`Network.Framework` and `URLSession` support for the [Gemini Protocol](https://gemini.circumlunar.space)

## Usage

### URLSession
Calling `URLProtocol.registerClass(GeminiProtocol.self)` will cause your normal `URLSession` code to "Just Work" with `gemini://` URLs. The `URLResponse` you receive will be a `GeminiURLResponse` with `statusCode` and `meta` properties.

## Code
- `GeminiProtocol.swift` contains the implementation of the `URLSession` support.
- `GeminiNetwork.swift` is a `Network.framework` implementation of a Gemini client.
