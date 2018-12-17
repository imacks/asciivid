ASCII Art Video in PowerShell
=============================

Originally adapted from code at http://bitly/e0Mw9w.

This is a simple demo on how to show ASCII art video in PowerShell.

File at [src/ascii-vid-frames.txt](./src/ascii-vid-frames.txt) must use Windows line ending!

Customize your template at [src/delivery-template.ps1](./src/delivery-template.ps1). The `{{ payload }}` part will be replaced during the build process.

When you are ready, run the [build script](./build.ps1). It will gzip and base64 encode the frame data, then embed into the template. The generated result is at [dist/output.ps1](./dist/output.ps1). Run the output script to enjoy :)
