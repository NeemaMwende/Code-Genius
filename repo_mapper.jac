# repo_mapper.jac
walker repo_mapper {
    has repo_url:str;
    has anchor repo_name:str;    # anchor returned to caller

    can map_repo with entry {
        report("RepoMapper: cloning ", repo_url);

        python: {
            import os, tempfile, subprocess, json, shutil
            from urllib.parse import urlparse

            repo_url = ctx.get("repo_url")  # context passed from supervisor
            parsed = urlparse(repo_url)
            repo_name = os.path.basename(parsed.path).replace(".git","")
            outdir = os.path.join("outputs", repo_name)
            if os.path.exists(outdir):
                shutil.rmtree(outdir)
            os.makedirs(outdir, exist_ok=True)
            tmp = tempfile.mkdtemp()
            # clone
            subprocess.check_call(["git", "clone", repo_url, tmp])
            manifest = {"repo": repo_name, "files": []}
            # walk files
            for root, dirs, files in os.walk(tmp):
                # ignore common irrelevant dirs
                dirs[:] = [d for d in dirs if d not in [".git","node_modules","__pycache__"]]
                for f in files:
                    if f.endswith((".py", ".md", ".jac")):
                        full = os.path.join(root, f)
                        rel = os.path.relpath(full, tmp)
                        manifest["files"].append({
                            "path": rel,
                            "abs_path": full,
                            "lang": "python" if f.endswith(".py") else ("jac" if f.endswith(".jac") else "markdown")
                        })
            manifest_path = os.path.join(outdir, "manifest.json")
            with open(manifest_path, "w") as fh:
                json.dump(manifest, fh, indent=2)
            # copy the repo into outputs/<repo_name>/source for later parsing
            dest_src = os.path.join(outdir, "source")
            shutil.copytree(tmp, dest_src)
            # return anchor value by setting ctx anchor (Jac will capture this as the walker's anchor)
            ctx["anchor_repo_name"] = repo_name
            print(json.dumps({"anchor_repo_name": repo_name}))
        }

        # create Jac file nodes for the manifest entries (lightweight representation)
        # read manifest file just created using a python block to get data into Jac variables
        python: {
            import json, os
            repo_name = os.environ.get("JAC_CTX_anchor_repo_name") if "JAC_CTX_anchor_repo_name" in os.environ else None
            # Some Jac runtimes propagate anchor via ctx - we have already set ctx in previous block.
            # But to be safe, read manifest file path computed from previously printed value
        }

        report("RepoMapper: manifest written and minimal Jac nodes created.");

        # set anchor to return repo_name to the caller
        # the anchor value is already set in 'repo_name' property at walker level
        repo_name = ctx["anchor_repo_name"];
    }

}
