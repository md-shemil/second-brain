import json
from pathlib import Path
from typing import List, Dict, Any

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    StorageContext,
    load_index_from_storage,
    Settings,
)
from llama_index.core.node_parser import SentenceSplitter
from llama_index.llms.ollama import Ollama
from llama_index.embeddings.ollama import OllamaEmbedding

STORAGE_DIR = Path("brain/storage")
META_FILE = Path("brain/meta.json")

# Models — change if needed
LLM_MODEL = "llama3"
EMBED_MODEL = "nomic-embed-text"
OLLAMA_BASE = "http://localhost:11434"


def _setup_settings():
    Settings.llm = Ollama(model=LLM_MODEL, base_url=OLLAMA_BASE, request_timeout=120.0)
    Settings.embed_model = OllamaEmbedding(model_name=EMBED_MODEL, base_url=OLLAMA_BASE)
    Settings.node_parser = SentenceSplitter(chunk_size=512, chunk_overlap=64)


class SecondBrain:
    def __init__(self):
        _setup_settings()
        STORAGE_DIR.mkdir(parents=True, exist_ok=True)
        META_FILE.parent.mkdir(parents=True, exist_ok=True)
        self._meta: Dict[str, Any] = self._load_meta()
        self._index: VectorStoreIndex | None = self._load_index()

    # ── Meta helpers ──────────────────────────────────────────────────────────

    def _load_meta(self) -> Dict:
        if META_FILE.exists():
            return json.loads(META_FILE.read_text())
        return {"docs": []}

    def _save_meta(self):
        META_FILE.write_text(json.dumps(self._meta, indent=2))

    # ── Index helpers ─────────────────────────────────────────────────────────

    def _load_index(self) -> VectorStoreIndex | None:
        docstore = STORAGE_DIR / "docstore.json"
        if docstore.exists():
            ctx = StorageContext.from_defaults(persist_dir=str(STORAGE_DIR))
            return load_index_from_storage(ctx)
        return None

    def _persist(self):
        self._index.storage_context.persist(persist_dir=str(STORAGE_DIR))

    # ── Public API ────────────────────────────────────────────────────────────

    def doc_count(self) -> int:
        return len(self._meta["docs"])

    def list_docs(self) -> List[Dict]:
        return self._meta["docs"]

    def index_directory(self, directory: Path) -> int:
        reader = SimpleDirectoryReader(
            input_dir=str(directory),
            recursive=True,
            required_exts=[".pdf", ".txt", ".md"],
        )
        docs = reader.load_data()
        if not docs:
            return 0

        if self._index is None:
            self._index = VectorStoreIndex.from_documents(docs)
        else:
            for d in docs:
                self._index.insert(d)

        self._persist()

        # Update meta
        existing = {d["name"] for d in self._meta["docs"]}
        for d in docs:
            fname = Path(d.metadata.get("file_path", "unknown")).name
            ext = Path(fname).suffix.lstrip(".").upper() or "TXT"
            if fname not in existing:
                self._meta["docs"].append({"name": fname, "type": ext})
                existing.add(fname)
        self._save_meta()
        return len(docs)

    def add_file(self, path: Path) -> int:
        reader = SimpleDirectoryReader(input_files=[str(path)])
        docs = reader.load_data()
        if not docs:
            return 0

        if self._index is None:
            self._index = VectorStoreIndex.from_documents(docs)
        else:
            for d in docs:
                self._index.insert(d)

        self._persist()

        existing = {d["name"] for d in self._meta["docs"]}
        for d in docs:
            fname = Path(d.metadata.get("file_path", path.name)).name
            ext = Path(fname).suffix.lstrip(".").upper() or "TXT"
            if fname not in existing:
                self._meta["docs"].append({"name": fname, "type": ext})
                existing.add(fname)  # prevent duplicates from multi-page docs
        self._save_meta()
        return len(docs)

    def remove_doc(self, filename: str) -> bool:
        """Remove all nodes for a given filename from the index + meta."""
        if self._index is None:
            return False

        # Find node ids belonging to this file
        docstore = self._index.storage_context.docstore
        ids_to_remove = [
            node_id for node_id, node in docstore.docs.items()
            if Path(node.metadata.get("file_path", "")).name == filename
        ]

        if not ids_to_remove:
            # Not in vector store but might be in meta — still clean up
            self._meta["docs"] = [d for d in self._meta["docs"] if d["name"] != filename]
            self._save_meta()
            return False

        for node_id in ids_to_remove:
            self._index.delete_nodes([node_id])

        self._persist()

        # Remove from meta
        self._meta["docs"] = [d for d in self._meta["docs"] if d["name"] != filename]
        self._save_meta()
        return True

    def clear_all(self) -> None:
        """Wipe entire index and meta."""
        import shutil
        if STORAGE_DIR.exists():
            shutil.rmtree(STORAGE_DIR)
        STORAGE_DIR.mkdir(parents=True, exist_ok=True)
        self._meta = {"docs": []}
        self._save_meta()
        self._index = None

    def query(self, question: str) -> Dict:
        if self._index is None:
            return {"answer": "No documents indexed yet.", "sources": []}

        engine = self._index.as_query_engine(
            similarity_top_k=4,
            response_mode="compact",
        )
        response = engine.query(question)

        sources = []
        seen = set()
        for node in response.source_nodes:
            fname = Path(node.metadata.get("file_path", "unknown")).name
            excerpt = node.get_content()[:300].replace("\n", " ").strip()
            key = (fname, excerpt[:60])
            if key not in seen:
                sources.append({"file": fname, "excerpt": excerpt, "score": round(node.score or 0, 3)})
                seen.add(key)

        return {
            "answer": str(response),
            "sources": sources,
        }