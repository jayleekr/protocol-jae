#!/bin/bash
# JAE Workflow Runner
# 지정된 워크플로우를 실행하는 편리한 스크립트

set -euo pipefail

# 스크립트 디렉토리 및 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"

# 기본값 설정
DEFAULT_WORKFLOW="quality-trio"
WORKFLOW_ENGINE="$SCRIPT_DIR/../core/workflow_engine.py"

# 사용법 출력
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [input_files...]

JAE Workflow Runner - Execute JAE agent workflows

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose logging
    -w, --workflow NAME     Workflow to run (default: $DEFAULT_WORKFLOW)
    -l, --list              List available workflows
    --config-dir DIR        Configuration directory
    --dry-run               Show what would be executed without running

WORKFLOWS:
    quality-trio            Polish + Review + Test (MVP)
    security-focused        Security-focused workflow
    full-workflow           Complete 9-agent workflow

EXAMPLES:
    $0 src/example.py
    $0 --workflow security-focused src/*.py
    $0 --list
    $0 --dry-run --workflow full-workflow

EOF
}

# 사용 가능한 워크플로우 목록 출력
list_workflows() {
    local config_file="$JAE_CONFIG_DIR/agents.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        error_exit "Configuration file not found: $config_file"
    fi
    
    echo "Available workflows:"
    echo "==================="
    
    if command -v yq &> /dev/null; then
        yq eval '.workflows | keys | .[]' "$config_file" | while read -r workflow; do
            description=$(yq eval ".workflows.${workflow}.description" "$config_file")
            agents=$(yq eval ".workflows.${workflow}.agents | length" "$config_file")
            echo "  $workflow: $description ($agents agents)"
        done
    else
        # yq가 없으면 간단한 grep 기반 파싱
        grep -A 2 "workflows:" "$config_file" | grep -E "^\s+[a-z-]+:" | sed 's/^\s*/  /' | sed 's/:$//'
    fi
    
    echo ""
    echo "Use --workflow <name> to run a specific workflow"
}

# 실행 계획 출력 (dry-run)
show_execution_plan() {
    local workflow="$1"
    local input_files=("${@:2}")
    
    echo "Execution Plan for workflow: $workflow"
    echo "====================================="
    echo "Input files: ${input_files[*]:-<none>}"
    echo ""
    echo "This would execute the following command:"
    echo "python3 '$WORKFLOW_ENGINE' '$workflow' ${input_files[*]}"
    echo ""
    echo "Configuration directory: $JAE_CONFIG_DIR"
    echo "Output directory: $JAE_OUTPUT_DIR"
    echo "Temp directory: $JAE_TEMP_DIR"
}

# 워크플로우 실행
run_workflow() {
    local workflow="$1"
    local verbose="$2"
    shift 2
    local input_files=("$@")
    
    log_info "Starting JAE workflow: $workflow"
    
    # 워크플로우 엔진 실행
    local cmd=(python3 "$WORKFLOW_ENGINE" "$workflow")
    
    if [[ "$verbose" == "true" ]]; then
        cmd+=(--verbose)
    fi
    
    if [[ -n "$JAE_CONFIG_DIR" ]]; then
        cmd+=(--config-dir "$JAE_CONFIG_DIR")
    fi
    
    # 입력 파일 추가
    cmd+=("${input_files[@]}")
    
    log_debug "Executing: ${cmd[*]}"
    
    # 실행 시작 시간 기록
    local start_time=$(date +%s)
    
    # 워크플로우 실행
    if "${cmd[@]}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_info "Workflow $workflow completed successfully in ${duration}s"
        
        # 결과 요약 출력
        echo ""
        echo "🎉 Workflow completed successfully!"
        echo "⏱️  Duration: ${duration} seconds"
        echo "📁 Output directory: $JAE_OUTPUT_DIR"
        echo ""
        echo "Next steps:"
        echo "  - Check the output directory for results"
        echo "  - Review the workflow report for details"
        echo "  - Use the processed files for your next steps"
        
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_error "Workflow $workflow failed after ${duration}s"
        
        echo ""
        echo "❌ Workflow failed!"
        echo "⏱️  Duration: ${duration} seconds"
        echo "📁 Check logs in: $JAE_OUTPUT_DIR"
        echo ""
        echo "Troubleshooting:"
        echo "  - Check agent logs for specific errors"
        echo "  - Verify input files are valid"
        echo "  - Ensure all required tools are installed"
        
        return 1
    fi
}

# 환경 검증
validate_environment() {
    log_debug "Validating environment..."
    
    # Python 확인
    if ! command -v python3 &> /dev/null; then
        error_exit "Python 3 is required but not found"
    fi
    
    # 워크플로우 엔진 확인
    if [[ ! -f "$WORKFLOW_ENGINE" ]]; then
        error_exit "Workflow engine not found: $WORKFLOW_ENGINE"
    fi
    
    # 설정 디렉토리 확인
    if [[ ! -d "$JAE_CONFIG_DIR" ]]; then
        error_exit "Configuration directory not found: $JAE_CONFIG_DIR"
    fi
    
    # 필수 설정 파일 확인
    local required_files=("agents.yaml" "tools.yaml")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$JAE_CONFIG_DIR/$file" ]]; then
            error_exit "Required configuration file not found: $JAE_CONFIG_DIR/$file"
        fi
    done
    
    # 출력 디렉토리 생성
    ensure_dir "$JAE_OUTPUT_DIR"
    ensure_dir "$JAE_TEMP_DIR"
    
    log_debug "Environment validation completed"
}

# 메인 함수
main() {
    local workflow="$DEFAULT_WORKFLOW"
    local verbose=false
    local dry_run=false
    local list_workflows_flag=false
    local input_files=()
    
    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                export JAE_LOG_LEVEL=$LOG_DEBUG
                shift
                ;;
            -w|--workflow)
                workflow="$2"
                shift 2
                ;;
            -l|--list)
                list_workflows_flag=true
                shift
                ;;
            --config-dir)
                export JAE_CONFIG_DIR="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                input_files+=("$1")
                shift
                ;;
        esac
    done
    
    # 환경 검증
    validate_environment
    
    # 워크플로우 목록 출력
    if [[ "$list_workflows_flag" == "true" ]]; then
        list_workflows
        exit 0
    fi
    
    # 실행 계획 출력 (dry-run)
    if [[ "$dry_run" == "true" ]]; then
        show_execution_plan "$workflow" "${input_files[@]}"
        exit 0
    fi
    
    # 입력 파일 검증
    for file in "${input_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error_exit "Input file not found: $file"
        fi
    done
    
    # 워크플로우 실행
    if run_workflow "$workflow" "$verbose" "${input_files[@]}"; then
        exit 0
    else
        exit 1
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi