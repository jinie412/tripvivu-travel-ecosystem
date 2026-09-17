import { apiClient } from './apiClient';

export interface SessionCfTrainingRunRequest {
  lookback_days?: number;
  upload_r2?: boolean;
  dry_run?: boolean;
}

export interface SessionCfTrainingRunResponse {
  success: boolean;
  run_id: string;
  n_users: number;
  n_items: number;
  n_interactions: number;
  n_explicit: number;
  n_implicit: number;
  overlap_places: number;
  model_type: string;
  global_mean: number;
  n_train: number;
  n_test: number;
  metrics: Record<string, number>;
  artifact_dir: string;
  exported: boolean;
  uploaded_r2: boolean;
  n_artifact_users: number | null;
  n_artifact_items: number | null;
  started_at: string;
  completed_at: string;
  duration_seconds: number;
  error: string | null;
}

export type SessionCfTrainingScheduleFrequency = 'daily' | 'weekly' | 'monthly';

export interface SessionCfTrainingSchedule {
  autoEnabled: boolean;
  frequency: SessionCfTrainingScheduleFrequency;
  runTime: string;
  runDay: string;
  lastRunAt: string | null;
}

export interface UpdateSessionCfTrainingScheduleRequest {
  autoEnabled?: boolean;
  frequency?: SessionCfTrainingScheduleFrequency;
  runTime?: string;
  runDay?: number;
}

export const sessionCfTrainingAPI = {
  runTraining: async (
    request: SessionCfTrainingRunRequest = {},
  ): Promise<SessionCfTrainingRunResponse> => {
    const response = await apiClient.post<SessionCfTrainingRunResponse>(
      '/admin/session-cf-training/run',
      request,
      { timeout: 600_000 },
    );
    return response.data;
  },

  getSchedule: async (): Promise<SessionCfTrainingSchedule> => {
    const response = await apiClient.get<SessionCfTrainingSchedule>(
      '/admin/session-cf-training/schedule',
    );
    return response.data;
  },

  updateSchedule: async (
    request: UpdateSessionCfTrainingScheduleRequest,
  ): Promise<SessionCfTrainingSchedule> => {
    const response = await apiClient.patch<SessionCfTrainingSchedule>(
      '/admin/session-cf-training/schedule',
      request,
    );
    return response.data;
  },
};
