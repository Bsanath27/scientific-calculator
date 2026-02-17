chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
        id: "solveMath",
        title: "Solve with Calculator",
        contexts: ["selection"]
    });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId === "solveMath" && info.selectionText) {
        fetch('http://localhost:8765', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text: info.selectionText })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    chrome.scripting.executeScript({
                        target: { tabId: tab.id },
                        func: (text, result) => alert(`Math Assistant:\n${text} = ${result}`),
                        args: [data.expression, data.result]
                    });
                } else {
                    chrome.scripting.executeScript({
                        target: { tabId: tab.id },
                        func: (msg) => alert(`Math Assistant Error:\n${msg}`),
                        args: [data.error || "Unknown error"]
                    });
                }
            })
            .catch(err => {
                console.error(err);
                chrome.scripting.executeScript({
                    target: { tabId: tab.id },
                    func: () => alert("Connection failed. Is Calculator app running?"),
                    args: []
                });
            });
    }
});
