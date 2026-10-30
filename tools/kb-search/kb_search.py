#!/usr/bin/env python3
"""Recherche de pertinence dans la mémoire CTF (knowledge base + writeups).

Brique de récupération (le « retrieval » d'un RAG), en Python stdlib pur :
indexe les entrées de knowledge-base/*.md et retrospectives/*.md, découpées
par titres markdown, puis classe par similarité TF-IDF avec la requête.
(Les writeups sont dans le vault Obsidian perso, hors repo — non indexés.)

Zéro dépendance externe — volontaire (repo partagé, « commencer simple »). Le jour
où le corpus grossit, le scoring lexical peut être remplacé par des embeddings
derrière la même interface `search()` / la même CLI, sans rien changer en amont.

Usage :
    python3 tools/kb-search/kb_search.py "godot pck aes"
    python3 tools/kb-search/kb_search.py --top 3 --json "ethernet/ip tag"
"""

from __future__ import annotations

import argparse
import glob
import json
import math
import os
import re
import sys
from collections import Counter

# Racine du repo = deux niveaux au-dessus de ce script (tools/kb-search/).
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

_TOKEN_RE = re.compile(r"[a-z0-9]+")
_HEADING_RE = re.compile(r"^(#{1,4})\s+(.*)$")


def tokenize(text: str) -> list[str]:
    """Minuscules + tokens alphanumériques. Simple et reproductible."""
    return _TOKEN_RE.findall(text.lower())


def iter_source_files() -> list[str]:
    """Fichiers de mémoire à indexer, relatifs à la racine du repo."""
    # Les writeups vivent dans le vault Obsidian perso (hors repo), pas indexés ici.
    patterns = [
        "knowledge-base/*.md",
        "retrospectives/*.md",
    ]
    files: list[str] = []
    for pat in patterns:
        files.extend(sorted(glob.glob(os.path.join(REPO_ROOT, pat))))
    return files


def chunk_markdown(path: str) -> list[dict]:
    """Découpe un markdown en chunks délimités par les titres (##, ###, ...).

    Chaque chunk porte le chemin du fichier, le titre courant et son corps.
    """
    rel = os.path.relpath(path, REPO_ROOT)
    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return []

    chunks: list[dict] = []
    heading = os.path.basename(path)
    buf: list[str] = []

    def flush() -> None:
        body = "".join(buf).strip()
        if body or heading:
            chunks.append({"source": rel, "heading": heading, "body": body})

    for line in lines:
        m = _HEADING_RE.match(line.rstrip("\n"))
        if m:
            flush()
            heading = m.group(2).strip()
            buf = []
        else:
            buf.append(line)
    flush()
    # Filtre les chunks vides (titres sans contenu).
    return [c for c in chunks if c["body"]]


def build_index(chunks: list[dict]) -> dict:
    """Index TF-IDF : df par terme, vecteurs tf-idf normalisés par chunk."""
    docs_tokens = []
    df: Counter = Counter()
    for c in chunks:
        toks = tokenize(c["heading"] + " " + c["body"])
        docs_tokens.append(toks)
        for term in set(toks):
            df[term] += 1

    n = max(len(chunks), 1)
    idf = {t: math.log((1 + n) / (1 + d)) + 1.0 for t, d in df.items()}

    vectors = []
    for toks in docs_tokens:
        tf = Counter(toks)
        vec = {t: (cnt / len(toks)) * idf[t] for t, cnt in tf.items()} if toks else {}
        norm = math.sqrt(sum(w * w for w in vec.values())) or 1.0
        vectors.append({t: w / norm for t, w in vec.items()})
    return {"idf": idf, "vectors": vectors, "chunks": chunks}


def search(query: str, top: int = 5) -> list[dict]:
    """Retourne les `top` chunks les plus pertinents pour `query`."""
    chunks = []
    for path in iter_source_files():
        chunks.extend(chunk_markdown(path))
    if not chunks:
        return []

    index = build_index(chunks)
    idf = index["idf"]
    q_tf = Counter(tokenize(query))
    if not q_tf:
        return []
    q_vec = {t: (cnt / sum(q_tf.values())) * idf.get(t, 0.0) for t, cnt in q_tf.items()}
    q_norm = math.sqrt(sum(w * w for w in q_vec.values())) or 1.0
    q_vec = {t: w / q_norm for t, w in q_vec.items()}

    scored = []
    for vec, chunk in zip(index["vectors"], chunks):
        score = sum(q_vec.get(t, 0.0) * w for t, w in vec.items())
        if score > 0:
            scored.append((score, chunk))
    scored.sort(key=lambda x: x[0], reverse=True)

    results = []
    for score, chunk in scored[:top]:
        snippet = " ".join(chunk["body"].split())[:220]
        results.append(
            {
                "score": round(score, 4),
                "source": chunk["source"],
                "heading": chunk["heading"],
                "snippet": snippet,
            }
        )
    return results


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Recherche dans la mémoire CTF (KB + writeups).")
    parser.add_argument("query", nargs="+", help="Termes de recherche")
    parser.add_argument("--top", type=int, default=5, help="Nombre de résultats (défaut 5)")
    parser.add_argument("--json", action="store_true", help="Sortie JSON")
    args = parser.parse_args(argv)

    results = search(" ".join(args.query), top=args.top)

    if args.json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
        return 0

    if not results:
        print("Aucun résultat. (mémoire vide ou aucun terme pertinent)")
        return 0

    for r in results:
        print(f"[{r['score']:.3f}] {r['source']} › {r['heading']}")
        print(f"        {r['snippet']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
