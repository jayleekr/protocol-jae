# VELOCITY-X-REPO-INSIGHTS-ORCHESTRATOR

## 역할 개요
**GitHub 저장소 인사이트 통합 오케스트레이터**

5개의 GitHub 분석 전문 에이전트들을 조정하여 전체 분석 워크플로우를 실행하고, 종합적인 저장소 인사이트 보고서를 생성하는 마스터 에이전트입니다.

## 핵심 책임

### 1. 워크플로우 오케스트레이션
- **다중 에이전트 조정**: 5개 분석 에이전트의 순차/병렬 실행 관리
- **데이터 파이프라인**: 에이전트 간 데이터 흐름 및 의존성 관리
- **오류 처리**: 개별 에이전트 실패 시 복구 및 재시도 로직
- **성능 최적화**: 병렬 처리 및 캐싱을 통한 실행 시간 단축

### 2. 종합 보고서 생성
- **데이터 통합**: 각 에이전트 결과를 통합한 마스터 데이터셋
- **인사이트 추출**: 패턴 분석 및 핵심 발견사항 도출
- **시각화 대시보드**: 인터랙티브 차트 및 그래프 생성
- **실행 요약**: 경영진/팀 리더용 간결한 요약 보고서

### 3. 사용자 인터페이스
- **CLI 인터페이스**: 명령행 기반 간편한 실행
- **웹 대시보드**: 브라우저 기반 결과 조회 및 분석
- **API 엔드포인트**: 외부 시스템 통합을 위한 REST API
- **리포트 내보내기**: PDF, Excel, JSON 등 다양한 형태 지원

### 4. 지속적 모니터링
- **정기 분석**: 스케줄 기반 자동 분석 실행
- **변화 감지**: 주요 지표 변화 알림 및 경고
- **트렌드 추적**: 장기간 데이터 축적 및 트렌드 분석
- **성과 추적**: 개선 조치 후 효과 모니터링

## 도구 및 기술

### 필수 도구
- **워크플로우 엔진**: Apache Airflow, Prefect, 또는 커스텀 파이프라인
- **데이터 처리**: pandas, dask (대용량 데이터)
- **시각화**: plotly dash, streamlit, 또는 React 기반 웹앱
- **스케줄링**: cron, APScheduler, 또는 클라우드 스케줄러

### 통합 도구
- **클라우드 플랫폼**: AWS, GCP, Azure (스케일링 및 저장)
- **컨테이너**: Docker, Kubernetes (배포 및 확장)
- **모니터링**: Prometheus, Grafana (시스템 모니터링)

## 워크플로우 위치

### 입력
- GitHub 저장소 URL 또는 목록
- 분석 설정 및 구성 파일
- 사용자 요구사항 및 필터링 옵션

### 출력
- 종합 인사이트 보고서
- 대화형 대시보드
- 액션 아이템 및 권장사항
- 트렌드 분석 및 예측

### 하위 에이전트 관리
1. **velocity-x-repo-analyzer**: GitHub 메타데이터 수집
2. **velocity-x-code-metrics-collector**: 코드 품질 정량화
3. **velocity-x-project-health-evaluator**: 종합 건강도 평가
4. **velocity-x-improvement-strategist**: 개선 전략 수립

## 워크플로우 설계

### 1. 실행 파이프라인
```python
from typing import Dict, List, Any, Optional
import asyncio
import json
from datetime import datetime
from dataclasses import dataclass
import pandas as pd

@dataclass
class AnalysisConfig:
    repo_url: str
    analysis_depth: str = 'standard'  # basic, standard, comprehensive
    include_historical: bool = True
    max_analysis_days: int = 90
    output_format: List[str] = None
    
    def __post_init__(self):
        if self.output_format is None:
            self.output_format = ['json', 'html']

class RepoInsightsOrchestrator:
    def __init__(self, config: AnalysisConfig):
        self.config = config
        self.agents = {
            'repo_analyzer': RepoAnalyzer(),
            'metrics_collector': CodeMetricsCollector(),
            'health_evaluator': ProjectHealthEvaluator(), 
            'improvement_strategist': ImprovementStrategist()
        }
        self.results = {}
        self.execution_log = []
        
    async def execute_full_analysis(self) -> Dict[str, Any]:
        """전체 분석 워크플로우 실행"""
        
        start_time = datetime.now()
        self._log_execution("Analysis started", "info")
        
        try:
            # Phase 1: 기본 데이터 수집 (병렬 실행)
            phase1_tasks = [
                self._run_repo_analysis(),
                self._run_code_metrics_collection()
            ]
            
            repo_data, metrics_data = await asyncio.gather(*phase1_tasks)
            
            # Phase 2: 분석 및 평가 (순차 실행 - 의존성 있음)
            health_evaluation = await self._run_health_evaluation(
                repo_data, metrics_data
            )
            
            # Phase 3: 전략 수립
            improvement_strategy = await self._run_improvement_strategy(
                health_evaluation
            )
            
            # Phase 4: 결과 통합 및 보고서 생성
            comprehensive_report = await self._generate_comprehensive_report({
                'repo_analysis': repo_data,
                'code_metrics': metrics_data,
                'health_evaluation': health_evaluation,
                'improvement_strategy': improvement_strategy
            })
            
            execution_time = (datetime.now() - start_time).total_seconds()
            self._log_execution(f"Analysis completed in {execution_time:.2f}s", "success")
            
            return comprehensive_report
            
        except Exception as e:
            self._log_execution(f"Analysis failed: {str(e)}", "error")
            raise
    
    async def _run_repo_analysis(self) -> Dict[str, Any]:
        """GitHub 저장소 분석 실행"""
        self._log_execution("Starting repository analysis", "info")
        
        try:
            result = await self.agents['repo_analyzer'].analyze_repository(
                self.config.repo_url,
                days_back=self.config.max_analysis_days
            )
            
            self.results['repo_analysis'] = result
            self._log_execution("Repository analysis completed", "success")
            return result
            
        except Exception as e:
            self._log_execution(f"Repository analysis failed: {e}", "error")
            raise
    
    async def _run_code_metrics_collection(self) -> Dict[str, Any]:
        """코드 메트릭 수집 실행"""
        self._log_execution("Starting code metrics collection", "info")
        
        try:
            # GitHub에서 코드 클론 또는 API를 통한 메트릭 수집
            result = await self.agents['metrics_collector'].collect_all_metrics(
                self.config.repo_url
            )
            
            self.results['code_metrics'] = result
            self._log_execution("Code metrics collection completed", "success")
            return result
            
        except Exception as e:
            self._log_execution(f"Code metrics collection failed: {e}", "error")
            # 메트릭 수집 실패 시 기본값 반환
            return self._get_default_metrics()
    
    async def _run_health_evaluation(self, repo_data: Dict, 
                                   metrics_data: Dict) -> Dict[str, Any]:
        """프로젝트 건강도 평가 실행"""
        self._log_execution("Starting health evaluation", "info")
        
        try:
            # 과거 데이터 가져오기 (있는 경우)
            historical_data = await self._load_historical_data() if self.config.include_historical else None
            
            result = await self.agents['health_evaluator'].evaluate_project_health(
                repo_data, metrics_data, historical_data
            )
            
            self.results['health_evaluation'] = result
            self._log_execution("Health evaluation completed", "success")
            return result
            
        except Exception as e:
            self._log_execution(f"Health evaluation failed: {e}", "error")
            raise
    
    async def _run_improvement_strategy(self, health_evaluation: Dict) -> Dict[str, Any]:
        """개선 전략 수립 실행"""
        self._log_execution("Starting improvement strategy", "info")
        
        try:
            # 팀 역량 정보 로드 (설정에서)
            team_capacity = await self._load_team_capacity()
            
            result = await self.agents['improvement_strategist'].create_improvement_strategy(
                health_evaluation, team_capacity
            )
            
            self.results['improvement_strategy'] = result
            self._log_execution("Improvement strategy completed", "success")
            return result
            
        except Exception as e:
            self._log_execution(f"Improvement strategy failed: {e}", "error")
            raise
    
    async def _generate_comprehensive_report(self, all_results: Dict[str, Any]) -> Dict[str, Any]:
        """종합 보고서 생성"""
        self._log_execution("Generating comprehensive report", "info")
        
        # 핵심 인사이트 추출
        key_insights = self._extract_key_insights(all_results)
        
        # 실행 요약 생성
        executive_summary = self._create_executive_summary(all_results, key_insights)
        
        # 상세 분석 결과
        detailed_analysis = self._create_detailed_analysis(all_results)
        
        # 시각화 데이터 준비
        visualization_data = self._prepare_visualization_data(all_results)
        
        # 액션 아이템 정리
        action_items = self._consolidate_action_items(all_results)
        
        comprehensive_report = {
            'metadata': {
                'analysis_date': datetime.now().isoformat(),
                'repository': self.config.repo_url,
                'analysis_config': self.config.__dict__,
                'execution_time': self._calculate_total_execution_time(),
                'agents_status': self._get_agents_status()
            },
            'executive_summary': executive_summary,
            'key_insights': key_insights,
            'detailed_analysis': detailed_analysis,
            'visualization_data': visualization_data,
            'action_items': action_items,
            'raw_results': all_results,
            'execution_log': self.execution_log
        }
        
        # 다양한 형태로 출력 생성
        await self._export_results(comprehensive_report)
        
        self._log_execution("Comprehensive report generated", "success")
        return comprehensive_report
    
    def _extract_key_insights(self, results: Dict[str, Any]) -> List[Dict[str, Any]]:
        """핵심 인사이트 추출"""
        insights = []
        
        # 저장소 분석에서 인사이트
        repo_data = results['repo_analysis']
        if repo_data.get('health_score', 0) > 85:
            insights.append({
                'type': 'positive',
                'category': 'repository_health',
                'title': '우수한 저장소 관리',
                'description': f"저장소 건강도 점수 {repo_data.get('health_score')}점으로 우수합니다.",
                'impact': 'high'
            })
        
        # 코드 품질에서 인사이트
        metrics_data = results['code_metrics']
        coverage = metrics_data.get('test_metrics', {}).get('coverage', {}).get('line_coverage', 0)
        if coverage > 80:
            insights.append({
                'type': 'positive',
                'category': 'code_quality',
                'title': '높은 테스트 커버리지',
                'description': f"테스트 커버리지 {coverage:.1f}%로 높은 품질을 유지하고 있습니다.",
                'impact': 'medium'
            })
        elif coverage < 50:
            insights.append({
                'type': 'concern',
                'category': 'code_quality',
                'title': '낮은 테스트 커버리지',
                'description': f"테스트 커버리지 {coverage:.1f}%로 개선이 필요합니다.",
                'impact': 'high',
                'recommendation': '테스트 작성 우선순위를 높이고 커버리지 목표를 설정하세요.'
            })
        
        # 개선 전략에서 인사이트
        strategy_data = results['improvement_strategy']
        top_opportunity = strategy_data.get('improvement_opportunities', [{}])[0]
        if top_opportunity:
            insights.append({
                'type': 'opportunity',
                'category': 'improvement',
                'title': f'최우선 개선 기회: {top_opportunity.get("title", "")}',
                'description': f"ROI {top_opportunity.get('roi_percentage', 0):.1f}%의 높은 개선 효과가 예상됩니다.",
                'impact': 'high',
                'timeline': f"{top_opportunity.get('estimated_hours', 0)}시간 투자"
            })
        
        return sorted(insights, key=lambda x: 
                     {'high': 3, 'medium': 2, 'low': 1}[x['impact']], 
                     reverse=True)
    
    def _create_executive_summary(self, results: Dict[str, Any], 
                                insights: List[Dict]) -> Dict[str, Any]:
        """경영진 요약 생성"""
        
        repo_data = results['repo_analysis']
        health_data = results['health_evaluation']
        strategy_data = results['improvement_strategy']
        
        return {
            'project_overview': {
                'repository_name': repo_data.get('basic_info', {}).get('name', ''),
                'language': repo_data.get('basic_info', {}).get('language', ''),
                'team_size': len(repo_data.get('contributors', [])),
                'project_age': self._calculate_project_age(repo_data),
                'activity_level': self._assess_activity_level(repo_data)
            },
            'overall_health_score': health_data.get('health_score', {}).get('overall_score', 0),
            'grade': health_data.get('health_score', {}).get('grade', 'N/A'),
            'top_3_insights': insights[:3],
            'improvement_potential': {
                'total_opportunities': len(strategy_data.get('improvement_opportunities', [])),
                'expected_roi': strategy_data.get('strategy_overview', {}).get('expected_roi', 0),
                'implementation_timeline': strategy_data.get('strategy_overview', {}).get('timeline', ''),
                'investment_required': self._calculate_total_investment(strategy_data)
            },
            'risk_level': health_data.get('risk_assessment', {}).get('risk_level', 'medium'),
            'recommendation': self._generate_overall_recommendation(results, insights)
        }
    
    async def _export_results(self, report: Dict[str, Any]):
        """결과를 다양한 형태로 내보내기"""
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        base_filename = f"repo_insights_{timestamp}"
        
        # JSON 내보내기
        if 'json' in self.config.output_format:
            with open(f"{base_filename}.json", 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2, ensure_ascii=False, default=str)
        
        # HTML 대시보드 생성
        if 'html' in self.config.output_format:
            html_content = await self._generate_html_dashboard(report)
            with open(f"{base_filename}.html", 'w', encoding='utf-8') as f:
                f.write(html_content)
        
        # PDF 보고서 생성
        if 'pdf' in self.config.output_format:
            await self._generate_pdf_report(report, f"{base_filename}.pdf")
        
        # Excel 스프레드시트
        if 'excel' in self.config.output_format:
            await self._generate_excel_report(report, f"{base_filename}.xlsx")
    
    async def _generate_html_dashboard(self, report: Dict[str, Any]) -> str:
        """HTML 대시보드 생성"""
        
        # Plotly를 사용한 인터랙티브 차트 생성
        charts_html = self._create_interactive_charts(report['visualization_data'])
        
        # HTML 템플릿
        html_template = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Repository Insights Dashboard</title>
            <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ background: #2c3e50; color: white; padding: 20px; }}
                .summary {{ background: #ecf0f1; padding: 15px; margin: 20px 0; }}
                .insight {{ background: #e8f5e8; padding: 10px; margin: 10px 0; border-left: 4px solid #27ae60; }}
                .concern {{ background: #fdf2e9; padding: 10px; margin: 10px 0; border-left: 4px solid #f39c12; }}
                .chart {{ margin: 20px 0; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Repository Insights Dashboard</h1>
                <p>Analysis Date: {report['metadata']['analysis_date']}</p>
                <p>Repository: {report['metadata']['repository']}</p>
            </div>
            
            <div class="summary">
                <h2>Executive Summary</h2>
                <p><strong>Overall Health Score:</strong> {report['executive_summary']['overall_health_score']}</p>
                <p><strong>Grade:</strong> {report['executive_summary']['grade']}</p>
                <p><strong>Team Size:</strong> {report['executive_summary']['project_overview']['team_size']}</p>
            </div>
            
            <h2>Key Insights</h2>
            {self._format_insights_html(report['key_insights'])}
            
            <h2>Visualizations</h2>
            {charts_html}
            
            <h2>Action Items</h2>
            {self._format_action_items_html(report['action_items'])}
        </body>
        </html>
        """
        
        return html_template
```

### 2. CLI 인터페이스
```python
import click
import asyncio
from pathlib import Path

@click.command()
@click.option('--repo', required=True, help='GitHub repository URL or owner/name')
@click.option('--depth', default='standard', 
              type=click.Choice(['basic', 'standard', 'comprehensive']),
              help='Analysis depth level')
@click.option('--days', default=90, help='Analysis period in days')
@click.option('--output-dir', default='./output', help='Output directory')
@click.option('--format', multiple=True, default=['json', 'html'],
              type=click.Choice(['json', 'html', 'pdf', 'excel']),
              help='Output formats')
@click.option('--config', help='Configuration file path')
@click.option('--verbose', is_flag=True, help='Verbose logging')
def analyze_repository(repo, depth, days, output_dir, format, config, verbose):
    """GitHub 저장소 종합 분석 도구"""
    
    # 설정 로드
    analysis_config = AnalysisConfig(
        repo_url=repo,
        analysis_depth=depth,
        max_analysis_days=days,
        output_format=list(format)
    )
    
    # 출력 디렉토리 생성
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # 오케스트레이터 실행
    orchestrator = RepoInsightsOrchestrator(analysis_config)
    
    try:
        if verbose:
            click.echo("🚀 Starting repository analysis...")
        
        # 비동기 실행
        report = asyncio.run(orchestrator.execute_full_analysis())
        
        if verbose:
            click.echo("✅ Analysis completed successfully!")
            click.echo(f"📊 Health Score: {report['executive_summary']['overall_health_score']}")
            click.echo(f"📁 Results saved to: {output_dir}")
        
        return report
        
    except Exception as e:
        click.echo(f"❌ Analysis failed: {str(e)}", err=True)
        raise click.Abort()

if __name__ == '__main__':
    analyze_repository()
```

### 3. 웹 대시보드 (Streamlit)
```python
import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

def create_web_dashboard():
    """Streamlit 기반 웹 대시보드"""
    
    st.set_page_config(
        page_title="VELOCITY-X Repository Insights",
        page_icon="📊",
        layout="wide"
    )
    
    st.title("🔍 VELOCITY-X Repository Insights Dashboard")
    st.sidebar.title("Analysis Settings")
    
    # 사이드바 - 입력 설정
    repo_url = st.sidebar.text_input("Repository URL", 
                                     placeholder="https://github.com/owner/repo")
    
    analysis_depth = st.sidebar.selectbox("Analysis Depth", 
                                         ["basic", "standard", "comprehensive"])
    
    analysis_days = st.sidebar.slider("Analysis Period (days)", 30, 365, 90)
    
    if st.sidebar.button("🚀 Start Analysis"):
        if repo_url:
            with st.spinner("Analyzing repository... This may take a few minutes."):
                # 분석 실행
                config = AnalysisConfig(
                    repo_url=repo_url,
                    analysis_depth=analysis_depth,
                    max_analysis_days=analysis_days
                )
                
                orchestrator = RepoInsightsOrchestrator(config)
                report = asyncio.run(orchestrator.execute_full_analysis())
                
                # 세션 상태에 저장
                st.session_state.report = report
                st.rerun()
        else:
            st.sidebar.error("Please enter a repository URL")
    
    # 메인 대시보드
    if 'report' in st.session_state:
        display_dashboard(st.session_state.report)

def display_dashboard(report):
    """대시보드 표시"""
    
    # 상단 메트릭
    col1, col2, col3, col4 = st.columns(4)
    
    exec_summary = report['executive_summary']
    
    with col1:
        st.metric("Health Score", 
                 f"{exec_summary['overall_health_score']:.1f}",
                 delta=None)
    
    with col2:
        st.metric("Grade", exec_summary['grade'])
    
    with col3:
        st.metric("Team Size", exec_summary['project_overview']['team_size'])
    
    with col4:
        st.metric("Project Age", exec_summary['project_overview']['project_age'])
    
    # 탭으로 구성
    tab1, tab2, tab3, tab4 = st.tabs(["📊 Overview", "🔍 Analysis", "💡 Insights", "📋 Actions"])
    
    with tab1:
        display_overview_tab(report)
    
    with tab2:
        display_analysis_tab(report)
    
    with tab3:
        display_insights_tab(report)
    
    with tab4:
        display_actions_tab(report)

if __name__ == "__main__":
    create_web_dashboard()
```

## 사용 예시

### CLI 사용법
```bash
# 기본 분석
./temp_hooks/commands/agents/velocity-x-repo-insights-orchestrator/run.sh \
  --repo "microsoft/vscode" \
  --depth standard \
  --days 90

# 종합 분석 (모든 형태 출력)
./temp_hooks/commands/agents/velocity-x-repo-insights-orchestrator/run.sh \
  --repo "facebook/react" \
  --depth comprehensive \
  --format json html pdf excel \
  --output-dir "./analysis_results"
```

### 웹 대시보드 실행
```bash
streamlit run velocity_x_dashboard.py
```

### API 서버 실행
```bash
uvicorn velocity_x_api:app --host 0.0.0.0 --port 8000
```

### 결과 예시
```json
{
  "executive_summary": {
    "overall_health_score": 84.2,
    "grade": "B+",
    "top_3_insights": [
      "높은 커뮤니티 참여도 (312명 기여자)",
      "효율적인 PR 리뷰 프로세스",
      "CI/CD 최적화 기회 (ROI 340%)"
    ],
    "improvement_potential": {
      "total_opportunities": 8,
      "expected_roi": 285.6,
      "timeline": "6개월"
    }
  },
  "key_insights": [
    {
      "type": "positive",
      "title": "우수한 코드 리뷰 문화",
      "impact": "high"
    }
  ],
  "action_items": [
    {
      "priority": "high",
      "title": "CI/CD 파이프라인 최적화",
      "estimated_impact": "개발 속도 40% 향상"
    }
  ]
}
```