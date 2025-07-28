#!/usr/bin/env python3
"""
GitHub API 통합 및 공통 라이브러리
VELOCITY-X GitHub 분석 에이전트들의 공통 기능 제공
"""

import os
import requests
import json
import time
from typing import Dict, List, Any, Optional, Union
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
import pandas as pd
from github import Github, RateLimitExceededException
import base64

@dataclass
class GitHubConfig:
    """GitHub API 설정"""
    token: str
    base_url: str = "https://api.github.com"
    timeout: int = 30
    max_retries: int = 3
    rate_limit_buffer: int = 100  # 남은 요청 수 버퍼

class GitHubAPIClient:
    """GitHub API 클라이언트"""
    
    def __init__(self, config: GitHubConfig):
        self.config = config
        self.github = Github(config.token)
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'token {config.token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'VELOCITY-X-GitHub-Analyzer/1.0'
        })
        
    def get_rate_limit_status(self) -> Dict[str, Any]:
        """API 사용량 확인"""
        try:
            rate_limit = self.github.get_rate_limit()
            return {
                'core': {
                    'limit': rate_limit.core.limit,
                    'remaining': rate_limit.core.remaining,
                    'reset': rate_limit.core.reset.timestamp(),
                    'used': rate_limit.core.limit - rate_limit.core.remaining
                },
                'search': {
                    'limit': rate_limit.search.limit,
                    'remaining': rate_limit.search.remaining,
                    'reset': rate_limit.search.reset.timestamp(),
                    'used': rate_limit.search.limit - rate_limit.search.remaining
                }
            }
        except Exception as e:
            print(f"Error getting rate limit: {e}")
            return {}
    
    def wait_for_rate_limit_reset(self, api_type: str = 'core'):
        """Rate limit 리셋 대기"""
        rate_limit_info = self.get_rate_limit_status()
        
        if rate_limit_info and api_type in rate_limit_info:
            remaining = rate_limit_info[api_type]['remaining']
            reset_time = rate_limit_info[api_type]['reset']
            
            if remaining < self.config.rate_limit_buffer:
                wait_time = max(0, reset_time - time.time()) + 60  # 1분 버퍼
                print(f"Rate limit approaching. Waiting {wait_time:.0f} seconds...")
                time.sleep(wait_time)
    
    def make_request(self, url: str, params: Dict = None, 
                    retry_count: int = 0) -> Optional[Dict]:
        """GitHub API 요청 (Rate limit 및 재시도 처리)"""
        
        self.wait_for_rate_limit_reset()
        
        try:
            response = self.session.get(
                url, 
                params=params, 
                timeout=self.config.timeout
            )
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 403:
                # Rate limit exceeded
                self.wait_for_rate_limit_reset()
                if retry_count < self.config.max_retries:
                    return self.make_request(url, params, retry_count + 1)
            elif response.status_code == 404:
                print(f"Resource not found: {url}")
                return None
            else:
                print(f"API request failed: {response.status_code} - {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"Request exception: {e}")
            if retry_count < self.config.max_retries:
                time.sleep(2 ** retry_count)  # Exponential backoff
                return self.make_request(url, params, retry_count + 1)
        
        return None

class RepositoryAnalyzer:
    """저장소 분석을 위한 공통 기능"""
    
    def __init__(self, github_client: GitHubAPIClient):
        self.client = github_client
        self.github = github_client.github
    
    def get_repository_info(self, repo_name: str) -> Optional[Dict[str, Any]]:
        """기본 저장소 정보 조회"""
        try:
            repo = self.github.get_repo(repo_name)
            
            return {
                'id': repo.id,
                'name': repo.name,
                'full_name': repo.full_name,
                'description': repo.description,
                'language': repo.language,
                'size': repo.size,
                'stars': repo.stargazers_count,
                'watchers': repo.watchers_count,
                'forks': repo.forks_count,
                'open_issues': repo.open_issues_count,
                'created_at': repo.created_at.isoformat(),
                'updated_at': repo.updated_at.isoformat(),
                'pushed_at': repo.pushed_at.isoformat() if repo.pushed_at else None,
                'clone_url': repo.clone_url,
                'ssh_url': repo.ssh_url,
                'default_branch': repo.default_branch,
                'archived': repo.archived,
                'disabled': repo.disabled,
                'private': repo.private,
                'fork': repo.fork,
                'has_issues': repo.has_issues,
                'has_projects': repo.has_projects,
                'has_wiki': repo.has_wiki,
                'license': repo.license.name if repo.license else None,
                'topics': repo.get_topics(),
                'visibility': getattr(repo, 'visibility', 'public')
            }
            
        except Exception as e:
            print(f"Error getting repository info: {e}")
            return None
    
    def get_commit_activity(self, repo_name: str, 
                           since: datetime = None, 
                           until: datetime = None) -> List[Dict[str, Any]]:
        """커밋 활동 분석"""
        try:
            repo = self.github.get_repo(repo_name)
            
            # 기본값 설정
            if since is None:
                since = datetime.now() - timedelta(days=90)
            if until is None:
                until = datetime.now()
            
            commits = repo.get_commits(since=since, until=until)
            
            commit_data = []
            for commit in commits:
                try:
                    commit_info = {
                        'sha': commit.sha,
                        'author': {
                            'name': commit.commit.author.name,
                            'email': commit.commit.author.email,
                            'login': commit.author.login if commit.author else None
                        },
                        'committer': {
                            'name': commit.commit.committer.name,
                            'email': commit.commit.committer.email,
                            'login': commit.committer.login if commit.committer else None
                        },
                        'date': commit.commit.author.date.isoformat(),
                        'message': commit.commit.message,
                        'stats': {
                            'additions': commit.stats.additions,
                            'deletions': commit.stats.deletions,
                            'total': commit.stats.total
                        },
                        'files_changed': len(commit.files),
                        'parents_count': len(commit.parents),
                        'verified': commit.commit.verification.verified if commit.commit.verification else False
                    }
                    commit_data.append(commit_info)
                    
                except Exception as e:
                    print(f"Error processing commit {commit.sha}: {e}")
                    continue
            
            return commit_data
            
        except Exception as e:
            print(f"Error getting commit activity: {e}")
            return []
    
    def get_pull_requests_analysis(self, repo_name: str, 
                                  state: str = 'all',
                                  since: datetime = None) -> List[Dict[str, Any]]:
        """Pull Request 분석"""
        try:
            repo = self.github.get_repo(repo_name)
            
            if since is None:
                since = datetime.now() - timedelta(days=90)
            
            # PyGithub는 since 파라미터를 직접 지원하지 않으므로 필터링 필요
            prs = repo.get_pulls(state=state, sort='updated', direction='desc')
            
            pr_data = []
            for pr in prs:
                try:
                    # since 날짜 이전 PR은 건너뛰기
                    if pr.updated_at < since:
                        break
                    
                    # 리뷰 정보 수집
                    reviews = list(pr.get_reviews())
                    review_comments = list(pr.get_review_comments())
                    issue_comments = list(pr.get_issue_comments())
                    
                    # 리뷰어 정보
                    reviewers = set()
                    for review in reviews:
                        if review.user:
                            reviewers.add(review.user.login)
                    
                    pr_info = {
                        'number': pr.number,
                        'title': pr.title,
                        'body': pr.body,
                        'state': pr.state,
                        'created_at': pr.created_at.isoformat(),
                        'updated_at': pr.updated_at.isoformat(),
                        'closed_at': pr.closed_at.isoformat() if pr.closed_at else None,
                        'merged_at': pr.merged_at.isoformat() if pr.merged_at else None,
                        'author': {
                            'login': pr.user.login,
                            'type': pr.user.type
                        },
                        'assignees': [a.login for a in pr.assignees],
                        'labels': [label.name for label in pr.labels],
                        'milestone': pr.milestone.title if pr.milestone else None,
                        'changes': {
                            'additions': pr.additions,
                            'deletions': pr.deletions,
                            'changed_files': pr.changed_files
                        },
                        'reviews': {
                            'total_reviews': len(reviews),
                            'unique_reviewers': len(reviewers),
                            'reviewers_list': list(reviewers),
                            'review_comments': len(review_comments),
                            'issue_comments': len(issue_comments)
                        },
                        'merge_info': {
                            'mergeable': pr.mergeable,
                            'merged': pr.merged,
                            'merge_commit_sha': pr.merge_commit_sha,
                            'merged_by': pr.merged_by.login if pr.merged_by else None
                        },
                        'head_branch': pr.head.ref,
                        'base_branch': pr.base.ref,
                        'draft': pr.draft if hasattr(pr, 'draft') else False
                    }
                    
                    pr_data.append(pr_info)
                    
                except Exception as e:
                    print(f"Error processing PR #{pr.number}: {e}")
                    continue
            
            return pr_data
            
        except Exception as e:
            print(f"Error getting pull requests: {e}")
            return []
    
    def get_issues_analysis(self, repo_name: str, 
                           state: str = 'all',
                           since: datetime = None) -> List[Dict[str, Any]]:
        """이슈 분석"""
        try:
            repo = self.github.get_repo(repo_name)
            
            if since is None:
                since = datetime.now() - timedelta(days=90)
            
            issues = repo.get_issues(state=state, since=since)
            
            issue_data = []
            for issue in issues:
                try:
                    # Pull Request는 제외 (GitHub API에서 이슈로 분류됨)
                    if issue.pull_request:
                        continue
                    
                    issue_info = {
                        'number': issue.number,
                        'title': issue.title,
                        'body': issue.body,
                        'state': issue.state,
                        'created_at': issue.created_at.isoformat(),
                        'updated_at': issue.updated_at.isoformat(),
                        'closed_at': issue.closed_at.isoformat() if issue.closed_at else None,
                        'author': {
                            'login': issue.user.login,
                            'type': issue.user.type
                        },
                        'assignees': [a.login for a in issue.assignees],
                        'labels': [label.name for label in issue.labels],
                        'milestone': issue.milestone.title if issue.milestone else None,
                        'comments_count': issue.comments,
                        'locked': issue.locked,
                        'reactions': {
                            '+1': issue.get_reactions().get_page(0)[0].content if issue.get_reactions().totalCount > 0 else 0
                        } if hasattr(issue, 'get_reactions') else {}
                    }
                    
                    issue_data.append(issue_info)
                    
                except Exception as e:
                    print(f"Error processing issue #{issue.number}: {e}")
                    continue
            
            return issue_data
            
        except Exception as e:
            print(f"Error getting issues: {e}")
            return []
    
    def get_contributors_analysis(self, repo_name: str) -> List[Dict[str, Any]]:
        """기여자 분석"""
        try:
            repo = self.github.get_repo(repo_name)
            contributors = repo.get_contributors()
            
            contributor_data = []
            for contributor in contributors:
                try:
                    contributor_info = {
                        'login': contributor.login,
                        'id': contributor.id,
                        'type': contributor.type,
                        'contributions': contributor.contributions,
                        'profile': {
                            'name': contributor.name,
                            'company': contributor.company,
                            'location': contributor.location,
                            'email': contributor.email,
                            'bio': contributor.bio,
                            'public_repos': contributor.public_repos,
                            'followers': contributor.followers,
                            'following': contributor.following,
                            'created_at': contributor.created_at.isoformat() if contributor.created_at else None
                        } if contributor.type == 'User' else {}
                    }
                    
                    contributor_data.append(contributor_info)
                    
                except Exception as e:
                    print(f"Error processing contributor {contributor.login}: {e}")
                    continue
            
            return contributor_data
            
        except Exception as e:
            print(f"Error getting contributors: {e}")
            return []
    
    def get_release_analysis(self, repo_name: str) -> List[Dict[str, Any]]:
        """릴리즈 분석"""
        try:
            repo = self.github.get_repo(repo_name)
            releases = repo.get_releases()
            
            release_data = []
            for release in releases:
                try:
                    release_info = {
                        'id': release.id,
                        'tag_name': release.tag_name,
                        'name': release.title,
                        'body': release.body,
                        'draft': release.draft,
                        'prerelease': release.prerelease,
                        'created_at': release.created_at.isoformat(),
                        'published_at': release.published_at.isoformat() if release.published_at else None,
                        'author': {
                            'login': release.author.login,
                            'type': release.author.type
                        } if release.author else None,
                        'assets': [
                            {
                                'name': asset.name,
                                'size': asset.size,
                                'download_count': asset.download_count,
                                'content_type': asset.content_type
                            }
                            for asset in release.get_assets()
                        ],
                        'tarball_url': release.tarball_url,
                        'zipball_url': release.zipball_url
                    }
                    
                    release_data.append(release_info)
                    
                except Exception as e:
                    print(f"Error processing release {release.tag_name}: {e}")
                    continue
            
            return release_data
            
        except Exception as e:
            print(f"Error getting releases: {e}")
            return []
    
    def get_code_frequency(self, repo_name: str) -> Dict[str, Any]:
        """코드 빈도 통계"""
        try:
            url = f"{self.client.config.base_url}/repos/{repo_name}/stats/code_frequency"
            data = self.client.make_request(url)
            
            if data:
                weekly_stats = []
                for week_data in data:
                    weekly_stats.append({
                        'week': datetime.fromtimestamp(week_data[0]).isoformat(),
                        'additions': week_data[1],
                        'deletions': abs(week_data[2])  # 삭제는 음수로 오므로 절댓값
                    })
                
                return {
                    'weekly_stats': weekly_stats,
                    'total_weeks': len(weekly_stats)
                }
            
            return {}
            
        except Exception as e:
            print(f"Error getting code frequency: {e}")
            return {}
    
    def get_languages(self, repo_name: str) -> Dict[str, Any]:
        """언어 통계"""
        try:
            repo = self.github.get_repo(repo_name)
            languages = repo.get_languages()
            
            total_bytes = sum(languages.values())
            
            language_stats = {}
            for language, bytes_count in languages.items():
                percentage = (bytes_count / total_bytes * 100) if total_bytes > 0 else 0
                language_stats[language] = {
                    'bytes': bytes_count,
                    'percentage': round(percentage, 2)
                }
            
            return {
                'languages': language_stats,
                'total_bytes': total_bytes,
                'primary_language': max(languages.items(), key=lambda x: x[1])[0] if languages else None
            }
            
        except Exception as e:
            print(f"Error getting languages: {e}")
            return {}

class DataProcessor:
    """데이터 처리 및 분석을 위한 유틸리티"""
    
    @staticmethod
    def calculate_commit_metrics(commits: List[Dict[str, Any]]) -> Dict[str, Any]:
        """커밋 메트릭 계산"""
        if not commits:
            return {}
        
        df = pd.DataFrame(commits)
        df['date'] = pd.to_datetime(df['date'])
        
        # 기본 통계
        total_commits = len(commits)
        unique_authors = df['author'].apply(lambda x: x['login'] if x.get('login') else x['name']).nunique()
        
        # 시간별 분포
        df['hour'] = df['date'].dt.hour
        df['day_of_week'] = df['date'].dt.day_name()
        
        # 크기 분포
        total_additions = df['stats'].apply(lambda x: x['additions']).sum()
        total_deletions = df['stats'].apply(lambda x: x['deletions']).sum()
        avg_files_changed = df['files_changed'].mean()
        
        # 작성자 기여도
        author_contributions = df.groupby(df['author'].apply(lambda x: x['login'] if x.get('login') else x['name'])).size().to_dict()
        
        return {
            'total_commits': total_commits,
            'unique_authors': unique_authors,
            'total_additions': total_additions,
            'total_deletions': total_deletions,
            'avg_files_changed': round(avg_files_changed, 2),
            'commits_per_day': df['date'].dt.date.value_counts().to_dict(),
            'commits_by_hour': df['hour'].value_counts().to_dict(),
            'commits_by_day_of_week': df['day_of_week'].value_counts().to_dict(),
            'author_contributions': author_contributions,
            'date_range': {
                'start': df['date'].min().isoformat(),
                'end': df['date'].max().isoformat()
            }
        }
    
    @staticmethod
    def calculate_pr_metrics(prs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Pull Request 메트릭 계산"""
        if not prs:
            return {}
        
        df = pd.DataFrame(prs)
        df['created_at'] = pd.to_datetime(df['created_at'])
        df['updated_at'] = pd.to_datetime(df['updated_at'])
        
        # 상태별 분포
        state_distribution = df['state'].value_counts().to_dict()
        
        # 머지된 PR 분석
        merged_prs = df[df['merged_at'].notna()].copy()
        if not merged_prs.empty:
            merged_prs['merged_at'] = pd.to_datetime(merged_prs['merged_at'])
            merged_prs['time_to_merge'] = (merged_prs['merged_at'] - merged_prs['created_at']).dt.total_seconds() / 3600  # hours
            avg_merge_time = merged_prs['time_to_merge'].mean()
        else:
            avg_merge_time = 0
        
        # 리뷰 분석
        review_stats = df['reviews'].apply(pd.Series)
        avg_reviews_per_pr = review_stats['total_reviews'].mean()
        avg_reviewers_per_pr = review_stats['unique_reviewers'].mean()
        
        # 크기 분석
        size_stats = df['changes'].apply(pd.Series)
        avg_additions = size_stats['additions'].mean()
        avg_deletions = size_stats['deletions'].mean()
        avg_files_changed = size_stats['changed_files'].mean()
        
        return {
            'total_prs': len(prs),
            'state_distribution': state_distribution,
            'merged_count': len(merged_prs),
            'merge_rate': len(merged_prs) / len(df) * 100 if len(df) > 0 else 0,
            'avg_merge_time_hours': round(avg_merge_time, 2),
            'avg_reviews_per_pr': round(avg_reviews_per_pr, 2),
            'avg_reviewers_per_pr': round(avg_reviewers_per_pr, 2),
            'avg_additions': round(avg_additions, 2),
            'avg_deletions': round(avg_deletions, 2),
            'avg_files_changed': round(avg_files_changed, 2),
            'draft_ratio': df['draft'].sum() / len(df) * 100 if 'draft' in df.columns else 0
        }
    
    @staticmethod
    def calculate_issue_metrics(issues: List[Dict[str, Any]]) -> Dict[str, Any]:
        """이슈 메트릭 계산"""
        if not issues:
            return {}
        
        df = pd.DataFrame(issues)
        df['created_at'] = pd.to_datetime(df['created_at'])
        df['updated_at'] = pd.to_datetime(df['updated_at'])
        
        # 상태별 분포
        state_distribution = df['state'].value_counts().to_dict()
        
        # 해결 시간 분석
        closed_issues = df[df['closed_at'].notna()].copy()
        if not closed_issues.empty:
            closed_issues['closed_at'] = pd.to_datetime(closed_issues['closed_at'])
            closed_issues['resolution_time'] = (closed_issues['closed_at'] - closed_issues['created_at']).dt.total_seconds() / 3600  # hours
            avg_resolution_time = closed_issues['resolution_time'].mean()
        else:
            avg_resolution_time = 0
        
        # 라벨 분석
        all_labels = []
        for issue in issues:
            all_labels.extend(issue['labels'])
        label_distribution = pd.Series(all_labels).value_counts().to_dict()
        
        # 버그 비율 계산 (bug, defect 등의 라벨 기준)
        bug_keywords = ['bug', 'defect', 'error', 'issue', 'problem']
        bug_count = sum(1 for issue in issues if any(keyword in ' '.join(issue['labels']).lower() for keyword in bug_keywords))
        bug_ratio = bug_count / len(issues) * 100 if issues else 0
        
        return {
            'total_issues': len(issues),
            'state_distribution': state_distribution,
            'closed_count': len(closed_issues),
            'closure_rate': len(closed_issues) / len(df) * 100 if len(df) > 0 else 0,
            'avg_resolution_time_hours': round(avg_resolution_time, 2),
            'avg_comments_per_issue': df['comments_count'].mean(),
            'label_distribution': label_distribution,
            'bug_count': bug_count,
            'bug_ratio': round(bug_ratio, 2)
        }
    
    @staticmethod
    def save_analysis_results(data: Dict[str, Any], output_path: str, format: str = 'json'):
        """분석 결과 저장"""
        try:
            if format.lower() == 'json':
                with open(output_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False, default=str)
            elif format.lower() == 'csv':
                # DataFrame으로 변환 가능한 데이터만 CSV로 저장
                for key, value in data.items():
                    if isinstance(value, list) and value:
                        df = pd.DataFrame(value)
                        csv_path = output_path.replace('.csv', f'_{key}.csv')
                        df.to_csv(csv_path, index=False, encoding='utf-8')
            
            print(f"Analysis results saved to: {output_path}")
            
        except Exception as e:
            print(f"Error saving results: {e}")

def create_github_client() -> GitHubAPIClient:
    """GitHub 클라이언트 생성"""
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        raise ValueError("GITHUB_TOKEN environment variable is required")
    
    config = GitHubConfig(token=token)
    return GitHubAPIClient(config)

def main():
    """테스트 및 예제 실행"""
    try:
        # GitHub 클라이언트 생성
        client = create_github_client()
        analyzer = RepositoryAnalyzer(client)
        
        # 테스트 저장소
        test_repo = "microsoft/vscode"
        
        print(f"Analyzing repository: {test_repo}")
        
        # 기본 정보
        repo_info = analyzer.get_repository_info(test_repo)
        print(f"Repository info: {repo_info['name']} - {repo_info['language']}")
        
        # 커밋 분석 (최근 30일)
        since_date = datetime.now() - timedelta(days=30)
        commits = analyzer.get_commit_activity(test_repo, since=since_date)
        commit_metrics = DataProcessor.calculate_commit_metrics(commits)
        print(f"Commits in last 30 days: {commit_metrics.get('total_commits', 0)}")
        
        # 결과 저장
        analysis_results = {
            'repository_info': repo_info,
            'commit_metrics': commit_metrics,
            'analysis_date': datetime.now().isoformat()
        }
        
        DataProcessor.save_analysis_results(
            analysis_results, 
            f"{test_repo.replace('/', '_')}_analysis.json"
        )
        
    except Exception as e:
        print(f"Error in main: {e}")

if __name__ == "__main__":
    main()