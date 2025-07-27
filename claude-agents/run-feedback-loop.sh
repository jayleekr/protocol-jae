#!/bin/bash

# JAE Claude Code 기반 피드백 루프 실행 스크립트

set -e

# 설정
MAX_ITERATIONS=5
WORK_DIR="claude-agents/work"
RESULTS_DIR="claude-agents/results/$(date +%Y%m%d_%H%M%S)"
TARGET_FILE="${1:-test_sample.py}"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 초기화
mkdir -p "$WORK_DIR" "$RESULTS_DIR"
cp "$TARGET_FILE" "$WORK_DIR/current_code.py"

echo -e "${BLUE}=== JAE 피드백 루프 워크플로우 시작 ===${NC}"
echo -e "대상 파일: $TARGET_FILE"
echo -e "최대 반복: $MAX_ITERATIONS"
echo ""

# 메인 루프
ITERATION=0
QUALITY_MET=false

while [ $ITERATION -lt $MAX_ITERATIONS ] && [ "$QUALITY_MET" = false ]; do
    ITERATION=$((ITERATION + 1))
    echo -e "${YELLOW}=== 반복 $ITERATION/$MAX_ITERATIONS ===${NC}"
    
    # 1. Polish Specialist 실행
    echo -e "${BLUE}[1/3] Polish Specialist 분석 중...${NC}"
    
    # 프롬프트 생성
    CODE_CONTENT=$(cat "$WORK_DIR/current_code.py")
    # sed 대신 템플릿 파일과 코드를 별도로 처리
    cp claude-agents/prompts/polish-specialist.md "$WORK_DIR/polish_prompt_base.md"
    echo -e "\n## 분석할 코드\n\`\`\`python" >> "$WORK_DIR/polish_prompt_base.md"
    cat "$WORK_DIR/current_code.py" >> "$WORK_DIR/polish_prompt_base.md"
    echo -e "\`\`\`" >> "$WORK_DIR/polish_prompt_base.md"
    
    # Claude Code 실행 (실제로는 claude 명령어 사용)
    mv "$WORK_DIR/polish_prompt_base.md" "$WORK_DIR/polish_prompt_$ITERATION.md"
    
    # 시뮬레이션: 실제로는 claude < polish_prompt.md > polish_output.json
    cat > "$WORK_DIR/polish_output_$ITERATION.json" << 'EOF'
{
  "analysis": {
    "complexity_score": 12,
    "code_smells": ["long function", "nested loops"],
    "duplicate_blocks": [],
    "security_concerns": []
  },
  "improvements": [
    {
      "type": "complexity",
      "location": "function process_data",
      "issue": "Triple nested loops with complexity 15",
      "suggestion": "Extract inner loops to separate functions",
      "priority": "P2"
    }
  ],
  "improved_code": "# Improved code here...",
  "metrics": {
    "before": {"complexity": 15, "lines": 120, "functions": 3},
    "after": {"complexity": 12, "lines": 100, "functions": 5}
  },
  "needs_further_work": true,
  "feedback_requested": {
    "reason": "complexity still above threshold",
    "specific_areas": ["process_data function"]
  }
}
EOF
    
    # 결과 분석
    COMPLEXITY=$(jq -r '.analysis.complexity_score' "$WORK_DIR/polish_output_$ITERATION.json")
    NEEDS_WORK=$(jq -r '.needs_further_work' "$WORK_DIR/polish_output_$ITERATION.json")
    
    echo -e "복잡도 점수: $COMPLEXITY"
    echo -e "추가 작업 필요: $NEEDS_WORK"
    
    # 2. 품질 기준 확인
    if [ "$COMPLEXITY" -lt 10 ] && [ "$NEEDS_WORK" = "false" ]; then
        echo -e "${GREEN}✅ Polish 기준 충족!${NC}"
        
        # 3. Code Reviewer 실행
        echo -e "${BLUE}[2/3] Code Reviewer 검증 중...${NC}"
        
        # Review 프롬프트 생성 및 실행
        cat > "$WORK_DIR/review_output_$ITERATION.json" << 'EOF'
{
  "review_passed": true,
  "security_issues": [],
  "performance_issues": [],
  "style_issues": [],
  "overall_score": 95
}
EOF
        
        REVIEW_PASSED=$(jq -r '.review_passed' "$WORK_DIR/review_output_$ITERATION.json")
        
        if [ "$REVIEW_PASSED" = "true" ]; then
            echo -e "${GREEN}✅ 모든 품질 기준 충족!${NC}"
            QUALITY_MET=true
        fi
    else
        # 4. 피드백 생성 및 적용
        echo -e "${YELLOW}[3/3] 피드백 생성 및 적용 중...${NC}"
        
        # 피드백 생성
        cat > "$WORK_DIR/feedback_$ITERATION.json" << EOF
{
  "iteration": $ITERATION,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source_agent": "polish-specialist",
  "issues": [
    {
      "type": "complexity",
      "severity": "high",
      "location": "process_data function",
      "current_value": $COMPLEXITY,
      "target_value": 10,
      "suggestion": "Split into smaller functions"
    }
  ],
  "action_items": [
    "Extract inner loop to 'process_batch' function",
    "Simplify conditional logic using early returns",
    "Replace nested if-else with switch statement"
  ]
}
EOF
        
        # 개선 사항 적용 (시뮬레이션)
        echo -e "${YELLOW}피드백 적용: 복잡도 $COMPLEXITY -> $((COMPLEXITY - 2))${NC}"
        
        # 다음 반복을 위한 코드 업데이트
        # 실제로는 Claude가 개선된 코드를 생성
        echo "# Iteration $ITERATION improvements applied" >> "$WORK_DIR/current_code.py"
    fi
    
    echo ""
done

# 최종 결과 저장
echo -e "${BLUE}=== 최종 결과 ===${NC}"

if [ "$QUALITY_MET" = "true" ]; then
    echo -e "${GREEN}✅ 성공: 모든 품질 기준 충족 (반복 $ITERATION회)${NC}"
else
    echo -e "${RED}⚠️  최대 반복 횟수 도달 (품질 개선 필요)${NC}"
fi

# 결과 파일 복사
cp "$WORK_DIR"/*.json "$RESULTS_DIR/"
cp "$WORK_DIR"/*.md "$RESULTS_DIR/" 2>/dev/null || true

# 요약 생성
cat > "$RESULTS_DIR/summary.json" << EOF
{
  "workflow": "feedback-loop",
  "target_file": "$TARGET_FILE",
  "total_iterations": $ITERATION,
  "quality_met": $QUALITY_MET,
  "final_complexity": $COMPLEXITY,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "results_location": "$RESULTS_DIR"
}
EOF

echo -e "\n결과 저장 위치: $RESULTS_DIR"
echo -e "상세 로그: $RESULTS_DIR/*.json"

# 학습 데이터 수집 (향후 개선용)
if [ -f "claude-agents/learning/feedback_history.jsonl" ]; then
    cat "$RESULTS_DIR/summary.json" >> "claude-agents/learning/feedback_history.jsonl"
    echo "" >> "claude-agents/learning/feedback_history.jsonl"
fi