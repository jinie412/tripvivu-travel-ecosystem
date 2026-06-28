import axios from 'axios';

const AI_SERVICE_URL =
  import.meta.env.VITE_AI_SERVICE_URL ||
  import.meta.env.VITE_AI_API_URL ||
  'http://localhost:8000';

const aiClient = axios.create({
  baseURL: AI_SERVICE_URL,
  timeout: Number(import.meta.env.VITE_AI_SERVICE_TIMEOUT || 15000),
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface HybridWeightsResponse {
  algorithm: string;
  is_active: boolean;
  distance_weight: number;
  model_weight: number;
  default_distance_weight?: number | null;
  candidate_count: number;
  default_candidate_count?: number | null;
}

export interface UpdateHybridWeightsRequest {
  distance_weight?: number;
  candidate_count?: number;
  actor?: string | null;
}

export const hybridConfigAPI = {
  getWeights: async (): Promise<HybridWeightsResponse> => {
    const response = await aiClient.get<HybridWeightsResponse>('/ai-config/hybrid/weights');
    return response.data;
  },

  updateWeights: async (payload: UpdateHybridWeightsRequest): Promise<HybridWeightsResponse> => {
    const response = await aiClient.put<HybridWeightsResponse>('/ai-config/hybrid/weights', payload);
    return response.data;
  },
};
