import { apiClient } from './apiClient';

export type IntentKey = 'general' | 'food' | 'urban' | 'nature' | 'beach' | 'culture';

export type SlotKey = 'attraction' | 'restaurant' | 'cafe' | 'entertainment' | 'accommodation';

export interface ParameterMeta {
  name: string;
  defaultValue: number;
  currentValue: number;
  minValue: number;
  maxValue: number;
  description: string | null;
}

export interface TwoTowerSettingsResponse {
  algorithm: {
    id: string;
    name: 'two_tower_retrieval';
    description: string | null;
    isActive: boolean;
    updatedAt: string | null;
  };
  core: {
    defaultTopK: ParameterMeta;
    maxTopK: ParameterMeta;
    maxIntents: ParameterMeta;
    fetchBufferMultiplier: ParameterMeta;
    enableAttractionTravelTypeFilter: ParameterMeta;
    enableDiversityBudget: ParameterMeta;
  };
  quotas: Record<IntentKey, Record<SlotKey, ParameterMeta>>;
}

export interface UpdateTwoTowerSettingsRequest {
  isActive?: boolean;
  defaultTopK?: number;
  maxTopK?: number;
  maxIntents?: number;
  fetchBufferMultiplier?: number;
  enableAttractionTravelTypeFilter?: boolean;
  enableDiversityBudget?: boolean;
  quotas?: Partial<Record<IntentKey, Partial<Record<SlotKey, number>>>>;
}

export type ReviewFilterTopicKey =
  | 'traffic'
  | 'weather'
  | 'crowd'
  | 'service'
  | 'price'
  | 'infra'
  | 'cleanliness'
  | 'food'
  | 'atmosphere'
  | 'activity'
  | 'other';

export interface ReviewFilterSettingsResponse {
  algorithm: {
    id: string;
    name: 'review_filter';
    description: string | null;
    isActive: boolean;
    updatedAt: string | null;
  };
  topics: Array<{ key: ReviewFilterTopicKey; label: string }>;
  parameters: Record<string, ParameterMeta>;
}

export interface UpdateReviewFilterSettingsRequest {
  parameters: Record<string, number>;
}

export type AlgorithmStatusesResponse = Record<string, boolean>;

export const algorithmSettingsAPI = {
  getAlgorithmStatuses: async (): Promise<AlgorithmStatusesResponse> => {
    const response = await apiClient.get<AlgorithmStatusesResponse>('/admin/algorithm-settings/statuses');
    return response.data;
  },

  getReviewFilterSettings: async (): Promise<ReviewFilterSettingsResponse> => {
    const response = await apiClient.get<ReviewFilterSettingsResponse>('/admin/algorithm-settings/review-filter');
    return response.data;
  },

  updateReviewFilterSettings: async (payload: UpdateReviewFilterSettingsRequest): Promise<ReviewFilterSettingsResponse> => {
    const response = await apiClient.patch<ReviewFilterSettingsResponse>('/admin/algorithm-settings/review-filter', payload);
    return response.data;
  },

  resetReviewFilterSettings: async (): Promise<ReviewFilterSettingsResponse> => {
    const response = await apiClient.post<ReviewFilterSettingsResponse>('/admin/algorithm-settings/review-filter/reset');
    return response.data;
  },

  getTwoTowerSettings: async (): Promise<TwoTowerSettingsResponse> => {
    const response = await apiClient.get<TwoTowerSettingsResponse>('/admin/algorithm-settings/two-tower');
    return response.data;
  },

  updateTwoTowerSettings: async (payload: UpdateTwoTowerSettingsRequest): Promise<TwoTowerSettingsResponse> => {
    const response = await apiClient.patch<TwoTowerSettingsResponse>('/admin/algorithm-settings/two-tower', payload);
    return response.data;
  },

  resetTwoTowerSettings: async (): Promise<TwoTowerSettingsResponse> => {
    const response = await apiClient.post<TwoTowerSettingsResponse>('/admin/algorithm-settings/two-tower/reset');
    return response.data;
  },
};
