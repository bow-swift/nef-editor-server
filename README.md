<p align="center">
<img src="https://github.com/47deg/nef-editor-server/workflows/Compile%20and%20test/badge.svg" alt="Compile and test">
<img src="https://img.shields.io/badge/Docker-Ubuntu%2018.04-blue" alt="Docker support">
<img src="https://img.shields.io/badge/macos-10.15%2B-blueviolet" alt="macOS support">
<img src="https://img.shields.io/badge/iOS-10%2B-blueviolet" alt="iOS support">
</p>

Welcome to server-side for nef editor!

It provides the services for [nef client](https://github.com/47deg/nef-editor-client). In the next lines, you will find information about APIs specification, how nef has integrated Apple Sign-in, and how does it generate a Playground Book.

It is an awesome project that mixes a lot of technologies to run Swift in backend.
- [**Vapor**](https://vapor.codes/): a Web Framework for Swift that works on macOS and **Ubuntu**
- [**Bow**](https://bow-swift.io/): a cross-platform library for Typed **Functional Programming** in Swift.
- [**nef**](https://nef.bow-swift.io): a lot of cool features for Playgrounds; it lets us build a **Playground Book** with external dependencies defined in a Swift Package.
- [**Bow OpenAPI**](https://openapi.bow-swift.io): auto derivate **functional HTTP clients** given an OpenAPI specification. Let us derivate clients for Apple APIs.

&nbsp;


## 🗝 How to Sign-in into nef?

Apple announced in 2019 a new feature, "Sign In with Apple" enabling users to sign in to apps using their Apple ID. Apple positioned this feature as a fast, secure, and privacy-friendly way for users to set up an account and start using your apps. It sounds like a great solution for our app to enable **authorized services** without having to rely on external identity providers.

### Client
1. Users will use Apple provider, and they will sign in using their two-factor authentication Apple ID (Face ID or Touch ID on passcode-protected devices).
2. Users grant/deny permissions that application requested.
3. Apple ID servers direct users back to the application, along with a token. This token contains identity token (JWT) and an authorization code, between other user's information.
4. The application then uses this user's information to sign-in; the client will send **AppleSignInRequest**.

### Backend
1. Using the JWT and the authorization code (AppleSignInRequest), received from the client, it will be used to retrieve information from Apple ID servers.
2. App server will verify the JWT (identity token) received.
   - Verify the JWS E256 **signature** using the server's public key.
   - Verify that the **iss** field contains https://appleid.apple.com.
   - Verify that the **aud** field is the developer's client_id.
   - Verify that the **time** is earlier than the exp value of the token.
3. Using the **authorization code** received from the client, and the **verified JWT**, app server will retrieve user's information from Apple ID servers.
4. App server uses received user's information to sign-in, and come back to the client, **AppleSignInResponse**.


<details>
<summary>📣 Sequence Diagram</summary>
<p align="center">
    <img src="assets/sign-in.png" alt="Apple sign-on flow" width="80%"/>
</p>
</details>

&nbsp;


## ⚙️ How to generate a Playground Book?
&nbsp;


## 📲 How to deploy?

&nbsp;


## APIs

### 🔌 Sign-in
Sign in to nef using their Apple ID. You can consume this service using [Bow OpenAPI](https://openapi.bow-swift.io) and the schema at `NefEditorSchema`.

##### Request
- **POST** /signin
- **Accept** application/json
- **Content-Type** application/json
- **Body** AppleSignInRequest

##### Response
- **Content-Type** application/json
- **Body** AppleSignInResponse

> You can read more about how sign-in works in [How to Sign-in into nef?](#-how-to-sign-in-into-nef)

&nbsp;

### 🔌 Generate Playground Book
Generates a Playground Book given a recipe.

##### Request
- **POST** /playgroundBook
- **Accept** application/json
- **Content-Type** application/json
- **Authorization** Bearer
- **Body** PlaygroundRecipe

##### Response
- **Content-Type** application/json
- **Body** PlaygroundBookGenerated

> This repo provides `NefEditorData` module in order to keep sync the models for request/response between client and backend.

&nbsp;


## ❤️ Contributing to the project

You can contribute in different ways to make `nef editor` better:

- File an issue if you encounter a bug or malfunction.
- Open a Pull Request fixing a problem or adding new functionality. You can check the [Issues](https://github.com/47deg/nef-editor-server/issues) to see some of the pending tasks.
- Discuss with us in the [Gitter channel for Bow](https://gitter.im/bowswift/bow) about all the above.

&nbsp;


## ⚖️ License

    Copyright (C) 2020 The nef Authors

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
