"""Quality Trio Workflow - Sequential execution of polish, review, and test agents."""

from pathlib import Path
from typing import Any, Dict, List, Optional

from crewai import Crew, Process

from src.agents import CodeReviewer, PolishSpecialist, TestEngineer
from src.config import CREW_CONFIG


class QualityTrioWorkflow:
    """
    Orchestrates the sequential execution of the Quality Trio:
    1. Polish Specialist - Improves code quality
    2. Code Reviewer - Reviews the polished code
    3. Test Engineer - Generates tests for the reviewed code
    """

    def __init__(self):
        """Initialize the Quality Trio workflow."""
        # Initialize agents
        self.polish_specialist = PolishSpecialist()
        self.code_reviewer = CodeReviewer()
        self.test_engineer = TestEngineer()

        # Workflow configuration
        self.verbose = CREW_CONFIG["verbose"]
        self.memory = CREW_CONFIG["memory"]

    def process_file(self, file_path: str) -> Dict[str, Any]:
        """
        Process a single file through the Quality Trio workflow.

        Args:
            file_path: Path to the file to process

        Returns:
            Dictionary containing results from all three agents
        """
        results = {
            "file_path": file_path,
            "workflow": "quality_trio",
            "stages": {},
        }

        print(f"\n🚀 Starting Quality Trio Workflow for: {file_path}")
        print("=" * 60)

        try:
            # Stage 1: Polish the code
            print("\n📝 Stage 1: Polish Specialist")
            print("-" * 40)
            polish_task = self.polish_specialist.create_polish_task(file_path)

            # Create a crew for polish stage
            polish_crew = Crew(
                agents=[self.polish_specialist.agent],
                tasks=[polish_task],
                process=Process.sequential,
                verbose=self.verbose,
                memory=self.memory,
            )

            polish_result = polish_crew.kickoff()
            results["stages"]["polish"] = {
                "status": "completed",
                "result": str(polish_result),
            }
            print("✅ Polish stage completed")

            # Stage 2: Review the polished code
            print("\n🔍 Stage 2: Code Reviewer")
            print("-" * 40)
            review_task = self.code_reviewer.create_review_task(
                file_path,
                context="This code has been polished by the Polish Specialist.",
            )

            # Create a crew for review stage
            review_crew = Crew(
                agents=[self.code_reviewer.agent],
                tasks=[review_task],
                process=Process.sequential,
                verbose=self.verbose,
                memory=self.memory,
            )

            review_result = review_crew.kickoff()
            results["stages"]["review"] = {
                "status": "completed",
                "result": str(review_result),
            }
            print("✅ Review stage completed")

            # Stage 3: Generate tests
            print("\n🧪 Stage 3: Test Engineer")
            print("-" * 40)
            test_task = self.test_engineer.create_test_generation_task(file_path)

            # Create a crew for test stage
            test_crew = Crew(
                agents=[self.test_engineer.agent],
                tasks=[test_task],
                process=Process.sequential,
                verbose=self.verbose,
                memory=self.memory,
            )

            test_result = test_crew.kickoff()
            results["stages"]["test"] = {
                "status": "completed",
                "result": str(test_result),
            }
            print("✅ Test generation stage completed")

            # Summary
            print("\n🎉 Quality Trio Workflow Completed Successfully!")
            print("=" * 60)

            results["status"] = "success"
            results["summary"] = self._generate_summary(results)

        except Exception as e:
            print(f"\n❌ Error in workflow: {str(e)}")
            results["status"] = "error"
            results["error"] = str(e)

        return results

    def process_directory(
        self,
        directory_path: str,
        pattern: str = "*.py",
        exclude_patterns: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Process all matching files in a directory.

        Args:
            directory_path: Path to the directory
            pattern: File pattern to match (default: "*.py")
            exclude_patterns: List of patterns to exclude

        Returns:
            Dictionary containing results for all processed files
        """
        dir_path = Path(directory_path)
        if not dir_path.exists() or not dir_path.is_dir():
            return {
                "error": (
                    f"Directory {directory_path} does not exist or is not a directory"
                )
            }

        # Default exclusions
        if exclude_patterns is None:
            exclude_patterns = ["__pycache__", "*.pyc", "test_*.py", "*_test.py"]

        # Find matching files
        files = list(dir_path.glob(pattern))

        # Filter out excluded patterns
        filtered_files = []
        for file in files:
            exclude = False
            for pattern in exclude_patterns:
                if file.match(pattern):
                    exclude = True
                    break
            if not exclude:
                filtered_files.append(file)

        results = {
            "directory": directory_path,
            "files_processed": [],
            "total_files": len(filtered_files),
            "workflow": "quality_trio",
        }

        print(f"\n🔄 Processing {len(filtered_files)} files in {directory_path}")

        for file_path in filtered_files:
            print(f"\n{'='*60}")
            print(
                f"Processing file {filtered_files.index(file_path) + 1}/"
                f"{len(filtered_files)}"
            )
            file_results = self.process_file(str(file_path))
            results["files_processed"].append(file_results)

        results["summary"] = self._generate_batch_summary(results)

        return results

    def _generate_summary(self, results: Dict[str, Any]) -> str:
        """Generate a summary of the workflow results."""
        summary_parts = [
            f"File: {results['file_path']}",
            f"Workflow Status: {results.get('status', 'unknown')}",
            "\nStages Completed:",
        ]

        for stage, stage_data in results.get("stages", {}).items():
            summary_parts.append(f"  - {stage}: {stage_data.get('status', 'unknown')}")

        return "\n".join(summary_parts)

    def _generate_batch_summary(self, results: Dict[str, Any]) -> str:
        """Generate a summary for batch processing results."""
        successful = sum(
            1 for file in results["files_processed"] if file.get("status") == "success"
        )
        failed = len(results["files_processed"]) - successful

        summary = f"""
Batch Processing Summary:
- Directory: {results['directory']}
- Total Files: {results['total_files']}
- Successful: {successful}
- Failed: {failed}
        """

        if failed > 0:
            summary += "\n\nFailed Files:"
            for file_result in results["files_processed"]:
                if file_result.get("status") != "success":
                    summary += (
                        f"\n  - {file_result['file_path']}: "
                        f"{file_result.get('error', 'Unknown error')}"
                    )

        return summary.strip()
