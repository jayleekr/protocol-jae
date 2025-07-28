#!/bin/bash
# VELOCITY-X Repository Analyzer Agent
# GitHub 저장소 분석 전문가

set -euo pipefail

# 스크립트 디렉토리 및 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/common.sh"

# 에이전트 정보
readonly AGENT_NAME="velocity-x-repo-analyzer"
readonly AGENT_VERSION="1.0.0"
readonly AGENT_DESCRIPTION="GitHub Repository Analysis Specialist"

# 사용법 출력
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <repository>

VELOCITY-X Repository Analyzer - GitHub 저장소 분석 전문가

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose logging
    -o, --output DIR        Output directory (default: auto-generated)
    --days DAYS             Analysis period in days (default: 90)
    --format FORMAT         Output format: json,html,csv (default: json)
    --token TOKEN           GitHub API token (or set GITHUB_TOKEN env var)

ARGUMENTS:
    repository              GitHub repository (owner/name or URL)

EXAMPLES:
    $0 microsoft/vscode
    $0 --days 180 --format json,html facebook/react
    $0 https://github.com/microsoft/vscode --verbose

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN           GitHub API token (required)
    VELOCITY-X_OUTPUT_DIR         Base output directory

EOF
}

# 기본 설정
DEFAULT_DAYS=90
DEFAULT_FORMAT="json"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# 옵션 파싱
parse_arguments() {
    local repository=""
    local days="$DEFAULT_DAYS"
    local format="$DEFAULT_FORMAT"
    local verbose=false
    local output_dir=""
    local token="$GITHUB_TOKEN"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                export VELOCITY-X_LOG_LEVEL=$LOG_DEBUG
                shift
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            --days)
                days="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --token)
                token="$2"
                shift 2
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                if [[ -z "$repository" ]]; then
                    repository="$1"
                else
                    error_exit "Multiple repositories not supported"
                fi
                shift
                ;;
        esac
    done
    
    # 필수 파라미터 검증
    if [[ -z "$repository" ]]; then
        error_exit "Repository is required. Use -h for help."
    fi
    
    if [[ -z "$token" ]]; then
        error_exit "GitHub token is required. Set GITHUB_TOKEN environment variable or use --token option."
    fi
    
    # 전역 변수 설정
    REPOSITORY="$repository"
    ANALYSIS_DAYS="$days"
    OUTPUT_FORMAT="$format"
    VERBOSE="$verbose"
    OUTPUT_DIR="$output_dir"
    GITHUB_TOKEN="$token"
    
    export GITHUB_TOKEN
}

# 저장소 이름 정규화
normalize_repository_name() {
    local repo="$1"
    
    # URL에서 저장소 이름 추출
    if [[ "$repo" =~ ^https?://github\.com/(.+)$ ]]; then
        repo="${BASH_REMATCH[1]}"
    fi
    
    # .git 제거
    repo="${repo%.git}"
    
    # owner/name 형식 검증
    if [[ ! "$repo" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
        error_exit "Invalid repository format. Expected: owner/name"
    fi
    
    echo "$repo"
}

# Python 분석 스크립트 실행
run_repository_analysis() {
    local repo_name="$1"
    local output_dir="$2"
    local days="$3"
    local format="$4"
    
    log_info "Starting repository analysis for: $repo_name"
    
    # Python 가상환경 확인 및 활성화
    if [[ -f "$SCRIPT_DIR/../../venv/bin/activate" ]]; then
        source "$SCRIPT_DIR/../../venv/bin/activate"
    fi
    
    # Python 분석 스크립트 실행
    python3 << EOF
import sys
import os
import json
from datetime import datetime, timedelta

# GitHub integration 모듈 경로 추가
sys.path.insert(0, '$SCRIPT_DIR/../../core')

try:
    from github_integration import create_github_client, RepositoryAnalyzer, DataProcessor
    
    def main():
        # GitHub 클라이언트 생성
        client = create_github_client()
        analyzer = RepositoryAnalyzer(client)
        
        repo_name = "$repo_name"
        output_dir = "$output_dir"
        days = int("$days")
        format_list = "$format".split(",")
        
        print(f"🔍 Analyzing repository: {repo_name}")
        print(f"📅 Analysis period: {days} days")
        print(f"📁 Output directory: {output_dir}")
        
        # 분석 시작 시간
        start_time = datetime.now()
        
        # 1. 기본 저장소 정보
        print("📊 Collecting repository information...")
        repo_info = analyzer.get_repository_info(repo_name)
        if not repo_info:
            print("❌ Failed to get repository information")
            sys.exit(1)
        
        # 2. 커밋 활동 분석
        print("💻 Analyzing commit activity...")
        since_date = datetime.now() - timedelta(days=days)
        commits = analyzer.get_commit_activity(repo_name, since=since_date)
        commit_metrics = DataProcessor.calculate_commit_metrics(commits)
        
        # 3. Pull Request 분석
        print("🔀 Analyzing pull requests...")
        prs = analyzer.get_pull_requests_analysis(repo_name, since=since_date)
        pr_metrics = DataProcessor.calculate_pr_metrics(prs)
        
        # 4. 이슈 분석
        print("🐛 Analyzing issues...")
        issues = analyzer.get_issues_analysis(repo_name, since=since_date)
        issue_metrics = DataProcessor.calculate_issue_metrics(issues)
        
        # 5. 기여자 분석
        print("👥 Analyzing contributors...")
        contributors = analyzer.get_contributors_analysis(repo_name)
        
        # 6. 릴리즈 분석
        print("🚀 Analyzing releases...")
        releases = analyzer.get_release_analysis(repo_name)
        
        # 7. 언어 통계
        print("📈 Collecting language statistics...")
        languages = analyzer.get_languages(repo_name)
        
        # 8. 코드 빈도 통계
        print("📊 Collecting code frequency...")
        code_frequency = analyzer.get_code_frequency(repo_name)
        
        # 결과 통합
        analysis_results = {
            'metadata': {
                'repository': repo_name,
                'analysis_date': datetime.now().isoformat(),
                'analysis_period_days': days,
                'agent_name': '$AGENT_NAME',
                'agent_version': '$AGENT_VERSION',
                'execution_time_seconds': (datetime.now() - start_time).total_seconds()
            },
            'repository_info': repo_info,
            'commit_analysis': {
                'raw_data': commits[:100],  # 최근 100개만 저장
                'metrics': commit_metrics
            },
            'pull_request_analysis': {
                'raw_data': prs[:50],  # 최근 50개만 저장
                'metrics': pr_metrics
            },
            'issue_analysis': {
                'raw_data': issues[:50],  # 최근 50개만 저장
                'metrics': issue_metrics
            },
            'contributors': contributors[:20],  # 상위 20명만 저장
            'releases': releases[:10],  # 최근 10개 릴리즈만 저장
            'languages': languages,
            'code_frequency': code_frequency,
            'summary': {
                'overall_activity_score': calculate_activity_score(commit_metrics, pr_metrics, issue_metrics),
                'health_indicators': calculate_health_indicators(repo_info, commit_metrics, pr_metrics, issue_metrics),
                'key_insights': generate_key_insights(repo_info, commit_metrics, pr_metrics, issue_metrics)
            }
        }
        
        # 결과 저장
        for format_type in format_list:
            format_type = format_type.strip()
            if format_type == 'json':
                output_file = os.path.join(output_dir, 'repository_analysis.json')
                DataProcessor.save_analysis_results(analysis_results, output_file, 'json')
            elif format_type == 'csv':
                output_file = os.path.join(output_dir, 'repository_analysis.csv')
                DataProcessor.save_analysis_results(analysis_results, output_file, 'csv')
            # HTML 형식은 추후 구현
        
        # 요약 정보 출력
        print("\n✅ Repository Analysis Completed!")
        print("=" * 50)
        print(f"Repository: {repo_info['full_name']}")
        print(f"Language: {repo_info['language']}")
        print(f"Stars: {repo_info['stars']}")
        print(f"Forks: {repo_info['forks']}")
        print(f"Contributors: {len(contributors)}")
        print(f"Commits (last {days} days): {commit_metrics.get('total_commits', 0)}")
        print(f"PRs (last {days} days): {pr_metrics.get('total_prs', 0)}")
        print(f"Issues (last {days} days): {issue_metrics.get('total_issues', 0)}")
        print(f"Overall Activity Score: {analysis_results['summary']['overall_activity_score']:.1f}/100")
        print("=" * 50)
        
        return analysis_results
    
    def calculate_activity_score(commit_metrics, pr_metrics, issue_metrics):
        """활동도 점수 계산 (0-100)"""
        commit_score = min(commit_metrics.get('total_commits', 0) / 10 * 20, 20)  # 최대 20점
        pr_score = min(pr_metrics.get('total_prs', 0) / 5 * 20, 20)  # 최대 20점
        issue_score = min(issue_metrics.get('total_issues', 0) / 10 * 20, 20)  # 최대 20점
        
        # 추가 품질 지표
        merge_rate = pr_metrics.get('merge_rate', 0)
        closure_rate = issue_metrics.get('closure_rate', 0)
        quality_score = (merge_rate + closure_rate) / 2 * 0.4  # 최대 40점
        
        return commit_score + pr_score + issue_score + quality_score
    
    def calculate_health_indicators(repo_info, commit_metrics, pr_metrics, issue_metrics):
        """건강도 지표 계산"""
        return {
            'maintenance_status': 'active' if commit_metrics.get('total_commits', 0) > 10 else 'low',
            'community_engagement': 'high' if repo_info['stars'] > 1000 else 'medium' if repo_info['stars'] > 100 else 'low',
            'development_velocity': 'high' if pr_metrics.get('total_prs', 0) > 20 else 'medium' if pr_metrics.get('total_prs', 0) > 5 else 'low',
            'issue_responsiveness': 'good' if issue_metrics.get('closure_rate', 0) > 70 else 'needs_improvement'
        }
    
    def generate_key_insights(repo_info, commit_metrics, pr_metrics, issue_metrics):
        """주요 인사이트 생성"""
        insights = []
        
        # 활동도 인사이트
        if commit_metrics.get('total_commits', 0) > 50:
            insights.append("높은 개발 활동도 - 활발한 커밋 활동이 관찰됩니다")
        
        # PR 인사이트
        if pr_metrics.get('merge_rate', 0) > 80:
            insights.append("효율적인 PR 프로세스 - 높은 머지 비율을 보입니다")
        
        # 이슈 인사이트
        if issue_metrics.get('bug_ratio', 0) < 20:
            insights.append("안정적인 코드베이스 - 버그 비율이 낮습니다")
        
        # 커뮤니티 인사이트
        if repo_info['stars'] > 1000:
            insights.append("인기 프로젝트 - 높은 커뮤니티 관심도를 보입니다")
        
        return insights
    
    if __name__ == "__main__":
        main()

except ImportError as e:
    print(f"❌ Error importing required modules: {e}")
    print("Please ensure github_integration.py is available and dependencies are installed")
    sys.exit(1)
except Exception as e:
    print(f"❌ Analysis failed: {e}")
    sys.exit(1)
EOF
    
    local python_exit_code=$?
    
    if [[ $python_exit_code -eq 0 ]]; then
        log_info "✅ Repository analysis completed successfully"
        return 0
    else
        log_error "❌ Repository analysis failed"
        return 1
    fi
}

# 메인 함수
main() {
    log_info "Initializing VELOCITY-X agent: $AGENT_NAME"
    
    # 인자 파싱
    parse_arguments "$@"
    
    # 저장소 이름 정규화
    REPOSITORY=$(normalize_repository_name "$REPOSITORY")
    
    # 출력 디렉토리 설정
    if [[ -z "$OUTPUT_DIR" ]]; then
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        OUTPUT_DIR="$VELOCITY-X_OUTPUT_DIR/${AGENT_NAME}_${timestamp}"
    fi
    
    ensure_dir "$OUTPUT_DIR"
    log_info "Output directory: $OUTPUT_DIR"
    
    # 필수 도구 확인
    check_required_tools "python3" "git"
    
    # Python 의존성 확인
    if ! python3 -c "import requests, pandas, github" 2>/dev/null; then
        log_error "Required Python packages not found. Please install: requests pandas PyGithub"
        error_exit "Missing Python dependencies"
    fi
    
    log_info "Agent $AGENT_NAME initialized successfully"
    
    # 진행률 표시 시작
    show_progress "$AGENT_NAME" 16 "Validating repository access"
    
    # GitHub 토큰 테스트
    if ! curl -sf -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$REPOSITORY" > /dev/null; then
        error_exit "Failed to access repository. Check repository name and token permissions."
    fi
    
    show_progress "$AGENT_NAME" 33 "Starting comprehensive analysis"
    
    # 저장소 분석 실행
    if run_repository_analysis "$REPOSITORY" "$OUTPUT_DIR" "$ANALYSIS_DAYS" "$OUTPUT_FORMAT"; then
        show_progress "$AGENT_NAME" 100 "Repository analysis completed"
        
        # 결과 메타데이터 저장
        cat > "$OUTPUT_DIR/result.json" << EOF
{
    "agent": "$AGENT_NAME",
    "version": "$AGENT_VERSION",
    "status": "success",
    "repository": "$REPOSITORY",
    "analysis_period_days": $ANALYSIS_DAYS,
    "output_format": "$OUTPUT_FORMAT",
    "execution_time": "$(date -Iseconds)",
    "output_files": [
        "repository_analysis.json"
    ]
}
EOF
        
        log_info "All analysis tasks completed successfully"
        log_info "Result metadata saved: $OUTPUT_DIR/result.json"
        log_info "Agent $AGENT_NAME completed successfully"
        
        return 0
    else
        error_exit "Repository analysis failed"
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi