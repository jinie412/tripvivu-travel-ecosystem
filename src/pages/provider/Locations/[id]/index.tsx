import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import axios from 'axios';
import { useNavigate, useParams } from 'react-router-dom';
import Input from '../../../../components/UI/Input';
import Button from '../../../../components/UI/Button';
import {
  Clock,
  MapPin,
  Upload,
  Wifi,
  Car,
  Wind,
  CreditCard,
  Plus,
  Trash2,
  Edit2,
  Star,
  Waves,
  Loader2,
  Search,
  RefreshCw,
  CheckCircle,
  AlertCircle,
} from 'lucide-react';
import { businessReviewAPI } from '../../../../services/businessReviewAPI';
import {
  getPlaceDetail,
  getPlaceServicesByType,
  updatePlaceDetail,
  uploadPlaceImage,
  addPlaceMenuItem,
  updatePlaceMenuItem,
  deletePlaceMenuItem,
  addPlaceHotelRoom,
  updatePlaceHotelRoom,
  deletePlaceHotelRoom,
  addPlaceFreeService,
  updatePlaceFreeService,
  deletePlaceFreeService,
} from '../../../../services/order.service';
import { apiClient, extractResponseData } from '../../../../services/apiClient';
import type { Location } from '../../../../types/location';
import { getCurrentUser } from '../../../../utils/auth';
import { markLocationPendingApproval } from '../../../../utils/locationApprovalOverride';
import Swal from 'sweetalert2';

// ─── Map utilities (same as AddLocation) ─────────────────────────────────────
type CityOption = { id: string; name: string };
type CatalogMode = 'food' | 'accommodation' | 'service';
type BusinessTypeOption = { id: string; name: string; category_name?: string | null; data_mode?: CatalogMode };

const normalizeTypeText = (...values: Array<string | null | undefined>) => values.filter(Boolean).join(' ').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
const getCatalogMode = (type?: BusinessTypeOption): CatalogMode => {
  const value = normalizeTypeText(type?.category_name, type?.name);
  if (/(luu tru|khach san|nha nghi|hotel|motel|hostel|homestay|resort|villa|can ho|accommodation)/.test(value)) return 'accommodation';
  if (/(am thuc|nha hang|quan an|an uong|food|restaurant|cafe|coffee)/.test(value)) return 'food';
  return type?.data_mode ?? 'service';
};

const VIETNAM_BOUNDS = { minLat: 8.18, maxLat: 23.39, minLng: 102.14, maxLng: 109.47 };
const MAP_TILE_SIZE = 256;
const MAP_ZOOM = 15;
const SELECTED_LOCATION_ZOOM = 19;
const OSM_MAX_TILE_ZOOM = 19;
const DEFAULT_MAP_SIZE = { width: 600, height: 400 };

const clamp = (value: number, min: number, max: number) => Math.min(Math.max(value, min), max);

const latLngToWorldPixel = (lat: number, lng: number, zoom = MAP_ZOOM) => {
  const scale = MAP_TILE_SIZE * 2 ** zoom;
  const sinLat = Math.sin((clamp(lat, -85.05112878, 85.05112878) * Math.PI) / 180);
  return {
    x: ((lng + 180) / 360) * scale,
    y: (0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI)) * scale,
  };
};

const worldPixelToLatLng = (x: number, y: number, zoom = MAP_ZOOM) => {
  const scale = MAP_TILE_SIZE * 2 ** zoom;
  const lng = (x / scale) * 360 - 180;
  const n = Math.PI - (2 * Math.PI * y) / scale;
  const lat = (180 / Math.PI) * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
  return { lat, lng };
};

const getMapTiles = (centerLat: number, centerLng: number, width = DEFAULT_MAP_SIZE.width, height = DEFAULT_MAP_SIZE.height, zoom = MAP_ZOOM) => {
  const tileZoom = Math.min(zoom, OSM_MAX_TILE_ZOOM);
  const overzoomScale = 2 ** (zoom - tileZoom);
  const center = latLngToWorldPixel(centerLat, centerLng, tileZoom);
  const startX = center.x - width / (2 * overzoomScale);
  const startY = center.y - height / (2 * overzoomScale);
  const firstTileX = Math.floor(startX / MAP_TILE_SIZE);
  const firstTileY = Math.floor(startY / MAP_TILE_SIZE);
  const lastTileX = Math.floor((startX + width / overzoomScale) / MAP_TILE_SIZE);
  const lastTileY = Math.floor((startY + height / overzoomScale) / MAP_TILE_SIZE);
  const maxTile = 2 ** tileZoom;
  const tiles: Array<{ key: string; src: string; left: number; top: number; size: number }> = [];
  for (let x = firstTileX; x <= lastTileX; x += 1) {
    for (let y = firstTileY; y <= lastTileY; y += 1) {
      if (y < 0 || y >= maxTile) continue;
      const wrappedX = ((x % maxTile) + maxTile) % maxTile;
      tiles.push({
        key: `${zoom}-${wrappedX}-${y}`,
        src: `https://${'abcd'[(wrappedX + y) % 4]}.basemaps.cartocdn.com/rastertiles/voyager/${tileZoom}/${wrappedX}/${y}.png`,
        left: (x * MAP_TILE_SIZE - startX) * overzoomScale,
        top: (y * MAP_TILE_SIZE - startY) * overzoomScale,
        size: MAP_TILE_SIZE * overzoomScale,
      });
    }
  }
  return tiles;
};

type GeocodeResult = {
  lat: string;
  lon: string;
  display_name?: string;
  importance?: number;
};

const normalizeSearchText = (value: string) => value
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .toLowerCase()
  .replace(/[^a-z0-9]+/g, ' ')
  .trim();

const getCityAliases = (city: string) => {
  const normalizedCity = normalizeSearchText(city);
  const aliases = [city.trim()];

  if (normalizedCity.includes('ho chi minh') || normalizedCity.includes('hcm')) {
    aliases.push('Ho Chi Minh City', 'Saigon');
  }

  return aliases.filter((alias, index, list) => alias && list.indexOf(alias) === index);
};

const getAddressVariants = (address: string) => {
  const segments = address
    .split(',')
    .map((segment) => segment.trim())
    .filter(Boolean);
  const firstSegment = segments[0] || address.trim();
  const streetWithNumber = firstSegment.replace(/^\s*(?:so|số)\s+/i, '').trim();
  const streetWithoutNumber = streetWithNumber
    .replace(/^\d+[a-zA-Z0-9/-]*\s+/i, '')
    .trim();

  return [
    address.trim(),
    [streetWithNumber, ...segments.slice(1)].filter(Boolean).join(', '),
    streetWithNumber,
    streetWithoutNumber,
  ].filter((variant, index, list) => variant && list.indexOf(variant) === index);
};

const pickBestGeocodeResult = (results: GeocodeResult[], city: string, address: string) => {
  const normalizedCityAliases = getCityAliases(city).map(normalizeSearchText);
  const addressTokens = normalizeSearchText(address)
    .split(' ')
    .filter((token) => token.length >= 3)
    .slice(0, 6);

  return results
    .map((result) => {
      const displayName = normalizeSearchText(result.display_name || '');
      const cityScore = normalizedCityAliases.some((alias) => alias && displayName.includes(alias)) ? 100 : 0;
      const addressScore = addressTokens.reduce((score, token) => score + (displayName.includes(token) ? 8 : 0), 0);
      const importanceScore = Number(result.importance || 0) * 10;
      return { result, score: cityScore + addressScore + importanceScore };
    })
    .sort((a, b) => b.score - a.score)[0]?.result;
};

const geocodeAddress = async (address: string, city: string, placeName = '') => {
  const cityAliases = getCityAliases(city);
  const addressVariants = getAddressVariants(address);
  const queryCandidates = addressVariants.flatMap((addressVariant) =>
    cityAliases.flatMap((cityAlias) => [
      [placeName.trim(), addressVariant, cityAlias, 'Vietnam'].filter(Boolean).join(', '),
      [addressVariant, cityAlias, 'Vietnam'].filter(Boolean).join(', '),
    ]),
  ).filter((query, index, list) => query && list.indexOf(query) === index);

  for (const query of queryCandidates) {
    const params = new URLSearchParams({
      format: 'json',
      q: query,
      countrycodes: 'vn',
      limit: '5',
      addressdetails: '1',
      namedetails: '1',
      extratags: '1',
      bounded: '1',
      viewbox: `${VIETNAM_BOUNDS.minLng},${VIETNAM_BOUNDS.maxLat},${VIETNAM_BOUNDS.maxLng},${VIETNAM_BOUNDS.minLat}`,
      'accept-language': 'vi',
    });
    const response = await fetch(`https://nominatim.openstreetmap.org/search?${params.toString()}`, { headers: { Accept: 'application/json' } });
    if (!response.ok) throw new Error('Không thể kết nối dịch vụ bản đồ.');
    const results: GeocodeResult[] = await response.json();
    const bestResult = pickBestGeocodeResult(results, city, address);
    if (bestResult) return bestResult;
  }

  return null;
};
// ─────────────────────────────────────────────────────────────────────────────

type TabKey = 'Thông tin chung' | 'Đánh giá' | 'Dịch vụ';
type ReviewSort = 'newest' | 'oldest' | 'highest_rating' | 'lowest_rating';
type ServiceKind = 'free' | 'paid';

interface PlaceSummary {
  id: string;
  name: string;
  statusLabel: string;
  statusColor: string;
  rejectionReason: string;
  isActive: boolean;
  category: string;
  rating: number;
  reviewCount: number;
  gallery: string[];
}

interface PlaceDraft {
  name: string;
  address: string;
  city: string;
  phone: string;
  email: string;
  typeId: string;
  type: string;
  openTime: string;
  closeTime: string;
  description: string;
  latitude: string;
  longitude: string;
  estimatedPreparationTime: string;
}

interface PlaceServiceItem {
  id: string;
  name: string;
  description: string;
  price: number | null;
  isActive: boolean;
  quantity?: number;
}

interface ReviewSummary {
  stats: {
    averageRating: number;
    totalReviews: number;
    breakdown: Record<1 | 2 | 3 | 4 | 5, { count: number; percent: number }>;
    aiInsight: string;
  };
  reviews: Array<{
    id: string;
    userName: string;
    rating: number;
    content: string;
    topic: string | null;
    images: string[];
    createdAt: string;
    reply: string | null;
    repliedAt: string | null;
  }>;
  availableTopics: string[];
}

interface ServiceEditorState {
  kind: ServiceKind;
  mode: 'create' | 'edit';
}

const defaultDraft: PlaceDraft = {
  name: '',
  address: '',
  city: '',
  phone: '',
  email: '',
  typeId: '',
  type: '',
  openTime: '',
  closeTime: '',
  description: '',
  latitude: '',
  longitude: '',
  estimatedPreparationTime: '',
};

const getText = (value: unknown, fallback = ''): string => {
  if (typeof value === 'string') return value;
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  return fallback;
};

const getNumber = (value: unknown, fallback = 0): number => {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(/[^\d.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : fallback;
};

const getBoolean = (value: unknown, fallback = true): boolean => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (['true', '1', 'yes', 'active', 'đang hoạt động'].includes(normalized)) return true;
    if (['false', '0', 'no', 'inactive', 'tạm ngưng'].includes(normalized)) return false;
  }
  return fallback;
};

const formatTime = (value: unknown): string => {
  const text = getText(value, '');
  if (!text) return '';
  return text.length >= 5 ? text.slice(0, 5) : text;
};

const formatPrice = (value: number | null): string => {
  if (value === null || Number.isNaN(value)) return '0 đ';
  return `${value.toLocaleString('vi-VN')} đ`;
};

const createId = (prefix: string): string => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;

const getStatusMeta = (value: unknown): { label: string; color: string } => {
  const normalized = getText(value, 'chờ duyệt').trim().toLowerCase();
  if (normalized.includes('approved') || normalized.includes('đã duyệt')) return { label: 'Đã duyệt', color: '#22c55e' };
  if (normalized.includes('rejected') || normalized.includes('từ chối')) return { label: 'Từ chối', color: '#ef4444' };
  return { label: 'Chờ duyệt', color: '#f59e0b' };
};

const getServiceIcon = (serviceName: string): React.ReactNode => {
  const lowerName = serviceName.toLowerCase();
  if (lowerName.includes('wifi')) return <Wifi size={16} />;
  if (lowerName.includes('xe') || lowerName.includes('đậu')) return <Car size={16} />;
  if (lowerName.includes('máy lạnh') || lowerName.includes('điều hòa')) return <Wind size={16} />;
  if (lowerName.includes('thanh toán') || lowerName.includes('thẻ')) return <CreditCard size={16} />;
  if (lowerName.includes('hồ bơi') || lowerName.includes('nước')) return <Waves size={16} />;
  return <Plus size={16} />;
};

const normalizeGallery = (raw: unknown): string[] => {
  if (Array.isArray(raw)) return raw.filter((item): item is string => typeof item === 'string' && item.length > 0);
  if (typeof raw === 'string' && raw) return [raw];
  return [];
};

const getApiErrorMessage = (error: unknown, fallback: string): string => {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.message || error.response?.data?.error;
    if (Array.isArray(message)) return message.join(', ');
    if (typeof message === 'string' && message.trim()) return message;
    if (error.message) return error.message;
  }
  if (error instanceof Error && error.message) return error.message;
  return fallback;
};

const normalizePlaceDetail = (raw: unknown): { summary: PlaceSummary; draft: PlaceDraft } => {
  const place = Array.isArray(raw) ? raw[0] : raw;
  const data = place && typeof place === 'object' ? (place as Record<string, unknown>) : {};
  const rawStatus = data.status ?? data.place_status ?? data.approval_status;
  const isApproved = data.is_approved ?? data.approved ?? data.is_active ?? data.active;
  const statusValue = rawStatus ?? (isApproved === true ? 'approved' : isApproved === false ? 'pending' : null);
  const statusMeta = getStatusMeta(statusValue);
  const gallery = normalizeGallery(data.images ?? data.gallery ?? data.image_urls ?? data.image_url).filter(Boolean);

  return {
    summary: {
      id: getText(data.id ?? data.place_id ?? data.placeId, ''),
      name: getText(data.place_name ?? data.name ?? data.title, 'Đang tải...'),
      statusLabel: statusMeta.label,
      statusColor: statusMeta.color,
      rejectionReason: getText(data.rejection_reason ?? data.rejectionReason, ''),
      isActive: getBoolean(data.is_active ?? data.active ?? true, true),
      category: getText(data.category ?? data.type ?? data.place_type, 'Địa điểm'),
      rating: getNumber(data.rating ?? data.average_rating, 0),
      reviewCount: getNumber(data.review_count ?? data.reviews_count ?? data.total_reviews, 0),
      gallery: gallery.length > 0 ? gallery : ['https://picsum.photos/seed/location/600/400'],
    },
    draft: {
      name: getText(data.place_name ?? data.name ?? data.title, ''),
      address: getText(data.address ?? data.place_address, ''),
      city: getText(data.city ?? data.place_city ?? data.province, ''),
      phone: getText(data.phone ?? data.contact_phone ?? data.phone_number, ''),
      email: getText(data.email ?? data.contact_email, ''),
      typeId: getText(data.type_id ?? data.typeId ?? data.business_type_id, ''),
      type: getText(data.type_name ?? data.category ?? data.place_type, ''),
      openTime: formatTime(data.open_time ?? data.openTime ?? data.opening_time),
      closeTime: formatTime(data.close_time ?? data.closeTime ?? data.closing_time),
      description: getText(data.description ?? data.place_description, ''),
      latitude: getText(data.latitude ?? data.lat ?? data.p_lat, ''),
      longitude: getText(data.longitude ?? data.lng ?? data.p_lng, ''),
      estimatedPreparationTime: data.estimated_preparation_time != null ? String(data.estimated_preparation_time) : '',
    },
  };
};

const normalizeServiceItem = (raw: unknown, kind: ServiceKind): PlaceServiceItem => {
  const data = raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : {};
  const priceValue = data.price ?? data.service_price ?? data.amount;
  const numericPrice = typeof priceValue === 'number'
    ? priceValue
    : priceValue === null || priceValue === undefined || priceValue === ''
      ? null
      : Number(String(priceValue).replace(/[^\d.-]/g, ''));
  return {
    id: getText(data.id ?? data.service_id ?? data.serviceId, createId(kind)),
    name: getText(data.name ?? data.service_name ?? data.title, 'Dịch vụ'),
    description: getText(data.description ?? data.service_description, ''),
    price: kind === 'paid' && Number.isFinite(numericPrice as number) ? (numericPrice as number) : null,
    isActive: getBoolean(data.is_active ?? data.active ?? data.status ?? true, true),
  };
};

const mergeWithLocationListItem = (
  detail: { summary: PlaceSummary; draft: PlaceDraft },
  locationItem: Location | null,
): { summary: PlaceSummary; draft: PlaceDraft } => {
  if (!locationItem) return detail;
  const locationStatus = getStatusMeta(locationItem.status);
  const hasPlaceholderGallery = detail.summary.gallery.length === 1 && detail.summary.gallery[0].includes('picsum.photos/seed/location/600/400');
  const nextGallery = hasPlaceholderGallery && locationItem.image ? [locationItem.image] : detail.summary.gallery;
  return {
    summary: {
      ...detail.summary,
      id: detail.summary.id || locationItem.id,
      name: detail.summary.name && detail.summary.name !== 'Đang tải...' ? detail.summary.name : locationItem.name,
      statusLabel: locationStatus.label,
      statusColor: locationStatus.color,
      category: detail.summary.category && detail.summary.category !== 'Địa điểm' ? detail.summary.category : locationItem.category,
      rating: detail.summary.rating > 0 ? detail.summary.rating : locationItem.rating || 0,
      reviewCount: detail.summary.reviewCount > 0 ? detail.summary.reviewCount : locationItem.review_count || 0,
      gallery: nextGallery,
    },
    draft: {
      ...detail.draft,
      name: detail.draft.name && detail.draft.name !== 'Đang tải...' ? detail.draft.name : locationItem.name,
      address: detail.draft.address && detail.draft.address !== 'Chưa có địa chỉ' ? detail.draft.address : locationItem.address,
    },
  };
};

const LocationEditPage: React.FC = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const mapRef = useRef<HTMLDivElement | null>(null);
  const currentUser = useMemo(
    () => getCurrentUser<{ businessId?: string; business_id?: string; vendorId?: string; vendor_id?: string; id?: string }>(),
    [],
  );
  const vendorCandidates = useMemo(
    () => [currentUser?.businessId, currentUser?.business_id, currentUser?.vendorId, currentUser?.vendor_id, currentUser?.id]
      .filter((value): value is string => typeof value === 'string' && value.trim().length > 0),
    [currentUser],
  );
  const vendorId = vendorCandidates[0] || '';

  const [activeTab, setActiveTab] = useState<TabKey>('Thông tin chung');
  const [place, setPlace] = useState<PlaceSummary | null>(null);
  const [draft, setDraft] = useState<PlaceDraft>(defaultDraft);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isActive, setIsActive] = useState(true);
  const [generalMessage, setGeneralMessage] = useState<string | null>(null);
  const [savingGeneralInfo, setSavingGeneralInfo] = useState(false);

  // Image state — split existing URLs from new file picks
  const [existingImageUrls, setExistingImageUrls] = useState<string[]>([]);
  const [newImages, setNewImages] = useState<Array<{ file: File; previewUrl: string }>>([]);

  // Map state
  const [mapSize, setMapSize] = useState(DEFAULT_MAP_SIZE);
  const [mapZoom, setMapZoom] = useState(MAP_ZOOM);
  const [isGeocoding, setIsGeocoding] = useState(false);
  const [geocodeError, setGeocodeError] = useState('');

  // Cities
  const [cities, setCities] = useState<CityOption[]>([]);
  const [loadingCities, setLoadingCities] = useState(true);
  const [citiesError, setCitiesError] = useState<string | null>(null);

  // Business types
  const [businessTypes, setBusinessTypes] = useState<BusinessTypeOption[]>([]);
  const [loadingBusinessTypes, setLoadingBusinessTypes] = useState(true);
  const [businessTypesError, setBusinessTypesError] = useState<string | null>(null);

  // Reviews
  const [reviewRating, setReviewRating] = useState<number | undefined>(undefined);
  const [reviewSort, setReviewSort] = useState<ReviewSort>('newest');
  const [reviewHasImages, setReviewHasImages] = useState(false);
  const [reviewData, setReviewData] = useState<ReviewSummary | null>(null);
  const [reviewLoading, setReviewLoading] = useState(false);
  const [reviewError, setReviewError] = useState<string | null>(null);
  const [replyingToId, setReplyingToId] = useState<string | null>(null);
  const [replyDraft, setReplyDraft] = useState('');
  const [replySubmitting, setReplySubmitting] = useState(false);
  const [replyErrorMessage, setReplyErrorMessage] = useState<string | null>(null);
  const [resolvedReviewIds, setResolvedReviewIds] = useState<{ placeId: string; vendorId: string } | null>(null);

  // Services
  const [freeServices, setFreeServices] = useState<PlaceServiceItem[]>([]);
  const [menuItems, setMenuItems] = useState<PlaceServiceItem[]>([]);
  const [servicesLoading, setServicesLoading] = useState(false);
  const [servicesError, setServicesError] = useState<string | null>(null);
  const [serviceEditor, setServiceEditor] = useState<ServiceEditorState | null>(null);
  const [serviceDraft, setServiceDraft] = useState({ id: '', name: '', description: '', price: '', quantity: '1', isActive: true });
  const [serviceSaving, setServiceSaving] = useState(false);
  const [serviceMessage, setServiceMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // ── Load cities ─────────────────────────────────────────────────────────────
  const loadCities = useCallback(async () => {
    setLoadingCities(true);
    setCitiesError(null);
    try {
      const response = await apiClient.get<CityOption[] | { data: CityOption[] }>('/cities');
      const data = extractResponseData<CityOption[]>(response as any);
      const list: CityOption[] = Array.isArray(data)
        ? data
            .map((item: any) => ({
              id: String(item.id ?? item.city_id ?? item.code ?? item.name ?? ''),
              name: String(item.name ?? item.city_name ?? item.city ?? item.province ?? ''),
            }))
            .filter((item) => item.id && item.name)
            .sort((a, b) => a.name.localeCompare(b.name, 'vi'))
        : [];
      if (list.length === 0) throw new Error('Danh sách tỉnh/thành từ hệ thống đang trống.');
      setCities(list);
    } catch (error) {
      setCities([]);
      setCitiesError(error instanceof Error ? error.message : 'Không thể tải danh sách tỉnh/thành.');
    } finally {
      setLoadingCities(false);
    }
  }, []);

  useEffect(() => { loadCities(); }, [loadCities]);

  // ── Load business types ──────────────────────────────────────────────────────
  const loadBusinessTypes = useCallback(async () => {
    setLoadingBusinessTypes(true);
    setBusinessTypesError(null);
    try {
      const response = await apiClient.get<BusinessTypeOption[] | { data: BusinessTypeOption[] }>('/types');
      const data = extractResponseData<BusinessTypeOption[]>(response as any);
      const list: BusinessTypeOption[] = Array.isArray(data)
        ? data
            .map((item: any) => ({
              id: String(item.id ?? item.type_id ?? item.code ?? item.name ?? ''),
              name: String(item.name ?? item.type_name ?? ''),
              category_name: item.category_name ?? null,
              data_mode: item.data_mode,
            }))
            .filter((item) => item.id && item.name)
            .sort((a, b) => a.name.localeCompare(b.name, 'vi'))
        : [];
      if (list.length === 0) throw new Error('Danh sách loại hình kinh doanh từ hệ thống đang trống.');
      setBusinessTypes(list);
    } catch (error) {
      setBusinessTypes([]);
      setBusinessTypesError(error instanceof Error ? error.message : 'Không thể tải danh sách loại hình kinh doanh.');
    } finally {
      setLoadingBusinessTypes(false);
    }
  }, []);

  useEffect(() => { loadBusinessTypes(); }, [loadBusinessTypes]);

  useEffect(() => {
    const element = mapRef.current;
    if (!element) return;

    const updateMapSize = () => {
      const rect = element.getBoundingClientRect();
      setMapSize({
        width: Math.max(Math.round(rect.width), 1),
        height: Math.max(Math.round(rect.height), 1),
      });
    };

    updateMapSize();
    const observer = new ResizeObserver(updateMapSize);
    observer.observe(element);

    return () => observer.disconnect();
  }, [activeTab]);

  // ── Load place detail ────────────────────────────────────────────────────────
  useEffect(() => {
    const fetchPlaceDetail = async () => {
      if (!id) { setError('Không tìm thấy địa điểm cần hiển thị.'); setLoading(false); return; }
      if (!vendorId) { setError('Không tìm thấy thông tin business. Vui lòng đăng nhập lại.'); setLoading(false); return; }

      try {
        setLoading(true);
        setError(null);

        const rawDetail = await getPlaceDetail(id);
        const normalized = normalizePlaceDetail(rawDetail);
        const merged = mergeWithLocationListItem(normalized, null);

        setPlace(merged.summary);
        setDraft(merged.draft);
        setIsActive(merged.summary.isActive);
        setExistingImageUrls(merged.summary.gallery.filter((url) => !url.includes('picsum.photos/seed/location')));
        setNewImages([]);

      } catch (err) {
        setError(getApiErrorMessage(err, 'Không thể tải thông tin địa điểm'));
      } finally {
        setLoading(false);
      }
    };

    void fetchPlaceDetail();
  }, [id, vendorId]);

  // ── Reviews ──────────────────────────────────────────────────────────────────
  useEffect(() => {
    const fetchReviews = async () => {
      if (activeTab !== 'Đánh giá') return;
      const placeCandidates = [place?.id, id, id ? decodeURIComponent(id) : undefined]
        .filter((value): value is string => typeof value === 'string' && value.trim().length > 0)
        .filter((value, index, array) => array.indexOf(value) === index);
      if (placeCandidates.length === 0 || vendorCandidates.length === 0) return;
      try {
        setReviewLoading(true);
        setReviewError(null);
        let loaded = false;
        let lastError: unknown = null;
        for (const placeIdCandidate of placeCandidates) {
          for (const vendorIdCandidate of vendorCandidates) {
            try {
              const response = await businessReviewAPI.getReviews({ vendorId: vendorIdCandidate, placeId: placeIdCandidate, rating: reviewRating, sort: reviewSort, hasImages: reviewHasImages || undefined }, 1, 20);
              setReviewData({ stats: response.stats, reviews: response.reviews, availableTopics: response.availableTopics });
              setResolvedReviewIds({ placeId: placeIdCandidate, vendorId: vendorIdCandidate });
              loaded = true;
              break;
            } catch (error) { lastError = error; }
          }
          if (loaded) break;
        }
        if (!loaded) throw lastError || new Error('Không thể tải đánh giá');
      } catch (err) {
        setReviewData(null);
        setReviewError(getApiErrorMessage(err, 'Không thể tải đánh giá'));
      } finally { setReviewLoading(false); }
    };
    void fetchReviews();
  }, [activeTab, id, place?.id, reviewHasImages, reviewRating, reviewSort, vendorCandidates]);

  const selectedBusinessType = businessTypes.find((type) => type.id === draft.typeId)
    ?? businessTypes.find((type) => type.name === draft.type);
  const catalogMode = getCatalogMode(selectedBusinessType);

  // ── Services ─────────────────────────────────────────────────────────────────
  useEffect(() => {
    const fetchServices = async () => {
      const targetPlaceId = place?.id || id;
      if (!targetPlaceId || activeTab !== 'Dịch vụ') return;
      try {
        setServicesLoading(true);
        setServicesError(null);
        const rawServices = await getPlaceServicesByType(targetPlaceId);
        const payload = rawServices && typeof rawServices === 'object' ? (rawServices as Record<string, unknown>) : {};
        const nested = (payload.data as Record<string, unknown> | undefined) ?? {};
        const free = Array.isArray(payload.freeServices) ? payload.freeServices : Array.isArray(nested.freeServices) ? (nested.freeServices as unknown[]) : [];
        const menu = Array.isArray(payload.menuItems) ? payload.menuItems : Array.isArray(nested.menuItems) ? (nested.menuItems as unknown[]) : [];
        const rooms = Array.isArray(payload.rooms) ? payload.rooms : Array.isArray(nested.rooms) ? (nested.rooms as unknown[]) : [];
        setFreeServices(free.map((item) => normalizeServiceItem(item, 'free')));
        setMenuItems((catalogMode === 'accommodation' ? rooms : catalogMode === 'food' ? menu : []).map((item) => {
          const normalized = normalizeServiceItem(item, 'paid');
          const record = item && typeof item === 'object' ? item as Record<string, unknown> : {};
          return { ...normalized, quantity: Number(record.quantity) || 1 };
        }));
      } catch (err) {
        setServicesError(getApiErrorMessage(err, 'Không thể tải dịch vụ'));
        setFreeServices([]);
      } finally { setServicesLoading(false); }
    };
    void fetchServices();
  }, [activeTab, catalogMode, id, place?.id]);

  // ── Map helpers ───────────────────────────────────────────────────────────────
  const currentLat = parseFloat(draft.latitude) || 10.77;
  const currentLng = parseFloat(draft.longitude) || 106.7;
  const mapTiles = getMapTiles(currentLat, currentLng, mapSize.width, mapSize.height, mapZoom);

  const handleMapClick = (event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = clamp(event.clientX - rect.left, 0, rect.width);
    const clickY = clamp(event.clientY - rect.top, 0, rect.height);
    const center = latLngToWorldPixel(currentLat, currentLng, mapZoom);
    const worldX = center.x - rect.width / 2 + clickX;
    const worldY = center.y - rect.height / 2 + clickY;
    const { lat, lng } = worldPixelToLatLng(worldX, worldY, mapZoom);
    const latitude = clamp(lat, VIETNAM_BOUNDS.minLat, VIETNAM_BOUNDS.maxLat);
    const longitude = clamp(lng, VIETNAM_BOUNDS.minLng, VIETNAM_BOUNDS.maxLng);
    setMapZoom(SELECTED_LOCATION_ZOOM);
    setDraft((current) => ({ ...current, latitude: latitude.toFixed(6), longitude: longitude.toFixed(6) }));
  };

  const handleFindOnMap = async () => {
    if (!draft.address.trim() || !draft.city.trim()) {
      setGeocodeError('Vui lòng nhập địa chỉ và chọn tỉnh/thành trước khi tìm trên bản đồ.');
      return;
    }
    try {
      setIsGeocoding(true);
      setGeocodeError('');
      const firstResult = await geocodeAddress(draft.address, draft.city, draft.name);
      if (!firstResult) throw new Error('Không tìm thấy vị trí phù hợp. Vui lòng thử nhập địa chỉ rõ hơn hoặc chọn thủ công trên bản đồ.');
      const latitude = clamp(Number(firstResult.lat), VIETNAM_BOUNDS.minLat, VIETNAM_BOUNDS.maxLat);
      const longitude = clamp(Number(firstResult.lon), VIETNAM_BOUNDS.minLng, VIETNAM_BOUNDS.maxLng);
      if (Number.isNaN(latitude) || Number.isNaN(longitude)) throw new Error('Dịch vụ bản đồ trả về tọa độ không hợp lệ.');
      setMapZoom(SELECTED_LOCATION_ZOOM);
      setDraft((current) => ({ ...current, latitude: latitude.toFixed(6), longitude: longitude.toFixed(6) }));
    } catch (error) {
      setGeocodeError(error instanceof Error ? error.message : 'Không thể tìm vị trí trên bản đồ.');
    } finally { setIsGeocoding(false); }
  };

  // ── Image helpers ─────────────────────────────────────────────────────────────
  const allImages = [...existingImageUrls, ...newImages.map((img) => img.previewUrl)];

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? []);
    const remaining = 5 - allImages.length;
    const toAdd = files.slice(0, remaining).map((file) => ({ file, previewUrl: URL.createObjectURL(file) }));
    setNewImages((prev) => [...prev, ...toAdd]);
    e.target.value = '';
  };

  const handleImageRemove = (index: number) => {
    const existingCount = existingImageUrls.length;
    if (index < existingCount) {
      setExistingImageUrls((prev) => prev.filter((_, i) => i !== index));
    } else {
      const newIdx = index - existingCount;
      setNewImages((prev) => {
        URL.revokeObjectURL(prev[newIdx].previewUrl);
        return prev.filter((_, i) => i !== newIdx);
      });
    }
  };

  // ── Validation ────────────────────────────────────────────────────────────────
  const phoneError = draft.phone && !/^0\d{9}$/.test(draft.phone) ? 'SĐT phải gồm đúng 10 chữ số và bắt đầu bằng số 0.' : '';
  const emailError = draft.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(draft.email) ? 'Email không đúng định dạng.' : '';

  // ── Save ──────────────────────────────────────────────────────────────────────
  const savedGeneralInfo = async () => {
    if (!id || !vendorId) { setGeneralMessage('Không tìm thấy thông tin địa điểm hoặc đối tác.'); return; }
    if (!draft.name.trim() || !draft.address.trim()) { setGeneralMessage('Vui lòng nhập đầy đủ tên và địa chỉ địa điểm.'); return; }
    if (phoneError) { setGeneralMessage('SĐT liên hệ không hợp lệ.'); return; }
    if (emailError) { setGeneralMessage('Email liên hệ không hợp lệ.'); return; }
    try {
      setSavingGeneralInfo(true);
      setGeneralMessage(null);
      const uploadedImages = await Promise.all(newImages.map((img) => uploadPlaceImage(img.file, id)));
      const imageUrls = [...existingImageUrls, ...uploadedImages].filter((url): url is string => typeof url === 'string' && url.trim().length > 0);
      await updatePlaceDetail({
        placeId: id,
        vendorId,
        p_type_id: draft.typeId,
        name: draft.name.trim(),
        address: draft.address.trim(),
        city: draft.city.trim(),
        email: draft.email.trim(),
        phone: draft.phone.trim(),
        p_email: draft.email.trim(),
        p_phone: draft.phone.trim(),
        latitude: draft.latitude,
        longitude: draft.longitude,
        openTime: draft.openTime,
        closeTime: draft.closeTime,
        description: draft.description,
        imageUrls,
        isActive,
        estimated_preparation_time: catalogMode === 'food' && draft.estimatedPreparationTime
          ? Number(draft.estimatedPreparationTime)
          : null,
        status: 'pending',
        placeStatus: 'pending',
        approvalStatus: 'pending',
        place_status: 'pending',
        approval_status: 'pending',
        isApproved: false,
        is_approved: false,
        approved: false,
      });
      markLocationPendingApproval(id);
      const pendingStatus = getStatusMeta('pending');
      setPlace((current) => current ? { ...current, statusLabel: pendingStatus.label, statusColor: pendingStatus.color } : current);
      await Swal.fire({ text: 'Lưu thay đổi địa điểm thành công!', icon: 'success' });
      navigate('/locations');
    } catch (err) {
      setGeneralMessage(getApiErrorMessage(err, 'Không thể lưu thay đổi địa điểm'));
    } finally { setSavingGeneralInfo(false); }
  };

  // ── Services helpers ──────────────────────────────────────────────────────────
  const openServiceEditor = (kind: ServiceKind, service?: PlaceServiceItem) => {
    setServiceEditor({ kind, mode: service ? 'edit' : 'create' });
    setServiceDraft({ id: service?.id || '', name: service?.name || '', description: service?.description || '', price: service?.price !== null && service?.price !== undefined ? String(service.price) : '', quantity: String(service?.quantity || 1), isActive: service?.isActive ?? true });
  };
  const closeServiceEditor = () => { setServiceEditor(null); setServiceDraft({ id: '', name: '', description: '', price: '', quantity: '1', isActive: true }); };
  const saveService = async () => {
    if (!serviceEditor) return;
    const trimmedName = serviceDraft.name.trim();
    if (!trimmedName) { Swal.fire({ text: 'Vui lòng nhập tên dịch vụ', icon: 'warning' }); return; }
    const price = serviceEditor.kind === 'paid'
      ? (() => { const n = Number(String(serviceDraft.price).replace(/[^\d.-]/g, '')); return Number.isFinite(n) ? n : 0; })()
      : null;
    const quantity = Number(serviceDraft.quantity);
    if (serviceEditor.kind === 'paid' && (!price || price <= 0)) { Swal.fire({ text: 'Giá phải lớn hơn 0', icon: 'warning' }); return; }
    if (serviceEditor.kind === 'paid' && catalogMode === 'accommodation' && (!Number.isInteger(quantity) || quantity <= 0)) { Swal.fire({ text: 'Sức chứa/phòng phải là số nguyên lớn hơn 0', icon: 'warning' }); return; }
    const targetPlaceId = id!;
    try {
      setServiceSaving(true);
      setServiceMessage(null);
      if (serviceEditor.kind === 'paid') {
        if (catalogMode === 'accommodation' && serviceEditor.mode === 'create') {
          const result = await addPlaceHotelRoom({ placeId: targetPlaceId, name: trimmedName, price: price ?? 0, quantity });
          const newId = (result?.item as any)?.id ?? (result as any)?.id ?? createId('paid');
          setMenuItems((current) => [...current, { id: newId, name: trimmedName, description: '', price, quantity, isActive: true }]);
        } else if (catalogMode === 'accommodation') {
          await updatePlaceHotelRoom({ roomId: serviceDraft.id, placeId: targetPlaceId, name: trimmedName, price: price ?? 0, quantity });
          setMenuItems((current) => current.map((item) => item.id === serviceDraft.id ? { ...item, name: trimmedName, price, quantity } : item));
        } else if (serviceEditor.mode === 'create') {
          const result = await addPlaceMenuItem({ placeId: targetPlaceId, name: trimmedName, description: serviceDraft.description.trim() || undefined, price: price ?? 0 });
          const newId = (result?.item as any)?.id ?? (result as any)?.id ?? createId('paid');
          setMenuItems((current) => [...current, { id: newId, name: trimmedName, description: serviceDraft.description.trim(), price, isActive: true }]);
        } else {
          await updatePlaceMenuItem({ itemId: serviceDraft.id, placeId: targetPlaceId, name: trimmedName, description: serviceDraft.description.trim() || undefined, price: price ?? 0 });
          setMenuItems((current) => current.map((item) => item.id === serviceDraft.id ? { ...item, name: trimmedName, description: serviceDraft.description.trim(), price } : item));
        }
      } else {
        if (serviceEditor.mode === 'create') {
          const result = await addPlaceFreeService({ placeId: targetPlaceId, name: trimmedName });
          const newId = (result as any)?.id ?? createId('free');
          setFreeServices((current) => [...current, { id: newId, name: trimmedName, description: serviceDraft.description.trim(), price: null, isActive: true }]);
        } else {
          const result = await updatePlaceFreeService({ serviceId: serviceDraft.id, placeId: targetPlaceId, name: trimmedName });
          const newId = (result as any)?.id ?? serviceDraft.id;
          setFreeServices((current) => current.map((item) => item.id === serviceDraft.id ? { ...item, id: newId, name: trimmedName, description: serviceDraft.description.trim() } : item));
        }
      }
      closeServiceEditor();
      setServiceMessage({ type: 'success', text: serviceEditor.mode === 'create' ? 'Đã thêm thành công!' : 'Đã cập nhật thành công!' });
      setTimeout(() => setServiceMessage(null), 3000);
    } catch (err) {
      setServiceMessage({ type: 'error', text: getApiErrorMessage(err, 'Không thể lưu dịch vụ') });
    } finally {
      setServiceSaving(false);
    }
  };
  const deleteService = async (kind: ServiceKind, serviceId: string) => {
    const result = await Swal.fire({ title: 'Xác nhận', text: 'Bạn có chắc muốn xóa dịch vụ này?', icon: 'warning', showCancelButton: true, confirmButtonText: 'Đồng ý', cancelButtonText: 'Hủy' });
    if (!result.isConfirmed) return;
    const targetPlaceId = id!;
    try {
      if (kind === 'paid') {
        if (catalogMode === 'accommodation') await deletePlaceHotelRoom({ roomId: serviceId, placeId: targetPlaceId });
        else await deletePlaceMenuItem({ itemId: serviceId, placeId: targetPlaceId });
        setMenuItems((current) => current.filter((item) => item.id !== serviceId));
      } else {
        await deletePlaceFreeService({ serviceId, placeId: targetPlaceId });
        setFreeServices((current) => current.filter((item) => item.id !== serviceId));
      }
      setServiceMessage({ type: 'success', text: 'Đã xóa thành công!' });
      setTimeout(() => setServiceMessage(null), 3000);
    } catch (err) {
      setServiceMessage({ type: 'error', text: getApiErrorMessage(err, 'Không thể xóa dịch vụ') });
    }
  };

  // ── Derived ───────────────────────────────────────────────────────────────────
  const locationData = useMemo(() => ({
    reviews: {
      average: reviewData?.stats.averageRating || 0,
      total: reviewData?.stats.totalReviews || 0,
      distribution: [5, 4, 3, 2, 1].map((score) => ({ score, percentage: reviewData?.stats.breakdown[score as 1 | 2 | 3 | 4 | 5]?.percent || 0, count: reviewData?.stats.breakdown[score as 1 | 2 | 3 | 4 | 5]?.count || 0 })),
      aiInsight: reviewData?.stats.aiInsight || 'Chưa có dữ liệu phân tích AI.',
      list: (reviewData?.reviews || []).map((review) => ({
        id: review.id,
        user: review.userName,
        date: new Date(review.createdAt).toLocaleDateString('vi-VN'),
        avatar: `https://picsum.photos/seed/${review.id}/100/100`,
        rating: review.rating,
        content: review.content,
        images: review.images,
        tags: review.topic ? [{ name: review.topic, color: '#3b82f6' }] : [],
        reply: review.reply,
        repliedAt: review.repliedAt,
      })),
    },
  }), [reviewData]);

  const pageTitle = draft.name || place?.name || 'Đang tải...';
  const statusMeta = place ? { label: place.statusLabel, color: place.statusColor } : { label: 'Chờ duyệt', color: '#f59e0b' };

  // ════════════════════════════════════════════════════════════════════════════
  // renderGeneralInfo — mirrors AddLocation Step 1
  // ════════════════════════════════════════════════════════════════════════════
  const renderGeneralInfo = () => (
    <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', padding: '32px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
      {generalMessage && (
        <div style={{ marginBottom: '20px', padding: '12px 16px', borderRadius: '12px', background: '#eff6ff', color: '#2563eb', fontSize: '14px', fontWeight: '600' }}>
          {generalMessage}
        </div>
      )}

      <div style={{ display: 'flex', gap: '48px' }}>
        {/* ── Left column ── */}
        <div style={{ flex: 1 }}>
          <Input
            label="Tên địa điểm"
            placeholder="Ví dụ: Khách sạn Marriott Hà Nội"
            value={draft.name}
            onChange={(e) => setDraft((current) => ({ ...current, name: e.target.value }))}
          />
          <Input
            label="Địa chỉ chi tiết"
            placeholder="Số nhà, tên đường..."
            value={draft.address}
            onChange={(e) => setDraft((current) => ({ ...current, address: e.target.value }))}
          />

          {/* City + Phone */}
          <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>Tỉnh/Thành</label>
              <select
                style={{ width: '100%', padding: '14px 16px', borderRadius: '12px', border: `1px solid ${citiesError ? '#ef4444' : 'var(--border-color)'}`, background: '#fcfcfc', outline: 'none', fontSize: '15px' }}
                value={draft.city}
                onChange={(e) => setDraft((current) => ({ ...current, city: e.target.value }))}
                disabled={loadingCities || !!citiesError || cities.length === 0}
              >
                {loadingCities ? (
                  <option value="">Đang tải danh sách tỉnh/thành...</option>
                ) : citiesError ? (
                  <option value="">Không tải được danh sách tỉnh/thành</option>
                ) : cities.length === 0 ? (
                  <option value="">Danh sách tỉnh/thành đang trống</option>
                ) : (
                  <>
                    <option value="" disabled>-- Chọn tỉnh/thành --</option>
                    {cities.map((c) => (
                      <option key={c.id} value={c.name}>{c.name}</option>
                    ))}
                  </>
                )}
              </select>
              {citiesError && (
                <div style={{ marginTop: '8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
                  <span style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4 }}>Không thể tải tỉnh/thành từ hệ thống.</span>
                  <button type="button" onClick={loadCities} disabled={loadingCities} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', border: '1px solid #fecaca', background: '#fff', color: '#dc2626', borderRadius: '10px', padding: '8px 10px', cursor: loadingCities ? 'not-allowed' : 'pointer', fontSize: '13px', fontWeight: 600, whiteSpace: 'nowrap' }}>
                    <RefreshCw size={14} /> Tải lại
                  </button>
                </div>
              )}
            </div>
            <div style={{ flex: 1 }}>
              <Input
                label="SĐT Liên hệ"
                placeholder="0xxxxxxxxx"
                inputMode="numeric"
                maxLength={10}
                error={phoneError}
                value={draft.phone}
                onChange={(e) => setDraft((current) => ({ ...current, phone: e.target.value.replace(/\D/g, '').slice(0, 10) }))}
                style={{ marginBottom: 0 }}
              />
            </div>
          </div>

          <Input
            label="Email liên hệ"
            type="email"
            placeholder="example@email.com"
            error={emailError}
            value={draft.email}
            onChange={(e) => setDraft((current) => ({ ...current, email: e.target.value }))}
          />

          {/* Description */}
          <div style={{ marginBottom: '24px' }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>Mô tả địa điểm</label>
            <textarea
              placeholder="Nhập giới thiệu ngắn gọn về địa điểm của bạn..."
              style={{ width: '100%', minHeight: '120px', padding: '16px', borderRadius: '12px', border: '1px solid #E2E8F0', background: '#fcfcfc', outline: 'none', fontSize: '15px', color: '#1e293b', lineHeight: '1.6', resize: 'vertical' }}
              value={draft.description}
              onChange={(e) => setDraft((current) => ({ ...current, description: e.target.value }))}
            />
          </div>

          {/* Business type */}
          <div style={{ marginBottom: '24px' }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>Loại hình kinh doanh</label>
            <select
              style={{ width: '100%', padding: '14px 16px', borderRadius: '12px', border: `1px solid ${businessTypesError ? '#ef4444' : 'var(--border-color)'}`, background: '#fcfcfc', outline: 'none', fontSize: '15px', color: '#1e293b' }}
              value={draft.typeId}
              onChange={(e) => {
                const selectedType = businessTypes.find((t) => t.id === e.target.value);
                setDraft((current) => ({
                  ...current,
                  typeId: selectedType?.id || '',
                  type: selectedType?.name || '',
                  estimatedPreparationTime: getCatalogMode(selectedType) === 'food' ? current.estimatedPreparationTime : '',
                }));
              }}
              disabled={loadingBusinessTypes || !!businessTypesError || businessTypes.length === 0}
            >
              {loadingBusinessTypes ? (
                <option value="">Đang tải danh sách loại hình...</option>
              ) : businessTypesError ? (
                <option value="">Không tải được danh sách loại hình</option>
              ) : businessTypes.length === 0 ? (
                <option value="">Danh sách loại hình đang trống</option>
              ) : (
                <>
                  <option value="" disabled>-- Chọn loại hình --</option>
                  {businessTypes.map((t) => (
                    <option key={t.id} value={t.id}>{t.name}</option>
                  ))}
                </>
              )}
            </select>
            {businessTypesError && (
              <div style={{ marginTop: '8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
                <span style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4 }}>Không thể tải loại hình kinh doanh từ hệ thống.</span>
                <button type="button" onClick={loadBusinessTypes} disabled={loadingBusinessTypes} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', border: '1px solid #fecaca', background: '#fff', color: '#dc2626', borderRadius: '10px', padding: '8px 10px', cursor: loadingBusinessTypes ? 'not-allowed' : 'pointer', fontSize: '13px', fontWeight: 600, whiteSpace: 'nowrap' }}>
                  <RefreshCw size={14} /> Tải lại
                </button>
              </div>
            )}
          </div>

          {/* Estimated preparation time — only for food category */}
          {catalogMode === 'food' && (
            <div style={{ marginBottom: '24px' }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
                Thời gian hoàn thành đơn (phút)
              </label>
              <input
                type="number"
                min={1}
                max={480}
                placeholder="Ví dụ: 30"
                value={draft.estimatedPreparationTime}
                onChange={(e) => setDraft((current) => ({ ...current, estimatedPreparationTime: e.target.value }))}
                style={{
                  width: '100%',
                  padding: '14px 16px',
                  borderRadius: '12px',
                  border: '1px solid var(--border-color)',
                  background: '#fcfcfc',
                  outline: 'none',
                  fontSize: '15px',
                  color: '#1e293b',
                  boxSizing: 'border-box',
                }}
              />
              <p style={{ marginTop: '6px', fontSize: '12px', color: '#94a3b8' }}>
                Thời gian dự kiến từ lúc khách đặt đến khi hoàn thành phục vụ
              </p>
            </div>
          )}

          {/* Open/Close time */}
          <div style={{ display: 'flex', gap: '16px' }}>
            <div style={{ flex: 1 }}>
              <Input label="Giờ mở cửa" type="time" value={draft.openTime} onChange={(e) => setDraft((current) => ({ ...current, openTime: e.target.value }))} icon={<Clock size={18} />} style={{ marginBottom: 0 }} />
            </div>
            <div style={{ flex: 1 }}>
              <Input label="Giờ đóng cửa" type="time" value={draft.closeTime} onChange={(e) => setDraft((current) => ({ ...current, closeTime: e.target.value }))} icon={<Clock size={18} />} style={{ marginBottom: 0 }} />
            </div>
          </div>
        </div>

        {/* ── Right column ── */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          {/* Map header */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', marginBottom: '12px' }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block' }}>Vị trí trên bản đồ</label>
            <button
              type="button"
              onClick={handleFindOnMap}
              disabled={isGeocoding || !draft.address.trim() || !draft.city.trim()}
              style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', border: '1px solid #bfdbfe', background: '#fff', color: '#2563eb', borderRadius: '10px', padding: '8px 12px', cursor: isGeocoding || !draft.address.trim() || !draft.city.trim() ? 'not-allowed' : 'pointer', fontSize: '13px', fontWeight: 700, whiteSpace: 'nowrap', opacity: isGeocoding || !draft.address.trim() || !draft.city.trim() ? 0.6 : 1 }}
            >
              {isGeocoding ? <Loader2 size={14} className="animate-spin" /> : <Search size={14} />}
              {isGeocoding ? 'Đang tìm...' : 'Tìm trên bản đồ'}
            </button>
          </div>
          {geocodeError && (
            <div style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4, marginBottom: '10px' }}>{geocodeError}</div>
          )}

          {/* Interactive map */}
          <div
            ref={mapRef}
            onClick={handleMapClick}
            style={{ width: '100%', flex: 1, minHeight: '240px', background: '#f8fafc', borderRadius: '16px', position: 'relative', overflow: 'hidden', border: '1px solid #F1F5F9', marginBottom: '24px', cursor: 'crosshair' }}
          >
            <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
              {mapTiles.map((tile) => (
                <img key={tile.key} src={tile.src} alt="" style={{ position: 'absolute', left: `${tile.left}px`, top: `${tile.top}px`, width: `${tile.size}px`, height: `${tile.size}px`, userSelect: 'none' }} />
              ))}
            </div>
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -100%)', color: '#ef4444', pointerEvents: 'none', filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.25))' }}>
              <MapPin size={32} fill="#ef444433" />
            </div>
            <div style={{ position: 'absolute', bottom: '12px', left: '12px', background: 'white', padding: '6px 12px', borderRadius: '8px', fontSize: '11px', boxShadow: '0 2px 4px rgba(0,0,0,0.1)', color: '#64748b' }}>
              Nhấn "Tìm trên bản đồ" hoặc click vào bản đồ để chỉnh vị trí.
            </div>
          </div>

          {/* Lat/Lng readonly */}
          <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <Input label="Vĩ độ (Latitude)" type="number" value={draft.latitude} readOnly style={{ marginBottom: 0, cursor: 'not-allowed', background: '#f8fafc' }} />
            </div>
            <div style={{ flex: 1 }}>
              <Input label="Kinh độ (Longitude)" type="number" value={draft.longitude} readOnly style={{ marginBottom: 0, cursor: 'not-allowed', background: '#f8fafc' }} />
            </div>
          </div>

          {/* Images */}
          <div>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>
              Hình ảnh địa điểm <span style={{ color: '#94a3b8', fontWeight: '400' }}>({allImages.length}/5)</span>
            </label>
            <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              {allImages.map((url, idx) => (
                <div key={`${url}-${idx}`} style={{ position: 'relative', width: '76px', height: '76px' }}>
                  <img src={url} alt="" style={{ width: '76px', height: '76px', borderRadius: '10px', objectFit: 'cover', border: '1px solid #E2E8F0' }} />
                  <button
                    onClick={() => handleImageRemove(idx)}
                    style={{ position: 'absolute', top: '-6px', right: '-6px', width: '20px', height: '20px', borderRadius: '50%', background: '#ef4444', color: 'white', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: '800', lineHeight: 1 }}
                  >×</button>
                </div>
              ))}
              {allImages.length < 5 && (
                <>
                  <input type="file" id="editPlaceImageInput" style={{ display: 'none' }} accept="image/*" multiple onChange={handleImageSelect} />
                  <div
                    onClick={() => document.getElementById('editPlaceImageInput')?.click()}
                    style={{ width: '76px', height: '76px', border: '2px dashed #E2E8F0', borderRadius: '10px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#94a3b8', fontSize: '10px', gap: '4px', cursor: 'pointer', background: '#F8FAFC' }}
                  >
                    <Upload size={20} />
                    <span>Thêm ảnh</span>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div style={{ marginTop: '48px', paddingTop: '32px', borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'flex-end', gap: '16px', alignItems: 'center' }}>
        <span onClick={() => navigate('/locations')} style={{ color: '#64748b', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>Hủy bỏ</span>
        <Button onClick={savedGeneralInfo} disabled={savingGeneralInfo} style={{ padding: '12px 32px', borderRadius: '12px', gap: '8px' }}>
          {savingGeneralInfo ? (
            <><Loader2 size={18} className="animate-spin" /> Đang lưu...</>
          ) : (
            <><CheckCircle size={18} /> Lưu thay đổi</>
          )}
        </Button>
      </div>
    </div>
  );

  const openReplyEditor = (reviewId: string, existingReply: string | null) => {
    setReplyErrorMessage(null);
    if (replyingToId === reviewId) {
      setReplyingToId(null);
      return;
    }
    setReplyDraft(existingReply ?? '');
    setReplyingToId(reviewId);
  };

  const submitReply = async (reviewId: string) => {
    if (!resolvedReviewIds || !replyDraft.trim()) return;
    try {
      setReplySubmitting(true);
      setReplyErrorMessage(null);
      const result = await businessReviewAPI.submitReply({
        vendorId: resolvedReviewIds.vendorId,
        placeId: resolvedReviewIds.placeId,
        reviewId,
        content: replyDraft.trim(),
      });
      setReviewData((current) => current ? {
        ...current,
        reviews: current.reviews.map((review) => review.id === reviewId
          ? { ...review, reply: result.reply, repliedAt: result.repliedAt }
          : review),
      } : current);
      setReplyingToId(null);
      setReplyDraft('');
    } catch (err) {
      setReplyErrorMessage(getApiErrorMessage(err, 'Không thể gửi phản hồi'));
    } finally {
      setReplySubmitting(false);
    }
  };

  // ── Reviews render ────────────────────────────────────────────────────────────
  const renderReviews = () => {
    const reviews = locationData.reviews.list;
    const displayAverageRating = locationData.reviews.average;
    const displayTotalReviews = locationData.reviews.total;
    const displayBreakdown = locationData.reviews.distribution.reduce((accumulator, item) => {
      accumulator[item.score as 1 | 2 | 3 | 4 | 5] = { count: item.count, percent: item.percentage };
      return accumulator;
    }, { 5: { count: 0, percent: 0 }, 4: { count: 0, percent: 0 }, 3: { count: 0, percent: 0 }, 2: { count: 0, percent: 0 }, 1: { count: 0, percent: 0 } } as Record<1 | 2 | 3 | 4 | 5, { count: number; percent: number }>);

    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
        <div style={{ background: 'white', borderRadius: '24px', padding: '32px', border: '1px solid #F1F5F9', display: 'flex', gap: '48px', alignItems: 'center' }}>
          <div style={{ textAlign: 'center', paddingRight: '48px', borderRight: '1px solid #F1F5F9' }}>
            <h1 style={{ fontSize: '48px', fontWeight: '800', color: '#1e293b', marginBottom: '8px' }}>{displayAverageRating}</h1>
            <div style={{ display: 'flex', gap: '4px', justifyContent: 'center', color: '#fbbf24', marginBottom: '8px' }}>
              {[1, 2, 3, 4, 5].map((score) => (<Star key={score} size={20} fill="#fbbf24" color="#fbbf24" />))}
            </div>
            <p style={{ fontSize: '13px', color: '#94a3b8', fontWeight: '600' }}>{displayTotalReviews} đánh giá</p>
          </div>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {[5, 4, 3, 2, 1].map((score) => {
              const item = displayBreakdown[score as 1 | 2 | 3 | 4 | 5];
              return (
                <div key={score} style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <span style={{ fontSize: '13px', fontWeight: '800', color: '#64748b', minWidth: '12px' }}>{score}</span>
                  <div style={{ flex: 1, height: '8px', background: '#F8FAFC', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: `${item.percent}%`, background: '#3b82f6' }} />
                  </div>
                  <span style={{ fontSize: '12px', fontWeight: '600', color: '#94a3b8', minWidth: '32px' }}>{item.count}</span>
                </div>
              );
            })}
          </div>
        </div>

        <div>
          <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '20px', fontFamily: '"Outfit", sans-serif' }}>Bộ lọc đánh giá</h5>
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
            <select value={reviewRating ?? ''} onChange={(event) => setReviewRating(event.target.value ? Number(event.target.value) : undefined)} style={{ padding: '8px 16px', borderRadius: '10px', border: '1px solid #E2E8F0', fontSize: '13px', background: 'white' }}>
              <option value="">Tất cả sao</option>
              {[5, 4, 3, 2, 1].map((s) => <option key={s} value={s}>{s} sao</option>)}
            </select>
            <Button variant="outline" onClick={() => setReviewSort('newest')} style={{ borderRadius: '10px', fontSize: '13px', padding: '8px 20px', background: reviewSort === 'newest' ? '#EFF6FF' : 'white', borderColor: reviewSort === 'newest' ? '#3b82f6' : '#E2E8F0', color: reviewSort === 'newest' ? '#3b82f6' : '#64748b', fontWeight: '700' }}>Mới nhất</Button>
            <Button variant="outline" onClick={() => setReviewHasImages((current) => !current)} style={{ borderRadius: '10px', fontSize: '13px', padding: '8px 20px', color: reviewHasImages ? '#3b82f6' : '#64748b', borderColor: reviewHasImages ? '#3b82f6' : '#E2E8F0', background: reviewHasImages ? '#EFF6FF' : 'white' }}>Có hình ảnh</Button>
          </div>
        </div>

        {reviewLoading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8', background: 'white', borderRadius: '24px', border: '1px solid #F1F5F9' }}>Đang tải đánh giá...</div>
        ) : reviewError ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#ef4444', background: 'white', borderRadius: '24px', border: '1px solid #FEE2E2' }}>{reviewError}</div>
        ) : reviews.length === 0 ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8', background: 'white', borderRadius: '24px', border: '1px solid #F1F5F9' }}>Chưa có đánh giá nào cho địa điểm này</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            {reviews.map((review) => (
              <div key={review.id} style={{ background: 'white', borderRadius: '24px', padding: '32px', border: '1px solid #F1F5F9' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px' }}>
                  <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                    <img src={`https://picsum.photos/seed/${review.id}/100/100`} alt="Avatar" style={{ width: '48px', height: '48px', borderRadius: '50%', objectFit: 'cover' }} />
                    <div>
                      <p style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-primary)', marginBottom: '4px' }}>{review.user}</p>
                      <p style={{ fontSize: '12px', color: '#94a3b8' }}>Đã ghé thăm ngày {review.date}</p>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '4px', color: '#fbbf24' }}>
                    {[1, 2, 3, 4, 5].map((score) => (<Star key={score} size={16} fill={score <= review.rating ? '#fbbf24' : 'none'} color="#fbbf24" />))}
                  </div>
                </div>
                <p style={{ fontSize: '15px', color: '#475569', lineHeight: '1.7', marginBottom: '20px' }}>{review.content}</p>
                {review.images.length > 0 && (
                  <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', flexWrap: 'wrap' }}>
                    {review.images.map((image, index) => (<img key={`${review.id}-${index}`} src={image} alt="Review" style={{ width: '120px', height: '90px', borderRadius: '12px', objectFit: 'cover' }} />))}
                  </div>
                )}
                {review.reply && replyingToId !== review.id && (
                  <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '20px' }}>
                    <div style={{ maxWidth: '80%', padding: '16px 20px', background: '#F8FAFC', borderRadius: '12px', borderRight: '3px solid #3b82f6' }}>
                      {review.repliedAt && (
                        <p style={{ fontSize: '12px', fontWeight: '700', color: '#3b82f6', marginBottom: '6px', textAlign: 'right' }}>
                          {new Date(review.repliedAt).toLocaleDateString('vi-VN')}
                        </p>
                      )}
                      <p style={{ fontSize: '14px', color: '#475569', lineHeight: '1.6', textAlign: 'right' }}>{review.reply}</p>
                    </div>
                  </div>
                )}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px' }}>
                  <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                    {review.tags.map((tag) => (<span key={`${review.id}-${tag.name}`} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 12px', background: '#F1F5F9', color: tag.color, borderRadius: '8px', fontSize: '12px', fontWeight: '700' }}>{tag.name}</span>))}
                  </div>
                  <Button variant="outline" onClick={() => openReplyEditor(review.id, review.reply)} style={{ borderRadius: '10px', fontSize: '13px', padding: '6px 20px', color: '#3b82f6', borderColor: '#EFF6FF', background: '#EFF6FF' }}>
                    {replyingToId === review.id ? 'Hủy' : review.reply ? 'Chỉnh sửa' : 'Trả lời'}
                  </Button>
                </div>
                {replyingToId === review.id && (
                  <div style={{ marginTop: '24px', padding: '24px', background: '#F8FAFC', borderRadius: '16px', border: '1px solid #F1F5F9' }}>
                    <label style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', display: 'block', marginBottom: '12px' }}>Nội dung phản hồi khách hàng</label>
                    <textarea
                      value={replyDraft}
                      onChange={(event) => setReplyDraft(event.target.value)}
                      placeholder="Cảm ơn bạn đã phản hồi, chúng tôi sẽ sớm cải thiện..."
                      style={{ width: '100%', minHeight: '100px', padding: '16px', borderRadius: '12px', border: '1px solid #E2E8F0', outline: 'none', fontSize: '14px', lineHeight: '1.6', marginBottom: '16px', resize: 'vertical' }}
                    />
                    {replyErrorMessage && (
                      <p style={{ fontSize: '13px', color: '#ef4444', marginBottom: '12px' }}>{replyErrorMessage}</p>
                    )}
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                      <Button variant="outline" onClick={() => { setReplyingToId(null); setReplyErrorMessage(null); }} style={{ padding: '8px 20px', borderRadius: '8px', fontSize: '13px' }}>Hủy bỏ</Button>
                      <Button onClick={() => submitReply(review.id)} disabled={replySubmitting || !replyDraft.trim()} style={{ padding: '8px 24px', borderRadius: '8px', fontSize: '13px' }}>
                        {replySubmitting ? 'Đang gửi...' : 'Gửi phản hồi'}
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    );
  };

  // ── Services render ───────────────────────────────────────────────────────────
  const renderServiceEditor = (kind: ServiceKind) => {
    if (!serviceEditor || serviceEditor.kind !== kind) return null;
    const isEdit = serviceEditor.mode === 'edit';
    const editorTitle = kind === 'free'
      ? (isEdit ? 'Chỉnh sửa tiện ích' : 'Thêm tiện ích mới')
      : (isEdit ? 'Chỉnh sửa dịch vụ' : 'Thêm dịch vụ mới');
    return (
      <div style={{ marginBottom: '24px', padding: '24px', background: '#F8FAFC', border: '1px solid #E2E8F0', borderRadius: '20px' }}>
        <p style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b', marginBottom: '20px' }}>{editorTitle}</p>
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ flex: '1 1 280px' }}><Input label={kind === 'free' ? 'Tên tiện ích' : catalogMode === 'accommodation' ? 'Tên loại phòng' : 'Tên món'} value={serviceDraft.name} onChange={(event) => setServiceDraft((current) => ({ ...current, name: event.target.value }))} style={{ marginBottom: 0 }} /></div>
          {kind === 'paid' && catalogMode === 'food' && <div style={{ flex: '1 1 360px' }}><Input label="Mô tả" value={serviceDraft.description} onChange={(event) => setServiceDraft((current) => ({ ...current, description: event.target.value }))} style={{ marginBottom: 0 }} /></div>}
          {kind === 'paid' && (<div style={{ flex: '1 1 180px' }}><Input label="Giá (VNĐ)" value={serviceDraft.price} onChange={(event) => setServiceDraft((current) => ({ ...current, price: event.target.value.replace(/[^\d]/g, '') }))} style={{ marginBottom: 0 }} placeholder="Ví dụ: 35000" inputMode="numeric" /></div>)}
          {kind === 'paid' && catalogMode === 'accommodation' && (<div style={{ flex: '1 1 180px' }}><Input label="Sức chứa/phòng" value={serviceDraft.quantity} onChange={(event) => setServiceDraft((current) => ({ ...current, quantity: event.target.value.replace(/[^\d]/g, '') }))} style={{ marginBottom: 0 }} placeholder="Ví dụ: 2" inputMode="numeric" /></div>)}
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
          <Button variant="outline" onClick={closeServiceEditor} disabled={serviceSaving}>Hủy</Button>
          <Button onClick={saveService} disabled={serviceSaving} style={{ gap: '8px' }}>
            {serviceSaving ? <><Loader2 size={16} className="animate-spin" /> Đang lưu...</> : (isEdit ? 'Cập nhật' : 'Thêm mới')}
          </Button>
        </div>
      </div>
    );
  };

  const renderServicesMenu = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '48px' }}>
      {serviceMessage && (
        <div style={{ padding: '12px 20px', borderRadius: '12px', fontSize: '14px', fontWeight: '600', background: serviceMessage.type === 'success' ? '#f0fdf4' : '#fef2f2', color: serviceMessage.type === 'success' ? '#16a34a' : '#dc2626', border: `1px solid ${serviceMessage.type === 'success' ? '#bbf7d0' : '#fecaca'}` }}>
          {serviceMessage.text}
        </div>
      )}
      <div style={{ display: catalogMode === 'service' ? 'none' : 'block' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>Tiện ích miễn phí</h5>
          <Button variant="outline" onClick={() => openServiceEditor('free')} style={{ borderRadius: '10px', fontSize: '13px', gap: '8px', padding: '8px 16px' }}><Plus size={16} /> Thêm tiện ích</Button>
        </div>
        {renderServiceEditor('free')}
        {servicesLoading ? (
          <div style={{ padding: '32px', textAlign: 'center', color: '#94a3b8', background: 'white', borderRadius: '20px', border: '1px solid #F1F5F9' }}>Đang tải tiện ích...</div>
        ) : servicesError ? (
          <div style={{ padding: '32px', textAlign: 'center', color: '#ef4444', background: 'white', borderRadius: '20px', border: '1px solid #FEE2E2' }}>{servicesError}</div>
        ) : (
          <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
            {freeServices.map((service) => (
              <div key={service.id} style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', padding: '14px 18px', background: '#F8FAFC', border: '1px solid #E2E8F0', color: '#334155', borderRadius: '20px', fontSize: '13px', fontWeight: '600', minWidth: '220px' }}>
                <div style={{ marginTop: '2px', color: '#64748b' }}>{getServiceIcon(service.name)}</div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', flex: 1 }}>
                  <span>{service.name}</span>
                  {service.description && <span style={{ fontSize: '12px', color: '#64748b', fontWeight: '400' }}>{service.description}</span>}
                </div>
                <div style={{ display: 'flex', gap: '8px', color: '#94a3b8' }}>
                  <Edit2 size={16} style={{ cursor: 'pointer' }} onClick={() => openServiceEditor('free', service)} />
                  <Trash2 size={16} style={{ cursor: 'pointer' }} onClick={() => deleteService('free', service.id)} />
                </div>
              </div>
            ))}
            <div onClick={() => openServiceEditor('free')} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '12px 24px', border: '1px solid #E2E8F0', borderStyle: 'dashed', color: '#94a3b8', borderRadius: '20px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', background: 'transparent' }}>
              <Plus size={16} /> <span>Thêm tiện ích</span>
            </div>
          </div>
        )}
      </div>

      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>{catalogMode === 'accommodation' ? 'Phòng' : 'Món ăn'} ({menuItems.length})</h5>
          <Button variant="outline" onClick={() => openServiceEditor('paid')} style={{ borderRadius: '10px', fontSize: '13px', gap: '8px', padding: '8px 16px' }}><Plus size={16} /> Thêm {catalogMode === 'accommodation' ? 'phòng' : 'món'}</Button>
        </div>
        {renderServiceEditor('paid')}
        <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', overflow: 'hidden', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
          {servicesLoading ? (
            <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>Đang tải dịch vụ...</div>
          ) : servicesError ? (
            <div style={{ padding: '48px', textAlign: 'center', color: '#ef4444', fontSize: '14px' }}>{servicesError}</div>
          ) : menuItems.length > 0 ? (
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ textAlign: 'left', background: '#FCFCFD', borderBottom: '1px solid #F1F5F9' }}>
                  {(catalogMode === 'accommodation' ? ['Tên loại phòng', 'Sức chứa', 'Giá', ''] : ['Tên món', 'Mô tả', 'Giá', '']).map((h, i) => (
                    <th key={`${h}-${i}`} style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: i === 2 ? 'left' : i === 3 ? 'right' : 'left' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {menuItems.map((item, index) => (
                  <tr key={item.id} style={{ borderBottom: index < menuItems.length - 1 ? '1px solid #F8FAFC' : 'none' }}>
                    <td style={{ padding: '24px 32px', fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{item.name}</td>
                    <td style={{ padding: '24px 32px', fontSize: '14px', color: '#64748b' }}>{catalogMode === 'accommodation' ? `${item.quantity || 1} khách/phòng` : item.description || '-'}</td>
                    <td style={{ padding: '24px 32px', fontSize: '15px', fontWeight: '800', color: '#3b82f6' }}>{formatPrice(item.price)}</td>
                    <td style={{ padding: '24px 32px', textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end', color: '#94a3b8' }}>
                        <Edit2 size={16} style={{ cursor: 'pointer', color: '#3b82f6' }} onClick={() => openServiceEditor('paid', item)} />
                        <Trash2 size={16} style={{ cursor: 'pointer', color: '#ef4444' }} onClick={() => deleteService('paid', item.id)} />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>
              <p style={{ marginBottom: '16px' }}>Chưa có dịch vụ nào</p>
              <button onClick={() => openServiceEditor('paid')} style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '10px 24px', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '10px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}>
                <Plus size={16} /> Thêm dịch vụ đầu tiên
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );

  // ── Main render ───────────────────────────────────────────────────────────────
  return (
    <>
      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>Đang tải dữ liệu địa điểm...</div>
      ) : error ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#ef4444' }}>{error}</div>
      ) : (
        <div style={{ padding: '0 20px' }}>
          {/* Header */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '32px' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#94a3b8', marginBottom: '12px' }}>
                <span style={{ cursor: 'pointer' }} onClick={() => navigate('/locations')}>Danh sách địa điểm</span>
                <span>/</span>
                <span style={{ color: '#1e293b', fontWeight: '700' }}>{pageTitle}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
                <h2 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>{pageTitle}</h2>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '4px 12px', background: `${statusMeta.color}10`, borderRadius: '8px', color: statusMeta.color, fontSize: '12px', fontWeight: '700' }}>
                  <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: statusMeta.color }} />
                  {statusMeta.label}
                </div>
              </div>
            </div>
          </div>

          {place?.statusLabel === 'Từ chối' && (
            <div
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: '10px',
                padding: '14px 18px',
                marginBottom: '24px',
                background: '#fef2f2',
                border: '1px solid #fecaca',
                borderLeft: '4px solid #ef4444',
                borderRadius: '12px',
              }}
            >
              <AlertCircle size={18} color="#ef4444" style={{ flexShrink: 0, marginTop: '1px' }} />
              <div style={{ fontSize: '13.5px', lineHeight: 1.5 }}>
                <span style={{ fontWeight: '700', color: '#991b1b' }}>Lý do từ chối: </span>
                <span style={{ color: '#7f1d1d' }}>
                  {place.rejectionReason || 'Chưa cung cấp lý do cụ thể.'}
                </span>
              </div>
            </div>
          )}

          {/* Tabs */}
          <div style={{ display: 'flex', gap: '32px', marginBottom: '32px', borderBottom: '1px solid #F1F5F9' }}>
            {(['Thông tin chung', 'Đánh giá', 'Dịch vụ'] as TabKey[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{ padding: '12px 0', fontSize: '14px', fontWeight: activeTab === tab ? '700' : '600', color: activeTab === tab ? '#3b82f6' : '#64748b', background: 'transparent', border: 'none', borderBottom: activeTab === tab ? '2px solid #3b82f6' : '2px solid transparent', cursor: 'pointer', transition: 'all 0.2s ease', marginBottom: '-1px' }}
              >
                {tab}
              </button>
            ))}
          </div>

          {activeTab === 'Dịch vụ' ? renderServicesMenu() : activeTab === 'Đánh giá' ? renderReviews() : renderGeneralInfo()}
        </div>
      )}
    </>
  );
};

export default LocationEditPage;
