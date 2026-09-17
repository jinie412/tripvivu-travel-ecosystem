import { apiClient } from './apiClient';

export interface PrepareDatasetResponse {
  // null khi skipped=true (khong tao training_runs moi) -- xem AlgorithmTrainingService.prepareDataset.
  trainingRunId: string | null;
  trainingDatasetId: string;
  r2Prefix: string;
  rowCounts: Record<string, number>;
  dateRangeStart: string | null;
  dateRangeEnd: string | null;
  // true neu khong co interaction moi ke tu lan export gan nhat -- server tra ve dataset cu thay
  // vi export lai, xem skipReason de biet ly do.
  skipped?: boolean;
  skipReason?: string;
}

export interface PrepareDatasetRequest {
  // Bo qua change-detection, luon export lai du khong phat hien thay doi.
  force?: boolean;
}

export interface RunFullTrainingRequest {
  trainingDatasetId?: string;
  isDemoMode?: boolean;
  // Mac dinh false (server-side) -- Yelp khong duoc upload len R2, chi bat true neu that su
  // muon pretrain lai tu dau qua Modal.
  includeYelp?: boolean;
}

export interface RunFullTrainingResponse {
  trainingRunId: string;
  status: string;
  modalCallId: string | null;
}

export type TrainingRunStatus = 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';

export interface TrainingRun {
  id: string;
  runType: 'data_export' | 'training' | 'promotion';
  status: TrainingRunStatus;
  triggerType: 'manual' | 'schedule';
  startedAt: string | null;
  completedAt: string | null;
  durationSeconds: number | null;
  errorMessage: string | null;
  metrics: Record<string, unknown> | null;
  createdAt: string;
}

export type ModelVersionStatus = 'candidate' | 'active' | 'archived' | 'failed';

export interface ModelVersion {
  id: string;
  versionTag: string;
  status: ModelVersionStatus;
  metrics: Record<string, number> | null;
  trainedAt: string | null;
  promotedAt: string | null;
  createdAt: string;
}

export type AlgorithmTrainingScheduleFrequency = 'daily' | 'weekly' | 'monthly';

export interface AlgorithmTrainingSchedule {
  autoEnabled: boolean;
  frequency: AlgorithmTrainingScheduleFrequency;
  runTime: string;
  runDay: string;
  lastRunAt: string | null;
}

export interface UpdateAlgorithmTrainingScheduleRequest {
  autoEnabled?: boolean;
  frequency?: AlgorithmTrainingScheduleFrequency;
  runTime?: string;
  runDay?: number;
}

// Chi ho tro 'two-tower' o lan nay (docs/trigger) — them 'hybrid-recommender' sau khi backend mo rong.
export type TrainableAlgorithm = 'two-tower';

export const algorithmTrainingAPI = {
  prepareDataset: async (
    algorithm: TrainableAlgorithm,
    request: PrepareDatasetRequest = {},
  ): Promise<PrepareDatasetResponse> => {
    const response = await apiClient.post<PrepareDatasetResponse>(
      `/admin/algorithm-training/${algorithm}/prepare-dataset`,
      request,
      { timeout: 600_000 },
    );
    return response.data;
  },

  runFullTraining: async (
    algorithm: TrainableAlgorithm,
    request: RunFullTrainingRequest = {},
  ): Promise<RunFullTrainingResponse> => {
    const response = await apiClient.post<RunFullTrainingResponse>(
      `/admin/algorithm-training/${algorithm}/run-full-training`,
      request,
    );
    return response.data;
  },

  getRuns: async (algorithm: TrainableAlgorithm, limit = 20): Promise<TrainingRun[]> => {
    const response = await apiClient.get<TrainingRun[]>(
      `/admin/algorithm-training/${algorithm}/runs`,
      { params: { limit } },
    );
    return response.data;
  },

  getVersions: async (algorithm: TrainableAlgorithm): Promise<ModelVersion[]> => {
    const response = await apiClient.get<ModelVersion[]>(
      `/admin/algorithm-training/${algorithm}/versions`,
    );
    return response.data;
  },

  promoteVersion: async (
    algorithm: TrainableAlgorithm,
    versionId: string,
  ): Promise<ModelVersion> => {
    const response = await apiClient.post<ModelVersion>(
      `/admin/algorithm-training/${algorithm}/versions/${versionId}/promote`,
      {},
    );
    return response.data;
  },

  getSchedule: async (algorithm: TrainableAlgorithm): Promise<AlgorithmTrainingSchedule> => {
    const response = await apiClient.get<AlgorithmTrainingSchedule>(
      `/admin/algorithm-training/${algorithm}/schedule`,
    );
    return response.data;
  },

  updateSchedule: async (
    algorithm: TrainableAlgorithm,
    request: UpdateAlgorithmTrainingScheduleRequest,
  ): Promise<AlgorithmTrainingSchedule> => {
    const response = await apiClient.patch<AlgorithmTrainingSchedule>(
      `/admin/algorithm-training/${algorithm}/schedule`,
      request,
    );
    return response.data;
  },
};
