#!/usr/bin/env python3
"""Main entry point for Jae - Agentic Workflow for Next-Gen Development."""

import argparse
import sys
from pathlib import Path

from src.config import PROJECT_ROOT
from src.workflows import QualityTrioWorkflow


def main():
    """Main function to run Jae workflows."""
    parser = argparse.ArgumentParser(
        description="Jae - 차세대 개발을 위한 에이전틱 워크플로우",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process a single file
  python main.py --file examples/sample_code.py
  
  # Process all Python files in a directory
  python main.py --directory src/
  
  # Run demo with sample code
  python main.py --demo
        """
    )
    
    parser.add_argument(
        "--file", "-f",
        type=str,
        help="Process a single Python file"
    )
    
    parser.add_argument(
        "--directory", "-d",
        type=str,
        help="Process all Python files in a directory"
    )
    
    parser.add_argument(
        "--demo",
        action="store_true",
        help="Run demo with sample code"
    )
    
    parser.add_argument(
        "--pattern",
        type=str,
        default="*.py",
        help="File pattern to match (default: *.py)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not any([args.file, args.directory, args.demo]):
        parser.print_help()
        sys.exit(1)
    
    # Initialize workflow
    print("\n🚀 Initializing Jae Quality Trio Workflow...")
    workflow = QualityTrioWorkflow()
    
    try:
        if args.demo:
            # Run demo
            demo_file = PROJECT_ROOT / "examples" / "sample_code.py"
            if not demo_file.exists():
                print(f"❌ Demo file not found: {demo_file}")
                sys.exit(1)
            
            print(f"\n📋 Running demo with: {demo_file}")
            results = workflow.process_file(str(demo_file))
            
        elif args.file:
            # Process single file
            file_path = Path(args.file)
            if not file_path.exists():
                print(f"❌ File not found: {args.file}")
                sys.exit(1)
            
            results = workflow.process_file(args.file)
            
        elif args.directory:
            # Process directory
            results = workflow.process_directory(args.directory, args.pattern)
        
        # Print final summary
        print("\n" + "="*60)
        print("📊 FINAL SUMMARY")
        print("="*60)
        
        if "summary" in results:
            print(results["summary"])
        else:
            print("✅ Workflow completed successfully!")
            
    except KeyboardInterrupt:
        print("\n\n⚠️  Workflow interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()