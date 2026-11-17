# Third-party notices

- The Android patch is based on OpenClaw `fc23bc864e4553c2d215e479eeec47b67a0bf943`. The preparation script preserves the upstream license and third-party notices in the prepared checkout. [OpenClaw source](https://github.com/openclaw/openclaw/tree/fc23bc864e4553c2d215e479eeec47b67a0bf943)
- The preparation script fetches the Apache-2.0 Sherpa-ONNX wake model and runtime and packages the required ARM64 Android libraries. ONNX Runtime carries MIT and third-party notices. The patch adds these notices and the source and checksums in the prepared checkout. [Wake assets and build guide](android/README.md) · [Sherpa-ONNX license](https://github.com/k2-fsa/sherpa-onnx/blob/master/LICENSE) · [ONNX Runtime license](https://github.com/microsoft/onnxruntime/blob/main/LICENSE)
