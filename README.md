# zway-app

Zway is an open-source instant messenger for common desktop and mobile operating systems with strong focus on security and privacy.

Zway features end-to-end encryption to exchange messages securely.

All your data is stored inside a password-protected, encrypted container on your device.

For more technical details, please refer to the [zway-lib](https://github.com/mw0x/zway-lib) repository.

## How to build

Zway's user interface is built on top of [Qt](https://www.qt.io/), a powerful and well established C++ framework for cross-platform applications.

You can download precompiled Qt libraries or build them yourself from source.

Some core parts like networking, cryptography and storage are provided by libzway, a separate library which is part of the project but does not depend on Qt. This library must be be built prior to building the app. In order to build it, see the instructions on it's [repository](https://github.com/mw0x/zway-lib) page.

Building Zway is currently supported under Linux and Mac OS  X.

### Get precompiled Qt libraries and QtCreator

Download the approriate package for your platform from [Qt](https://www.qt.io/download-open-source/#section-2) and install it.

### Configuring the project

Fire up QtCreator and open the Zway.pro project file.

Prior to building, two environment variables need to be set in the build settings, to make QtCreator know where your libzway is located:

LIBZWAY_ROOT: The path to your root directory of libzway (for include files)

LIBZWAY_PATH: The path to your build directory of libzway (for the libzway library)

After that, you should be able to build and run the app.

### Build Qt from source

Details to follow



