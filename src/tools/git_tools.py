"""Git integration tools for Jae agents."""

import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

from crewai_tools import BaseTool


class GitFileTool(BaseTool):
    """Tool for reading and writing files in a git repository."""

    name: str = "Git File Tool"
    description: str = (
        "Read and write files in a git repository. "
        "Use this tool to access and modify source code files."
    )

    def _run(
        self,
        action: str,
        file_path: str,
        content: Optional[str] = None,
        **kwargs: Any,
    ) -> str:
        """
        Execute git file operations.

        Args:
            action: 'read' or 'write'
            file_path: Path to the file relative to repository root
            content: Content to write (only for 'write' action)

        Returns:
            File content for 'read', success message for 'write'
        """
        try:
            path = Path(file_path)

            if action == "read":
                if not path.exists():
                    return f"Error: File {file_path} does not exist"
                return path.read_text(encoding="utf-8")

            elif action == "write":
                if content is None:
                    return "Error: Content is required for write action"

                # Create parent directories if they don't exist
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")

                return f"Successfully wrote to {file_path}"

            else:
                return f"Error: Unknown action '{action}'. Use 'read' or 'write'"

        except Exception as e:
            return f"Error: {str(e)}"


class GitDiffTool(BaseTool):
    """Tool for generating git diffs."""

    name: str = "Git Diff Tool"
    description: str = (
        "Generate git diffs to see what changes have been made. "
        "Useful for reviewing modifications before committing."
    )

    def _run(self, file_path: Optional[str] = None, **kwargs: Any) -> str:
        """
        Generate git diff.

        Args:
            file_path: Optional specific file to diff

        Returns:
            Git diff output
        """
        try:
            cmd = ["git", "diff"]
            if file_path:
                cmd.append(file_path)

            result = subprocess.run(
                cmd, capture_output=True, text=True, check=True
            )

            if not result.stdout:
                return "No changes detected"

            return result.stdout

        except subprocess.CalledProcessError as e:
            return f"Error running git diff: {e.stderr}"
        except Exception as e:
            return f"Error: {str(e)}"


class GitStatusTool(BaseTool):
    """Tool for checking git status."""

    name: str = "Git Status Tool"
    description: str = (
        "Check the current git status to see modified, staged, and untracked files."
    )

    def _run(self, **kwargs: Any) -> str:
        """
        Get git status.

        Returns:
            Git status output
        """
        try:
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                capture_output=True,
                text=True,
                check=True,
            )

            if not result.stdout:
                return "Working directory clean"

            # Parse git status output
            lines = result.stdout.strip().split("\n")
            status_dict: Dict[str, List[str]] = {
                "modified": [],
                "added": [],
                "deleted": [],
                "untracked": [],
            }

            for line in lines:
                if line.startswith(" M"):
                    status_dict["modified"].append(line[3:])
                elif line.startswith("M "):
                    status_dict["modified"].append(line[3:])
                elif line.startswith("A "):
                    status_dict["added"].append(line[3:])
                elif line.startswith("D "):
                    status_dict["deleted"].append(line[3:])
                elif line.startswith("??"):
                    status_dict["untracked"].append(line[3:])

            # Format output
            output = []
            for status_type, files in status_dict.items():
                if files:
                    output.append(f"\n{status_type.capitalize()} files:")
                    for file in files:
                        output.append(f"  - {file}")

            return (
                "Git Status:" + "".join(output) 
                if output 
                else "Working directory clean"
            )

        except subprocess.CalledProcessError as e:
            return f"Error running git status: {e.stderr}"
        except Exception as e:
            return f"Error: {str(e)}"


# Export tools for use by agents
git_file_tool = GitFileTool()
git_diff_tool = GitDiffTool()
git_status_tool = GitStatusTool()