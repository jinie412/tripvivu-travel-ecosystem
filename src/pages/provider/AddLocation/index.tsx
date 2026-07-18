import React, { useState, useEffect, useCallback, useRef } from 'react';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import {
  Clock,
  ArrowRight,
  ArrowLeft,
  MapPin,
  Plus,
  Trash2,
  Edit2,
  Upload,
  Wifi,
  FileSpreadsheet,
  CheckCircle,
  RefreshCw,
  Loader2,
  Search,
  Download,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { addNewPlace, fetchAllServices, uploadFoodDraftImage, uploadPlaceImage } from '@/services/order.service';
import { apiClient, extractResponseData } from '@/services/apiClient';
import { getCurrentUser } from '@/utils/auth';
import * as XLSX from 'xlsx';
import defaultServiceIcon from '@/assets/images/service_icon_default.jpg';
import Swal from 'sweetalert2';

type CityOption = { id: string; name: string };
type BusinessTypeOption = { id: string; name: string; category_name?: string | null };
type AmenityDraft = { id: string; name: string; description: string; icon: React.ReactNode };
type MenuDraft = { id: string; name: string; description: string; price: string; quantity?: string; img: string; imageFile?: File | null; previewUrl?: string };
type MenuColumnKey = 'name' | 'price' | 'description';
type MenuColumnMapping = Record<MenuColumnKey, string>;
type ExcelRow = Record<string, unknown>;

const MENU_COLUMNS: Array<{ key: MenuColumnKey; label: string; aliases: string[] }> = [
  { key: 'name', label: 'Tên món', aliases: ['ten mon', 'ten', 'name', 'item', 'product'] },
  { key: 'price', label: 'Giá bán', aliases: ['gia ban', 'gia', 'price', 'cost', 'value'] },
  { key: 'description', label: 'Mô tả', aliases: ['mo ta', 'description', 'ghi chu', 'note'] },
];

const normalizeColumnName = (value: string) => value
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .toLowerCase()
  .trim();

const parseMappedMenuRows = (rows: ExcelRow[], mapping: MenuColumnMapping) => rows.map(row => {
  const rawPrice = row[mapping.price];
  const numericPrice = typeof rawPrice === 'number'
    ? rawPrice
    : Number(String(rawPrice ?? '').replace(/[^\d-]/g, ''));
  return {
    name: String(row[mapping.name] ?? '').trim(),
    price: numericPrice > 0 ? String(numericPrice) : '',
    description: String(row[mapping.description] ?? '').trim(),
  };
}).filter(item => item.name && item.price);
type WeekdayKey = 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday';
type DayHours = { enabled: boolean; openTime: string; closeTime: string };
type WeeklyHours = Record<WeekdayKey, DayHours>;
type OpeningHourGroup = { id: string; days: WeekdayKey[]; openTime: string; closeTime: string };
type AddLocationFormData = {
  name: string;
  address: string;
  city: string;
  phone: string;
  email: string;
  latitude: number;
  longitude: number;
  type: string;
  typeId: string;
  openTime: string;
  closeTime: string;
  weeklyHours: WeeklyHours;
  openingHourGroups: OpeningHourGroup[];
  description: string;
  estimatedPreparationTime: string;
  amenities: AmenityDraft[];
  menu: MenuDraft[];
};

const WEEKDAY_OPTIONS: Array<{ key: WeekdayKey; label: string }> = [
  { key: 'Monday', label: 'Thứ 2' },
  { key: 'Tuesday', label: 'Thứ 3' },
  { key: 'Wednesday', label: 'Thứ 4' },
  { key: 'Thursday', label: 'Thứ 5' },
  { key: 'Friday', label: 'Thứ 6' },
  { key: 'Saturday', label: 'Thứ 7' },
  { key: 'Sunday', label: 'Chủ nhật' },
];

const createDefaultWeeklyHours = (openTime = '08:00', closeTime = '22:00'): WeeklyHours => ({
  Monday: { enabled: true, openTime, closeTime },
  Tuesday: { enabled: true, openTime, closeTime },
  Wednesday: { enabled: true, openTime, closeTime },
  Thursday: { enabled: true, openTime, closeTime },
  Friday: { enabled: true, openTime, closeTime },
  Saturday: { enabled: true, openTime, closeTime },
  Sunday: { enabled: true, openTime, closeTime },
});

const createDefaultOpeningHourGroups = (openTime = '08:00', closeTime = '22:00'): OpeningHourGroup[] => ([
  {
    id: 'default',
    days: WEEKDAY_OPTIONS.map((day) => day.key),
    openTime,
    closeTime,
  },
]);

const buildWeeklyHoursFromGroups = (groups: OpeningHourGroup[]): WeeklyHours => {
  const weeklyHours = WEEKDAY_OPTIONS.reduce((result, day) => {
    result[day.key] = { enabled: false, openTime: '08:00', closeTime: '22:00' };
    return result;
  }, {} as WeeklyHours);

  groups.forEach((group) => {
    group.days.forEach((day) => {
      weeklyHours[day] = {
        enabled: true,
        openTime: group.openTime,
        closeTime: group.closeTime,
      };
    });
  });

  return weeklyHours;
};

const buildOpeningHourGroupsFromWeeklyHours = (weeklyHours: WeeklyHours): OpeningHourGroup[] => {
  const grouped = new Map<string, OpeningHourGroup>();

  WEEKDAY_OPTIONS.forEach((day) => {
    const item = weeklyHours[day.key];
    if (!item.enabled) return;

    const groupKey = `${item.openTime}|${item.closeTime}`;
    const existing = grouped.get(groupKey);
    if (existing) {
      existing.days.push(day.key);
      return;
    }

    grouped.set(groupKey, {
      id: groupKey,
      days: [day.key],
      openTime: item.openTime,
      closeTime: item.closeTime,
    });
  });

  const groups = Array.from(grouped.values());
  return groups.length > 0 ? groups : createDefaultOpeningHourGroups();
};

const normalizeTimeForCompressedHours = (value: string): string => {
  if (!value) return '';
  return value.length === 5 ? `${value}:00` : value;
};

const buildOpenHourCompressed = (weeklyHours: WeeklyHours): Record<WeekdayKey, [string, string][]> => {
  return WEEKDAY_OPTIONS.reduce((result, day) => {
    const item = weeklyHours[day.key];
    result[day.key] = item.enabled && item.openTime && item.closeTime
      ? [[normalizeTimeForCompressedHours(item.openTime), normalizeTimeForCompressedHours(item.closeTime)]]
      : [];
    return result;
  }, {} as Record<WeekdayKey, [string, string][]>);
};

const getPrimaryOpenCloseTime = (weeklyHours: WeeklyHours): { openTime: string; closeTime: string } => {
  const firstOpenDay = WEEKDAY_OPTIONS
    .map((day) => weeklyHours[day.key])
    .find((item) => item.enabled && item.openTime && item.closeTime);

  return {
    openTime: firstOpenDay?.openTime || '08:00',
    closeTime: firstOpenDay?.closeTime || '22:00',
  };
};

const isFoodCategory = (categoryName?: string | null): boolean => {
  const lower = (categoryName ?? '').toLowerCase();
  return lower.includes('ẩm thực') || lower.includes('nhà hàng') || lower.includes('ăn uống');
};

const isAccommodationCategory = (...values: Array<string | null | undefined>): boolean => {
  const normalized = values
    .filter((value): value is string => typeof value === 'string')
    .join(' ')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();

  return normalized.includes('luu tru')
    || normalized.includes('khach san')
    || normalized.includes('hotel')
    || normalized.includes('homestay')
    || normalized.includes('resort')
    || normalized.includes('accommodation');
};
type AddLocationDraft = {
  step: number;
  fileUploaded: boolean;
  serviceMode: 'free' | 'paid';
  formData: Omit<AddLocationFormData, 'amenities' | 'menu'> & {
    amenities: Array<Omit<AmenityDraft, 'icon'>>;
    menu: Array<Omit<MenuDraft, 'imageFile' | 'previewUrl'>>;
  };
};

const ADD_LOCATION_DRAFT_KEY = 'provider:add-location:draft:v1';
const DEFAULT_ADD_LOCATION_FORM_DATA: AddLocationFormData = {
  name: '',
  address: '',
  city: '',
  phone: '',
  email: '',
  latitude: 10.77,
  longitude: 106.7,
  type: '',
  typeId: '',
  openTime: '08:00',
  closeTime: '22:00',
  weeklyHours: createDefaultWeeklyHours(),
  openingHourGroups: createDefaultOpeningHourGroups(),
  description: '',
  estimatedPreparationTime: '',
  amenities: [],
  menu: [],
};

const isBrowser = () => typeof window !== 'undefined';

const shouldRestoreAddLocationDraft = () => {
  if (!isBrowser()) return false;
  return new URLSearchParams(window.location.search).get('resumeDraft') === '1';
};

const restoreAddLocationDraft = (): AddLocationDraft | null => {
  if (!isBrowser()) return null;
  if (!shouldRestoreAddLocationDraft()) {
    window.localStorage.removeItem(ADD_LOCATION_DRAFT_KEY);
    return null;
  }

  try {
    const raw = window.localStorage.getItem(ADD_LOCATION_DRAFT_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<AddLocationDraft>;
    if (!parsed.formData || typeof parsed.formData !== 'object') return null;
    const restoredWeeklyHours = parsed.formData.weeklyHours ?? createDefaultWeeklyHours(
      String(parsed.formData.openTime ?? DEFAULT_ADD_LOCATION_FORM_DATA.openTime),
      String(parsed.formData.closeTime ?? DEFAULT_ADD_LOCATION_FORM_DATA.closeTime),
    );
    const restoredOpeningHourGroups = Array.isArray(parsed.formData.openingHourGroups)
      ? parsed.formData.openingHourGroups
      : buildOpeningHourGroupsFromWeeklyHours(restoredWeeklyHours);

    return {
      step: typeof parsed.step === 'number' ? Math.min(Math.max(parsed.step, 1), 3) : 1,
      fileUploaded: Boolean(parsed.fileUploaded),
      serviceMode: parsed.serviceMode === 'paid' ? 'paid' : 'free',
      formData: {
        ...DEFAULT_ADD_LOCATION_FORM_DATA,
        ...parsed.formData,
        phone: String(parsed.formData.phone ?? '').replace(/\D/g, '').slice(0, 10),
        latitude: Number(parsed.formData.latitude) || DEFAULT_ADD_LOCATION_FORM_DATA.latitude,
        longitude: Number(parsed.formData.longitude) || DEFAULT_ADD_LOCATION_FORM_DATA.longitude,
        weeklyHours: buildWeeklyHoursFromGroups(restoredOpeningHourGroups),
        openingHourGroups: restoredOpeningHourGroups,
        amenities: Array.isArray(parsed.formData.amenities) ? parsed.formData.amenities : [],
        menu: Array.isArray(parsed.formData.menu) ? parsed.formData.menu : [],
      },
    };
  } catch {
    return null;
  }
};

const buildRestoredFormData = (draft: AddLocationDraft | null): AddLocationFormData => ({
  ...(draft?.formData ?? DEFAULT_ADD_LOCATION_FORM_DATA),
  amenities: (draft?.formData.amenities ?? []).map((item) => ({
    id: item.id || Date.now().toString(),
    name: item.name || '',
    description: item.description || '',
    icon: <Wifi size={18} />,
  })),
  menu: (draft?.formData.menu ?? []).map((item) => ({
    id: item.id || Date.now().toString(),
    name: item.name || '',
    description: item.description || '',
    price: item.price || '',
    quantity: item.quantity || '1',
    img: item.img || '',
    imageFile: null,
    previewUrl: '',
  })),
});

const buildPersistableFormData = (formData: AddLocationFormData): AddLocationDraft['formData'] => ({
  ...formData,
  amenities: formData.amenities.map(({ id, name, description }) => ({ id, name, description })),
  menu: formData.menu.map(({ id, name, description, price, quantity, img }) => ({ id, name, description, price, quantity, img })),
});

const PRESET_FREE_SERVICES = [
  { name: 'Trà đá miễn phí', description: '' },
  { name: 'Nước lọc miễn phí', description: '' },
  { name: 'Giữ xe miễn phí', description: '' },
  { name: 'Wifi miễn phí', description: '' },
];

const VIETNAM_BOUNDS = {
  minLat: 8.18,
  maxLat: 23.39,
  minLng: 102.14,
  maxLng: 109.47,
};
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
    const response = await fetch(`https://nominatim.openstreetmap.org/search?${params.toString()}`, {
      headers: { Accept: 'application/json' },
    });

    if (!response.ok) {
      throw new Error('Không thể kết nối dịch vụ bản đồ.');
    }

    const results: GeocodeResult[] = await response.json();
    const bestResult = pickBestGeocodeResult(results, city, address);
    if (bestResult) return bestResult;
  }

  return null;
};

const AddLocationPage: React.FC = () => {
  const navigate = useNavigate();
  const mapRef = useRef<HTMLDivElement | null>(null);
  const [restoredDraft] = useState(() => restoreAddLocationDraft());
  const [step, setStep] = useState(() => restoredDraft?.step ?? 1);
  const [fileUploaded, setFileUploaded] = useState(() => restoredDraft?.fileUploaded ?? false);
  const [showExcelImport, setShowExcelImport] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isGeocoding, setIsGeocoding] = useState(false);
  const [geocodeError, setGeocodeError] = useState('');
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [selectedImages, setSelectedImages] = useState<Array<{ file: File; previewUrl: string }>>([]);
  const [mapSize, setMapSize] = useState(DEFAULT_MAP_SIZE);
  const [mapZoom, setMapZoom] = useState(MAP_ZOOM);
  // Service input state
  const [serviceInput, setServiceInput] = useState({ name: '', description: '' });
  const [serviceMode, setServiceMode] = useState<'free' | 'paid'>(() => restoredDraft?.serviceMode ?? 'free');

  // Menu item input state
  const [menuInput, setMenuInput] = useState<{
    name: string;
    description: string;
    price: string;
    quantity: string;
    img: string;
    imageFile: File | null;
    previewUrl: string;
  }>({ name: '', description: '', price: '', quantity: '1', img: '', imageFile: null, previewUrl: '' });
  const [editingMenuId, setEditingMenuId] = useState<string | null>(null);

  // Excel preview state
  const [excelPreviewItems, setExcelPreviewItems] = useState<{ name: string; price: string; description: string }[]>([]);
  const [showExcelPreview, setShowExcelPreview] = useState(false);
  const [excelHeaders, setExcelHeaders] = useState<string[]>([]);
  const [excelRows, setExcelRows] = useState<ExcelRow[]>([]);
  const [columnMapping, setColumnMapping] = useState<MenuColumnMapping>({ name: '', price: '', description: '' });

  // DB services cache for dedup check
  const [dbServices, setDbServices] = useState<Array<{ id: string; name: string }>>([]);

  useEffect(() => {
    fetchAllServices().then(setDbServices);
  }, []);

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
  }, [step]);

  const [formData, setFormData] = useState<AddLocationFormData>(() => buildRestoredFormData(restoredDraft));

  useEffect(() => {
    if (!isBrowser()) return;

    const draft: AddLocationDraft = {
      step,
      fileUploaded,
      serviceMode,
      formData: buildPersistableFormData(formData),
    };

    window.localStorage.setItem(ADD_LOCATION_DRAFT_KEY, JSON.stringify(draft));
  }, [fileUploaded, formData, serviceMode, step]);

  const [cities, setCities] = useState<CityOption[]>([]);
  const [loadingCities, setLoadingCities] = useState(true);
  const [citiesError, setCitiesError] = useState<string | null>(null);
  const [businessTypes, setBusinessTypes] = useState<BusinessTypeOption[]>([]);
  const [loadingBusinessTypes, setLoadingBusinessTypes] = useState(true);
  const [businessTypesError, setBusinessTypesError] = useState<string | null>(null);

  const loadCities = useCallback(async () => {
    setLoadingCities(true);
    setCitiesError(null);

    try {
      const response = await apiClient.get<CityOption[] | { data: CityOption[] }>('/cities');
      const data = extractResponseData<CityOption[]>(response as any);

      const list: CityOption[] = Array.isArray(data)
        ? data
          .map((item: any) => ({
            id: String(item.id ?? item.city_id ?? item.code ?? item.name ?? item.city_name ?? item.city ?? item.province ?? ''),
            name: String(item.name ?? item.city_name ?? item.city ?? item.province ?? ''),
          }))
          .filter((item) => item.id && item.name)
          .sort((a, b) => a.name.localeCompare(b.name, 'vi'))
        : [];

      if (list.length === 0) {
        throw new Error('Danh sách tỉnh/thành từ hệ thống đang trống.');
      }

      setCities(list);
      setFormData((prev) => ({
        ...prev,
        city: list.some((city) => city.name === prev.city) ? prev.city : '',
      }));
    } catch (error) {
      console.error('[cities] Load failed:', error);
      setCities([]);
      setFormData((prev) => ({ ...prev, city: '' }));
      setCitiesError(error instanceof Error ? error.message : 'Không thể tải danh sách tỉnh/thành.');
    } finally {
      setLoadingCities(false);
    }
  }, []);

  useEffect(() => {
    loadCities();
  }, [loadCities]);

  const loadBusinessTypes = useCallback(async () => {
    setLoadingBusinessTypes(true);
    setBusinessTypesError(null);

    try {
      const response = await apiClient.get<BusinessTypeOption[] | { data: BusinessTypeOption[] }>('/types');
      const data = extractResponseData<BusinessTypeOption[]>(response as any);

      const list: BusinessTypeOption[] = Array.isArray(data)
        ? data
          .map((item: any) => ({
            id: String(item.id ?? item.type_id ?? item.code ?? item.name ?? item.type_name ?? ''),
            name: String(item.name ?? item.type_name ?? ''),
            category_name: item.category_name ?? null,
          }))
          .filter((item) => item.id && item.name)
          .sort((a, b) => a.name.localeCompare(b.name, 'vi'))
        : [];

      if (list.length === 0) {
        throw new Error('Danh sách loại hình kinh doanh từ hệ thống đang trống.');
      }

      setBusinessTypes(list);
      setFormData((prev) => ({
        ...prev,
        type: list.some((type) => type.id === prev.typeId && type.name === prev.type) ? prev.type : '',
        typeId: list.some((type) => type.id === prev.typeId && type.name === prev.type) ? prev.typeId : '',
      }));
    } catch (error) {
      console.error('[business-types] Load failed:', error);
      setBusinessTypes([]);
      setFormData((prev) => ({ ...prev, type: '', typeId: '' }));
      setBusinessTypesError(error instanceof Error ? error.message : 'Không thể tải danh sách loại hình kinh doanh.');
    } finally {
      setLoadingBusinessTypes(false);
    }
  }, []);

  useEffect(() => {
    loadBusinessTypes();
  }, [loadBusinessTypes]);

  const phoneError = formData.phone && !/^0\d{9}$/.test(formData.phone)
    ? 'SĐT phải gồm đúng 10 chữ số và bắt đầu bằng số 0.'
    : '';
  const emailError = formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)
    ? 'Email không đúng định dạng.'
    : '';
  const hasValidCity = !loadingCities && !citiesError && cities.some((city) => city.name === formData.city);
  const hasValidBusinessType = !loadingBusinessTypes
    && !businessTypesError
    && businessTypes.some((type) => type.id === formData.typeId && type.name === formData.type);
  const canProceedFromStep1 = Boolean(
    formData.name
    && formData.address
    && formData.type
    && hasValidCity
    && hasValidBusinessType
    && formData.phone
    && !phoneError
    && formData.email
    && !emailError,
  );
  const selectedBusinessType = businessTypes.find((type) => type.id === formData.typeId);
  const isAccommodation = isAccommodationCategory(
    selectedBusinessType?.category_name,
    selectedBusinessType?.name,
    formData.type,
  );

  const handlePhoneChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const digitsOnly = event.target.value.replace(/\D/g, '').slice(0, 10);
    setFormData({ ...formData, phone: digitsOnly });
  };

  const handleMapClick = (event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = clamp(event.clientX - rect.left, 0, rect.width);
    const clickY = clamp(event.clientY - rect.top, 0, rect.height);
    const center = latLngToWorldPixel(formData.latitude, formData.longitude, mapZoom);
    const worldX = center.x - rect.width / 2 + clickX;
    const worldY = center.y - rect.height / 2 + clickY;
    const { lat, lng } = worldPixelToLatLng(worldX, worldY, mapZoom);
    const latitude = clamp(lat, VIETNAM_BOUNDS.minLat, VIETNAM_BOUNDS.maxLat);
    const longitude = clamp(lng, VIETNAM_BOUNDS.minLng, VIETNAM_BOUNDS.maxLng);

    setMapZoom(SELECTED_LOCATION_ZOOM);
    setFormData((prev) => ({
      ...prev,
      latitude: Number(latitude.toFixed(6)),
      longitude: Number(longitude.toFixed(6)),
    }));
  };

  const handleFindOnMap = async () => {
    if (!formData.address.trim() || !formData.city.trim()) {
      setGeocodeError('Vui lòng nhập địa chỉ và chọn tỉnh/thành trước khi tìm trên bản đồ.');
      return;
    }

    try {
      setIsGeocoding(true);
      setGeocodeError('');

      const firstResult = await geocodeAddress(formData.address, formData.city, formData.name);

      if (!firstResult) {
        throw new Error('Không tìm thấy vị trí phù hợp. Vui lòng thử nhập địa chỉ rõ hơn hoặc chọn thủ công trên bản đồ.');
      }

      const latitude = clamp(Number(firstResult.lat), VIETNAM_BOUNDS.minLat, VIETNAM_BOUNDS.maxLat);
      const longitude = clamp(Number(firstResult.lon), VIETNAM_BOUNDS.minLng, VIETNAM_BOUNDS.maxLng);

      if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
        throw new Error('Dịch vụ bản đồ trả về tọa độ không hợp lệ.');
      }

      setMapZoom(SELECTED_LOCATION_ZOOM);
      setFormData((prev) => ({
        ...prev,
        latitude: Number(latitude.toFixed(6)),
        longitude: Number(longitude.toFixed(6)),
      }));
    } catch (error) {
      console.error('[map] Geocoding failed:', error);
      setGeocodeError(error instanceof Error ? error.message : 'Không thể tìm vị trí trên bản đồ.');
    } finally {
      setIsGeocoding(false);
    }
  };

  const validateBasicInfo = () => {
    if (!formData.name || !formData.address || !formData.phone || !formData.email || !formData.type || !formData.typeId) {
      Swal.fire({ text: 'Vui lòng điền đầy đủ thông tin tại Bước 1', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (phoneError) {
      Swal.fire({ text: 'SĐT liên hệ phải gồm đúng 10 chữ số và bắt đầu bằng số 0.', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (emailError) {
      Swal.fire({ text: 'Email liên hệ không đúng định dạng.', icon: 'warning' });
      setStep(1);
      return false;
    }

    const openDays = WEEKDAY_OPTIONS
      .map((day) => formData.weeklyHours[day.key])
      .filter((item) => item.enabled);

    if (openDays.length === 0) {
      Swal.fire({ text: 'Vui lòng chọn ít nhất một ngày mở cửa.', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (openDays.some((item) => !item.openTime || !item.closeTime || item.openTime >= item.closeTime)) {
      Swal.fire({ text: 'Giờ mở cửa theo ngày chưa hợp lệ. Giờ đóng cửa phải sau giờ mở cửa.', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (loadingCities) {
      Swal.fire({ text: 'Danh sách tỉnh/thành đang tải. Vui lòng chờ trong giây lát.', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (citiesError || cities.length === 0) {
      Swal.fire({ text: 'Không thể tải danh sách tỉnh/thành từ hệ thống. Vui lòng bấm "Tải lại" trước khi tiếp tục.', icon: 'error' });
      setStep(1);
      return false;
    }

    if (!cities.some((city) => city.name === formData.city)) {
      Swal.fire({ text: 'Vui lòng chọn tỉnh/thành hợp lệ từ danh sách hệ thống.', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (loadingBusinessTypes) {
      Swal.fire({ text: 'Danh sách loại hình kinh doanh đang tải. Vui lòng chờ trong giây lát.', icon: 'warning' });
      setStep(1);
      return false;
    }

    if (businessTypesError || businessTypes.length === 0) {
      Swal.fire({ text: 'Không thể tải danh sách loại hình kinh doanh từ hệ thống. Vui lòng bấm "Tải lại" trước khi tiếp tục.', icon: 'error' });
      setStep(1);
      return false;
    }

    if (!businessTypes.some((type) => type.id === formData.typeId && type.name === formData.type)) {
      Swal.fire({ text: 'Vui lòng chọn loại hình kinh doanh hợp lệ từ danh sách hệ thống.', icon: 'warning' });
      setStep(1);
      return false;
    }

    return true;
  };


  const handleAddService = () => {
    if (!serviceInput.name.trim()) {
      Swal.fire({ text: 'Vui lòng nhập tên dịch vụ', icon: 'warning' });
      return;
    }

    const newService = {
      id: Date.now().toString(),
      name: serviceInput.name,
      description: serviceInput.description,
      icon: <Wifi size={18} />
    };

    setFormData(prev => ({
      ...prev,
      amenities: [...prev.amenities, newService]
    }));

    setServiceInput({ name: '', description: '' });
  };

  const handleRemoveService = (id: string) => {
    setFormData(prev => ({
      ...prev,
      amenities: prev.amenities.filter(a => a.id !== id)
    }));
  };

  const handleAddMenuItem = () => {
    if (!menuInput.name.trim() || !menuInput.price.trim()) {
      Swal.fire({ text: isAccommodation ? 'Vui long nhap ten phong va gia phong' : 'Vui long nhap ten va gia cua mon an', icon: 'warning' });
      return;
    }

    const price = parseFloat(menuInput.price);
    if (Number.isNaN(price) || price <= 0) {
      Swal.fire({ text: 'Gia dich vu co phi phai lon hon 0', icon: 'warning' });
      return;
    }

    const quantity = parseInt(menuInput.quantity || '1', 10);
    if (isAccommodation && (!Number.isFinite(quantity) || quantity <= 0)) {
      Swal.fire({ text: 'Suc chua phong phai lon hon 0', icon: 'warning' });
      return;
    }

    const newMenuItem = {
      id: Date.now().toString(),
      name: menuInput.name,
      description: menuInput.description,
      price: menuInput.price,
      quantity: String(quantity),
      img: menuInput.img || '',
      imageFile: menuInput.imageFile,
      previewUrl: menuInput.previewUrl,
    };

    setFormData(prev => ({
      ...prev,
      menu: [...prev.menu, newMenuItem]
    }));

    setMenuInput({ name: '', description: '', price: '', quantity: '1', img: '', imageFile: null, previewUrl: '' });
  };

  const handleEditMenuItem = (id: string) => {
    const item = formData.menu.find(m => m.id === id);
    if (!item) return;
    setEditingMenuId(id);
    setMenuInput({
      name: item.name,
      description: item.description,
      price: item.price,
      quantity: item.quantity || '1',
      img: item.img || '',
      imageFile: item.imageFile ?? null,
      previewUrl: item.previewUrl || '',
    });
  };

  const handleUpdateMenuItem = () => {
    if (!menuInput.name.trim() || !menuInput.price.trim()) {
      Swal.fire({ text: isAccommodation ? 'Vui long nhap ten phong va gia phong' : 'Vui long nhap ten va gia cua mon an', icon: 'warning' });
      return;
    }

    const price = parseFloat(menuInput.price);
    if (Number.isNaN(price) || price <= 0) {
      Swal.fire({ text: 'Gia dich vu co phi phai lon hon 0', icon: 'warning' });
      return;
    }

    const quantity = parseInt(menuInput.quantity || '1', 10);
    if (isAccommodation && (!Number.isFinite(quantity) || quantity <= 0)) {
      Swal.fire({ text: 'Suc chua phong phai lon hon 0', icon: 'warning' });
      return;
    }

    setFormData(prev => ({
      ...prev,
      menu: prev.menu.map(m =>
        m.id === editingMenuId
          ? { ...m, name: menuInput.name, description: menuInput.description, price: menuInput.price, quantity: String(quantity), img: menuInput.img, imageFile: menuInput.imageFile, previewUrl: menuInput.previewUrl }
          : m
      ),
    }));

    setEditingMenuId(null);
    setMenuInput({ name: '', description: '', price: '', quantity: '1', img: '', imageFile: null, previewUrl: '' });
  };

  const handleCancelEdit = () => {
    setEditingMenuId(null);
    setMenuInput({ name: '', description: '', price: '', quantity: '1', img: '', imageFile: null, previewUrl: '' });
  };
  const handleRemoveMenuItem = (id: string) => {
    setFormData(prev => ({
      ...prev,
      menu: prev.menu.filter(m => m.id !== id)
    }));
  };

  const handleMenuImageSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = '';

    if (!file) return;

    if (menuInput.previewUrl) {
      URL.revokeObjectURL(menuInput.previewUrl);
    }

    setMenuInput((prev) => ({
      ...prev,
      imageFile: file,
      img: '',
      previewUrl: URL.createObjectURL(file),
    }));
  };

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files) return;
    const files = Array.from(e.target.files);
    const remaining = 5 - selectedImages.length;
    const toAdd = files.slice(0, remaining).map(file => ({
      file,
      previewUrl: URL.createObjectURL(file),
    }));
    setSelectedImages(prev => [...prev, ...toAdd]);
    e.target.value = '';
  };

  const handleImageRemove = (index: number) => {
    setSelectedImages(prev => {
      URL.revokeObjectURL(prev[index].previewUrl);
      return prev.filter((_, i) => i !== index);
    });
  };

  const handleExcelFileUpload = (file: File) => {
    const reader = new FileReader();

    reader.onerror = () => Swal.fire({ text: 'Lỗi khi đọc file. Vui lòng thử lại.', icon: 'error' });

    reader.onload = (e: any) => {
      try {
        const workbook = XLSX.read(e.target.result, { type: 'array' });

        if (!workbook.SheetNames?.length) {
          Swal.fire({ text: 'File Excel không chứa bảng tính', icon: 'warning' });
          return;
        }

        const worksheet = workbook.Sheets[workbook.SheetNames[0]];
        const rows = XLSX.utils.sheet_to_json<ExcelRow>(worksheet, { defval: '' });

        if (rows.length === 0) {
          Swal.fire({ text: 'Sheet không chứa dữ liệu. Vui lòng thêm dữ liệu vào file.', icon: 'warning' });
          return;
        }

        const headers = Object.keys(rows[0]);
        const suggestedMapping = MENU_COLUMNS.reduce<MenuColumnMapping>((mapping, column) => {
          const match = headers.find(header => {
            const normalizedHeader = normalizeColumnName(header);
            return column.aliases.some(alias => normalizedHeader === alias);
          });
          mapping[column.key] = match ?? '';
          return mapping;
        }, { name: '', price: '', description: '' });

        setExcelHeaders(headers);
        setExcelRows(rows);
        setColumnMapping(suggestedMapping);
        setUploadedFile(file);

        const isFullyMapped = Object.values(suggestedMapping).every(Boolean)
          && new Set(Object.values(suggestedMapping)).size === MENU_COLUMNS.length;
        if (isFullyMapped) {
          const parsed = parseMappedMenuRows(rows, suggestedMapping);
          if (!parsed.length) {
            Swal.fire({ text: 'Không có dòng hợp lệ. Tên món không được trống và giá bán phải lớn hơn 0.', icon: 'warning' });
            return;
          }
          setExcelPreviewItems(parsed);
          setShowExcelPreview(true);
        } else {
          setExcelPreviewItems([]);
          setShowExcelPreview(false);
        }
      } catch (err) {
        Swal.fire({ text: `Lỗi khi xử lý file: ${err instanceof Error ? err.message : 'Không xác định'}`, icon: 'error' });
      }
    };

    reader.readAsArrayBuffer(file);
  };

  const handleApplyColumnMapping = () => {
    const selectedColumns = Object.values(columnMapping);
    if (selectedColumns.some(column => !column)) {
      Swal.fire({ text: 'Vui lòng mapping đầy đủ 3 cột hệ thống.', icon: 'warning' });
      return;
    }
    if (new Set(selectedColumns).size !== selectedColumns.length) {
      Swal.fire({ text: 'Mỗi cột trong file chỉ được mapping với một cột hệ thống.', icon: 'warning' });
      return;
    }

    const parsed = parseMappedMenuRows(excelRows, columnMapping);

    if (!parsed.length) {
      Swal.fire({ text: 'Không có dòng hợp lệ. Tên món không được trống và giá bán phải lớn hơn 0.', icon: 'warning' });
      return;
    }

    setExcelPreviewItems(parsed);
    setShowExcelPreview(true);
  };

  const handleDownloadMenuTemplate = () => {
    const worksheet = XLSX.utils.aoa_to_sheet([
      ['Tên món', 'Giá bán', 'Mô tả'],
      ['Phở bò', 50000, 'Phở bò tái, phục vụ nóng'],
    ]);
    worksheet['!cols'] = [{ wch: 28 }, { wch: 16 }, { wch: 45 }];
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Thực đơn');
    XLSX.writeFile(workbook, 'mau-thuc-don.xlsx', { bookType: 'xlsx', compression: true });
  };

  const handleConfirmExcelImport = () => {
    const newItems = excelPreviewItems.map(item => ({
      id: Date.now().toString() + Math.random(),
      name: item.name,
      description: item.description,
      price: item.price,
      img: '',
    }));
    setFormData(prev => ({ ...prev, menu: [...prev.menu, ...newItems] }));
    setShowExcelPreview(false);
    setExcelHeaders([]);
    setExcelRows([]);
    setColumnMapping({ name: '', price: '', description: '' });
    setFileUploaded(true);
    setShowExcelImport(false);
    setStep(2);
  };

  const handleCancelExcelImport = () => {
    setShowExcelPreview(false);
    setUploadedFile(null);
    setExcelPreviewItems([]);
    setExcelHeaders([]);
    setExcelRows([]);
    setColumnMapping({ name: '', price: '', description: '' });
    setShowExcelImport(false);
    setStep(2);
  };

  const handleSubmitForm = async () => {
    try {
      setIsLoading(true);

      // 1. Kiểm tra thông tin cơ bản
      if (!validateBasicInfo()) {
        return;
      }

      // 2. Logic Upload ảnh (Học từ ProfilePage)
      const uploadedUrls: string[] = [];
      if (selectedImages.length > 0) {
        // Dùng for...of để đảm bảo upload xong hết mới chạy tiếp
        for (const imgItem of selectedImages) {
          try {
            const url = await uploadPlaceImage(imgItem.file);
            uploadedUrls.push(url);
          } catch (uploadErr) {
            console.error("Lỗi upload 1 file:", uploadErr);
            // Có thể chọn dừng lại hoặc tiếp tục tùy bạn
          }
        }
      }

      const currentUser = getCurrentUser<{
        businessId?: string;
        business_id?: string;
        vendorId?: string;
        vendor_id?: string;
        id?: string;
      }>();
      const vendorId = [
        currentUser?.businessId,
        currentUser?.business_id,
        currentUser?.vendorId,
        currentUser?.vendor_id,
        currentUser?.id,
      ].find((value): value is string => typeof value === 'string' && value.trim().length > 0) || '';

      if (!vendorId) {
        Swal.fire({ text: 'Không tìm thấy thông tin đối tác. Vui lòng đăng nhập lại.', icon: 'warning' });
        return;
      }

      const menuWithUploadedImages = await Promise.all(
        formData.menu.map(async (item) => {
          let imageUrl = item.img || '';

          if (item.imageFile) {
            imageUrl = await uploadFoodDraftImage(item.imageFile);
          }

          return {
            name: item.name,
            description: item.description || '',
            price: parseFloat(item.price) || 0,
            quantity: parseInt(item.quantity || '1', 10) || 1,
            image_url: imageUrl || undefined,
          };
        }),
      );
      const roomPayload = menuWithUploadedImages.map((item) => ({
        name: item.name,
        price: item.price,
        quantity: item.quantity,
      }));
      const primaryOpenCloseTime = getPrimaryOpenCloseTime(formData.weeklyHours);

      const payload = {
        p_name: formData.name,
        p_address: formData.address,
        p_city: formData.city,
        p_lat: formData.latitude,
        p_lng: formData.longitude,
        p_vendor_id: vendorId,
        p_email: formData.email.trim(),
        p_phone: formData.phone.trim(),
        p_type_id: formData.typeId,
        p_type_name: formData.type,
        p_categories: formData.type ? [formData.type] : [],
        p_open_time: primaryOpenCloseTime.openTime,
        p_close_time: primaryOpenCloseTime.closeTime,
        p_open_hour_compressed: buildOpenHourCompressed(formData.weeklyHours),
        p_description: formData.description,
        p_estimated_preparation_time: isFoodCategory(selectedBusinessType?.category_name) && formData.estimatedPreparationTime
          ? Number(formData.estimatedPreparationTime)
          : null,
        p_services: formData.amenities.map(a => {
          const existing = dbServices.find(s => s.name.toLowerCase().trim() === a.name.toLowerCase().trim());
          return {
            name: a.name,
            description: a.description || '',
            ...(existing ? { service_id: existing.id } : {}),
          };
        }),
        p_menu: isAccommodation ? [] : menuWithUploadedImages,
        p_rooms: isAccommodation ? roomPayload : [],
        p_images: uploadedUrls // Mảng 5 URL ảnh đã upload lên cloud
      };

      // 4. Gọi API lưu vào Supabase qua hàm create_full_place
      const result = await addNewPlace(payload);
      window.localStorage.removeItem(ADD_LOCATION_DRAFT_KEY);

      await Swal.fire({ text: 'Tạo địa điểm và lưu ảnh thành công!', icon: 'success' });
      const newPlaceId = result?.placeId;
      navigate(newPlaceId ? `/locations/${newPlaceId}` : '/dashboard');

    } catch (error) {
      console.error('Lỗi khi thêm địa điểm:', error);
      const responseMessage = (error as any)?.response?.data?.message;
      const responseError = (error as any)?.response?.data?.error;
      const message = Array.isArray(responseMessage)
        ? responseMessage.join('\n')
        : responseMessage || responseError || (error instanceof Error ? error.message : '');
      Swal.fire({ text: message ? `Không thể tạo địa điểm: ${message}` : 'Không thể tạo địa điểm. Vui lòng thử lại.', icon: 'error' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleNext = () => {
    if (step === 1 && !validateBasicInfo()) {
      return;
    }

    if (step === 2 && serviceMode === 'free' && serviceInput.name.trim()) {
      Swal.fire({ text: 'Bạn có dịch vụ chưa thêm vào danh sách. Vui lòng bấm Thêm vào danh sách hoặc xóa nội dung.', icon: 'warning' });
      return;
    }

    if (step === 2 && serviceMode === 'paid' && (menuInput.name.trim() || menuInput.price.trim())) {
      Swal.fire({ text: 'Bạn có dịch vụ có phí chưa thêm vào danh sách. Vui lòng bấm Thêm hoặc xóa nội dung.', icon: 'warning' });
      return;
    }

    if (step === 2 && !showExcelImport) {
      handleSubmitForm();
      return;
    }

    if (step < 3) {
      setStep((prev) => prev + 1);
    } else if (step === 3) {
      handleSubmitForm();
    }
  };

  const handleBack = () => {
    if (step === 3 && showExcelImport) {
      setShowExcelImport(false);
      setStep(2);
    } else if (fileUploaded) {
      setFileUploaded(false);
    } else if (step > 1) {
      setStep((prev) => prev - 1);
    }
  };

  const updateOpeningHourGroups = (updater: (current: OpeningHourGroup[]) => OpeningHourGroup[]) => {
    setFormData((current) => {
      const openingHourGroups = updater(current.openingHourGroups);
      const weeklyHours = buildWeeklyHoursFromGroups(openingHourGroups);
      const primaryOpenCloseTime = getPrimaryOpenCloseTime(weeklyHours);

      return {
        ...current,
        openingHourGroups,
        weeklyHours,
        openTime: primaryOpenCloseTime.openTime,
        closeTime: primaryOpenCloseTime.closeTime,
      };
    });
  };

  const handleGroupTimeChange = (groupId: string, field: 'openTime' | 'closeTime', value: string) => {
    updateOpeningHourGroups((current) =>
      current.map((group) => group.id === groupId ? { ...group, [field]: value } : group),
    );
  };

  const handleToggleGroupDay = (groupId: string, day: WeekdayKey) => {
    updateOpeningHourGroups((current) => {
      const targetGroup = current.find((group) => group.id === groupId);
      const shouldSelect = !targetGroup?.days.includes(day);

      return current.map((group) => {
        const daysWithoutCurrent = group.days.filter((item) => item !== day);
        if (group.id !== groupId) {
          return { ...group, days: daysWithoutCurrent };
        }

        return {
          ...group,
          days: shouldSelect ? [...daysWithoutCurrent, day] : daysWithoutCurrent,
        };
      });
    });
  };

  const handleAddOpeningHourGroup = () => {
    updateOpeningHourGroups((current) => [
      ...current,
      {
        id: `${Date.now()}-${current.length}`,
        days: [],
        openTime: '08:00',
        closeTime: '22:00',
      },
    ]);
  };

  const handleRemoveOpeningHourGroup = (groupId: string) => {
    updateOpeningHourGroups((current) => current.filter((group) => group.id !== groupId));
  };

  const mapTiles = getMapTiles(formData.latitude, formData.longitude, mapSize.width, mapSize.height, mapZoom);

  const renderStep1 = () => (
    <div style={{ display: 'flex', gap: '48px' }}>
      <div style={{ flex: 1 }}>
        <Input
          label="Tên địa điểm"
          placeholder="Ví dụ: Khách sạn Marriott Hà Nội"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
        />
        <Input
          label="Địa chỉ chi tiết"
          placeholder="Số nhà, tên đường..."
          value={formData.address}
          onChange={(e) => setFormData({ ...formData, address: e.target.value })}
        />
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
              Tỉnh/Thành
            </label>
            <select
              style={{
                width: '100%',
                padding: '14px 16px',
                borderRadius: '12px',
                border: `1px solid ${citiesError ? '#ef4444' : 'var(--border-color)'}`,
                background: '#fcfcfc',
                outline: 'none',
                fontSize: '15px',
              }}
              value={formData.city}
              onChange={(e) => setFormData({ ...formData, city: e.target.value })}
              disabled={loadingCities || !!citiesError || cities.length === 0}>
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
                <span style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4 }}>
                  Không thể tải tỉnh/thành từ hệ thống. Dữ liệu sẽ không được lưu cho đến khi tải lại thành công.
                </span>
                <button
                  type="button"
                  onClick={loadCities}
                  disabled={loadingCities}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    border: '1px solid #fecaca',
                    background: '#fff',
                    color: '#dc2626',
                    borderRadius: '10px',
                    padding: '8px 10px',
                    cursor: loadingCities ? 'not-allowed' : 'pointer',
                    fontSize: '13px',
                    fontWeight: 600,
                    whiteSpace: 'nowrap',
                  }}>
                  <RefreshCw size={14} />
                  Tải lại
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
              value={formData.phone}
              onChange={handlePhoneChange}
              style={{ marginBottom: 0 }}
            />
          </div>
        </div>
        <Input
          label="Email liên hệ"
          type="email"
          placeholder="example@email.com"
          error={emailError}
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
        />
        {/* --- THÀNH PHẦN MỚI: TEXTBOX MÔ TẢ --- */}
        <div style={{ marginBottom: '24px' }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
            Mô tả địa điểm
          </label>
          <textarea
            placeholder="Nhập giới thiệu ngắn gọn về địa điểm của bạn (ví dụ: không gian, phong cách, đặc sản...)"
            style={{
              width: '100%',
              minHeight: '120px',
              padding: '16px',
              borderRadius: '12px',
              border: '1px solid #E2E8F0',
              background: '#fcfcfc',
              outline: 'none',
              fontSize: '15px',
              color: '#1e293b',
              lineHeight: '1.6',
              resize: 'vertical', // Cho phép user kéo giãn chiều cao
            }}
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          />
        </div>
        <div style={{ marginBottom: '24px' }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
            Loại hình kinh doanh
          </label>
          <select
            style={{
              width: '100%',
              padding: '14px 16px',
              borderRadius: '12px',
              border: `1px solid ${businessTypesError ? '#ef4444' : 'var(--border-color)'}`,
              background: '#fcfcfc',
              outline: 'none',
              fontSize: '15px',
              color: '#1e293b',
            }}
            value={formData.typeId}
            onChange={(e) => {
              const selectedType = businessTypes.find((type) => type.id === e.target.value);
              setFormData({
                ...formData,
                typeId: selectedType?.id || '',
                type: selectedType?.name || '',
                estimatedPreparationTime: isFoodCategory(selectedType?.category_name)
                  ? (formData.estimatedPreparationTime || '15')
                  : formData.estimatedPreparationTime,
              });
            }}
            disabled={loadingBusinessTypes || !!businessTypesError || businessTypes.length === 0}>
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
              <span style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4 }}>
                Không thể tải loại hình kinh doanh từ hệ thống.
              </span>
              <button
                type="button"
                onClick={loadBusinessTypes}
                disabled={loadingBusinessTypes}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  border: '1px solid #fecaca',
                  background: '#fff',
                  color: '#dc2626',
                  borderRadius: '10px',
                  padding: '8px 10px',
                  cursor: loadingBusinessTypes ? 'not-allowed' : 'pointer',
                  fontSize: '13px',
                  fontWeight: 600,
                  whiteSpace: 'nowrap',
                }}>
                <RefreshCw size={14} />
                Tải lại
              </button>
            </div>
          )}
        </div>
        {isFoodCategory(businessTypes.find((t) => t.id === formData.typeId)?.category_name) && (
          <div style={{ marginBottom: '24px' }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
              Thời gian hoàn thành đơn (phút)
            </label>
            <input
              type="number"
              min={1}
              max={480}
              placeholder="Ví dụ: 30"
              value={formData.estimatedPreparationTime}
              onChange={(e) => setFormData({ ...formData, estimatedPreparationTime: e.target.value })}
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
        <div style={{ marginBottom: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', marginBottom: '12px' }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Clock size={18} />
              Lịch mở cửa
            </label>
          </div>
          <div style={{ display: 'grid', gap: '14px' }}>
            {formData.openingHourGroups.map((group) => {
              return (
                <div
                  key={group.id}
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '12px',
                    padding: '14px',
                    border: '1px solid #E2E8F0',
                    borderRadius: '12px',
                    background: '#fff',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                      {WEEKDAY_OPTIONS.map((day) => {
                        const selected = group.days.includes(day.key);
                        return (
                          <button
                            key={day.key}
                            type="button"
                            onClick={() => handleToggleGroupDay(group.id, day.key)}
                            style={{
                              border: `1px solid ${selected ? '#2563eb' : '#CBD5E1'}`,
                              background: selected ? '#EFF6FF' : '#fff',
                              color: selected ? '#2563eb' : '#475569',
                              borderRadius: '999px',
                              padding: '8px 12px',
                              cursor: 'pointer',
                              fontSize: '13px',
                              fontWeight: 700,
                            }}
                          >
                            {day.label}
                          </button>
                        );
                      })}
                    </div>
                    {formData.openingHourGroups.length > 1 && (
                      <button
                        type="button"
                        onClick={() => handleRemoveOpeningHourGroup(group.id)}
                        style={{
                          border: 'none',
                          background: 'transparent',
                          color: '#ef4444',
                          cursor: 'pointer',
                          fontSize: '13px',
                          fontWeight: 700,
                          whiteSpace: 'nowrap',
                        }}
                      >
                        Xóa
                      </button>
                    )}
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: '12px' }}>
                    <input
                      type="time"
                      value={group.openTime}
                      onChange={(e) => handleGroupTimeChange(group.id, 'openTime', e.target.value)}
                      style={{
                        width: '100%',
                        padding: '10px 12px',
                        borderRadius: '10px',
                        border: '1px solid var(--border-color)',
                        background: '#fcfcfc',
                        color: '#1e293b',
                        outline: 'none',
                      }}
                    />
                    <span style={{ color: '#64748b', fontSize: '13px', fontWeight: 700 }}>đến</span>
                    <input
                      type="time"
                      value={group.closeTime}
                      onChange={(e) => handleGroupTimeChange(group.id, 'closeTime', e.target.value)}
                      style={{
                        width: '100%',
                        padding: '10px 12px',
                        borderRadius: '10px',
                        border: '1px solid var(--border-color)',
                        background: '#fcfcfc',
                        color: '#1e293b',
                        outline: 'none',
                      }}
                    />
                  </div>
                  {group.days.length === 0 && (
                    <p style={{ margin: 0, color: '#f59e0b', fontSize: '12px', fontWeight: 600 }}>
                      Chọn ít nhất một ngày cho khung giờ này hoặc xóa dòng.
                    </p>
                  )}
                </div>
              );
            })}
          </div>
          <button
            type="button"
            onClick={handleAddOpeningHourGroup}
            style={{
              marginTop: '12px',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              border: '1px solid #bfdbfe',
              background: '#fff',
              color: '#2563eb',
              borderRadius: '10px',
              padding: '10px 12px',
              cursor: 'pointer',
              fontSize: '13px',
              fontWeight: 700,
            }}
          >
            <Plus size={16} />
            Thêm khung giờ mới
          </button>
        </div>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', marginBottom: '12px' }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block' }}>
            Xác định vị trí trên bản đồ
          </label>
          <button
            type="button"
            onClick={handleFindOnMap}
            disabled={isGeocoding || !formData.address.trim() || !formData.city.trim()}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              border: '1px solid #bfdbfe',
              background: '#fff',
              color: '#2563eb',
              borderRadius: '10px',
              padding: '8px 12px',
              cursor: isGeocoding || !formData.address.trim() || !formData.city.trim() ? 'not-allowed' : 'pointer',
              fontSize: '13px',
              fontWeight: 700,
              whiteSpace: 'nowrap',
              opacity: isGeocoding || !formData.address.trim() || !formData.city.trim() ? 0.6 : 1,
            }}>
            {isGeocoding ? <Loader2 size={14} className="animate-spin" /> : <Search size={14} />}
            {isGeocoding ? 'Đang tìm...' : 'Tìm trên bản đồ'}
          </button>
        </div>
        {geocodeError && (
          <div style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4, marginBottom: '10px' }}>
            {geocodeError}
          </div>
        )}
        <div
          ref={mapRef}
          onClick={handleMapClick}
          style={{
            width: '100%',
            flex: 1,
            minHeight: '240px',
            background: '#f8fafc',
            borderRadius: '16px',
            position: 'relative',
            overflow: 'hidden',
            border: '1px solid #F1F5F9',
            marginBottom: '24px',
            cursor: 'crosshair',
          }}>
          <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
            {mapTiles.map((tile) => (
              <img
                key={tile.key}
                src={tile.src}
                alt=""
                style={{
                  position: 'absolute',
                  left: `${tile.left}px`,
                  top: `${tile.top}px`,
                  width: `${tile.size}px`,
                  height: `${tile.size}px`,
                  userSelect: 'none',
                }}
              />
            ))}
          </div>
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -100%)',
              color: '#ef4444',
              pointerEvents: 'none',
              filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.25))',
            }}>
            <MapPin size={32} fill="#ef444433" />
          </div>
          <div
            style={{
              position: 'absolute',
              bottom: '12px',
              left: '12px',
              background: 'white',
              padding: '6px 12px',
              borderRadius: '8px',
              fontSize: '11px',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
              color: '#64748b',
            }}>
            Nhấn "Tìm trên bản đồ" hoặc click vào bản đồ để chỉnh vị trí.
          </div>
        </div>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}>
            <Input
              label="Vĩ độ (Latitude)"
              type="number"
              value={formData.latitude}
              readOnly
              style={{ marginBottom: 0, cursor: 'not-allowed', background: '#f8fafc' }}
            />
          </div>
          <div style={{ flex: 1 }}>
            <Input
              label="Kinh độ (Longitude)"
              type="number"
              value={formData.longitude}
              readOnly
              style={{ marginBottom: 0, cursor: 'not-allowed', background: '#f8fafc' }}
            />
          </div>
        </div>
        {/* Image Upload */}
        <div>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>
            Hình ảnh địa điểm <span style={{ color: '#94a3b8', fontWeight: '400' }}>(tối đa 5 ảnh)</span>
          </label>
          <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
            {selectedImages.map((img, idx) => (
              <div key={idx} style={{ position: 'relative', width: '76px', height: '76px' }}>
                <img
                  src={img.previewUrl}
                  alt=""
                  style={{ width: '76px', height: '76px', borderRadius: '10px', objectFit: 'cover', border: '1px solid #E2E8F0' }}
                />
                <button
                  onClick={() => handleImageRemove(idx)}
                  style={{ position: 'absolute', top: '-6px', right: '-6px', width: '20px', height: '20px', borderRadius: '50%', background: '#ef4444', color: 'white', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: '800', lineHeight: 1 }}
                >×</button>
              </div>
            ))}
            {selectedImages.length < 5 && (
              <>
                <input type="file" id="placeImageInput" style={{ display: 'none' }} accept="image/*" multiple onChange={handleImageSelect} />
                <div
                  onClick={() => document.getElementById('placeImageInput')?.click()}
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
  );

  const renderStep2 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ background: 'white', padding: '20px 24px', borderRadius: '20px', border: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '20px', flexWrap: 'wrap' }}>
        <div>
          <h4 style={{ fontSize: '1rem', fontWeight: '800', fontFamily: '"Outfit", sans-serif', color: '#0f172a', marginBottom: '4px' }}>Dịch vụ kinh doanh</h4>
          <p style={{ fontSize: '13px', color: '#64748b' }}>Chọn loại dịch vụ trước khi thêm: tiện ích miễn phí hoặc dịch vụ có giá bán.</p>
          <p style={{ fontSize: '13px', color: '#2563eb', fontWeight: 700, marginTop: '8px' }}>
            Đã thêm {formData.amenities.length} dịch vụ miễn phí và {formData.menu.length} dịch vụ có phí. Nút hoàn tất địa điểm sẽ lưu cả hai loại.
          </p>
        </div>
        <div style={{ display: 'flex', padding: '4px', background: '#F1F5F9', borderRadius: '14px', gap: '4px' }}>
          <button type="button" onClick={() => setServiceMode('free')} style={{ minHeight: '40px', padding: '0 18px', borderRadius: '10px', border: 'none', background: serviceMode === 'free' ? 'white' : 'transparent', color: serviceMode === 'free' ? '#2563eb' : '#64748b', fontWeight: 800, cursor: 'pointer', boxShadow: serviceMode === 'free' ? '0 1px 3px rgba(15, 23, 42, 0.08)' : 'none' }}>
            Miễn phí ({formData.amenities.length})
          </button>
          <button type="button" onClick={() => setServiceMode('paid')} style={{ minHeight: '40px', padding: '0 18px', borderRadius: '10px', border: 'none', background: serviceMode === 'paid' ? 'white' : 'transparent', color: serviceMode === 'paid' ? '#2563eb' : '#64748b', fontWeight: 800, cursor: 'pointer', boxShadow: serviceMode === 'paid' ? '0 1px 3px rgba(15, 23, 42, 0.08)' : 'none' }}>
            Có phí ({formData.menu.length})
          </button>
        </div>
      </div>

      <div style={{ display: serviceMode === 'free' ? 'block' : 'none', background: '#F8FAFC80', padding: '24px', borderRadius: '24px', border: '1px solid #F1F5F9' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '24px', color: '#1e293b' }}>
          <h4 style={{ fontSize: '1rem', fontWeight: '700', fontFamily: '"Outfit", sans-serif' }}>Dịch vụ tiện ích</h4>
        </div>
        <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}><Input label="Tên dịch vụ" placeholder="VD: Giữ xe miễn phí" value={serviceInput.name} onChange={(e) => setServiceInput({ ...serviceInput, name: e.target.value })} style={{ marginBottom: 0 }} /></div>
          <div style={{ flex: 1.5 }}><Input label="Mô tả (không bắt buộc)" placeholder="Nhập mô tả ngắn về dịch vụ" value={serviceInput.description} onChange={(e) => setServiceInput({ ...serviceInput, description: e.target.value })} style={{ marginBottom: 0 }} /></div>
          <div style={{ display: 'flex', flexDirection: 'column', minWidth: '240px' }}>
            <span style={{ fontSize: '14px', fontWeight: '600', lineHeight: 1.5, visibility: 'hidden', marginBottom: '8px' }}>
              Thao tác
            </span>
            <Button
              disabled={!serviceInput.name.trim()}
              style={{
                height: '53px',
                minHeight: '53px',
                boxSizing: 'border-box',
                gap: '8px',
                padding: '0 24px',
                borderRadius: '12px',
                color: '#ffffff',
                background: '#3b82f6',
                border: '1px solid #3b82f6',
                opacity: serviceInput.name.trim() ? 1 : 0.55,
                cursor: serviceInput.name.trim() ? 'pointer' : 'not-allowed',
                whiteSpace: 'nowrap',
              }}
              onClick={handleAddService}>
              Thêm vào danh sách
            </Button>
          </div>
        </div>
        <div>
          {/* Preset chips */}
          <label style={{ fontSize: '12px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', marginBottom: '10px', display: 'block', letterSpacing: '0.5px' }}>
            Chọn nhanh
          </label>
          <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', marginBottom: '20px' }}>
            {PRESET_FREE_SERVICES.map(preset => {
              const isSelected = formData.amenities.some(a => a.name === preset.name);
              return (
                <button
                  key={preset.name}
                  type="button"
                  onClick={() => {
                    if (isSelected) {
                      const target = formData.amenities.find(a => a.name === preset.name);
                      if (target) handleRemoveService(target.id);
                    } else {
                      setFormData(prev => ({
                        ...prev,
                        amenities: [...prev.amenities, {
                          id: Date.now().toString(),
                          name: preset.name,
                          description: preset.description,
                          icon: <Wifi size={18} />,
                        }],
                      }));
                    }
                  }}
                  style={{
                    padding: '8px 18px',
                    borderRadius: '20px',
                    border: `1.5px solid ${isSelected ? '#3b82f6' : '#E2E8F0'}`,
                    background: isSelected ? '#EFF6FF' : 'white',
                    color: isSelected ? '#2563eb' : '#64748b',
                    fontWeight: 600,
                    fontSize: '13px',
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {isSelected ? (
                    <CheckCircle size={14} color="#2563eb" />
                  ) : (
                    <Plus size={14} />
                  )}
                  {preset.name}
                </button>
              );
            })}
          </div>

          <label
            style={{
              fontSize: '12px',
              fontWeight: '800',
              color: '#94a3b8',
              textTransform: 'uppercase',
              marginBottom: '12px',
              display: 'block',
              letterSpacing: '0.5px',
            }}>
            Dịch vụ đã thêm
          </label>
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            {formData.amenities.length === 0 ? (
              <span style={{ color: '#94a3b8', fontSize: '14px' }}>Chưa có dịch vụ nào được thêm.</span>
            ) : (
              formData.amenities.map((item) => (
                <div
                  key={item.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    padding: '8px 16px',
                    background: 'white',
                    border: '1px solid #E2E8F0',
                    borderRadius: '12px',
                    fontSize: '14px',
                    color: '#475569',
                  }}>
                  <span>{item.name}</span>
                  <span style={{ cursor: 'pointer', color: '#94a3b8', fontSize: '16px', marginLeft: '4px' }} onClick={() => handleRemoveService(item.id)}>×</span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      <div style={{ display: serviceMode === 'paid' ? 'block' : 'none', background: '#F8FAFC80', padding: '24px', borderRadius: '24px', border: '1px solid #F1F5F9' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#1e293b' }}>
            <h4 style={{ fontSize: '1rem', fontWeight: '700', fontFamily: '"Outfit", sans-serif' }}>Danh sách sản phẩm</h4>
          </div>
        </div>

        {editingMenuId && (
          <div style={{ marginBottom: '12px', padding: '10px 16px', background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: '12px', fontSize: '13px', color: '#1D4ED8', fontWeight: 600 }}>
            Đang chỉnh sửa dịch vụ. Cập nhật thông tin bên dưới rồi nhấn "Cập nhật".
          </div>
        )}
        <div style={{ display: 'flex', gap: '20px', alignItems: 'flex-start', marginBottom: '32px' }}>
          <input
            id="menuImageInput"
            type="file"
            accept="image/*"
            style={{ display: 'none' }}
            onChange={handleMenuImageSelect}
          />
          <div
            onClick={() => document.getElementById('menuImageInput')?.click()}
            style={{
              width: '100px',
              height: '100px',
              background: '#f8fafc',
              borderRadius: '16px',
              border: `2px dashed ${editingMenuId ? '#93C5FD' : '#E2E8F0'}`,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#94a3b8',
              fontSize: '10px',
              gap: '4px',
              cursor: 'pointer',
              overflow: 'hidden',
            }}>
            {menuInput.previewUrl ? (
              <img
                src={menuInput.previewUrl}
                alt=""
                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              />
            ) : (
              <>
                <Upload size={24} /> Tải lên
              </>
            )}
          </div>
          <div style={{ flex: 1, display: 'flex', gap: '16px', alignItems: 'flex-end', paddingTop: '16px', flexWrap: 'wrap' }}>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>Sản phẩm</label>
              <input
                placeholder="VD: Cơm Gà Hải Nam"
                value={menuInput.name}
                onChange={(e) => setMenuInput({ ...menuInput, name: e.target.value })}
                style={{
                  width: '100%',
                  height: '48px',
                  padding: '0 16px',
                  borderRadius: '12px',
                  border: `1px solid ${editingMenuId ? '#93C5FD' : 'var(--border-color)'}`,
                  background: '#fcfcfc',
                  fontSize: '15px',
                  outline: 'none',
                  color: 'var(--text-primary)',
                }}
              />
            </div>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>Giá bán (VNĐ)</label>
              <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                <input
                  placeholder="0"
                  value={menuInput.price}
                  onChange={(e) => setMenuInput({ ...menuInput, price: e.target.value })}
                  style={{
                    width: '100%',
                    height: '48px',
                    padding: '0 40px 0 16px',
                    borderRadius: '12px',
                    border: `1px solid ${editingMenuId ? '#93C5FD' : 'var(--border-color)'}`,
                    background: '#fcfcfc',
                    fontSize: '15px',
                    outline: 'none',
                    color: 'var(--text-primary)',
                  }}
                />
                <span style={{ position: 'absolute', right: '14px', color: 'var(--text-secondary)', fontSize: '15px' }}>đ</span>
              </div>
            </div>
            {isAccommodation && (
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>Sức chứa</label>
                <input
                  placeholder="2"
                  value={menuInput.quantity}
                  onChange={(e) => setMenuInput({ ...menuInput, quantity: e.target.value })}
                  style={{
                    width: '100%',
                    height: '48px',
                    padding: '0 16px',
                    borderRadius: '12px',
                    border: `1px solid ${editingMenuId ? '#93C5FD' : 'var(--border-color)'}`,
                    background: '#fcfcfc',
                    fontSize: '15px',
                    outline: 'none',
                    color: 'var(--text-primary)',
                  }}
                />
              </div>
            )}
            <div style={{ flex: '1 1 100%', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>Mô tả chi tiết</label>
              <textarea
                placeholder="VD: Bao gồm vé vào cửa, nước uống, áp dụng cuối tuần..."
                value={menuInput.description}
                onChange={(e) => setMenuInput({ ...menuInput, description: e.target.value })}
                rows={3}
                style={{
                  width: '100%',
                  minHeight: '88px',
                  padding: '12px 16px',
                  borderRadius: '12px',
                  border: `1px solid ${editingMenuId ? '#93C5FD' : 'var(--border-color)'}`,
                  background: '#fcfcfc',
                  fontSize: '15px',
                  outline: 'none',
                  color: 'var(--text-primary)',
                  resize: 'vertical',
                  lineHeight: 1.5,
                  fontFamily: 'inherit',
                }}
              />
            </div>
            <div style={{ flex: '1 1 100%', display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              {editingMenuId && (
                <button
                  type="button"
                  onClick={handleCancelEdit}
                  style={{
                    height: '52px',
                    padding: '0 24px',
                    borderRadius: '14px',
                    fontSize: '15px',
                    fontWeight: 700,
                    border: '1px solid #E2E8F0',
                    background: 'white',
                    color: '#64748b',
                    cursor: 'pointer',
                    whiteSpace: 'nowrap',
                  }}
                >
                  Hủy
                </button>
              )}
              <Button
                style={{
                  height: '52px',
                  minWidth: '150px',
                  padding: '0 32px',
                  borderRadius: '14px',
                  fontSize: '15px',
                  fontWeight: 800,
                  whiteSpace: 'nowrap',
                  boxShadow: '0 10px 18px rgba(37, 99, 235, 0.22)',
                  ...(editingMenuId ? { background: '#0284c7' } : {}),
                }}
                onClick={editingMenuId ? handleUpdateMenuItem : handleAddMenuItem}
              >
                {editingMenuId ? 'Cập nhật' : 'Thêm'}
              </Button>
            </div>
          </div>
        </div>

        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', marginBottom: '16px' }}>
            <label
              style={{
                fontSize: '12px',
                fontWeight: '800',
                color: '#94a3b8',
                textTransform: 'uppercase',
                display: 'block',
                letterSpacing: '0.5px',
              }}>
              Danh sách món ăn
            </label>
            <Button
              variant="outline"
              style={{ padding: '10px 18px', borderRadius: '12px', fontSize: '14px', gap: '8px', color: '#3b82f6', borderColor: '#DBEAFE', background: '#F0F9FF' }}
              onClick={() => {
                setShowExcelImport(true);
                setStep(3);
              }}>
              <Plus size={18} /> Thêm từ file
            </Button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px' }}>
            {formData.menu.map((item) => (
              <div
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                  padding: '12px',
                  background: editingMenuId === item.id ? '#EFF6FF' : 'white',
                  border: `1px solid ${editingMenuId === item.id ? '#93C5FD' : '#E2E8F0'}`,
                  borderRadius: '16px',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.02)',
                }}>
                <img src={item.previewUrl || item.img || defaultServiceIcon} alt={item.name} style={{ width: '56px', height: '56px', borderRadius: '12px', objectFit: 'cover' }} />
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                  <span style={{ fontWeight: '700', color: '#1e293b', fontSize: '14px' }}>{item.name}</span>
                  {item.description && (
                    <span style={{ fontSize: '12px', color: '#64748b', lineHeight: 1.4, marginTop: '4px' }}>{item.description}</span>
                  )}
                  <span style={{ fontSize: '13px', color: '#3b82f6', fontWeight: '600' }}>{item.price}đ</span>
                </div>
                <div style={{ display: 'flex', gap: '12px', color: '#94a3b8' }}>
                  <Trash2 size={16} style={{ cursor: 'pointer' }} onClick={() => handleRemoveMenuItem(item.id)} />
                  <Edit2
                    size={16}
                    style={{ cursor: 'pointer', color: editingMenuId === item.id ? '#2563eb' : '#94a3b8' }}
                    onClick={() => handleEditMenuItem(item.id)}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep3Initial = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '40px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', color: '#1e293b' }}>
        <h4 style={{ fontSize: '1rem', fontWeight: '700', fontFamily: '"Outfit", sans-serif' }}>Xác nhận thông tin</h4>
      </div>

      {/* Current menu items summary */}
      {formData.menu.length > 0 && (
        <div style={{ background: '#F0FDF4', border: '1px solid #DCFCE7', borderRadius: '24px', padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <CheckCircle size={20} color="#22c55e" />
            <h5 style={{ fontSize: '0.9375rem', fontWeight: '700', fontFamily: '"Outfit", sans-serif', color: '#1e293b' }}>Món ăn đã thêm ({formData.menu.length})</h5>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '12px' }}>
            {formData.menu.map(item => (
              <div key={item.id} style={{ padding: '12px', background: 'white', borderRadius: '12px', border: '1px solid #DCFCE7' }}>
                <div style={{ fontWeight: '600', color: '#1e293b', marginBottom: '4px' }}>{item.name}</div>
                <div style={{ fontSize: '13px', color: '#22c55e', marginBottom: '4px' }}>{parseFloat(item.price).toLocaleString('vi-VN')}đ</div>
                {item.description && <div style={{ fontSize: '12px', color: '#64748b' }}>{item.description}</div>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* File upload section */}
      <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', padding: '40px' }}>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px', alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: '#F0F9FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
            <FileSpreadsheet size={24} />
          </div>
          <div style={{ flex: 1 }}>
            <h5 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>Thêm món ăn từ file Excel (tùy chọn)</h5>
            <p style={{ fontSize: '13px', color: '#94a3b8' }}>Tải dữ liệu thực đơn và mapping 3 cột hệ thống: "Tên món", "Giá bán", "Mô tả".</p>
          </div>
          <button
            type="button"
            onClick={handleDownloadMenuTemplate}
            style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 16px', borderRadius: '10px', border: '1px solid #BFDBFE', background: '#EFF6FF', color: '#2563EB', fontWeight: 700, cursor: 'pointer', whiteSpace: 'nowrap' }}
          >
            <Download size={17} /> Tải file mẫu
          </button>
        </div>

        <input
          type="file"
          id="fileInput"
          style={{ display: 'none' }}
          accept=".xlsx,.xls,.csv"
          onChange={(e) => {
            if (e.target.files && e.target.files[0]) {
              handleExcelFileUpload(e.target.files[0]);
              e.target.value = '';
            }
          }}
        />

        {excelHeaders.length === 0 ? (
          <div onClick={() => document.getElementById('fileInput')?.click()} style={{
            height: '240px',
            border: '2px dashed #E2E8F0',
            borderRadius: '24px',
            background: '#F8FAFC40',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '16px',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
          }}>
            <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: '#F0F9FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
              <Upload size={24} />
            </div>
            <div style={{ textAlign: 'center' }}>
              <p style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>Kéo thả file đã nhập liệu vào đây</p>
              <p style={{ fontSize: '13px', color: '#94a3b8' }}>Hoặc click để chọn tệp từ máy tính</p>
            </div>
            <span style={{ fontSize: '11px', fontWeight: '800', color: '#CBD5E1', letterSpacing: '1px' }}>XLSX, XLS HOẶC CSV</span>
          </div>
        ) : !showExcelPreview ? (
          <div style={{ border: '1px solid #E2E8F0', borderRadius: '16px', padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '16px', marginBottom: '20px' }}>
              <div>
                <h6 style={{ margin: 0, fontSize: '15px', color: '#1E293B' }}>Mapping cột dữ liệu</h6>
                <p style={{ margin: '6px 0 0', fontSize: '13px', color: '#64748B' }}>Chọn cột trong file tương ứng với từng cột mà hệ thống yêu cầu.</p>
              </div>
              <button type="button" onClick={() => { setUploadedFile(null); setExcelHeaders([]); setExcelRows([]); setColumnMapping({ name: '', price: '', description: '' }); }} style={{ border: 0, background: 'transparent', color: '#EF4444', fontWeight: 600, cursor: 'pointer' }}>Đổi file</button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {MENU_COLUMNS.map(column => (
                <div key={column.key} style={{ display: 'flex', alignItems: 'center', gap: '18px', padding: '14px 16px', border: '1px solid #E2E8F0', borderRadius: '12px', background: '#F8FAFC', flexWrap: 'wrap' }}>
                  <div style={{ width: '220px', minWidth: '180px' }}>
                    <div style={{ fontSize: '11px', fontWeight: 800, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '5px' }}>Cột hệ thống</div>
                    <div style={{ fontSize: '14px', fontWeight: 700, color: '#1E293B' }}>{column.label} <span style={{ color: '#EF4444' }}>*</span></div>
                  </div>
                  <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: '#DBEAFE', color: '#2563EB', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <ArrowRight size={18} />
                  </div>
                  <label style={{ flex: 1, minWidth: '240px' }}>
                    <span style={{ display: 'block', fontSize: '11px', fontWeight: 800, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '5px' }}>Cột trong file</span>
                  <select
                    value={columnMapping[column.key]}
                    onChange={event => setColumnMapping(previous => ({ ...previous, [column.key]: event.target.value }))}
                    style={{ width: '100%', padding: '11px 12px', border: '1px solid #CBD5E1', borderRadius: '10px', background: 'white', color: columnMapping[column.key] ? '#1E293B' : '#94A3B8', fontSize: '14px', outline: 'none' }}
                  >
                    <option value="">-- Chọn cột trong file --</option>
                    {excelHeaders.map(header => <option key={header} value={header}>{header}</option>)}
                  </select>
                  </label>
                </div>
              ))}
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px' }}>
              <Button onClick={handleApplyColumnMapping} style={{ padding: '11px 24px', borderRadius: '10px' }}>Áp dụng mapping</Button>
            </div>
          </div>
        ) : (
          <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <CheckCircle size={18} color="#22c55e" />
                <span style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>
                  {uploadedFile?.name}
                  <span style={{ color: '#64748b', fontWeight: 400, marginLeft: '6px' }}>— {excelPreviewItems.length} món ăn</span>
                </span>
              </div>
              <button
                type="button"
                onClick={() => { setShowExcelPreview(false); setUploadedFile(null); setExcelPreviewItems([]); setExcelHeaders([]); setExcelRows([]); setColumnMapping({ name: '', price: '', description: '' }); }}
                style={{ fontSize: '13px', color: '#ef4444', background: 'transparent', border: 'none', cursor: 'pointer', fontWeight: '600' }}
              >
                Đổi file
              </button>
            </div>

            {/* Preview table */}
            <div style={{ borderRadius: '16px', border: '1px solid #E2E8F0', overflow: 'hidden', maxHeight: '360px', overflowY: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead style={{ position: 'sticky', top: 0, zIndex: 1 }}>
                  <tr style={{ background: '#F8FAFC' }}>
                    {['TÊN MÓN', 'GIÁ BÁN', 'MÔ TẢ'].map((col, i) => (
                      <th key={col} style={{
                        padding: '14px 20px',
                        textAlign: 'left',
                        fontSize: '11px',
                        fontWeight: '800',
                        color: '#94a3b8',
                        textTransform: 'uppercase',
                        letterSpacing: '0.5px',
                        borderBottom: '1px solid #E2E8F0',
                        width: i === 0 ? '30%' : i === 1 ? '20%' : '50%',
                      }}>
                        {col}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {excelPreviewItems.map((item, idx) => (
                    <tr key={idx} style={{ borderBottom: idx < excelPreviewItems.length - 1 ? '1px solid #F1F5F9' : 'none', background: idx % 2 === 0 ? 'white' : '#FAFAFA' }}>
                      <td style={{ padding: '14px 20px', fontSize: '14px', fontWeight: '600', color: '#1e293b' }}>{item.name}</td>
                      <td style={{ padding: '14px 20px', fontSize: '14px', fontWeight: '600', color: '#3b82f6' }}>
                        {parseFloat(item.price).toLocaleString('vi-VN')}đ
                      </td>
                      <td style={{ padding: '14px 20px', fontSize: '13px', color: '#64748b' }}>{item.description || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
              <button
                type="button"
                onClick={handleCancelExcelImport}
                style={{
                  padding: '12px 28px',
                  borderRadius: '12px',
                  border: '1px solid #E2E8F0',
                  background: 'white',
                  color: '#64748b',
                  fontSize: '15px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                Hủy
              </button>
              <Button
                onClick={handleConfirmExcelImport}
                style={{ padding: '12px 32px', borderRadius: '12px', gap: '8px' }}
              >
                <CheckCircle size={16} /> Xác nhận
              </Button>
            </div>
          </div>
        )}
      </div>

      {fileUploaded && !showExcelPreview && uploadedFile && (
        <div style={{ background: '#F0FDF4', border: '1px solid #DCFCE7', borderRadius: '16px', padding: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <CheckCircle size={20} color="#22c55e" />
            <div>
              <p style={{ fontSize: '14px', fontWeight: '600', color: '#1e293b' }}>File đã tải: {uploadedFile.name}</p>
              <p style={{ fontSize: '12px', color: '#22c55e' }}>Dữ liệu đã được thêm vào danh sách</p>
            </div>
          </div>
          <button onClick={() => { setUploadedFile(null); setFileUploaded(false); }} style={{ fontSize: '13px', color: '#3b82f6', background: 'transparent', border: 'none', cursor: 'pointer', fontWeight: '600' }}>Xóa</button>
        </div>
      )}
    </div>
  );

  return (
    <>
      <div style={{ maxWidth: step === 3 ? '1200px' : '1000px', margin: '0 auto', paddingBottom: '40px' }}>
        {step !== 3 && (
          <div style={{ marginBottom: '32px' }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '8px', fontFamily: '"Outfit", sans-serif' }}>Thêm địa điểm mới</h2>
            <p style={{ fontSize: '15px', color: '#64748b' }}>
              Vui lòng điền thông tin chi tiết về địa điểm kinh doanh của bạn để bắt đầu.
            </p>
          </div>
        )}

        <div
          style={{
            background: step === 3 ? 'transparent' : 'white',
            borderRadius: '24px',
            padding: step === 3 ? '0' : '32px',
            boxShadow: step === 3 ? 'none' : '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
            border: step === 3 ? 'none' : '1px solid #F1F5F9',
            marginBottom: step === 3 ? '0' : undefined,
          }}>
          {step !== 3 && (
            <>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '48px', marginBottom: '40px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: step >= 1 ? '#3b82f6' : '#94a3b8' }}>
                  <span
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: step >= 1 ? '#3b82f6' : '#f1f5f9',
                      color: step >= 1 ? 'white' : '#94a3b8',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      fontWeight: '700',
                    }}>
                    1
                  </span>
                  <span style={{ fontWeight: '700', fontSize: '14px' }}>Thông tin</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: step >= 2 ? '#3b82f6' : '#94a3b8' }}>
                  <span
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: step >= 2 ? '#3b82f6' : '#f1f5f9',
                      color: step >= 2 ? 'white' : '#94a3b8',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      fontWeight: '700',
                    }}>
                    2
                  </span>
                  <span style={{ fontWeight: '700', fontSize: '14px' }}>Dịch vụ</span>
                </div>
              </div>

              <div style={{ marginBottom: '40px' }}>
                <div style={{ height: '6px', background: '#f1f5f9', borderRadius: '3px', overflow: 'hidden' }}>
                  <div
                    style={{
                      width: step === 1 ? '50%' : '100%',
                      height: '100%',
                      background: '#3b82f6',
                      borderRadius: '3px',
                      transition: 'width 0.3s ease',
                    }}></div>
                </div>
              </div>
            </>
          )}

          {step === 1 ? renderStep1() : step === 2 ? renderStep2() : renderStep3Initial()}

          {/* Footer Actions */}
          {step !== 3 && (
            <div style={{
              marginTop: '48px',
              padding: '32px 0 0 0',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '24px',
            }}>
              {step === 1 ? (
                <button
                  onClick={() => navigate('/dashboard')}
                  style={{
                    background: 'transparent',
                    color: '#64748b',
                    fontSize: '14px',
                    fontWeight: '700',
                    padding: '12px 24px',
                    cursor: 'pointer',
                    border: 'none',
                  }}>
                  Hủy bỏ
                </button>
              ) : (
                <button
                  onClick={handleBack}
                  style={{
                    background: '#F1F5F9',
                    color: '#475569',
                    fontSize: '14px',
                    fontWeight: '700',
                    padding: '12px 24px',
                    borderRadius: '12px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    cursor: 'pointer',
                    border: 'none',
                  }}>
                  <ArrowLeft size={18} /> Quay lại
                </button>
              )}

              <Button
                onClick={handleNext}
                disabled={(step === 1 && !canProceedFromStep1) || isLoading}
                style={{ gap: '8px', padding: '12px 32px', borderRadius: '12px' }}>
                {isLoading && step === 2 ? (
                  <>
                    <Loader2 size={18} className="animate-spin" /> Đang xử lý...
                  </>
                ) : (
                  <>
                    {step === 1 ? 'Tiếp theo' : 'Hoàn tất'}
                    {step === 1 ? <ArrowRight size={18} /> : <CheckCircle size={18} />}
                  </>
                )}
              </Button>
            </div>
          )}
        </div>

        {step !== 3 && (
          <p style={{ textAlign: 'center', marginTop: '32px', fontSize: '13px', color: '#94a3b8' }}>
            Bằng cách nhấn tiếp tục, bạn đồng ý với{' '}
            <a href="#" style={{ textDecoration: 'underline' }}>
              Điều khoản & Chính sách
            </a>{' '}
            của Travel Portal.
          </p>
        )}
      </div>
    </>
  );
};

export default AddLocationPage;
