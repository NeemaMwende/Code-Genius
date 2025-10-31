# code_analyzer.jac
walker code_analyzer {
    has repo_name:str;

    can analyze with entry {
        report("CodeAnalyzer: Tree-sitter analysis for ", repo_name);

        python: {
            import os, json
            from tree_sitter import Language, Parser
            from collections import defaultdict

            repo = ctx["repo_name"]
            base = os.path.join("outputs", repo)
            manifest = json.load(open(os.path.join(base,"manifest.json")))

            # --- build Tree-sitter shared library once (keep it in project) ---
            lang_so = "build/my-languages.so"
            if not os.path.exists(lang_so):
                Language.build_library(lang_so, [
                    "vendor/tree-sitter-python",
                    "vendor/tree-sitter-javascript",
                    "vendor/tree-sitter-jac"
                ])
            PY_LANG = Language(lang_so, "python")
            JS_LANG = Language(lang_so, "javascript")
            JAC_LANG = Language(lang_so, "jac")

            parser = Parser()
            ccg = {"nodes": [], "edges": []}
            node_id = 1

            def add_node(k,n,m):
                nonlocal node_id
                nid=f"N{node_id}"; node_id+=1
                ccg["nodes"].append({"id":nid,"kind":k,"name":n,"meta":m})
                return nid

            for f in manifest["files"]:
                lang = f["lang"]
                if lang not in ["python","jac","javascript"]:
                    continue
                if lang=="python": parser.set_language(PY_LANG)
                if lang=="jac": parser.set_language(JAC_LANG)
                if lang=="javascript": parser.set_language(JS_LANG)
                src = open(f["abs_path"],"rb").read()
                tree = parser.parse(src)
                # minimal traversal example (extract function names)
                cursor = tree.walk()
                def traverse(c):
                    while True:
                        node_type = c.node.type
                        if node_type in ("function_definition","class_definition"):
                            name_node = c.node.child_by_field_name("name")
                            name = src[name_node.start_byte:name_node.end_byte].decode()
                            add_node(node_type,name,{"file":f["path"]})
                        if c.goto_first_child():
                            traverse(c)
                            c.goto_parent()
                        if not c.goto_next_sibling():
                            break
                traverse(cursor)
            with open(os.path.join(base,"ccg.json"),"w") as fh:
                json.dump(ccg,fh,indent=2)
            print(json.dumps({"status":"ok","ccg_nodes":len(ccg["nodes"])}))
        }

        report("✅ CodeAnalyzer: Tree-sitter CCG built.")
    }
}
