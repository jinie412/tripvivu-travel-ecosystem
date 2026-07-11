import { apiClient } from './apiClient';

export interface PipelineRunRequest {
  limit?: number;
  no_pretrained?: boolean;
  topic_other_threshold?: number;
  candidate_mode?: 'all' | 'topk';
  promotion_mode?: 'representative' | 'all';
  dry_run?: boolean;
}

export interface PipelineRunResponse {
  success: boolean;
  run_id: string;
  total_reviews: number;
  contents_processed: number;
  conflicts_detected: number;
  long_term_summaries: number;
  hidden_reviews: number;
  output_dir: string;
  started_at: string;
  completed_at: string;
  duration_seconds: number;
  embedding_model_active: boolean;
  sentiment_model_active: boolean;
  zeroshot_model_active: boolean;
  phobert_model_active: boolean;
  error: string | null;
}

export interface PipelineHistoryItem {
  run_id: string;
  algorithm_id?: string | null;
  algorithm_name?: string;
  status?: string;
  action?: string;
  details?: Record<string, unknown> | null;
  started_at: string;
  completed_at: string;
  total_reviews: number;
  contents_processed: number;
  conflicts_detected: number;
  long_term_summaries: number;
  duration_seconds: number;
  success: boolean;
  error: string | null;
  created_at?: string;
}

export interface PipelineHistoryResponse {
  history: PipelineHistoryItem[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface PipelineHistoryParams {
  page?: number;
  pageSize?: number;
  limit?: number;
  algorithm?: string;
  date?: string;
}

export type ReviewFilterScheduleFrequency = 'daily' | 'weekly' | 'monthly';

export interface ReviewFilterSchedule {
  autoEnabled: boolean;
  frequency: ReviewFilterScheduleFrequency;
  runTime: string;
  runDay: string;
  lastRunAt: string | null;
}

export interface UpdateReviewFilterScheduleRequest {
  autoEnabled?: boolean;
  frequency?: ReviewFilterScheduleFrequency;
  runTime?: string;
  runDay?: number;
}

export interface RecommenderRetrainRun {
  id: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  triggerType: 'manual' | 'scheduled';
  triggeredBy: string | null;
  startedAt: string | null;
  completedAt: string | null;
  durationSeconds: number | null;
  errorMessage: string | null;
  metrics: {
    progress?: number;
    current_step?: string;
    rating_only_test_rmse?: number;
    test_rmse?: number;
    hybrid_log_coverage_test?: number;
    log_tail?: string[];
  } | null;
  createdAt: string;
}

export interface RecommenderRetrainStatus {
  currentRun: RecommenderRetrainRun | null;
  latestRun: RecommenderRetrainRun | null;
}

const formatDuration = (seconds: number): string => {
  if (seconds < 60) return `${Math.round(seconds)}s`;
  const mins = Math.floor(seconds / 60);
  const secs = Math.round(seconds % 60);
  if (mins < 60) return secs > 0 ? `${mins}m ${secs}s` : `${mins} phút`;
  const hours = Math.floor(mins / 60);
  const remainMins = mins % 60;
  return remainMins > 0 ? `${hours}h ${remainMins} phút` : `${hours}h`;
};

const formatDateTime = (iso: string): string => {
  const d = new Date(iso);
  if (isNaN(d.getTime())) return iso;
  return `${d.toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })} ${d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Ho_Chi_Minh' })}`;
};

export const formatPipelineDuration = formatDuration;
export const formatPipelineDateTime = formatDateTime;

export const algorithmPipelineAPI = {
  runPipeline: async (request: PipelineRunRequest = {}): Promise<PipelineRunResponse> => {
    const response = await apiClient.post<PipelineRunResponse>(
      '/admin/algorithm-pipeline/run',
      request,
      { timeout: 600_000 },
    );
    return response.data;
  },

  getHistory: async (
    params: PipelineHistoryParams | number = {},
  ): Promise<PipelineHistoryResponse> => {
    const queryParams =
      typeof params === 'number' ? { limit: params } : params;
    const response = await apiClient.get<PipelineHistoryResponse>(
      '/admin/algorithm-pipeline/history',
      { params: queryParams },
    );
    return response.data;
  },

  getReviewFilterSchedule: async (): Promise<ReviewFilterSchedule> => {
    const response = await apiClient.get<ReviewFilterSchedule>(
      '/admin/algorithm-pipeline/review-filter/schedule',
    );
    return response.data;
  },

  updateReviewFilterSchedule: async (
    request: UpdateReviewFilterScheduleRequest,
  ): Promise<ReviewFilterSchedule> => {
    const response = await apiClient.patch<ReviewFilterSchedule>(
      '/admin/algorithm-pipeline/review-filter/schedule',
      request,
    );
    return response.data;
  },

  runRecommenderRetrain: async (): Promise<RecommenderRetrainStatus> => {
    const response = await apiClient.post<RecommenderRetrainStatus>(
      '/admin/algorithm-pipeline/recommender-retrain/run',
      {},
    );
    return response.data;
  },

  getRecommenderRetrainStatus: async (): Promise<RecommenderRetrainStatus> => {
    const response = await apiClient.get<RecommenderRetrainStatus>(
      '/admin/algorithm-pipeline/recommender-retrain/status',
    );
    return response.data;
  },

  getRecommenderRetrainRun: async (id: string): Promise<RecommenderRetrainRun> => {
    const response = await apiClient.get<RecommenderRetrainRun>(
      `/admin/algorithm-pipeline/recommender-retrain/runs/${id}`,
    );
    return response.data;
  },

  getRecommenderRetrainSchedule: async (): Promise<ReviewFilterSchedule> => {
    const response = await apiClient.get<ReviewFilterSchedule>(
      '/admin/algorithm-pipeline/recommender-retrain/schedule',
    );
    return response.data;
  },

  updateRecommenderRetrainSchedule: async (
    request: UpdateReviewFilterScheduleRequest,
  ): Promise<ReviewFilterSchedule> => {
    const response = await apiClient.patch<ReviewFilterSchedule>(
      '/admin/algorithm-pipeline/recommender-retrain/schedule',
      request,
    );
    return response.data;
  },
};
