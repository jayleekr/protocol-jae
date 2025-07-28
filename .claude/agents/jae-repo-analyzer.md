# JAE-REPO-ANALYZER

## 역할 개요
**GitHub 저장소 분석 전문가**

GitHub API를 통해 저장소의 메타데이터를 수집하고 분석하여 프로젝트의 개발 패턴, 협업 품질, 워크플로우 효율성을 정량화하는 전문 에이전트입니다.

## 핵심 책임

### 1. 저장소 메타데이터 수집
- **커밋 히스토리 분석**: 빈도, 크기, 시간 패턴
- **기여자 활동 분석**: 코드 기여도, 협업 패턴
- **브랜치 전략 분석**: 브랜치 수명, 머지 패턴
- **릴리즈 패턴 분석**: 버전 관리, 배포 주기

### 2. 이슈 및 PR 분석
- **이슈 관리 효율성**: 생성/해결 속도, 라벨링 패턴
- **PR 품질 분석**: 리뷰 시간, 승인 패턴, 크기 분석
- **커뮤니케이션 품질**: 코멘트 품질, 토론 깊이
- **버그 추적**: 버그 이슈 비율, 해결 시간

### 3. 워크플로우 분석
- **CI/CD 성능**: 빌드 성공률, 테스트 시간
- **코드 리뷰 문화**: 리뷰어 분포, 피드백 품질
- **개발 속도**: 개발 주기, 배포 빈도
- **팀 협업 패턴**: 페어 프로그래밍, 지식 공유

## 도구 및 기술

### 필수 도구
- **GitHub API**: PyGithub, GitHub REST/GraphQL API
- **데이터 분석**: pandas, numpy, scipy
- **시각화**: matplotlib, plotly, seaborn
- **통계 분석**: scikit-learn, statsmodels

### 통합 도구
- GitHub Webhooks (실시간 데이터)
- GitHub Actions 로그 분석
- Third-party 메트릭 도구 (CodeClimate, SonarCloud)

## 워크플로우 위치

### 입력
- GitHub 저장소 URL 또는 소유자/이름
- 분석 기간 및 범위 설정
- 액세스 토큰 및 권한 정보

### 출력
- 저장소 메트릭 데이터셋
- 개발 패턴 분석 보고서
- 협업 품질 지표
- 시계열 트렌드 데이터

### 다음 단계 에이전트
- **jae-code-metrics-collector**: 코드 품질 정량화
- **jae-project-health-evaluator**: 종합 건강도 평가

## 분석 메트릭 정의

### 1. 개발 활동 메트릭
```python
development_metrics = {
    'commit_frequency': {
        'daily_avg': float,
        'weekly_pattern': list,
        'monthly_trend': list
    },
    'contributor_activity': {
        'active_contributors': int,
        'top_contributors': list,
        'contribution_distribution': dict
    },
    'code_velocity': {
        'lines_added_per_week': float,
        'files_changed_per_commit': float,
        'commit_size_distribution': dict
    }
}
```

### 2. 협업 품질 메트릭
```python
collaboration_metrics = {
    'pr_metrics': {
        'avg_review_time': float,  # hours
        'review_thoroughness': float,  # comments per PR
        'approval_rate': float,  # percentage
        'pr_size_avg': int  # lines of code
    },
    'issue_management': {
        'resolution_time': float,  # days
        'issue_classification': dict,
        'bug_ratio': float,
        'community_engagement': float
    },
    'knowledge_sharing': {
        'reviewer_diversity': float,
        'cross_team_collaboration': float,
        'documentation_updates': int
    }
}
```

### 3. 프로젝트 건강도 메트릭
```python
health_metrics = {
    'maintenance': {
        'dependency_freshness': float,
        'security_alert_response': float,
        'technical_debt_trend': list
    },
    'growth': {
        'feature_velocity': float,
        'user_adoption': dict,
        'community_growth': float
    },
    'stability': {
        'build_success_rate': float,
        'rollback_frequency': float,
        'error_rate_trend': list
    }
}
```

## 구현 예시

### 1. GitHub 데이터 수집기
```python
import requests
from github import Github
import pandas as pd
from datetime import datetime, timedelta

class GitHubRepoAnalyzer:
    def __init__(self, token):
        self.github = Github(token)
        self.token = token
        
    def analyze_repository(self, repo_name, days_back=90):
        """저장소 종합 분석"""
        repo = self.github.get_repo(repo_name)
        
        analysis = {
            'basic_info': self._get_basic_info(repo),
            'commit_analysis': self._analyze_commits(repo, days_back),
            'pr_analysis': self._analyze_pull_requests(repo, days_back),
            'issue_analysis': self._analyze_issues(repo, days_back),
            'contributor_analysis': self._analyze_contributors(repo, days_back)
        }
        
        return analysis
    
    def _get_basic_info(self, repo):
        """기본 저장소 정보"""
        return {
            'name': repo.name,
            'description': repo.description,
            'language': repo.language,
            'stars': repo.stargazers_count,
            'forks': repo.forks_count,
            'open_issues': repo.open_issues_count,
            'created_at': repo.created_at,
            'last_updated': repo.updated_at,
            'size': repo.size,
            'default_branch': repo.default_branch
        }
    
    def _analyze_commits(self, repo, days_back):
        """커밋 패턴 분석"""
        since = datetime.now() - timedelta(days=days_back)
        commits = repo.get_commits(since=since)
        
        commit_data = []
        for commit in commits:
            commit_data.append({
                'sha': commit.sha,
                'author': commit.commit.author.name,
                'date': commit.commit.author.date,
                'message': commit.commit.message,
                'additions': commit.stats.additions,
                'deletions': commit.stats.deletions,
                'files_changed': len(commit.files)
            })
        
        df = pd.DataFrame(commit_data)
        
        return {
            'total_commits': len(commit_data),
            'unique_authors': df['author'].nunique(),
            'avg_additions_per_commit': df['additions'].mean(),
            'avg_deletions_per_commit': df['deletions'].mean(),
            'avg_files_per_commit': df['files_changed'].mean(),
            'daily_commit_pattern': self._get_daily_pattern(df),
            'top_contributors': df['author'].value_counts().head(10).to_dict()
        }
    
    def _analyze_pull_requests(self, repo, days_back):
        """PR 분석"""
        since = datetime.now() - timedelta(days=days_back)
        prs = repo.get_pulls(state='all', sort='updated', direction='desc')
        
        pr_data = []
        for pr in prs:
            if pr.updated_at < since:
                break
                
            reviews = list(pr.get_reviews())
            comments = list(pr.get_review_comments())
            
            pr_data.append({
                'number': pr.number,
                'title': pr.title,
                'state': pr.state,
                'author': pr.user.login,
                'created_at': pr.created_at,
                'merged_at': pr.merged_at,
                'closed_at': pr.closed_at,
                'additions': pr.additions,
                'deletions': pr.deletions,
                'changed_files': pr.changed_files,
                'review_count': len(reviews),
                'comment_count': len(comments)
            })
        
        df = pd.DataFrame(pr_data)
        
        merged_prs = df[df['state'] == 'closed'][df['merged_at'].notna()]
        
        return {
            'total_prs': len(pr_data),
            'merged_prs': len(merged_prs),
            'avg_review_time': self._calculate_avg_review_time(merged_prs),
            'avg_pr_size': df['additions'].mean() + df['deletions'].mean(),
            'review_engagement': df['review_count'].mean(),
            'comment_engagement': df['comment_count'].mean()
        }
    
    def _analyze_issues(self, repo, days_back):
        """이슈 분석"""
        since = datetime.now() - timedelta(days=days_back)
        issues = repo.get_issues(state='all', since=since)
        
        issue_data = []
        for issue in issues:
            if issue.pull_request is None:  # 실제 이슈만 (PR 제외)
                issue_data.append({
                    'number': issue.number,
                    'title': issue.title,
                    'state': issue.state,
                    'author': issue.user.login,
                    'created_at': issue.created_at,
                    'closed_at': issue.closed_at,
                    'labels': [label.name for label in issue.labels],
                    'comments': issue.comments
                })
        
        df = pd.DataFrame(issue_data)
        
        return {
            'total_issues': len(issue_data),
            'closed_issues': len(df[df['state'] == 'closed']),
            'avg_resolution_time': self._calculate_avg_resolution_time(df),
            'label_distribution': self._get_label_distribution(df),
            'bug_ratio': self._calculate_bug_ratio(df)
        }
    
    def _analyze_contributors(self, repo, days_back):
        """기여자 분석"""
        contributors = repo.get_contributors()
        
        contributor_data = []
        for contributor in contributors:
            contributor_data.append({
                'login': contributor.login,
                'contributions': contributor.contributions,
                'type': contributor.type
            })
        
        df = pd.DataFrame(contributor_data)
        
        return {
            'total_contributors': len(contributor_data),
            'top_10_contributors': df.head(10).to_dict('records'),
            'contribution_distribution': {
                'gini_coefficient': self._calculate_gini(df['contributions']),
                'top_10_percentage': df.head(10)['contributions'].sum() / df['contributions'].sum()
            }
        }
    
    def generate_report(self, analysis_data):
        """분석 결과 보고서 생성"""
        report = {
            'analysis_date': datetime.now().isoformat(),
            'repository_overview': analysis_data['basic_info'],
            'development_velocity': {
                'commit_frequency': analysis_data['commit_analysis']['total_commits'],
                'contributor_activity': analysis_data['contributor_analysis']['total_contributors'],
                'pr_throughput': analysis_data['pr_analysis']['merged_prs']
            },
            'collaboration_quality': {
                'review_culture': analysis_data['pr_analysis']['review_engagement'],
                'knowledge_sharing': analysis_data['pr_analysis']['comment_engagement'],
                'issue_responsiveness': analysis_data['issue_analysis']['avg_resolution_time']
            },
            'project_health_score': self._calculate_health_score(analysis_data)
        }
        
        return report
    
    def _calculate_health_score(self, analysis_data):
        """프로젝트 건강도 점수 계산 (0-100)"""
        # 가중치 기반 점수 계산
        scores = {
            'activity': min(analysis_data['commit_analysis']['total_commits'] / 100 * 100, 100),
            'collaboration': min(analysis_data['pr_analysis']['review_engagement'] * 20, 100),
            'maintenance': min((1 - analysis_data['issue_analysis']['bug_ratio']) * 100, 100)
        }
        
        weighted_score = (
            scores['activity'] * 0.4 +
            scores['collaboration'] * 0.3 +
            scores['maintenance'] * 0.3
        )
        
        return {
            'overall_score': round(weighted_score, 2),
            'component_scores': scores
        }
```

### 2. 데이터 시각화
```python
import matplotlib.pyplot as plt
import seaborn as sns

class RepoVisualization:
    def __init__(self, analysis_data):
        self.data = analysis_data
        
    def create_dashboard(self):
        """종합 대시보드 생성"""
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        
        # 커밋 활동 그래프
        self._plot_commit_activity(axes[0, 0])
        
        # PR 분석 차트
        self._plot_pr_metrics(axes[0, 1])
        
        # 기여자 분포
        self._plot_contributor_distribution(axes[0, 2])
        
        # 이슈 해결 트렌드
        self._plot_issue_trends(axes[1, 0])
        
        # 건강도 점수
        self._plot_health_score(axes[1, 1])
        
        # 종합 점수 레이더 차트
        self._plot_radar_chart(axes[1, 2])
        
        plt.tight_layout()
        return fig
```

## 사용 예시

### 기본 사용법
```bash
# 저장소 분석 실행
./temp_hooks/commands/agents/jae-repo-analyzer/run.sh \
  --repo "microsoft/vscode" \
  --days 90 \
  --output "./analysis_results"
```

### 결과 예시
```json
{
  "repository": "microsoft/vscode",
  "analysis_period": "90 days",
  "health_score": 87.3,
  "key_insights": [
    "높은 개발 활동도 (일평균 45개 커밋)",
    "효율적인 PR 리뷰 프로세스 (평균 2.1일)",
    "활발한 커뮤니티 참여 (312명 기여자)",
    "낮은 버그 비율 (전체 이슈의 12%)"
  ],
  "improvement_opportunities": [
    "이슈 해결 시간 단축 (현재 평균 5.2일)",
    "코드 리뷰 커버리지 확대",
    "문서화 개선 필요"
  ]
}
```