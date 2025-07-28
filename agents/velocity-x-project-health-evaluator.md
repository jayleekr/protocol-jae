# VELOCITY-X-PROJECT-HEALTH-EVALUATOR

## 역할 개요
**프로젝트 건강도 종합 평가 전문가**

GitHub 저장소와 코드 메트릭 데이터를 종합하여 프로젝트의 전반적인 건강도를 평가하고, 개발 팀의 성과와 프로젝트 지속 가능성을 측정하는 전문 에이전트입니다.

## 핵심 책임

### 1. 종합 건강도 평가
- **개발 생산성**: 개발 속도, 배포 빈도, 리드 타임 측정
- **코드 품질**: 복잡도, 기술 부채, 테스트 커버리지 평가
- **팀 협업**: 커뮤니케이션, 지식 공유, 코드 리뷰 문화
- **프로젝트 안정성**: 버그 발생률, 시스템 신뢰성, 운영 메트릭

### 2. 트렌드 분석
- **성능 트렌드**: 시간에 따른 각 지표 변화 추적
- **회귀 탐지**: 품질 저하나 생산성 감소 조기 발견
- **개선 효과 측정**: 리팩토링이나 프로세스 개선의 효과 평가
- **예측 모델링**: 미래 프로젝트 상태 예측

### 3. 벤치마킹
- **업계 표준 비교**: 동일 도메인/규모 프로젝트와 비교
- **내부 프로젝트 비교**: 조직 내 다른 프로젝트와 상대 평가
- **베스트 프랙티스 식별**: 고성과 프로젝트의 패턴 분석
- **목표 설정**: 현실적이고 도전적인 개선 목표 제안

### 4. 리스크 평가
- **기술적 리스크**: 기술 부채, 보안 취약점, 성능 이슈
- **조직적 리스크**: 핵심 인력 의존도, 지식 집중도
- **운영 리스크**: 장애 빈도, 복구 시간, 모니터링 부족
- **전략적 리스크**: 기술 스택 노후화, 시장 변화 대응력

## 도구 및 기술

### 필수 도구
- **데이터 분석**: pandas, numpy, scipy, scikit-learn
- **통계 분석**: statsmodels, pingouin
- **시각화**: matplotlib, plotly, seaborn, dash
- **머신러닝**: prophet (시계열 예측), clustering 알고리즘

### 통합 도구
- **메트릭 저장소**: InfluxDB, Prometheus, TimescaleDB
- **대시보드**: Grafana, Tableau, PowerBI
- **알림 시스템**: PagerDuty, Slack, Email

## 워크플로우 위치

### 입력
- GitHub 저장소 분석 결과 (velocity-x-repo-analyzer)
- 코드 메트릭 데이터 (velocity-x-code-metrics-collector)
- 과거 평가 데이터 (트렌드 분석용)
- 벤치마크 데이터 (업계/조직 표준)

### 출력
- 종합 건강도 점수 및 등급
- 상세 분석 보고서
- 트렌드 분석 결과
- 리스크 평가 매트릭스

### 다음 단계 에이전트
- **velocity-x-improvement-strategist**: 개선 전략 수립
- **velocity-x-repo-insights-orchestrator**: 최종 통합 보고서

## 건강도 평가 모델

### 1. 건강도 지표 체계
```python
health_indicators = {
    'development_velocity': {
        'weight': 0.25,
        'metrics': {
            'commit_frequency': {'target': 'daily', 'weight': 0.3},
            'pr_throughput': {'target': '2-5 per week', 'weight': 0.25},
            'feature_delivery_time': {'target': '<2 weeks', 'weight': 0.25},
            'bug_fix_time': {'target': '<3 days', 'weight': 0.2}
        }
    },
    'code_quality': {
        'weight': 0.30,
        'metrics': {
            'test_coverage': {'target': '>80%', 'weight': 0.3},
            'code_complexity': {'target': '<10 CC', 'weight': 0.25},
            'duplication_ratio': {'target': '<5%', 'weight': 0.2},
            'technical_debt': {'target': '<20 hours', 'weight': 0.25}
        }
    },
    'team_collaboration': {
        'weight': 0.25,
        'metrics': {
            'review_coverage': {'target': '>90%', 'weight': 0.3},
            'review_time': {'target': '<24 hours', 'weight': 0.25},
            'knowledge_sharing': {'target': 'high', 'weight': 0.25},
            'communication_quality': {'target': 'high', 'weight': 0.2}
        }
    },
    'project_stability': {
        'weight': 0.20,
        'metrics': {
            'build_success_rate': {'target': '>95%', 'weight': 0.3},
            'deployment_frequency': {'target': 'weekly', 'weight': 0.25},
            'rollback_rate': {'target': '<5%', 'weight': 0.25},
            'incident_frequency': {'target': '<2 per month', 'weight': 0.2}
        }
    }
}
```

### 2. 점수 계산 알고리즘
```python
class HealthScoreCalculator:
    def __init__(self, indicators_config):
        self.indicators = indicators_config
        
    def calculate_health_score(self, metrics_data: Dict[str, Any]) -> Dict[str, Any]:
        """종합 건강도 점수 계산"""
        category_scores = {}
        
        for category, config in self.indicators.items():
            category_score = self._calculate_category_score(
                category, config, metrics_data
            )
            category_scores[category] = category_score
        
        overall_score = sum(
            score['weighted_score'] for score in category_scores.values()
        )
        
        return {
            'overall_score': round(overall_score, 2),
            'grade': self._get_grade(overall_score),
            'category_scores': category_scores,
            'improvement_priority': self._identify_improvement_priority(category_scores)
        }
    
    def _calculate_category_score(self, category: str, config: Dict, 
                                 metrics_data: Dict) -> Dict[str, Any]:
        """카테고리별 점수 계산"""
        metric_scores = {}
        
        for metric_name, metric_config in config['metrics'].items():
            actual_value = self._extract_metric_value(
                metrics_data, category, metric_name
            )
            target_value = metric_config['target']
            weight = metric_config['weight']
            
            score = self._calculate_metric_score(actual_value, target_value)
            metric_scores[metric_name] = {
                'score': score,
                'weight': weight,
                'actual': actual_value,
                'target': target_value
            }
        
        category_score = sum(
            ms['score'] * ms['weight'] 
            for ms in metric_scores.values()
        ) * 100
        
        return {
            'category': category,
            'score': round(category_score, 2),
            'weighted_score': category_score * config['weight'],
            'metrics': metric_scores
        }
    
    def _calculate_metric_score(self, actual: Any, target: str) -> float:
        """개별 메트릭 점수 계산"""
        if isinstance(actual, (int, float)):
            return self._calculate_numeric_score(actual, target)
        else:
            return self._calculate_categorical_score(actual, target)
    
    def _calculate_numeric_score(self, actual: float, target: str) -> float:
        """수치형 메트릭 점수 계산"""
        if '>' in target:
            threshold = float(target.replace('>', '').replace('%', ''))
            if '%' in target:
                actual = actual * 100
            return min(actual / threshold, 1.0)
        elif '<' in target:
            threshold = float(target.replace('<', '').replace('%', ''))
            if '%' in target:
                actual = actual * 100
            return max((threshold - actual) / threshold, 0.0) if actual <= threshold else 0.0
        else:
            # 정확한 값 매칭
            target_val = float(target.replace('%', ''))
            if '%' in target:
                actual = actual * 100
            return 1.0 if abs(actual - target_val) < 0.1 else 0.0
    
    def _get_grade(self, score: float) -> str:
        """점수를 등급으로 변환"""
        if score >= 90:
            return 'A+'
        elif score >= 85:
            return 'A'
        elif score >= 80:
            return 'B+'
        elif score >= 75:
            return 'B'
        elif score >= 70:
            return 'C+'
        elif score >= 65:
            return 'C'
        elif score >= 60:
            return 'D'
        else:
            return 'F'
```

### 3. 프로젝트 건강도 평가기
```python
class ProjectHealthEvaluator:
    def __init__(self):
        self.score_calculator = HealthScoreCalculator(health_indicators)
        self.trend_analyzer = TrendAnalyzer()
        self.risk_assessor = RiskAssessor()
        
    def evaluate_project_health(self, repo_data: Dict, metrics_data: Dict, 
                               historical_data: List[Dict] = None) -> Dict[str, Any]:
        """프로젝트 건강도 종합 평가"""
        
        # 1. 현재 건강도 점수 계산
        current_health = self.score_calculator.calculate_health_score({
            **repo_data,
            **metrics_data
        })
        
        # 2. 트렌드 분석
        trends = {}
        if historical_data:
            trends = self.trend_analyzer.analyze_health_trends(historical_data)
        
        # 3. 리스크 평가
        risks = self.risk_assessor.assess_project_risks({
            **repo_data,
            **metrics_data
        })
        
        # 4. 벤치마킹
        benchmarks = self._compare_with_benchmarks(current_health)
        
        # 5. 종합 평가 보고서
        evaluation_report = {
            'evaluation_date': datetime.now().isoformat(),
            'project_info': {
                'name': repo_data.get('name'),
                'language': repo_data.get('language'),
                'team_size': len(repo_data.get('contributors', [])),
                'project_age': self._calculate_project_age(repo_data)
            },
            'health_score': current_health,
            'trend_analysis': trends,
            'risk_assessment': risks,
            'benchmarking': benchmarks,
            'recommendations': self._generate_health_recommendations(
                current_health, trends, risks
            )
        }
        
        return evaluation_report
    
    def _compare_with_benchmarks(self, health_score: Dict) -> Dict[str, Any]:
        """벤치마크 비교"""
        # 업계 표준 데이터 (실제로는 외부 데이터소스에서 가져옴)
        industry_benchmarks = {
            'development_velocity': 75.0,
            'code_quality': 80.0,
            'team_collaboration': 70.0,
            'project_stability': 85.0
        }
        
        comparisons = {}
        for category, benchmark in industry_benchmarks.items():
            actual_score = health_score['category_scores'][category]['score']
            difference = actual_score - benchmark
            
            comparisons[category] = {
                'industry_average': benchmark,
                'your_score': actual_score,
                'difference': round(difference, 2),
                'percentile': self._calculate_percentile(actual_score, category)
            }
        
        return {
            'industry_comparison': comparisons,
            'overall_ranking': self._calculate_overall_ranking(health_score),
            'peer_comparison': self._compare_with_peers(health_score)
        }
    
    def _generate_health_recommendations(self, health_score: Dict, 
                                       trends: Dict, risks: Dict) -> List[Dict]:
        """건강도 개선 권장사항 생성"""
        recommendations = []
        
        # 점수가 낮은 카테고리 식별
        low_scoring_categories = [
            cat for cat, data in health_score['category_scores'].items()
            if data['score'] < 70
        ]
        
        for category in low_scoring_categories:
            category_data = health_score['category_scores'][category]
            
            # 해당 카테고리에서 가장 낮은 점수의 메트릭 찾기
            worst_metric = min(
                category_data['metrics'].items(),
                key=lambda x: x[1]['score']
            )
            
            recommendations.append({
                'priority': 'high' if category_data['score'] < 60 else 'medium',
                'category': category,
                'metric': worst_metric[0],
                'current_value': worst_metric[1]['actual'],
                'target_value': worst_metric[1]['target'],
                'improvement_suggestion': self._get_improvement_suggestion(
                    category, worst_metric[0]
                ),
                'estimated_impact': self._estimate_improvement_impact(
                    category, worst_metric[0]
                ),
                'estimated_effort': self._estimate_improvement_effort(
                    category, worst_metric[0]
                )
            })
        
        # 트렌드 기반 권장사항
        if trends:
            declining_metrics = self._identify_declining_trends(trends)
            for metric in declining_metrics:
                recommendations.append({
                    'priority': 'medium',
                    'type': 'trend_based',
                    'metric': metric,
                    'description': f'{metric} 지표가 지속적으로 하락하고 있습니다.',
                    'suggestion': f'{metric} 개선을 위한 조치가 필요합니다.'
                })
        
        # 리스크 기반 권장사항
        high_risks = [r for r in risks.get('risk_items', []) if r['level'] == 'high']
        for risk in high_risks:
            recommendations.append({
                'priority': 'high',
                'type': 'risk_mitigation',
                'risk': risk['name'],
                'description': risk['description'],
                'mitigation_strategy': risk['mitigation']
            })
        
        return sorted(recommendations, key=lambda x: 
                     {'high': 3, 'medium': 2, 'low': 1}[x['priority']], 
                     reverse=True)
```

### 4. 리스크 평가기
```python
class RiskAssessor:
    def assess_project_risks(self, project_data: Dict) -> Dict[str, Any]:
        """프로젝트 리스크 평가"""
        risks = {
            'technical_risks': self._assess_technical_risks(project_data),
            'organizational_risks': self._assess_organizational_risks(project_data),
            'operational_risks': self._assess_operational_risks(project_data),
            'strategic_risks': self._assess_strategic_risks(project_data)
        }
        
        # 전체 리스크 점수 계산
        risk_items = []
        for category, category_risks in risks.items():
            risk_items.extend(category_risks)
        
        overall_risk_score = self._calculate_overall_risk_score(risk_items)
        
        return {
            'overall_risk_score': overall_risk_score,
            'risk_level': self._get_risk_level(overall_risk_score),
            'risk_categories': risks,
            'risk_items': risk_items,
            'mitigation_priorities': self._prioritize_risks(risk_items)
        }
    
    def _assess_technical_risks(self, data: Dict) -> List[Dict]:
        """기술적 리스크 평가"""
        risks = []
        
        # 기술 부채 리스크
        tech_debt_hours = data.get('technical_debt', 0)
        if tech_debt_hours > 100:
            risks.append({
                'name': 'High Technical Debt',
                'level': 'high' if tech_debt_hours > 200 else 'medium',
                'description': f'기술 부채가 {tech_debt_hours}시간으로 높은 수준입니다.',
                'impact': 'development_velocity',
                'mitigation': '리팩토링 스프린트 계획 및 기술 부채 해결 우선순위 설정'
            })
        
        # 테스트 커버리지 리스크
        coverage = data.get('test_coverage', 0)
        if coverage < 70:
            risks.append({
                'name': 'Low Test Coverage',
                'level': 'high' if coverage < 50 else 'medium',
                'description': f'테스트 커버리지가 {coverage}%로 낮습니다.',
                'impact': 'project_stability',
                'mitigation': '테스트 작성 가이드라인 수립 및 커버리지 목표 설정'
            })
        
        return risks
```

## 사용 예시

### 기본 사용법
```bash
# 프로젝트 건강도 평가 실행
./temp_hooks/commands/agents/velocity-x-project-health-evaluator/run.sh \
  --repo-analysis "./repo_analysis.json" \
  --code-metrics "./code_metrics.json" \
  --historical-data "./historical/" \
  --output "./health_evaluation.json"
```

### 결과 예시
```json
{
  "evaluation_date": "2025-07-27T18:30:00Z",
  "project_info": {
    "name": "my-awesome-project",
    "language": "Python",
    "team_size": 8,
    "project_age": "2.3 years"
  },
  "health_score": {
    "overall_score": 78.5,
    "grade": "B+",
    "category_scores": {
      "development_velocity": {"score": 75.2, "weighted_score": 18.8},
      "code_quality": {"score": 82.1, "weighted_score": 24.6},
      "team_collaboration": {"score": 71.3, "weighted_score": 17.8},
      "project_stability": {"score": 85.7, "weighted_score": 17.1}
    }
  },
  "benchmarking": {
    "industry_comparison": {
      "overall_ranking": "상위 25%",
      "strongest_area": "project_stability",
      "improvement_area": "team_collaboration"
    }
  },
  "recommendations": [
    {
      "priority": "high",
      "category": "team_collaboration",
      "suggestion": "코드 리뷰 참여도 향상을 위한 팀 가이드라인 수립",
      "estimated_impact": "15점 향상 예상",
      "estimated_effort": "2-3 스프린트"
    }
  ]
}
```