document.getElementById('solveBtn').addEventListener('click', async () => {
    const text = document.getElementById('input').value;
    if (!text) return;

    try {
        const response = await fetch('http://localhost:8765', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text })
        });

        const data = await response.json();

        if (data.success) {
            document.getElementById('result').textContent = `${data.result}`;
            document.getElementById('result').classList.remove('hidden');
            document.getElementById('error').classList.add('hidden');
        } else {
            document.getElementById('error').textContent = data.error || "Unknown error";
            document.getElementById('error').classList.remove('hidden');
            document.getElementById('result').classList.add('hidden');
        }
    } catch (e) {
        document.getElementById('error').textContent = "Connection failed. Is Calculator app running?";
        document.getElementById('error').classList.remove('hidden');
        document.getElementById('result').classList.add('hidden');
    }
});
