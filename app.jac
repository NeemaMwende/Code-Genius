# ===========================================================
# app.jac — Entry file for Codebase Genius backend
# ===========================================================

# ---- Import agent walkers ----
import { repo_mapper } from "repo_mapper.jac";
import { code_analyzer } from "code_analyzer.jac";
import { docgenie } from "docgenie.jac";

# ===========================================================
# Supervisor Walker — orchestrates all agents
# ===========================================================
walker code_genius {
    has repo_url:str;
    has repo_name:str;

    can run_pipeline with entry {
        report("🚀 Codebase Genius started for repo: ", repo_url);

        # ---------- Step 1: Clone and Map Repository ----------
        report("🗂 Launching RepoMapper...");
        let map_job = spawn here repo_mapper(repo_url);
        wait;
        repo_name = map_job.repo_name;  # capture returned name
        report("✅ RepoMapper completed. Repo name: ", repo_name);

        # ---------- Step 2: Code Analysis (Tree-sitter CCG) ----------
        report("🔍 Launching CodeAnalyzer...");
        spawn here code_analyzer(repo_name);
        wait;
        report("✅ CodeAnalyzer completed CCG generation.");

        # ---------- Step 3: Doc Generation (LLM Summarization) ----------
        report("🪄 Launching DocGenie...");
        spawn here docgenie(repo_name);
        wait;
        report("✅ DocGenie generated final documentation.");

        report("🎯 Pipeline completed for ", repo_name);
    }
}

# ===========================================================
# Optional: Utility walker to verify backend health
# ===========================================================
walker ping {
    can check with entry {
        report("✅ Jac backend is live and ready!");
    }
}

# ===========================================================
# Entry node / graph definition
# ===========================================================
graph main {
    has entry;  # marks it as main entry graph
}

# ===========================================================
# Expose walkers to Jac server
# ===========================================================
# When you run `jac serve app.jac`, these walkers become HTTP endpoints:
#  POST /walker_run { "name": "code_genius", "ctx": { "repo_url": "<URL>" } }
#  POST /walker_run { "name": "ping" }

# ===========================================================
# Example internal run (for debugging in Jac CLI)
# ===========================================================
walker main {
    can run with entry {
        report("🚦 Running local debug...");
        spawn here code_genius("https://github.com/psf/requests");
    }
}
