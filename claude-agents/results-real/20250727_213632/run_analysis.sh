#!/bin/bash
# Claude Code로 분석 실행하는 헬퍼 스크립트

echo "Claude Code에 분석 요청..."
# 실제로는: cat analyze_request.md | claude > result.json

echo "결과 파싱..."
# jq로 JSON 파싱하여 품질 확인

echo "피드백 적용..."
# 필요시 개선 요청 반복
