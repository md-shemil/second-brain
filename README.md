# Second Brain

Ask questions from your own PDFs and notes. Runs fully offline. No cloud. No API key. No cost.

![Python](https://img.shields.io/badge/Python-3.10+-blue)
![Ollama](https://img.shields.io/badge/Ollama-local-green)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Mac%20%7C%20Windows-lightgrey)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## One-Command Setup

### Linux / Mac
```bash
git clone https://github.com/md-shemil/second-brain.git
cd second-brain
bash setup.sh
```

### Windows (PowerShell as Admin)
```powershell
git clone https://github.com/md-shemil/second-brain.git
cd second-brain
.\setup.ps1
```

Setup will install Ollama if not present, let you choose an LLM model, pull it along with the embedding model, create a virtual environment, install all Python dependencies, and create the required folders.

---

## Run

### Linux / Mac
```bash
bash run.sh
```

### Windows
```powershell
.\venv\Scripts\Activate.ps1
python main.py
```

Browser opens automatically at `http://localhost:5050`.

---

## Usage

Drop your PDFs or text files into the `docs/` folder, click "Index folder", and start asking questions. You can also upload files directly from the browser.

Each answer includes source badges showing which document and excerpt the answer came from. Click a badge to expand the full excerpt.

To remove a document from the index, click the X on its pill in the top bar. To wipe everything, click "Clear all".

---

## How It Works

```
docs/ folder
    -> chunked into paragraphs
    -> each chunk embedded as a vector (nomic-embed-text)
    -> stored in ChromaDB on disk

your question
    -> embedded as a vector
    -> similarity search finds top-4 matching chunks
    -> chunks + question sent to local LLM
    -> cited answer returned
```

No data leaves your machine at any point.

---

## Demo

```
> What optimization algorithm is used for gradient descent in this paper?

Answer:
The paper uses Adam optimizer with a learning rate of 0.001 and a batch
size of 32. A cosine annealing scheduler is applied to decay the learning
rate across 100 epochs, with early stopping triggered after 10 epochs of
no improvement on the validation set.

Sources:
[1] ml_research.pdf   ...Adam optimizer was selected due to its adaptive
                       learning rate properties. The scheduler reduces lr
                       by a factor of 0.1 every 20 epochs...
[2] ml_research.pdf   ...validation accuracy plateaued at epoch 87,
                       triggering early stopping with best weights...
```

---

## Change Model

Edit `brain.py`:
```python
LLM_MODEL = "llama3"       # llama3 / llama3.2 / mistral / phi3 / gemma2
EMBED_MODEL = "nomic-embed-text"
```

Or re-run `setup.sh` to pick a different model interactively.

---

## Stack

| Tool | Role |
|------|------|
| LlamaIndex | RAG pipeline |
| Ollama | Local LLM runtime |
| Llama3 | Language model |
| nomic-embed-text | Embedding model |
| ChromaDB | Vector store |
| Flask | Backend server |

---

## Project Structure

```
second-brain/
├── main.py          - Flask server + API
├── brain.py         - RAG engine
├── setup.sh         - Linux/Mac setup
├── setup.ps1        - Windows setup
├── run.sh           - Quick launcher
├── requirements.txt
├── static/
│   └── index.html   - Browser UI
├── docs/            - Drop your files here
└── brain/           - Vector store (auto-created)
```

---

## License

MIT