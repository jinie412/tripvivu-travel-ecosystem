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
  Eye,
  CheckCircle,
  Info,
  RefreshCw,
  Loader2,
  Search,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { uploadFoodDraftImage, uploadPlaceImage } from '@/services/order.service';
import { locationAPI, type AdminVendorOption } from '@/services/locationAPI';
import { apiClient, extractResponseData } from '@/services/apiClient';
import * as XLSX from 'xlsx';
import defaultServiceIcon from '@/assets/images/service_icon_default.jpg';

type CityOption = { id: string; name: string };
type BusinessTypeOption = { id: string; name: string };
type SourceMode = 'system' | 'vendor';
type AmenityDraft = { id: string; name: string; description: string; icon: React.ReactNode };
type MenuDraft = { id: string; name: string; description: string; price: string; img: string; imageFile?: File | null; previewUrl?: string };
type AdminAddLocationFormData = {
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
  description: string;
  amenities: AmenityDraft[];
  menu: MenuDraft[];
};
type AdminAddLocationDraft = {
  step: number;
  fileUploaded: boolean;
  sourceMode: SourceMode;
  selectedVendorId: string;
  serviceMode: 'free' | 'paid';
  formData: Omit<AdminAddLocationFormData, 'amenities' | 'menu'> & {
    amenities: Array<Omit<AmenityDraft, 'icon'>>;
    menu: Array<Omit<MenuDraft, 'imageFile' | 'previewUrl'>>;
  };
};

const ADMIN_ADD_LOCATION_DRAFT_KEY = 'admin:add-location:draft:v1';
const DEFAULT_ADMIN_ADD_LOCATION_FORM_DATA: AdminAddLocationFormData = {
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
  description: '',
  amenities: [],
  menu: [],
};

const isBrowser = () => typeof window !== 'undefined';

const restoreAdminAddLocationDraft = (): AdminAddLocationDraft | null => {
  if (!isBrowser()) return null;
  try {
    const raw = window.localStorage.getItem(ADMIN_ADD_LOCATION_DRAFT_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<AdminAddLocationDraft>;
    if (!parsed.formData || typeof parsed.formData !== 'object') return null;

    return {
      step: typeof parsed.step === 'number' ? Math.min(Math.max(parsed.step, 1), 3) : 1,
      fileUploaded: Boolean(parsed.fileUploaded),
      sourceMode: parsed.sourceMode === 'vendor' ? 'vendor' : 'system',
      selectedVendorId: typeof parsed.selectedVendorId === 'string' ? parsed.selectedVendorId : '',
      serviceMode: parsed.serviceMode === 'paid' ? 'paid' : 'free',
      formData: {
        ...DEFAULT_ADMIN_ADD_LOCATION_FORM_DATA,
        ...parsed.formData,
        phone: String(parsed.formData.phone ?? '').replace(/\D/g, '').slice(0, 10),
        latitude: Number(parsed.formData.latitude) || DEFAULT_ADMIN_ADD_LOCATION_FORM_DATA.latitude,
        longitude: Number(parsed.formData.longitude) || DEFAULT_ADMIN_ADD_LOCATION_FORM_DATA.longitude,
        amenities: Array.isArray(parsed.formData.amenities) ? parsed.formData.amenities : [],
        menu: Array.isArray(parsed.formData.menu) ? parsed.formData.menu : [],
      },
    };
  } catch {
    return null;
  }
};

const buildRestoredFormData = (draft: AdminAddLocationDraft | null): AdminAddLocationFormData => ({
  ...(draft?.formData ?? DEFAULT_ADMIN_ADD_LOCATION_FORM_DATA),
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
    img: item.img || '',
    imageFile: null,
    previewUrl: '',
  })),
});

const buildPersistableFormData = (formData: AdminAddLocationFormData): AdminAddLocationDraft['formData'] => ({
  ...formData,
  amenities: formData.amenities.map(({ id, name, description }) => ({ id, name, description })),
  menu: formData.menu.map(({ id, name, description, price, img }) => ({ id, name, description, price, img })),
});

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
        src: `https://tile.openstreetmap.org/${tileZoom}/${wrappedX}/${y}.png`,
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

export const AddLocation: React.FC = () => {
  const navigate = useNavigate();
  const mapRef = useRef<HTMLDivElement | null>(null);
  const [restoredDraft] = useState(() => restoreAdminAddLocationDraft());
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
  const [sourceMode, setSourceMode] = useState<SourceMode>(() => restoredDraft?.sourceMode ?? 'system');
  const [selectedVendorId, setSelectedVendorId] = useState(() => restoredDraft?.selectedVendorId ?? '');
  const [vendors, setVendors] = useState<AdminVendorOption[]>([]);
  const [loadingVendors, setLoadingVendors] = useState(false);
  const [vendorsError, setVendorsError] = useState<string | null>(null);
  // Service input state
  const [serviceInput, setServiceInput] = useState({ name: '', description: '' });
  const [serviceMode, setServiceMode] = useState<'free' | 'paid'>(() => restoredDraft?.serviceMode ?? 'free');

  // Menu item input state
  const [menuInput, setMenuInput] = useState<{
    name: string;
    description: string;
    price: string;
    img: string;
    imageFile: File | null;
    previewUrl: string;
  }>({ name: '', description: '', price: '', img: '', imageFile: null, previewUrl: '' });

  const [formData, setFormData] = useState<AdminAddLocationFormData>(() => buildRestoredFormData(restoredDraft));

  const [cities, setCities] = useState<CityOption[]>([]);
  const [loadingCities, setLoadingCities] = useState(true);
  const [citiesError, setCitiesError] = useState<string | null>(null);
  const [businessTypes, setBusinessTypes] = useState<BusinessTypeOption[]>([]);
  const [loadingBusinessTypes, setLoadingBusinessTypes] = useState(true);
  const [businessTypesError, setBusinessTypesError] = useState<string | null>(null);

  useEffect(() => {
    if (!isBrowser()) return;

    const draft: AdminAddLocationDraft = {
      step,
      fileUploaded,
      sourceMode,
      selectedVendorId,
      serviceMode,
      formData: buildPersistableFormData(formData),
    };

    window.localStorage.setItem(ADMIN_ADD_LOCATION_DRAFT_KEY, JSON.stringify(draft));
  }, [fileUploaded, formData, selectedVendorId, serviceMode, sourceMode, step]);

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

  const loadVendors = useCallback(async () => {
    setLoadingVendors(true);
    setVendorsError(null);

    try {
      const list = await locationAPI.getBusinessVendors();
      setVendors(list);
      setSelectedVendorId((prev) => (list.some((vendor) => vendor.id === prev) ? prev : ''));
    } catch (error) {
      console.error('[admin-vendors] Load failed:', error);
      setVendors([]);
      setSelectedVendorId('');
      setVendorsError(error instanceof Error ? error.message : 'Không thể tải danh sách đối tác.');
    } finally {
      setLoadingVendors(false);
    }
  }, []);

  useEffect(() => {
    loadVendors();
  }, [loadVendors]);

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
    && !emailError
    && (sourceMode === 'system' || Boolean(selectedVendorId)),
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
      alert('Vui lòng điền đầy đủ thông tin tại Bước 1');
      setStep(1);
      return false;
    }

    if (phoneError) {
      alert('SĐT liên hệ phải gồm đúng 10 chữ số và bắt đầu bằng số 0.');
      setStep(1);
      return false;
    }

    if (emailError) {
      alert('Email liên hệ không đúng định dạng.');
      setStep(1);
      return false;
    }

    if (loadingCities) {
      alert('Danh sách tỉnh/thành đang tải. Vui lòng chờ trong giây lát.');
      setStep(1);
      return false;
    }

    if (citiesError || cities.length === 0) {
      alert('Không thể tải danh sách tỉnh/thành từ hệ thống. Vui lòng bấm "Tải lại" trước khi tiếp tục.');
      setStep(1);
      return false;
    }

    if (!cities.some((city) => city.name === formData.city)) {
      alert('Vui lòng chọn tỉnh/thành hợp lệ từ danh sách hệ thống.');
      setStep(1);
      return false;
    }

    if (loadingBusinessTypes) {
      alert('Danh sách loại hình kinh doanh đang tải. Vui lòng chờ trong giây lát.');
      setStep(1);
      return false;
    }

    if (businessTypesError || businessTypes.length === 0) {
      alert('Không thể tải danh sách loại hình kinh doanh từ hệ thống. Vui lòng bấm "Tải lại" trước khi tiếp tục.');
      setStep(1);
      return false;
    }

    if (!businessTypes.some((type) => type.id === formData.typeId && type.name === formData.type)) {
      alert('Vui lòng chọn loại hình kinh doanh hợp lệ từ danh sách hệ thống.');
      setStep(1);
      return false;
    }

    if (sourceMode === 'vendor') {
      if (loadingVendors) {
        alert('Danh sách đối tác đang tải. Vui lòng chờ trong giây lát.');
        setStep(1);
        return false;
      }

      if (vendorsError || vendors.length === 0) {
        alert('Không thể tải danh sách đối tác. Vui lòng bấm "Tải lại" trước khi tiếp tục.');
        setStep(1);
        return false;
      }

      if (!vendors.some((vendor) => vendor.id === selectedVendorId)) {
        alert('Vui lòng chọn đối tác quản lý địa điểm.');
        setStep(1);
        return false;
      }
    }

    return true;
  };


  const handleAddService = () => {
    if (!serviceInput.name.trim()) {
      alert('Vui lòng nhập tên dịch vụ');
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
      alert('Vui lòng nhập tên và giá của món ăn');
      return;
    }

    const price = parseFloat(menuInput.price);
    if (Number.isNaN(price) || price <= 0) {
      alert('Giá dịch vụ có phí phải lớn hơn 0');
      return;
    }

    const newMenuItem = {
      id: Date.now().toString(),
      name: menuInput.name,
      description: menuInput.description,
      price: menuInput.price,
      img: menuInput.img || '',
      imageFile: menuInput.imageFile,
      previewUrl: menuInput.previewUrl,
    };

    setFormData(prev => ({
      ...prev,
      menu: [...prev.menu, newMenuItem]
    }));

    setMenuInput({ name: '', description: '', price: '', img: '', imageFile: null, previewUrl: '' });
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
    try {
      const reader = new FileReader();

      reader.onerror = () => {
        console.error('FileReader error:', reader.error);
        alert('Lỗi khi đọc file. Vui lòng thử lại.');
      };

      reader.onload = (e: any) => {
        try {
          const data = e.target.result;
          console.log('📄 File data loaded, size:', data.byteLength, 'bytes');

          // Read Excel workbook
          const workbook = XLSX.read(data, { type: 'array' });
          console.log('📊 Workbook sheets found:', workbook.SheetNames);

          if (!workbook.SheetNames || workbook.SheetNames.length === 0) {
            alert('File Excel không chứa bảng tính');
            return;
          }

          // Get first sheet
          const worksheet = workbook.Sheets[workbook.SheetNames[0]];
          const rows = XLSX.utils.sheet_to_json(worksheet);
          console.log('📋 Raw rows from Excel:', rows);

          if (rows.length === 0) {
            alert('Sheet không chứa dữ liệu. Vui lòng thêm dữ liệu vào file.');
            return;
          }

          // Show actual headers for debugging
          const firstRow = rows[0] as any;
          const actualHeaders = Object.keys(firstRow);
          console.log('🔑 Actual column headers in file:', actualHeaders);

          // Find columns by flexible matching
          const findColumn = (row: any, ...possibleNames: string[]) => {
            for (const name of possibleNames) {
              const key = Object.keys(row).find(
                k => k.toLowerCase().trim() === name.toLowerCase().trim() ||
                  k.toLowerCase().includes(name.toLowerCase())
              );
              if (key) return row[key];
            }
            return '';
          };

          // Parse Excel rows with flexible column matching
          const newItems = rows.map((row: any) => {
            const name = findColumn(row, 'Tên món', 'name', 'Tên', 'item', 'product');
            const priceStr = findColumn(row, 'Giá bán', 'price', 'Giá', 'Cost', 'Value');
            const description = findColumn(row, 'Mô tả', 'description', 'Description', 'Mô tả');

            return {
              id: Date.now().toString() + Math.random(),
              name: String(name).trim(),
              description: String(description).trim(),
              price: String(priceStr).trim(),
              img: ''
            };
          }).filter((item: any) => {
            // Validate: name must exist and price must be a valid number
            return item.name && !isNaN(parseFloat(item.price)) && parseFloat(item.price) > 0;
          });

          console.log('✓ Parsed items:', newItems);
          console.log('📊 Items count:', newItems.length);

          if (newItems.length === 0) {
            console.warn('⚠️ No valid items found');
            console.log('Expected columns:', 'Tên món (or name), Giá bán (or price)');
            console.log('Found columns in file:', actualHeaders);
            alert(`⚠️ Không tìm thấy dữ liệu hợp lệ.\n\nCác cột trong file của bạn:\n${actualHeaders.join(', ')}\n\nFile cần có cột:\n• "Tên món" hoặc "name"\n• "Giá bán" hoặc "price"`);
            return;
          }

          // Merge with existing items
          setFormData(prev => ({
            ...prev,
            menu: [...prev.menu, ...newItems]
          }));

          console.log('✅ File processed successfully, added', newItems.length, 'items');
          alert(`✓ Đã thêm ${newItems.length} món ăn từ file!`);
          setUploadedFile(file);
          setFileUploaded(true);
        } catch (parseError) {
          console.error('❌ Parse error:', parseError);
          alert(`Lỗi khi xử lý file: ${parseError instanceof Error ? parseError.message : 'Không xác định'}`);
        }
      };

      reader.readAsArrayBuffer(file);
    } catch (error) {
      console.error('❌ Error:', error);
      alert(`Lỗi: ${error instanceof Error ? error.message : 'Không xác định'}`);
    }
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
            image_url: imageUrl || undefined,
          };
        }),
      );

      const payload = {
        sourceMode,
        p_name: formData.name,
        p_address: formData.address,
        p_city: formData.city,
        p_lat: formData.latitude,
        p_lng: formData.longitude,
        p_vendor_id: sourceMode === 'vendor' ? selectedVendorId : undefined,
        p_email: formData.email.trim(),
        p_phone: formData.phone.trim(),
        p_type_id: formData.typeId,
        p_type_name: formData.type,
        p_categories: formData.type ? [formData.type] : [],
        p_open_time: formData.openTime, // Thêm trường này
        p_close_time: formData.closeTime, // Thêm trường này
        p_description: formData.description,
        p_services: formData.amenities.map(a => ({
          name: a.name,
          description: a.description || ''
        })),
        p_menu: menuWithUploadedImages,
        p_images: uploadedUrls // Mảng 5 URL ảnh đã upload lên cloud
      };

      await locationAPI.createFullLocation(payload);
      window.localStorage.removeItem(ADMIN_ADD_LOCATION_DRAFT_KEY);

      alert('Tạo địa điểm và lưu ảnh thành công!');
      navigate('/admin/locations');

    } catch (error) {
      console.error('Lỗi khi thêm địa điểm:', error);
      const responseMessage = (error as any)?.response?.data?.message;
      const responseError = (error as any)?.response?.data?.error;
      const message = Array.isArray(responseMessage)
        ? responseMessage.join('\n')
        : responseMessage || responseError || (error instanceof Error ? error.message : '');
      alert(message ? `Không thể tạo địa điểm: ${message}` : 'Không thể tạo địa điểm. Vui lòng thử lại.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleNext = () => {
    if (step === 1 && !validateBasicInfo()) {
      return;
    }

    if (step === 2 && serviceMode === 'free' && serviceInput.name.trim()) {
      alert('Bạn có dịch vụ chưa thêm vào danh sách. Vui lòng bấm Thêm vào danh sách hoặc xóa nội dung.');
      return;
    }

    if (step === 2 && serviceMode === 'paid' && (menuInput.name.trim() || menuInput.price.trim())) {
      alert('Bạn có dịch vụ có phí chưa thêm vào danh sách. Vui lòng bấm Thêm hoặc xóa nội dung.');
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

  const mapTiles = getMapTiles(formData.latitude, formData.longitude, mapSize.width, mapSize.height, mapZoom);

  const renderStep1 = () => (
    <div style={{ display: 'flex', gap: '48px' }}>
      <div style={{ flex: 1 }}>
        <div style={{ marginBottom: '24px' }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '10px' }}>
            Nguồn địa điểm
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '12px', marginBottom: sourceMode === 'vendor' ? '16px' : 0 }}>
            {[
              { value: 'system' as const, label: 'Địa điểm hệ thống', description: 'Admin quản lý trực tiếp' },
              { value: 'vendor' as const, label: 'Thuộc đối tác', description: 'Gắn địa điểm cho provider' },
            ].map((option) => {
              const active = sourceMode === option.value;
              return (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => {
                    setSourceMode(option.value);
                    if (option.value === 'system') {
                      setSelectedVendorId('');
                    }
                  }}
                  style={{
                    textAlign: 'left',
                    padding: '14px 16px',
                    borderRadius: '14px',
                    border: `1px solid ${active ? '#3b82f6' : '#e2e8f0'}`,
                    background: active ? '#eff6ff' : '#ffffff',
                    color: active ? '#1d4ed8' : '#334155',
                    cursor: 'pointer',
                  }}>
                  <div style={{ fontSize: '14px', fontWeight: 800 }}>{option.label}</div>
                  <div style={{ marginTop: '4px', fontSize: '12px', color: active ? '#3b82f6' : '#94a3b8' }}>{option.description}</div>
                </button>
              );
            })}
          </div>
          {sourceMode === 'vendor' && (
            <div>
              <select
                value={selectedVendorId}
                onChange={(event) => setSelectedVendorId(event.target.value)}
                disabled={loadingVendors || !!vendorsError || vendors.length === 0}
                style={{
                  width: '100%',
                  padding: '14px 16px',
                  borderRadius: '12px',
                  border: `1px solid ${vendorsError ? '#ef4444' : 'var(--border-color)'}`,
                  background: '#fcfcfc',
                  outline: 'none',
                  fontSize: '15px',
                  color: '#1e293b',
                }}>
                {loadingVendors ? (
                  <option value="">Đang tải danh sách đối tác...</option>
                ) : vendorsError ? (
                  <option value="">Không tải được danh sách đối tác</option>
                ) : vendors.length === 0 ? (
                  <option value="">Chưa có đối tác phù hợp</option>
                ) : (
                  <>
                    <option value="" disabled>-- Chọn đối tác --</option>
                    {vendors.map((vendor) => (
                      <option key={vendor.id} value={vendor.id}>
                        {vendor.name}{vendor.email ? ` - ${vendor.email}` : ''}
                      </option>
                    ))}
                  </>
                )}
              </select>
              {vendorsError && (
                <div style={{ marginTop: '8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
                  <span style={{ color: '#dc2626', fontSize: '13px', lineHeight: 1.4 }}>
                    Không thể tải danh sách đối tác.
                  </span>
                  <button
                    type="button"
                    onClick={loadVendors}
                    disabled={loadingVendors}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                      border: '1px solid #fecaca',
                      background: '#fff',
                      color: '#dc2626',
                      borderRadius: '10px',
                      padding: '8px 10px',
                      cursor: loadingVendors ? 'not-allowed' : 'pointer',
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
          )}
        </div>
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
        <div style={{ display: 'flex', gap: '16px' }}>
          <div style={{ flex: 1 }}>
            <Input
              label="Giờ mở cửa"
              type="time"
              value={formData.openTime}
              onChange={(e) => setFormData({ ...formData, openTime: e.target.value })}
              icon={<Clock size={18} />}
              style={{ marginBottom: 0 }}
            />
          </div>
          <div style={{ flex: 1 }}>
            <Input
              label="Giờ đóng cửa"
              type="time"
              value={formData.closeTime}
              onChange={(e) => setFormData({ ...formData, closeTime: e.target.value })}
              icon={<Clock size={18} />}
              style={{ marginBottom: 0 }}
            />
          </div>
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
            <h4 style={{ fontSize: '1rem', fontWeight: '700', fontFamily: '"Outfit", sans-serif' }}>Thực đơn món ăn (Nhà hàng)</h4>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span style={{ fontSize: '13px', fontWeight: '600', color: '#3b82f6' }}>Đăng ký thực đơn</span>
            <div
              style={{
                width: '44px',
                height: '24px',
                background: '#3b82f6',
                borderRadius: '12px',
                position: 'relative',
                cursor: 'pointer',
              }}>
              <div
                style={{
                  position: 'absolute',
                  right: '4px',
                  top: '4px',
                  width: '16px',
                  height: '16px',
                  background: 'white',
                  borderRadius: '50%',
                }}></div>
            </div>
          </div>
        </div>

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
              border: '2px dashed #E2E8F0',
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
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>Tên món ăn</label>
              <input
                placeholder="VD: Cơm Gà Hải Nam"
                value={menuInput.name}
                onChange={(e) => setMenuInput({ ...menuInput, name: e.target.value })}
                style={{
                  width: '100%',
                  height: '48px',
                  padding: '0 16px',
                  borderRadius: '12px',
                  border: '1px solid var(--border-color)',
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
                    border: '1px solid var(--border-color)',
                    background: '#fcfcfc',
                    fontSize: '15px',
                    outline: 'none',
                    color: 'var(--text-primary)',
                  }}
                />
                <span style={{ position: 'absolute', right: '14px', color: 'var(--text-secondary)', fontSize: '15px' }}>đ</span>
              </div>
            </div>
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
                  border: '1px solid var(--border-color)',
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
            <div style={{ flex: '1 1 100%', display: 'flex', justifyContent: 'flex-end' }}>
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
                }}
                onClick={handleAddMenuItem}
              >
                Thêm
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
                  background: 'white',
                  border: '1px solid #E2E8F0',
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
                  <Edit2 size={16} style={{ cursor: 'pointer' }} />
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
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: '#F0F9FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
            <FileSpreadsheet size={24} />
          </div>
          <div>
            <h5 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>Thêm món ăn từ file Excel (tùy chọn)</h5>
            <p style={{ fontSize: '13px', color: '#94a3b8' }}>Tải thêm dữ liệu thực đơn bằng file Excel. File cần có các cột: "Tên món", "Giá bán", "Mô tả" (tùy chọn).</p>
          </div>
        </div>

        <input
          type="file"
          id="fileInput"
          style={{ display: 'none' }}
          accept=".xlsx,.xls,.csv"
          onChange={(e) => {
            if (e.target.files && e.target.files[0]) {
              handleExcelFileUpload(e.target.files[0]);
            }
          }}
        />

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
          <div
            style={{
              width: '48px',
              height: '48px',
              borderRadius: '50%',
              background: '#F0F9FF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#3b82f6',
            }}>
            <Upload size={24} />
          </div>
          <div style={{ textAlign: 'center' }}>
            <p style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>Kéo thả file đã nhập liệu vào đây</p>
            <p style={{ fontSize: '13px', color: '#94a3b8' }}>Hoặc click để chọn tệp từ máy tính</p>
          </div>
          <span style={{ fontSize: '11px', fontWeight: '800', color: '#CBD5E1', letterSpacing: '1px' }}>XLSX, XLS HOẶC CSV</span>
        </div>
      </div>

      {uploadedFile && (
        <div style={{ background: '#F0FDF4', border: '1px solid #DCFCE7', borderRadius: '16px', padding: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <CheckCircle size={20} color="#22c55e" />
            <div>
              <p style={{ fontSize: '14px', fontWeight: '600', color: '#1e293b' }}>File đã tải: {uploadedFile.name}</p>
              <p style={{ fontSize: '12px', color: '#22c55e' }}>Dữ liệu đã được thêm vào danh sách</p>
            </div>
          </div>
          <button onClick={() => setUploadedFile(null)} style={{ fontSize: '13px', color: '#3b82f6', background: 'transparent', border: 'none', cursor: 'pointer', fontWeight: '600' }}>Xóa</button>
        </div>
      )}
    </div>
  );

  return (
    <>
      <div style={{ maxWidth: step === 3 ? '1200px' : '1000px', margin: '0 auto', paddingBottom: step === 3 ? '120px' : '40px' }}>
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
          <div style={{
            marginTop: step === 3 ? '0' : '48px',
            paddingTop: step === 3 ? '24px' : '32px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            background: step === 3 ? 'white' : 'transparent',
            padding: step === 3 ? '24px 40px' : '32px 0 0 0',
            position: step === 3 ? 'fixed' : 'relative',
            bottom: 0,
            left: step === 3 ? '280px' : 'auto',
            right: 0,
            zIndex: 10,
            borderTop: step === 3 ? '1px solid #f1f5f9' : 'none'
          }}>
            {step === 3 ? (
              <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: '24px', width: '100%' }}>
                <button onClick={() => navigate('/admin/locations')} style={{ background: 'transparent', border: 'none', color: '#ef4444', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>Hủy</button>
                {uploadedFile && (
                  <button onClick={() => {
                    setUploadedFile(null);
                    setFileUploaded(false);
                  }} style={{ background: 'transparent', border: 'none', color: '#64748b', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>Xóa file</button>
                )}
                <button onClick={handleBack} style={{ background: 'white', border: '1px solid #E2E8F0', padding: '10px 24px', borderRadius: '12px', fontSize: '14px', fontWeight: '700', color: '#475569', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <ArrowLeft size={18} /> Quay lại
                </button>
                {/* Ở phần Footer Actions, tìm nút Hoàn tất và sửa lại như sau: */}
                <Button
                  onClick={handleNext}
                  // Bỏ điều kiện formData.menu.length === 0
                  disabled={isLoading}
                  style={{ padding: '12px 32px', borderRadius: '12px', gap: '8px' }}
                >
                  {isLoading ? (
                    <>
                      <Loader2 size={18} className="animate-spin" /> Đang xử lý...
                    </>
                  ) : (
                    <>
                      Hoàn tất <CheckCircle size={18} />
                    </>
                  )}
                </Button>
              </div>
            ) : (
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '24px', width: '100%' }}>
                {step === 1 ? (
                  <button
                    onClick={() => navigate('/admin/locations')}
                    style={{
                      background: 'transparent',
                      color: '#64748b',
                      fontSize: '14px',
                      fontWeight: '700',
                      padding: '12px 24px',
                      cursor: 'pointer',
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

export default AddLocation;
