import os
import sys
import threading
import webbrowser
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from brain import SecondBrain

DOCS_DIR = Path("docs")
DOCS_DIR.mkdir(exist_ok=True)

app = Flask(__name__, static_folder="static")
CORS(app)
brain = None

def init_brain():
    global brain
    try:
        brain = SecondBrain()
        print("  ✓ Brain initialized")
    except Exception as e:
        print(f"  ✗ Brain init failed: {e}")
        print("  Make sure Ollama is running: ollama serve")
        sys.exit(1)

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

@app.route("/api/status")
def status():
    return jsonify({
        "docs": brain.doc_count(),
        "list": brain.list_docs()
    })

@app.route("/api/index", methods=["POST"])
def index_docs():
    try:
        files = list(DOCS_DIR.glob("**/*.pdf")) + \
                list(DOCS_DIR.glob("**/*.txt")) + \
                list(DOCS_DIR.glob("**/*.md"))
        if not files:
            return jsonify({"error": "No files found in docs/ folder"}), 400
        count = brain.index_directory(DOCS_DIR)
        return jsonify({"indexed": count, "docs": brain.list_docs()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400
    f = request.files["file"]
    if f.filename == "":
        return jsonify({"error": "Empty filename"}), 400
    allowed = {".pdf", ".txt", ".md"}
    ext = Path(f.filename).suffix.lower()
    if ext not in allowed:
        return jsonify({"error": f"Unsupported type. Use: {', '.join(allowed)}"}), 400
    save_path = DOCS_DIR / f.filename
    f.save(save_path)
    try:
        brain.add_file(save_path)
        return jsonify({"message": f"Uploaded and indexed: {f.filename}", "docs": brain.list_docs()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/remove", methods=["POST"])
def remove_doc():
    data = request.get_json()
    filename = (data or {}).get("filename", "").strip()
    if not filename:
        return jsonify({"error": "No filename provided"}), 400
    try:
        brain.remove_doc(filename)
        # also delete from docs/ folder
        doc_path = DOCS_DIR / filename
        if doc_path.exists():
            doc_path.unlink()
        return jsonify({"message": f"Removed: {filename}", "docs": brain.list_docs()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/clear", methods=["POST"])
def clear_all():
    try:
        brain.clear_all()
        # clear docs folder too
        for f in DOCS_DIR.iterdir():
            if f.is_file():
                f.unlink()
        return jsonify({"message": "Cleared all", "docs": []})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/query", methods=["POST"])
def query():
    data = request.get_json()
    question = (data or {}).get("question", "").strip()
    if not question:
        return jsonify({"error": "No question provided"}), 400
    if brain.doc_count() == 0:
        return jsonify({"error": "No documents indexed. Upload files first."}), 400
    try:
        result = brain.query(question)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def open_browser():
    import time
    time.sleep(1.2)
    webbrowser.open("http://localhost:5050")

if __name__ == "__main__":
    print("\n   Second Brain — starting up...")
    init_brain()
    threading.Thread(target=open_browser, daemon=True).start()
    print("  ✓ Opening browser at http://localhost:5050")
    print("  Press Ctrl+C to stop\n")
    app.run(host="0.0.0.0", port=5050, debug=False)