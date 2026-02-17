# Local API & Browser Extension Guide

The **Scientific Calculator** exposes a local HTTP API that allows external tools (like browser extensions) to solve math problems using the app's powerful hybrid engine.

## API Specification

**Base URL**: `http://localhost:8765`

### 1. Evaluate / Translate
- **URL**: `/`
- **Method**: `POST`
- **Headers**:
    - `Content-Type: application/json`
- **Body**:
    ```json
    {
        "text": "derivative of x^2"
    }
    ```
- **Response (200 OK)**:
    ```json
    {
        "success": true,
        "expression": "diff(x**2, x)",
        "result": "2*x",
        "operation": "differentiate",
        "confidence": 0.95
    }
    ```
- **Error Response (200 OK with success: false)**:
    ```json
    {
        "success": false,
        "error": "Could not translate text"
    }
    ```

### 2. CORS Support
The server supports Cross-Origin Resource Sharing (CORS) by including the following headers:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: POST, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type`

---

## Creating a Browser Extension

You can create a simple Chrome/Edge/Brave extension to solve math on any webpage.

### 1. `manifest.json`
```json
{
  "manifest_version": 3,
  "name": "Scientific Calculator Helper",
  "version": "1.0",
  "permissions": ["contextMenus", "activeTab", "scripting"],
  "background": {
    "service_worker": "background.js"
  }
}
```

### 2. `background.js`
```javascript
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "solve-math",
    title: "Solve with Calculator",
    contexts: ["selection"]
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "solve-math") {
    const text = info.selectionText;
    
    fetch("http://localhost:8765", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: text })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Inject a script to show an alert or custom popup
        chrome.scripting.executeScript({
          target: { tabId: tab.id },
          func: (res) => alert(`Result: ${res}`),
          args: [data.result]
        });
      } else {
        console.error("Calculator Error:", data.error);
      }
    })
    .catch(err => console.error("Failed to connect to Calculator:", err));
  }
});
```

### 3. Installation
1.  Save the above files in a folder named `extension`.
2.  Open Chrome and go to `chrome://extensions`.
3.  Enable **Developer mode**.
4.  Click **Load unpacked** and select the `extension` folder.
5.  Highlight math on any page (e.g., `integrate x^2`), right-click, and choose **Solve with Calculator**.
