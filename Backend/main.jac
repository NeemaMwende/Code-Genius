import:py os;
import:py from dotenv, load_dotenv;

load_dotenv();

include:jac impl main;

walker analyze_repository {
    has repo_url: str;
    has task_id: str = "";
    has status: str = "pending";
    has result: dict = {};

    can enter_repo_analysis with `root entry {
        import:py uuid;
        self.task_id = str(uuid.uuid4());

        visit [-->](`?RepositoryNode) else {
            repo_node = RepositoryNode(
                url=self.repo_url,
                task_id=self.task_id,
                status="initialzed"
            );
            root ++> repo_node;
            visit repo_node;
        }
    }

    can process_repository with RepositoryNode entry {
        self.status = "processing";
        here.status = "processing"; 

        supervisor = spawn SupervisorAgent(
            repo_url=self.repo_url,
            task_id=self.task_id
        );

        visit supervisor;

        self.result = supervisor.final_result;
        self.status = supervisor.status;
        here.status = supervisor.status;
        here.status = supervisor.final_status;
    }
}

walker check_status{
    has task_id: str;
    has status: str = "not_found";
    has progress: dict = {};

    repo_nodes = [-->](`?RepositoryNode);
    for repo_node in repo_nodes {
        if node.task_id == self.task_id {
            self.status = node.status;
            self.progress = {
                "status": node.status,
                "task_id": node.task_id,
                "url": node.url,
                "progress_percentage": node.progress_percentage,
                "current_step": node.current_step,
                "result": node.result if node.status == "completed" else {}
            };
            break;
        }
    }
}

walker download_documentation {
    has task_id: str;
    has doc_content: str = "";
    has error: str = "";

    can get_documentation with `root entry {
        repo_nodes = [-->](`?RepositoryNode);
        for node in repo_nodes {
            if node.task_id == self.task_id {
                if node.status == "completed" and node.result {
                    self.doc_content = node.result.get("documentation", "");
                    if not self.doc_content {
                        self.error = "Documentation not generated yet";
                    } else {
                        self.error = f"Task status: {node.status}";
                    }
                    return;
                }
            }
            self.error = "Task not found";
        }
    }
    }

walker health_check {
    has status: str = "healthy";
    has version: str = "1.0.0";
    has timestamp: str = "";

    can check with `root entry {
        import:py from datetime, datetime;
        self.timestamp = datetime.now().isoformat();
        self.status = "healthy";
    }
}

node RepositoryNode {
    has url: str;
    has task_id: str;
    has status: str = "initialized";
    has progress_percentage: int = 0;
    has result: dict = {};
    has current_step: str = "";
}

node SupervisorAgent {
    has repo_url: str;
    has task_id: str;
    has status: str = "initialized";
    has final_result: dict = {};
    has current_step: str = "";
    has documentation: str = "";
    has ccg_data: dict = {};
    has repo_info: dict = {};
}

