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
  return `${d.toLocaleDateString('vi-VN')} ${d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}`;
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

  getHistory: async (limit = 20): Promise<PipelineHistoryResponse> => {
    const response = await apiClient.get<PipelineHistoryResponse>(
      '/admin/algorithm-pipeline/history',
      { params: { limit } },
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
};
