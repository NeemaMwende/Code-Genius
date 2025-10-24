"""
Codebase Genius - Streamlit Frontend
Web interface for the documentation generation system
"""

import streamlit as st
import requests
import time
import json
from datetime import datetime

# Page configuration
st.set_page_config(
    page_title="Codebase Genius",
    page_icon="📚",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Backend configuration
BACKEND_URL = "http://localhost:8000"

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        font-weight: bold;
        text-align: center;
        margin-bottom: 2rem;
        background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }
    .stButton>button {
        width: 100%;
        background-color: #667eea;
        color: white;
        border-radius: 8px;
        padding: 0.5rem 1rem;
        font-weight: bold;
    }
    .stButton>button:hover {
        background-color: #764ba2;
    }
    .success-box {
        padding: 1rem;
        border-radius: 8px;
        background-color: #d4edda;
        border: 1px solid #c3e6cb;
        margin: 1rem 0;
    }
    .error-box {
        padding: 1rem;
        border-radius: 8px;
        background-color: #f8d7da;
        border: 1px solid #f5c6cb;
        margin: 1rem 0;
    }
    .info-box {
        padding: 1rem;
        border-radius: 8px;
        background-color: #d1ecf1;
        border: 1px solid #bee5eb;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)

# Initialize session state
if 'task_id' not in st.session_state:
    st.session_state.task_id = None
if 'status' not in st.session_state:
    st.session_state.status = None
if 'documentation' not in st.session_state:
    st.session_state.documentation = None
if 'repo_url' not in st.session_state:
    st.session_state.repo_url = ""

# Helper functions
def check_backend_health():
    """Check if backend is running"""
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        return response.status_code == 200
    except:
        return False

def analyze_repository(repo_url):
    """Start repository analysis"""
    try:
        response = requests.post(
            f"{BACKEND_URL}/analyze_repo",
            json={"repo_url": repo_url},
            timeout=10
        )
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": f"Failed with status code: {response.status_code}"}
    except Exception as e:
        return {"error": str(e)}

def check_task_status(task_id):
    """Check analysis status"""
    try:
        response = requests.get(f"{BACKEND_URL}/status/{task_id}", timeout=5)
        if response.status_code == 200:
            return response.json()
        else:
            return {"status": "error", "error": "Failed to check status"}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def download_documentation(task_id):
    """Download generated documentation"""
    try:
        response = requests.get(f"{BACKEND_URL}/download/{task_id}", timeout=5)
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": "Failed to download documentation"}
    except Exception as e:
        return {"error": str(e)}

# Main UI
st.markdown('<div class="main-header">📚 Codebase Genius</div>', unsafe_allow_html=True)
st.markdown('<p style="text-align: center; font-size: 1.2rem; color: #666;">AI-Powered Automatic Code Documentation Generator</p>', unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.header("⚙️ Settings")
    
    # Backend health check
    if check_backend_health():
        st.success("✅ Backend is running")
    else:
        st.error("❌ Backend is not responding")
        st.info("Please start the backend server:\n```bash\ncd BE/v2\njac serve main.jac\n```")
    
    st.markdown("---")
    
    st.subheader("About")
    st.info("""
    Codebase Genius is a multi-agent system that:
    
    - 🔍 Analyzes code repositories
    - 📊 Builds code context graphs
    - 📝 Generates comprehensive docs
    - 🎨 Creates visual diagrams
    """)
    
    st.markdown("---")
    
    st.subheader("Examples")
    example_repos = [
        "https://github.com/jaseci-labs/jaclang",
        "https://github.com/fastapi/fastapi",
        "https://github.com/pallets/flask"
    ]
    
    selected_example = st.selectbox(
        "Try an example:",
        ["Select an example..."] + example_repos
    )
    
    if selected_example != "Select an example...":
        if st.button("Use This Example"):
            st.session_state.repo_url = selected_example

# Main content area
col1, col2 = st.columns([2, 1])

with col1:
    st.header("🚀 Generate Documentation")
    
    # Repository URL input
    repo_url = st.text_input(
        "GitHub Repository URL",
        value=st.session_state.repo_url,
        placeholder="https://github.com/username/repository",
        help="Enter a public GitHub repository URL"
    )
    
    # Analyze button
    if st.button("🔍 Analyze Repository", type="primary"):
        if not repo_url:
            st.error("Please enter a repository URL")
        elif not repo_url.startswith("https://github.com/"):
            st.error("Please enter a valid GitHub URL")
        else:
            with st.spinner("Starting analysis..."):
                result = analyze_repository(repo_url)
                
                if "error" in result:
                    st.error(f"Error: {result['error']}")
                else:
                    st.session_state.task_id = result.get("task_id")
                    st.session_state.status = "processing"
                    st.session_state.repo_url = repo_url
                    st.success(f"✅ Analysis started! Task ID: {st.session_state.task_id}")
                    st.rerun()

with col2:
    if st.session_state.task_id:
        st.header("📊 Status")
        
        # Status container
        status_container = st.container()
        
        with status_container:
            # Check status
            status_data = check_task_status(st.session_state.task_id)
            current_status = status_data.get("progress", {}).get("status", "unknown")
            progress_pct = status_data.get("progress", {}).get("progress_percentage", 0)
            current_step = status_data.get("progress", {}).get("current_step", "")
            
            # Display status
            if current_status == "completed":
                st.success("✅ Completed!")
                st.progress(100)
            elif current_status == "error":
                st.error("❌ Error occurred")
                st.progress(0)
            elif current_status == "processing":
                st.info(f"🔄 Processing: {current_step}")
                st.progress(progress_pct / 100)
            else:
                st.warning(f"Status: {current_status}")
                st.progress(0)
            
            # Auto-refresh button
            if current_status not in ["completed", "error"]:
                if st.button("🔄 Refresh Status"):
                    st.rerun()
                
                # Auto-refresh every 3 seconds
                time.sleep(3)
                st.rerun()

# Results section
if st.session_state.task_id:
    st.markdown("---")
    st.header("📄 Documentation")
    
    status_data = check_task_status(st.session_state.task_id)
    current_status = status_data.get("progress", {}).get("status", "unknown")
    
    if current_status == "completed":
        # Download documentation
        doc_data = download_documentation(st.session_state.task_id)
        
        if "error" not in doc_data:
            documentation = doc_data.get("doc_content", "")
            
            if documentation:
                # Tabs for different views
                tab1, tab2, tab3 = st.tabs(["📝 Preview", "📋 Raw Markdown", "📊 Stats"])
                
                with tab1:
                    st.markdown(documentation)
                
                with tab2:
                    st.code(documentation, language="markdown")
                    
                    # Download button
                    st.download_button(
                        label="💾 Download Documentation",
                        data=documentation,
                        file_name=f"documentation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md",
                        mime="text/markdown"
                    )
                
                with tab3:
                    result = status_data.get("progress", {}).get("result", {})
                    stats = result.get("stats", {})
                    
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        st.metric("Total Files", stats.get("total_files", 0))
                    with col2:
                        st.metric("Total Entities", stats.get("total_entities", 0))
                    with col3:
                        st.metric("Doc Size", f"{stats.get('documentation_size', 0):,} chars")
                    
                    # Display repo info
                    if result.get("repo_info"):
                        st.subheader("Repository Information")
                        repo_info = result["repo_info"]
                        st.json(repo_info)
            else:
                st.warning("Documentation is empty or not yet generated.")
        else:
            st.error(f"Error downloading documentation: {doc_data['error']}")
    
    elif current_status == "error":
        st.error("An error occurred during analysis. Please try again.")
    
    elif current_status == "processing":
        st.info("⏳ Analysis in progress... Please wait.")
    
    else:
        st.info("Waiting for analysis to start...")

# Footer
st.markdown("---")
st.markdown("""
<div style="text-align: center; color: #666; padding: 2rem 0;">
    <p>Built with ❤️ using Jac and Streamlit</p>
    <p>Powered by AI agents for intelligent code documentation</p>
</div>
""", unsafe_allow_html=True)