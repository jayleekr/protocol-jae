#!/usr/bin/env python3
"""Demo script for Jae Quality Trio Workflow."""

import os
import sys
from pathlib import Path

# Add src to path
sys.path.append(str(Path(__file__).parent / "src"))

def check_environment():
    """Check if environment is properly configured."""
    print("🔍 환경 설정 확인...")
    
    # Check if .env file exists
    env_file = Path(".env")
    if not env_file.exists():
        print("⚠️  .env 파일이 없습니다. .env.example을 복사하여 .env를 만들고 API 키를 설정하세요.")
        return False
    
    # Check for API keys
    from dotenv import load_dotenv
    load_dotenv()
    
    openai_key = os.getenv("OPENAI_API_KEY")
    if not openai_key or openai_key == "your_openai_api_key_here":
        print("⚠️  OPENAI_API_KEY가 설정되지 않았습니다.")
        return False
    
    print("✅ 환경 설정 완료!")
    return True

def run_demo():
    """Run the Jae demo."""
    print("\n" + "="*60)
    print("🚀 Project Jae - 차세대 개발을 위한 에이전틱 워크플로우")
    print("="*60)
    
    if not check_environment():
        print("\n❌ 환경 설정을 완료한 후 다시 실행하세요.")
        return
    
    print("\n📋 데모 시나리오:")
    print("1. 품질이 낮은 샘플 코드를 Quality Trio가 처리")
    print("2. Polish Specialist → Code Reviewer → Test Engineer 순서로 실행")
    print("3. 각 단계별 결과 확인")
    
    # Import after environment check
    try:
        from src.workflows import QualityTrioWorkflow
        
        # Initialize workflow
        workflow = QualityTrioWorkflow()
        
        # Run demo
        demo_file = "examples/sample_code.py"
        print(f"\n🎯 처리할 파일: {demo_file}")
        
        results = workflow.process_file(demo_file)
        
        print("\n" + "="*60)
        print("📊 데모 결과 요약")
        print("="*60)
        
        if results.get("status") == "success":
            print("✅ Quality Trio 워크플로우가 성공적으로 완료되었습니다!")
            print("\n📈 개선 사항:")
            print("- 코드 품질 향상")
            print("- 보안 취약점 검사")
            print("- 자동 테스트 생성")
            print("- 포괄적인 코드 리뷰")
        else:
            print(f"❌ 오류 발생: {results.get('error', 'Unknown error')}")
        
    except ImportError as e:
        print(f"❌ 모듈 임포트 오류: {e}")
        print("필요한 패키지가 설치되었는지 확인하세요: pip install -r requirements.txt")
    except Exception as e:
        print(f"❌ 예상치 못한 오류: {e}")

if __name__ == "__main__":
    run_demo()