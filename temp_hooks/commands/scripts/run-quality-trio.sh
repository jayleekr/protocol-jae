#!/bin/bash
# JAE Quality Trio Workflow Runner
# Polish → Review → Test 순서로 에이전트 실행

set -euo pipefail

# 스크립트 디렉토리 및 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"

# 워크플로우 정보
readonly WORKFLOW_NAME="quality-trio"
readonly AGENTS=("jae-polish-specialist" "jae-code-reviewer")  # test-engineer는 아직 구현되지 않음

# 사용법 출력
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <input_file>

JAE Quality Trio Workflow - Polish → Review → Test

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose logging
    -o, --output DIR        Output directory (default: auto-generated)

ARGUMENTS:
    input_file              Python file to process (.py)

EXAMPLES:
    $0 src/example.py
    $0 --verbose test_sample.py

EOF
}

# 워크플로우 실행
run_quality_trio() {
    local input_file="$1"
    local verbose="${2:-false}"
    
    log_info "Starting Quality Trio workflow for: $input_file"
    
    local workflow_id=$(date '+%Y%m%d_%H%M%S')
    local workflow_start_time=$(date +%s)
    local workflow_output_dir="$JAE_OUTPUT_DIR/workflow_${workflow_id}"
    
    ensure_dir "$workflow_output_dir"
    
    # 워크플로우 컨텍스트 저장
    cat > "$workflow_output_dir/workflow_context.json" << EOF
{
    "workflow_name": "$WORKFLOW_NAME",
    "workflow_id": "$workflow_id",
    "start_time": "$(date -Iseconds)",
    "input_file": "$input_file",
    "agents": $(printf '%s\n' "${AGENTS[@]}" | jq -R . | jq -s .),
    "environment": {
        "pwd": "$(pwd)",
        "user": "$USER"
    }
}
EOF
    
    local agent_results=()
    local agent_outputs=()
    
    # 각 에이전트 순차 실행
    for i in "${!AGENTS[@]}"; do
        local agent="${AGENTS[$i]}"
        local agent_num=$((i + 1))
        local total_agents=${#AGENTS[@]}
        
        log_info "[$agent_num/$total_agents] Running agent: $agent"
        
        # 에이전트 실행
        local agent_script="$SCRIPT_DIR/../agents/$agent/run.sh"
        
        if [[ ! -f "$agent_script" ]]; then
            log_error "Agent script not found: $agent_script"
            agent_results+=("failed")
            continue
        fi
        
        # 에이전트 실행 (verbose 옵션 전달)
        local agent_cmd=("$agent_script")
        if [[ "$verbose" == "true" ]]; then
            agent_cmd+=("--verbose")
        fi
        agent_cmd+=("$input_file")
        
        log_debug "Executing: ${agent_cmd[*]}"
        
        local agent_start_time=$(date +%s)
        if "${agent_cmd[@]}"; then
            local agent_end_time=$(date +%s)
            local agent_duration=$((agent_end_time - agent_start_time))
            
            log_info "✅ Agent $agent completed successfully in ${agent_duration}s"
            agent_results+=("success")
            
            # 최신 출력 디렉토리 찾기
            local latest_output=$(ls -dt "$JAE_OUTPUT_DIR/${agent}_"* 2>/dev/null | head -n1 || echo "")
            agent_outputs+=("$latest_output")
        else
            local agent_end_time=$(date +%s)
            local agent_duration=$((agent_end_time - agent_start_time))
            
            log_error "❌ Agent $agent failed after ${agent_duration}s"
            agent_results+=("failed")
            agent_outputs+=("")
            
            # 실패 시 워크플로우 중단 여부 결정
            if [[ "$agent" == "jae-security-guardian" ]]; then
                log_error "Critical security agent failed, stopping workflow"
                break
            fi
        fi
        
        # 진행률 표시
        local progress=$((agent_num * 100 / total_agents))
        echo "Progress: $progress% ($agent_num/$total_agents agents completed)"
    done
    
    # 워크플로우 결과 정리
    local workflow_end_time=$(date +%s)
    local workflow_duration=$((workflow_end_time - workflow_start_time))
    
    # 성공/실패 통계
    local success_count=0
    local failed_count=0
    
    for result in "${agent_results[@]}"; do
        if [[ "$result" == "success" ]]; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    local overall_status="success"
    if [[ $failed_count -gt 0 ]]; then
        overall_status="failed"
    fi
    
    # 최종 보고서 생성
    cat > "$workflow_output_dir/workflow_report.json" << EOF
{
    "workflow_name": "$WORKFLOW_NAME",
    "workflow_id": "$workflow_id",
    "status": "$overall_status",
    "start_time": "$(date -d @$workflow_start_time -Iseconds)",
    "end_time": "$(date -Iseconds)",
    "duration_seconds": $workflow_duration,
    "input_file": "$input_file",
    "statistics": {
        "total_agents": ${#AGENTS[@]},
        "success": $success_count,
        "failed": $failed_count
    },
    "agent_results": [
EOF
    
    # 에이전트 결과 추가
    for i in "${!AGENTS[@]}"; do
        local agent="${AGENTS[$i]}"
        local result="${agent_results[$i]:-unknown}"
        local output="${agent_outputs[$i]:-}"
        
        cat >> "$workflow_output_dir/workflow_report.json" << EOF
        {
            "agent": "$agent",
            "status": "$result",
            "output_dir": "$output"
        }
EOF
        
        if [[ $i -lt $((${#AGENTS[@]} - 1)) ]]; then
            echo "," >> "$workflow_output_dir/workflow_report.json"
        fi
    done
    
    cat >> "$workflow_output_dir/workflow_report.json" << EOF
    ]
}
EOF
    
    # 결과 출력
    echo ""
    echo "🏁 Quality Trio Workflow Completed!"
    echo "======================================"
    echo "Status: $overall_status"
    echo "Duration: ${workflow_duration}s"
    echo "Success: $success_count/${#AGENTS[@]} agents"
    echo "Report: $workflow_output_dir/workflow_report.json"
    echo ""
    
    if [[ "$overall_status" == "success" ]]; then
        echo "✨ All agents completed successfully!"
        echo "📁 Check the output directories for detailed results:"
        for output in "${agent_outputs[@]}"; do
            if [[ -n "$output" ]]; then
                echo "   - $output"
            fi
        done
    else
        echo "⚠️  Some agents failed. Check the logs for details."
    fi
    
    return $([ "$overall_status" == "success" ] && echo 0 || echo 1)
}

# 메인 함수
main() {
    local input_file=""
    local verbose=false
    
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
            -o|--output)
                export JAE_OUTPUT_DIR="$2"
                shift 2
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                else
                    error_exit "Multiple input files not supported"
                fi
                shift
                ;;
        esac
    done
    
    # 입력 파일 검증
    if [[ -z "$input_file" ]]; then
        error_exit "Input file is required. Use -h for help."
    fi
    
    if [[ ! -f "$input_file" ]]; then
        error_exit "Input file not found: $input_file"
    fi
    
    if [[ ! "$input_file" =~ \.py$ ]]; then
        error_exit "Input file must be a Python file (.py)"
    fi
    
    # 필수 도구 확인
    check_required_tools "python3" "jq"
    
    # 출력 디렉토리 준비
    ensure_dir "$JAE_OUTPUT_DIR"
    
    # 워크플로우 실행
    if run_quality_trio "$input_file" "$verbose"; then
        exit 0
    else
        exit 1
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi