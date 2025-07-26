"""Static analysis tools for code quality checking."""

import subprocess
import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from crewai_tools import BaseTool


class RuffTool(BaseTool):
    """Tool for running Ruff static analysis."""

    name: str = "Ruff Static Analysis Tool"
    description: str = (
        "Run Ruff to check code quality, find issues, and suggest fixes. "
        "Ruff is an extremely fast Python linter that covers many rules."
    )

    def _run(
        self,
        file_path: str,
        fix: bool = False,
        **kwargs: Any,
    ) -> str:
        """
        Run Ruff on a file.

        Args:
            file_path: Path to the Python file to analyze
            fix: Whether to automatically fix issues

        Returns:
            Analysis results or error message
        """
        try:
            cmd = ["ruff", "check", file_path, "--output-format", "json"]
            if fix:
                cmd.append("--fix")

            result = subprocess.run(
                cmd, capture_output=True, text=True
            )

            if result.returncode == 0:
                return f"✅ No issues found in {file_path}"

            # Parse JSON output
            try:
                issues = json.loads(result.stdout)
                if not issues:
                    return f"✅ No issues found in {file_path}"

                # Format issues
                output = [f"🔍 Ruff found {len(issues)} issue(s) in {file_path}:\n"]
                
                for issue in issues:
                    output.append(
                        f"  - Line {issue['location']['row']}: "
                        f"{issue['code']} - {issue['message']}"
                    )
                    if issue.get('fix'):
                        output.append(f"    Fix available: {issue['fix']['message']}")

                return "\n".join(output)

            except json.JSONDecodeError:
                # Fallback to plain text output
                return f"Ruff output:\n{result.stdout}"

        except FileNotFoundError:
            return "Error: Ruff is not installed. Please install it with 'pip install ruff'"
        except Exception as e:
            return f"Error running Ruff: {str(e)}"


class PylintTool(BaseTool):
    """Tool for running Pylint static analysis."""

    name: str = "Pylint Static Analysis Tool"
    description: str = (
        "Run Pylint for comprehensive code analysis including "
        "code smells, refactoring opportunities, and best practices."
    )

    def _run(
        self,
        file_path: str,
        **kwargs: Any,
    ) -> str:
        """
        Run Pylint on a file.

        Args:
            file_path: Path to the Python file to analyze

        Returns:
            Analysis results with score and issues
        """
        try:
            # Run pylint with JSON output
            cmd = [
                "pylint",
                file_path,
                "--output-format=json",
                "--reports=n",
            ]

            result = subprocess.run(
                cmd, capture_output=True, text=True
            )

            # Parse JSON output
            try:
                if result.stdout:
                    issues = json.loads(result.stdout)
                    
                    if not issues:
                        return f"✅ Pylint found no issues in {file_path}"

                    # Group issues by type
                    issue_types: Dict[str, List[Dict[str, Any]]] = {
                        "error": [],
                        "warning": [],
                        "refactor": [],
                        "convention": [],
                    }

                    for issue in issues:
                        issue_type = issue.get("type", "warning")
                        if issue_type in issue_types:
                            issue_types[issue_type].append(issue)

                    # Format output
                    output = [f"🔍 Pylint analysis for {file_path}:\n"]

                    for issue_type, type_issues in issue_types.items():
                        if type_issues:
                            output.append(f"\n{issue_type.upper()}S ({len(type_issues)}):")
                            for issue in type_issues:
                                output.append(
                                    f"  - Line {issue['line']}: "
                                    f"{issue['symbol']} - {issue['message']}"
                                )

                    # Get score
                    score_cmd = [
                        "pylint",
                        file_path,
                        "--score=y",
                        "--reports=n",
                    ]
                    score_result = subprocess.run(
                        score_cmd, capture_output=True, text=True
                    )
                    
                    # Extract score from output
                    for line in score_result.stdout.split('\n'):
                        if "Your code has been rated at" in line:
                            output.append(f"\n{line}")
                            break

                    return "\n".join(output)

                else:
                    return f"✅ Pylint found no issues in {file_path}"

            except json.JSONDecodeError:
                # Fallback to plain text
                return f"Pylint output:\n{result.stderr}"

        except FileNotFoundError:
            return "Error: Pylint is not installed. Please install it with 'pip install pylint'"
        except Exception as e:
            return f"Error running Pylint: {str(e)}"


class CodeComplexityTool(BaseTool):
    """Tool for analyzing code complexity."""

    name: str = "Code Complexity Tool"
    description: str = (
        "Analyze code complexity metrics including cyclomatic complexity, "
        "cognitive complexity, and maintainability index."
    )

    def _run(
        self,
        file_path: str,
        **kwargs: Any,
    ) -> str:
        """
        Analyze code complexity.

        Args:
            file_path: Path to the Python file to analyze

        Returns:
            Complexity analysis results
        """
        try:
            # Use radon for complexity analysis
            cmd = ["radon", "cc", file_path, "-s", "--json"]

            result = subprocess.run(
                cmd, capture_output=True, text=True
            )

            if result.returncode != 0:
                return f"Error analyzing complexity: {result.stderr}"

            # Parse JSON output
            try:
                data = json.loads(result.stdout)
                
                if not data or not data.get(file_path):
                    return f"✅ No complexity issues found in {file_path}"

                output = [f"🔍 Complexity analysis for {file_path}:\n"]
                
                for item in data[file_path]:
                    complexity = item['complexity']
                    name = item['name']
                    line = item['lineno']
                    
                    # Determine complexity level
                    if complexity <= 5:
                        level = "Simple"
                        emoji = "✅"
                    elif complexity <= 10:
                        level = "Moderate"
                        emoji = "⚠️"
                    else:
                        level = "Complex"
                        emoji = "🚨"
                    
                    output.append(
                        f"  {emoji} {name} (line {line}): "
                        f"Complexity = {complexity} ({level})"
                    )

                # Add maintainability index
                mi_cmd = ["radon", "mi", file_path, "-s"]
                mi_result = subprocess.run(
                    mi_cmd, capture_output=True, text=True
                )
                
                if mi_result.returncode == 0:
                    output.append(f"\n{mi_result.stdout.strip()}")

                return "\n".join(output)

            except json.JSONDecodeError:
                return f"Complexity analysis output:\n{result.stdout}"

        except FileNotFoundError:
            return "Error: Radon is not installed. Please install it with 'pip install radon'"
        except Exception as e:
            return f"Error analyzing complexity: {str(e)}"


# Export tools for use by agents
ruff_tool = RuffTool()
pylint_tool = PylintTool()
complexity_tool = CodeComplexityTool()