# supervisor.jac
walker code_genius {
    has repo_url:str;
    has anchor repo_name;

    can orchestrate with entry {
        report("Supervisor: starting orchestration for: ", repo_url);

        # spawn repo mapper and capture returned anchor (repo_name)
        repo_name = spawn here repo_mapper(repo_url);

        report("Supervisor: repo mapped: ", repo_name);

        #  spawn analyzer; it will read outputs/<repo_name>/manifest.json
        spawn here code_analyzer(repo_name);
        wait;

        # generate documentation
        spawn here docgenie(repo_name);
        wait;

        report("Supervisor: finished all steps for: ", repo_name);
    }

    impl {
        # entry is the default entry ability for the walker
    }
}
