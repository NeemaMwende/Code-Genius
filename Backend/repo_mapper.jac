# ======================================================
# RepoMapper.jac — Single Walker Test (Cloning + Mapping)
# Author: Neema Mwende
# ======================================================

import from byllm.llm { Model }
import python import os
import python import subprocess
import python import shutil
import python import json

# Initialize the byLLM model
glob llm = Model(model_name="gpt-4o", verbose=False)

# -------------------------------
# Node to store repository info
# -------------------------------
node RepoContext:
    has repo_url: str
    has repo_name: str
    has repo_dir: str
    has file_tree: str
    has readme_summary: str


# -----------------------------------------
# Walker: RepoMapper (Cloning + Mapping)
# -----------------------------------------
walker RepoMapper:
    can RepoContext
    has report: str

    body:
        report = f"📦 Starting RepoMapper for {here.repo_url}\n"

        # --- Derive repo name and temp dir
        here.repo_name = here.repo_url.split("/")[-1].replace(".git", "")
        here.repo_dir = f"./tmp/{here.repo_name}"

        # --- Remove old clone if exists
        if os.path.exists(here.repo_dir):
            shutil.rmtree(here.repo_dir)

        # --- Clone repository
        report += f"🔄 Cloning repository into {here.repo_dir}...\n"
        subprocess.run(["git", "clone", "--depth", "1", here.repo_url, here.repo_dir], check=True)
        report += "✅ Repository cloned successfully.\n"

        # --- Generate file tree
        def build_tree(path):
            tree = {}
            for root_dir, dirs, files in os.walk(path):
                # Skip irrelevant folders
                dirs[:] = [d for d in dirs if d not in [".git", "node_modules", "__pycache__"]]
                rel_path = os.path.relpath(root_dir, path)
                tree[rel_path] = files
            return tree

        file_tree = build_tree(here.repo_dir)
        here.file_tree = json.dumps(file_tree, indent=2)
        report += "🗂️ File tree structure generated.\n"

        # --- Summarize README.md if exists
        readme_path = os.path.join(here.repo_dir, "README.md")
        if os.path.exists(readme_path):
            with open(readme_path, "r") as f:
                content = f.read()
                here.readme_summary = llm(
                    prompt=f"Summarize this README for documentation:\n{content[:3000]}"
                )
            report += "📖 README summary generated.\n"
        else:
            here.readme_summary = "No README.md found."
            report += "⚠️ No README.md file found.\n"

        return {
            "repo_name": here.repo_name,
            "file_tree": here.file_tree,
            "readme_summary": here.readme_summary,
            "report": report
        }

# -----------------------------------------
# Entry point for API or CLI testing
# -----------------------------------------
walker_run(repo_url: str):
    start = spawn node::RepoContext(repo_url=repo_url)
    start::RepoMapper
