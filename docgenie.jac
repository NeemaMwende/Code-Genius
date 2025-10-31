# docgenie.jac
use module byllm.llm as llm        # byLLM helper (install byLLM pip-pkg)
walker docgenie {
    has repo_name:str;

    can generate with entry {
        report("DocGenie: generating final docs for ", repo_name);

        python: {
            import os, json
            base = os.path.join("outputs", ctx["repo_name"])
            manifest = json.load(open(os.path.join(base,"manifest.json")))
            readmes = [f for f in manifest["files"] if f["path"].lower().startswith("readme")]
            readme_text = ""
            if readmes:
                try:
                    with open(os.path.join(base,"source",readmes[0]["path"])) as fh:
                        readme_text = fh.read()[:4000]
                except Exception as e:
                    print("No README found:", e)
            ctx["readme_text"] = readme_text
        }

        # --- byLLM summarisation ---
        python: {
            from byllm.llm import chat_complete
            readme_text = ctx.get("readme_text","")
            if readme_text:
                summary = chat_complete(
                    system="Summarise this README into a concise technical overview.",
                    user=readme_text,
                    model="gpt-4-turbo",   # or gemini if configured
                    max_output_tokens=500
                )
                ctx["readme_summary"] = summary
            else:
                ctx["readme_summary"] = "No README file found."
        }

        python: {
            import json, os
            base = os.path.join("outputs", ctx["repo_name"])
            ccg = json.load(open(os.path.join(base,"ccg.json")))
            docs_path = os.path.join(base,"docs.md")
            lines = [
                f"# Documentation for {ctx['repo_name']}",
                "## README Summary",
                ctx["readme_summary"],
                "## API Reference"
            ]
            for n in ccg["nodes"]:
                if n["kind"] in ("function","class"):
                    lines.append(f"- **{n['kind']}** `{n['name']}` — {n['meta'].get('file')}")
            with open(docs_path,"w") as f:
                f.write("\n\n".join(lines))
        }
        report("✅ DocGenie: final docs (LLM summary + API) written.")
    }
}
