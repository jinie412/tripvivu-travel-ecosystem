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

export const algorithmSettingsAPI = {
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
