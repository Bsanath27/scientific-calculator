# Walkthrough - Phase 4: OCR Engine

## Overview
Implemented a local, offline OCR engine for converting images of mathematical equations into computable expressions.
The solution uses a Python microservice (`pix2tex`) for LaTeX recognition and a Swift client for normalization and integration.

## Features
- **Local Python OCR Service**: Runs on port 5002, uses `pix2tex` model.
- **Image Import**: Supports dragging/dropping images, PDFs, or pasting from clipboard.
- **LaTeX Normalization**: Converts raw LaTeX (e.g. `\frac{1}{2}`) into calculator syntax (e.g. `(1)/(2)`).
- **Metric Tracking**: Tracks OCR time, confidence scores, and processing overhead.
- **UI Integration**: Dedicated OCR sheet in the main calculator view.

## Files Created
- `PythonOCR/ocr_service.py`: Flask service with `pix2tex`.
- `ScientificCalculator/OCREngine/OCRClient.swift`: Swift HTTP client.
- `ScientificCalculator/OCREngine/LatexNormalizer.swift`: Logic to convert LaTeX to math syntax.
- `ScientificCalculator/OCREngine/OCRViewModel.swift`: State management.
- `ScientificCalculator/OCREngine/OCRView.swift`: UI for image selection and preview.
- `ScientificCalculator/OCREngine/OCRPreprocessor.swift`: Image processing.
- `ScientificCalculator/OCREngine/OCRMetrics.swift`: Performance tracking.

## How to Run

### 1. Start the OCR Service
The Swift app requires the Python service to be running locally.

```bash
cd PythonOCR
pip install -r requirements.txt
python3 ocr_service.py
```
*Note: The first run will download the `pix2tex` model (approx. 80MB).*
*Service runs on http://127.0.0.1:5002*

### 2. Run the App
- Open `ScientificCalculator.xcodeproj`
- Run the **ScientificCalculator** scheme.
- Click the **OCR** button in the top right.
- Import an image or paste from clipboard.
- The recognized expression will appear. Click **Evaluate** to calculate.

## Verification
- **Unit Tests**: `LatexNormalizerTests` and `OCRClientTests` PASSED.
- **Integration**: Verified that `ContentView` launches `OCRView` and returns expression to `CalculatorViewModel`.
- **Project Structure**: Validated `project.pbxproj` integrity after adding 8 new files (6 source + 2 test).
- **Build**: Successful compilation with no errors.

## Next Steps
- Implement **Phase 5: History & Persistence** (Clean up History UI).
