import React, { useEffect, useMemo, useState } from 'react';
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
} from 'lucide-react';
import { businessLocationAPI } from '../../../../services/businessLocationAPI';
import { businessReviewAPI } from '../../../../services/businessReviewAPI';
import { getPlaceDetail, getPlaceServicesByType, updatePlaceDetail, uploadPlaceImage } from '../../../../services/order.service';
import type { Location } from '../../../../types/location';
import { getCurrentUser } from '../../../../utils/auth';

type TabKey = 'Thông tin chung' | 'Đánh giá' | 'Dịch vụ';

type ReviewSort = 'newest' | 'oldest' | 'highest_rating' | 'lowest_rating';

type ServiceKind = 'free' | 'paid';

interface PlaceSummary {
  id: string;
  name: string;
  statusLabel: string;
  statusColor: string;
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
  district: string;
  openTime: string;
  closeTime: string;
  description: string;
  latitude: string;
  longitude: string;
}

interface PlaceServiceItem {
  id: string;
  name: string;
  description: string;
  price: number | null;
  isActive: boolean;
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
  district: '',
  openTime: '',
  closeTime: '',
  description: '',
  latitude: '',
  longitude: '',
};

const getText = (value: unknown, fallback = ''): string => {
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' && Number.isFinite(value)) {
    return String(value);
  }
  return fallback;
};

const getNumber = (value: unknown, fallback = 0): number => {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(/[^\d.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : fallback;
};

const getBoolean = (value: unknown, fallback = true): boolean => {
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value !== 0;
  }
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (['true', '1', 'yes', 'active', 'đang hoạt động'].includes(normalized)) {
      return true;
    }
    if (['false', '0', 'no', 'inactive', 'tạm ngưng'].includes(normalized)) {
      return false;
    }
  }
  return fallback;
};

const formatTime = (value: unknown): string => {
  const text = getText(value, '');
  if (!text) {
    return '';
  }
  if (text.length >= 5) {
    return text.slice(0, 5);
  }
  return text;
};

const formatPrice = (value: number | null): string => {
  if (value === null || Number.isNaN(value)) {
    return '0 đ';
  }
  return `${value.toLocaleString('vi-VN')} đ`;
};

const createId = (prefix: string): string => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;

const getStatusMeta = (value: unknown): { label: string; color: string } => {
  const normalized = getText(value, 'chờ duyệt').trim().toLowerCase();
  if (normalized.includes('approved') || normalized.includes('đã duyệt')) {
    return { label: 'Đã duyệt', color: '#22c55e' };
  }
  if (normalized.includes('rejected') || normalized.includes('từ chối')) {
    return { label: 'Từ chối', color: '#ef4444' };
  }
  return { label: 'Chờ duyệt', color: '#f59e0b' };
};

const getServiceIcon = (serviceName: string): React.ReactNode => {
  const lowerName = serviceName.toLowerCase();
  if (lowerName.includes('wifi')) {
    return <Wifi size={16} />;
  }
  if (lowerName.includes('xe') || lowerName.includes('đậu')) {
    return <Car size={16} />;
  }
  if (lowerName.includes('máy lạnh') || lowerName.includes('điều hòa')) {
    return <Wind size={16} />;
  }
  if (lowerName.includes('thanh toán') || lowerName.includes('thẻ')) {
    return <CreditCard size={16} />;
  }
  if (lowerName.includes('hồ bơi') || lowerName.includes('nước')) {
    return <Waves size={16} />;
  }
  return <Plus size={16} />;
};

const normalizeGallery = (raw: unknown): string[] => {
  if (Array.isArray(raw)) {
    return raw.filter((item): item is string => typeof item === 'string' && item.length > 0);
  }
  if (typeof raw === 'string' && raw) {
    return [raw];
  }
  return [];
};

const getApiErrorMessage = (error: unknown, fallback: string): string => {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.message || error.response?.data?.error;
    if (Array.isArray(message)) {
      return message.join(', ');
    }
    if (typeof message === 'string' && message.trim()) {
      return message;
    }
    if (error.message) {
      return error.message;
    }
  }

  if (error instanceof Error && error.message) {
    return error.message;
  }

  return fallback;
};

const normalizePlaceDetail = (raw: unknown): {
  summary: PlaceSummary;
  draft: PlaceDraft;
} => {
  const place = Array.isArray(raw) ? raw[0] : raw;
  const data = place && typeof place === 'object' ? (place as Record<string, unknown>) : {};
  // is_approved: true -> approved, false/null -> pending (chờ duyệt)
  const rawStatus = data.status ?? data.place_status ?? data.approval_status;
  const isApproved = data.is_approved ?? data.approved ?? data.is_active ?? data.active;
  const statusValue = rawStatus ?? (isApproved === true ? 'approved' : isApproved === false ? 'pending' : null);
  const statusMeta = getStatusMeta(statusValue);
  const gallery = normalizeGallery(data.images ?? data.gallery ?? data.image_urls ?? data.image_url)
    .filter(Boolean);

  return {
    summary: {
      id: getText(data.id ?? data.place_id ?? data.placeId, ''),
      name: getText(data.place_name ?? data.name ?? data.title, 'Đang tải...'),
      statusLabel: statusMeta.label,
      statusColor: statusMeta.color,
      isActive: getBoolean(data.is_active ?? data.active ?? true, true),
      category: getText(data.category ?? data.type ?? data.place_type, 'Địa điểm'),
      rating: getNumber(data.rating ?? data.average_rating, 0),
      reviewCount: getNumber(data.review_count ?? data.reviews_count ?? data.total_reviews, 0),
      gallery: gallery.length > 0 ? gallery : ['https://picsum.photos/seed/location/600/400'],
    },
    draft: {
      name: getText(data.place_name ?? data.name ?? data.title, 'Đang tải...'),
      address: getText(data.address ?? data.place_address, 'Chưa có địa chỉ'),
      city: getText(data.city ?? data.place_city ?? data.province, ''),
      district: getText(data.district ?? data.district_name, ''),
      openTime: formatTime(data.open_time ?? data.openTime ?? data.opening_time),
      closeTime: formatTime(data.close_time ?? data.closeTime ?? data.closing_time),
      description: getText(data.description ?? data.place_description, ''),
      latitude: getText(data.latitude ?? data.lat ?? data.p_lat, ''),
      longitude: getText(data.longitude ?? data.lng ?? data.p_lng, ''),
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
  if (!locationItem) {
    return detail;
  }

  const locationStatus = getStatusMeta(locationItem.status);
  const hasPlaceholderGallery = detail.summary.gallery.length === 1
    && detail.summary.gallery[0].includes('picsum.photos/seed/location/600/400');
  const nextGallery = hasPlaceholderGallery && locationItem.image
    ? [locationItem.image]
    : detail.summary.gallery;

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
  const currentUser = useMemo(
    () =>
      getCurrentUser<{
        businessId?: string;
        business_id?: string;
        vendorId?: string;
        vendor_id?: string;
        id?: string;
      }>(),
    [],
  );
  const vendorCandidates = useMemo(
    () =>
      [
        currentUser?.businessId,
        currentUser?.business_id,
        currentUser?.vendorId,
        currentUser?.vendor_id,
        currentUser?.id,
      ].filter((value): value is string => typeof value === 'string' && value.trim().length > 0),
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
  const [galleryImages, setGalleryImages] = useState<string[]>([]);
  const [pendingImageFiles, setPendingImageFiles] = useState<File[]>([]);
  const [savingGeneralInfo, setSavingGeneralInfo] = useState(false);

  const [reviewRating, setReviewRating] = useState<number | undefined>(undefined);
  const [reviewSort, setReviewSort] = useState<ReviewSort>('newest');
  const [reviewHasImages, setReviewHasImages] = useState(false);
  const [reviewData, setReviewData] = useState<ReviewSummary | null>(null);
  const [reviewLoading, setReviewLoading] = useState(false);
  const [reviewError, setReviewError] = useState<string | null>(null);
  const [replyingToId, setReplyingToId] = useState<string | null>(null);

  const [freeServices, setFreeServices] = useState<PlaceServiceItem[]>([]);
  const [paidServices, setPaidServices] = useState<PlaceServiceItem[]>([]);
  const [menuItems, setMenuItems] = useState<PlaceServiceItem[]>([]);
  const [servicesLoading, setServicesLoading] = useState(false);
  const [servicesError, setServicesError] = useState<string | null>(null);
  const [serviceEditor, setServiceEditor] = useState<ServiceEditorState | null>(null);
  const [serviceDraft, setServiceDraft] = useState({
    id: '',
    name: '',
    description: '',
    price: '',
    isActive: true,
  });

  useEffect(() => {
    const fetchPlaceDetail = async () => {
      if (!id) {
        setError('Không tìm thấy địa điểm cần hiển thị.');
        setLoading(false);
        return;
      }

      if (!vendorId) {
        setError('Không tìm thấy thông tin business. Vui lòng đăng nhập lại.');
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        setError(null);

        const [detailResult, listResult] = await Promise.allSettled([
          getPlaceDetail(id),
          businessLocationAPI.getLocations(
            {
              vendorId,
            },
            {
              page: 1,
              limit: 200,
            },
          ),
        ]);

        const locations = listResult.status === 'fulfilled'
          ? listResult.value.locations
          : [];
        const fromList = locations.find((item) => item.id === id)
          || null;

        if (detailResult.status === 'rejected' && !fromList) {
          throw new Error(
            getApiErrorMessage(
              detailResult.reason,
              'Không thể tải thông tin địa điểm',
            ),
          );
        }

        if (listResult.status === 'rejected' && detailResult.status === 'rejected') {
          throw new Error(
            [
              getApiErrorMessage(detailResult.reason, 'Không thể tải chi tiết địa điểm'),
              getApiErrorMessage(listResult.reason, 'Không thể tải danh sách địa điểm'),
            ].join(' | '),
          );
        }

        const rawDetail = detailResult.status === 'fulfilled' && detailResult.value
          ? detailResult.value
          : {
              id: fromList?.id,
              name: fromList?.name,
              address: fromList?.address,
              category: fromList?.category,
              status: fromList?.status,
              average_rating: fromList?.rating,
              review_count: fromList?.review_count,
              image_url: fromList?.image,
            };

        const normalized = normalizePlaceDetail(rawDetail);
        const merged = mergeWithLocationListItem(normalized, fromList);
        setPlace(merged.summary);
        setDraft(merged.draft);
        setIsActive(merged.summary.isActive);
        setGalleryImages(
          merged.summary.gallery.filter((url) => !url.includes('picsum.photos/seed/location')),
        );
        setPendingImageFiles([]);
        if (detailResult.status === 'rejected') {
          setGeneralMessage(
            `Đang hiển thị dữ liệu tạm từ danh sách. Chi tiết lỗi: ${getApiErrorMessage(
              detailResult.reason,
              'Không thể tải chi tiết địa điểm',
            )}`,
          );
        }
      } catch (err) {
        setError(getApiErrorMessage(err, 'Không thể tải thông tin địa điểm'));
      } finally {
        setLoading(false);
      }
    };

    void fetchPlaceDetail();
  }, [id, vendorId]);

  useEffect(() => {
    const fetchReviews = async () => {
      if (activeTab !== 'Đánh giá') {
        return;
      }

      const placeCandidates = [place?.id, id, id ? decodeURIComponent(id) : undefined]
        .filter((value): value is string => typeof value === 'string' && value.trim().length > 0)
        .filter((value, index, array) => array.indexOf(value) === index);

      if (placeCandidates.length === 0 || vendorCandidates.length === 0) {
        return;
      }

      try {
        setReviewLoading(true);
        setReviewError(null);
        let loaded = false;
        let lastError: unknown = null;

        for (const placeIdCandidate of placeCandidates) {
          for (const vendorIdCandidate of vendorCandidates) {
            try {
              const response = await businessReviewAPI.getReviews(
                {
                  vendorId: vendorIdCandidate,
                  placeId: placeIdCandidate,
                  rating: reviewRating,
                  sort: reviewSort,
                  hasImages: reviewHasImages || undefined,
                },
                1,
                20,
              );

              setReviewData({
                stats: response.stats,
                reviews: response.reviews,
                availableTopics: response.availableTopics,
              });
              loaded = true;
              break;
            } catch (error) {
              lastError = error;
            }
          }

          if (loaded) {
            break;
          }
        }

        if (!loaded) {
          throw lastError || new Error('Không thể tải đánh giá');
        }
      } catch (err) {
        setReviewData(null);
        setReviewError(getApiErrorMessage(err, 'Không thể tải đánh giá'));
      } finally {
        setReviewLoading(false);
      }
    };

    void fetchReviews();
  }, [activeTab, id, place?.id, reviewHasImages, reviewRating, reviewSort, vendorCandidates]);

  useEffect(() => {
    const fetchServices = async () => {
      const targetPlaceId = place?.id || id;
      if (!targetPlaceId || activeTab !== 'Dịch vụ') {
        return;
      }

      try {
        setServicesLoading(true);
        setServicesError(null);
        const rawServices = await getPlaceServicesByType(targetPlaceId);
        const payload = rawServices && typeof rawServices === 'object' ? (rawServices as Record<string, unknown>) : {};
        const nested = (payload.data as Record<string, unknown> | undefined) ?? {};
        const free = Array.isArray(payload.freeServices) ? payload.freeServices : Array.isArray(nested.freeServices) ? (nested.freeServices as unknown[]) : [];
        const paid = Array.isArray(payload.paidServices) ? payload.paidServices : Array.isArray(nested.paidServices) ? (nested.paidServices as unknown[]) : [];
        const menu = Array.isArray(payload.menuItems) ? payload.menuItems : Array.isArray(nested.menuItems) ? (nested.menuItems as unknown[]) : [];

        setFreeServices(free.map((item) => normalizeServiceItem(item, 'free')));
        setPaidServices(paid.map((item) => normalizeServiceItem(item, 'paid')));
        setMenuItems(menu.map((item) => normalizeServiceItem(item, 'paid')));
      } catch (err) {
        setServicesError(getApiErrorMessage(err, 'Không thể tải dịch vụ'));
        setFreeServices([]);
        setPaidServices([]);
      } finally {
        setServicesLoading(false);
      }
    };

    void fetchServices();
  }, [activeTab, id, place?.id]);

  const locationData = useMemo(() => {
    return {
      reviews: {
        average: reviewData?.stats.averageRating || 0,
        total: reviewData?.stats.totalReviews || 0,
        distribution: [5, 4, 3, 2, 1].map((score) => ({
          score,
          percentage: reviewData?.stats.breakdown[score as 1 | 2 | 3 | 4 | 5]?.percent || 0,
        })),
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
        })),
      },
    };
  }, [reviewData]);

  const pageTitle = draft.name || place?.name || 'Đang tải...';
  const statusMeta = place
    ? { label: place.statusLabel, color: place.statusColor }
    : { label: 'Chờ duyệt', color: '#f59e0b' };

  const savedGeneralInfo = async () => {
    if (!id || !vendorId) {
      setGeneralMessage('Không tìm thấy thông tin địa điểm hoặc đối tác.');
      return;
    }

    if (!draft.name.trim() || !draft.address.trim()) {
      setGeneralMessage('Vui lòng nhập đầy đủ tên và địa chỉ địa điểm.');
      return;
    }

    try {
      setSavingGeneralInfo(true);
      setGeneralMessage(null);

      const existingImages = galleryImages.filter((url) => !url.startsWith('blob:'));
      const uploadedImages = await Promise.all(
        pendingImageFiles.map((file) => uploadPlaceImage(file, id)),
      );
      const imageUrls = [...existingImages, ...uploadedImages]
        .filter((url): url is string => typeof url === 'string' && url.trim().length > 0);

      await updatePlaceDetail({
        placeId: id,
        vendorId,
        name: draft.name.trim(),
        address: draft.address.trim(),
        city: draft.city.trim(),
        latitude: draft.latitude,
        longitude: draft.longitude,
        openTime: draft.openTime,
        closeTime: draft.closeTime,
        description: draft.description,
        imageUrls,
        isActive,
      });

      navigate('/locations');
    } catch (err) {
      setGeneralMessage(getApiErrorMessage(err, 'Không thể lưu thay đổi địa điểm'));
    } finally {
      setSavingGeneralInfo(false);
    }
  };

  const openServiceEditor = (kind: ServiceKind, service?: PlaceServiceItem) => {
    setServiceEditor({
      kind,
      mode: service ? 'edit' : 'create',
    });
    setServiceDraft({
      id: service?.id || '',
      name: service?.name || '',
      description: service?.description || '',
      price: service?.price !== null && service?.price !== undefined ? String(service.price) : '',
      isActive: service?.isActive ?? true,
    });
  };

  const closeServiceEditor = () => {
    setServiceEditor(null);
    setServiceDraft({
      id: '',
      name: '',
      description: '',
      price: '',
      isActive: true,
    });
  };

  const saveService = () => {
    if (!serviceEditor) {
      return;
    }

    const trimmedName = serviceDraft.name.trim();
    if (!trimmedName) {
      window.alert('Vui lòng nhập tên dịch vụ');
      return;
    }

    const nextService: PlaceServiceItem = {
      id: serviceDraft.id || createId(serviceEditor.kind),
      name: trimmedName,
      description: serviceDraft.description.trim(),
      price: serviceEditor.kind === 'paid'
        ? (() => {
            const numericPrice = Number(String(serviceDraft.price).replace(/[^\d.-]/g, ''));
            return Number.isFinite(numericPrice) ? numericPrice : 0;
          })()
        : null,
      isActive: serviceDraft.isActive,
    };

    if (serviceEditor.kind === 'free') {
      setFreeServices((current) => {
        if (serviceEditor.mode === 'edit') {
          return current.map((item) => (item.id === nextService.id ? nextService : item));
        }
        return [...current, nextService];
      });
    } else {
      setPaidServices((current) => {
        if (serviceEditor.mode === 'edit') {
          return current.map((item) => (item.id === nextService.id ? nextService : item));
        }
        return [...current, nextService];
      });
    }

    closeServiceEditor();
  };

  const deleteService = (kind: ServiceKind, serviceId: string) => {
    if (kind === 'free') {
      setFreeServices((current) => current.filter((item) => item.id !== serviceId));
      return;
    }
    setPaidServices((current) => current.filter((item) => item.id !== serviceId));
  };

  const togglePaidService = (serviceId: string) => {
    setPaidServices((current) =>
      current.map((item) =>
        item.id === serviceId ? { ...item, isActive: !item.isActive } : item,
      ),
    );
  };

  const renderGeneralInfo = () => (
    <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', padding: '32px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
      {generalMessage && (
        <div style={{ marginBottom: '20px', padding: '12px 16px', borderRadius: '12px', background: '#eff6ff', color: '#2563eb', fontSize: '14px', fontWeight: '600' }}>
          {generalMessage}
        </div>
      )}

      <div style={{ display: 'flex', gap: '48px', alignItems: 'flex-start' }}>
        <div style={{ flex: 1.2 }}>
          <Input label="Tên địa điểm" value={draft.name} onChange={(event) => setDraft((current) => ({ ...current, name: event.target.value }))} />
          <Input label="Địa chỉ chi tiết" value={draft.address} onChange={(event) => setDraft((current) => ({ ...current, address: event.target.value }))} />

          <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <Input
                label="Tỉnh/Thành phố"
                value={draft.city}
                onChange={(event) => setDraft((current) => ({ ...current, city: event.target.value }))}
                style={{ marginBottom: 0 }}
              />
            </div>
            <div style={{ flex: 1 }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>SĐT liên hệ</label>
              <input
                value={draft.district}
                onChange={(event) => setDraft((current) => ({ ...current, district: event.target.value }))}
                style={{ width: '100%', padding: '14px 16px', borderRadius: '12px', border: '1px solid #E2E8F0', background: '#fcfcfc', outline: 'none', fontSize: '15px', color: '#1e293b' }}
                placeholder="Số điện thoại liên hệ..."
              />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <Input
                label="Giờ mở cửa"
                value={draft.openTime}
                onChange={(event) => setDraft((current) => ({ ...current, openTime: event.target.value }))}
                icon={<Clock size={16} />}
                style={{ marginBottom: 0 }}
              />
            </div>
            <div style={{ flex: 1 }}>
              <Input
                label="Giờ đóng cửa"
                value={draft.closeTime}
                onChange={(event) => setDraft((current) => ({ ...current, closeTime: event.target.value }))}
                icon={<Clock size={16} />}
                style={{ marginBottom: 0 }}
              />
            </div>
          </div>

          <div>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>Mô tả địa điểm</label>
            <textarea
              style={{ width: '100%', minHeight: '160px', padding: '16px', borderRadius: '12px', border: '1px solid #E2E8F0', background: '#fcfcfc', outline: 'none', fontSize: '15px', color: '#1e293b', lineHeight: '1.6', resize: 'vertical' }}
              value={draft.description}
              onChange={(event) => setDraft((current) => ({ ...current, description: event.target.value }))}
              placeholder="Nhập mô tả địa điểm..."
            />
          </div>
        </div>

        <div style={{ flex: 1 }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>Vị trí trên bản đồ</label>
          <div style={{ width: '100%', height: '240px', background: '#f8fafc', borderRadius: '16px', border: '1px solid #E2E8F0', overflow: 'hidden', position: 'relative', marginBottom: '24px' }}>
            <img
              src="https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=600&h=400&fit=crop"
              alt="Map"
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -100%)', color: '#ef4444' }}>
              <MapPin size={32} fill="#ef444433" />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '16px', marginBottom: '32px' }}>
            <div style={{ flex: 1 }}>
              <Input label="Vĩ độ (Latitude)" value={draft.latitude} onChange={(event) => setDraft((current) => ({ ...current, latitude: event.target.value }))} style={{ marginBottom: 0 }} />
            </div>
            <div style={{ flex: 1 }}>
              <Input label="Kinh độ (Longitude)" value={draft.longitude} onChange={(event) => setDraft((current) => ({ ...current, longitude: event.target.value }))} style={{ marginBottom: 0 }} />
            </div>
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>Hình ảnh địa điểm ({galleryImages.length})</label>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '12px' }}>
              {(galleryImages.length ? galleryImages : ['https://picsum.photos/seed/location/200/200']).map((image, index) => (
                <div key={`${image}-${index}`} style={{ aspectRatio: '1', borderRadius: '12px', overflow: 'hidden', border: '1px solid #F1F5F9' }}>
                  <img src={image} alt={`Gallery ${index + 1}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              ))}
              <label style={{ aspectRatio: '1', borderRadius: '12px', border: '2px dashed #E2E8F0', background: '#F8FAFC', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '4px', cursor: 'pointer', color: '#94a3b8' }}>
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  style={{ display: 'none' }}
                  onChange={(event) => {
                    const files = Array.from(event.target.files ?? []);
                    if (files.length === 0) {
                      return;
                    }
                    setPendingImageFiles((current) => [...current, ...files]);
                    setGalleryImages((current) => [
                      ...current.filter((url) => !url.includes('picsum.photos/seed/location')),
                      ...files.map((file) => URL.createObjectURL(file)),
                    ]);
                    event.target.value = '';
                  }}
                />
                <Upload size={20} />
                <span style={{ fontSize: '10px', fontWeight: '800' }}>TẢI LÊN</span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <div style={{ marginTop: '48px', paddingTop: '32px', borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'flex-end', gap: '16px', alignItems: 'center' }}>
        <span onClick={() => navigate('/locations')} style={{ color: '#64748b', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>Hủy bỏ</span>
        <Button onClick={savedGeneralInfo} disabled={savingGeneralInfo} style={{ padding: '12px 32px', borderRadius: '12px' }}>
          {savingGeneralInfo ? 'Đang lưu...' : 'Lưu thay đổi'}
        </Button>
      </div>
    </div>
  );

  const renderReviews = () => {
    const reviews = locationData.reviews.list;
    const displayAverageRating = locationData.reviews.average;
    const displayTotalReviews = locationData.reviews.total;
    const displayBreakdown = locationData.reviews.distribution.reduce((accumulator, item) => {
      accumulator[item.score as 1 | 2 | 3 | 4 | 5] = {
        count: 0,
        percent: item.percentage,
      };
      return accumulator;
    }, {
      5: { count: 0, percent: 0 },
      4: { count: 0, percent: 0 },
      3: { count: 0, percent: 0 },
      2: { count: 0, percent: 0 },
      1: { count: 0, percent: 0 },
    } as Record<1 | 2 | 3 | 4 | 5, { count: number; percent: number }>);

    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
        <div style={{ background: 'white', borderRadius: '24px', padding: '32px', border: '1px solid #F1F5F9', display: 'flex', gap: '48px', alignItems: 'center' }}>
          <div style={{ textAlign: 'center', paddingRight: '48px', borderRight: '1px solid #F1F5F9' }}>
            <h1 style={{ fontSize: '48px', fontWeight: '800', color: '#1e293b', marginBottom: '8px' }}>{displayAverageRating}</h1>
            <div style={{ display: 'flex', gap: '4px', justifyContent: 'center', color: '#fbbf24', marginBottom: '8px' }}>
              {[1, 2, 3, 4, 5].map((score) => (
                <Star key={score} size={20} fill="#fbbf24" color="#fbbf24" />
              ))}
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
                  <span style={{ fontSize: '12px', fontWeight: '600', color: '#94a3b8', minWidth: '32px' }}>{item.percent}%</span>
                </div>
              );
            })}
          </div>
        </div>

        <div>
          <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '20px', fontFamily: '"Outfit", sans-serif' }}>Bộ lọc đánh giá</h5>
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
            <select
              value={reviewRating ?? ''}
              onChange={(event) => setReviewRating(event.target.value ? Number(event.target.value) : undefined)}
              style={{ padding: '8px 16px', borderRadius: '10px', border: '1px solid #E2E8F0', fontSize: '13px', background: 'white' }}>
              <option value="">Tất cả sao</option>
              <option value="5">5 sao</option>
              <option value="4">4 sao</option>
              <option value="3">3 sao</option>
              <option value="2">2 sao</option>
              <option value="1">1 sao</option>
            </select>

            <Button
              variant="outline"
              onClick={() => setReviewSort('newest')}
              style={{
                borderRadius: '10px',
                fontSize: '13px',
                padding: '8px 20px',
                background: reviewSort === 'newest' ? '#EFF6FF' : 'white',
                borderColor: reviewSort === 'newest' ? '#3b82f6' : '#E2E8F0',
                color: reviewSort === 'newest' ? '#3b82f6' : '#64748b',
                fontWeight: '700',
              }}>
              Mới nhất
            </Button>
            <Button
              variant="outline"
              onClick={() => setReviewHasImages((current) => !current)}
              style={{
                borderRadius: '10px',
                fontSize: '13px',
                padding: '8px 20px',
                color: reviewHasImages ? '#3b82f6' : '#64748b',
                borderColor: reviewHasImages ? '#3b82f6' : '#E2E8F0',
                background: reviewHasImages ? '#EFF6FF' : 'white',
              }}>
              Có hình ảnh
            </Button>
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
                    {[1, 2, 3, 4, 5].map((score) => (
                      <Star key={score} size={16} fill={score <= review.rating ? '#fbbf24' : 'none'} color="#fbbf24" />
                    ))}
                  </div>
                </div>

                <p style={{ fontSize: '15px', color: '#475569', lineHeight: '1.7', marginBottom: '20px' }}>{review.content}</p>

                {review.images.length > 0 && (
                  <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', flexWrap: 'wrap' }}>
                    {review.images.map((image, index) => (
                      <img key={`${review.id}-${index}`} src={image} alt="Review" style={{ width: '120px', height: '90px', borderRadius: '12px', objectFit: 'cover' }} />
                    ))}
                  </div>
                )}

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px' }}>
                  <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                    {review.tags.map((tag) => (
                      <span key={`${review.id}-${tag.name}`} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 12px', background: '#F1F5F9', color: tag.color, borderRadius: '8px', fontSize: '12px', fontWeight: '700' }}>
                        {tag.name}
                      </span>
                    ))}
                  </div>
                  <Button
                    variant="outline"
                    onClick={() => setReplyingToId((current) => (current === review.id ? null : review.id))}
                    style={{ borderRadius: '10px', fontSize: '13px', padding: '6px 20px', color: '#3b82f6', borderColor: '#EFF6FF', background: '#EFF6FF' }}>
                    {replyingToId === review.id ? 'Hủy' : 'Trả lời'}
                  </Button>
                </div>

                {replyingToId === review.id && (
                  <div style={{ marginTop: '24px', padding: '24px', background: '#F8FAFC', borderRadius: '16px', border: '1px solid #F1F5F9' }}>
                    <label style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', display: 'block', marginBottom: '12px' }}>Nội dung phản hồi khách hàng</label>
                    <textarea
                      placeholder="Cảm ơn bạn đã phản hồi, chúng tôi sẽ sớm cải thiện..."
                      style={{ width: '100%', minHeight: '100px', padding: '16px', borderRadius: '12px', border: '1px solid #E2E8F0', outline: 'none', fontSize: '14px', lineHeight: '1.6', marginBottom: '16px', resize: 'vertical' }}
                    />
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                      <Button variant="outline" onClick={() => setReplyingToId(null)} style={{ padding: '8px 20px', borderRadius: '8px', fontSize: '13px' }}>
                        Hủy bỏ
                      </Button>
                      <Button onClick={() => setReplyingToId(null)} style={{ padding: '8px 24px', borderRadius: '8px', fontSize: '13px' }}>
                        Gửi phản hồi
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

  const renderServiceEditor = (kind: ServiceKind) => {
    if (!serviceEditor || serviceEditor.kind !== kind) {
      return null;
    }

    return (
      <div style={{ marginBottom: '24px', padding: '24px', background: '#F8FAFC', border: '1px solid #E2E8F0', borderRadius: '20px' }}>
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ flex: '1 1 280px' }}>
            <Input
              label="Tên dịch vụ"
              value={serviceDraft.name}
              onChange={(event) => setServiceDraft((current) => ({ ...current, name: event.target.value }))}
              style={{ marginBottom: 0 }}
            />
          </div>
          <div style={{ flex: '1 1 360px' }}>
            <Input
              label="Mô tả"
              value={serviceDraft.description}
              onChange={(event) => setServiceDraft((current) => ({ ...current, description: event.target.value }))}
              style={{ marginBottom: 0 }}
            />
          </div>
          {kind === 'paid' && (
            <div style={{ flex: '1 1 180px' }}>
              <Input
                label="Giá dịch vụ"
                value={serviceDraft.price}
                onChange={(event) => setServiceDraft((current) => ({ ...current, price: event.target.value }))}
                style={{ marginBottom: 0 }}
                placeholder="Ví dụ: 200000"
              />
            </div>
          )}
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
          <Button variant="outline" onClick={closeServiceEditor}>Hủy</Button>
          <Button onClick={saveService}>Lưu</Button>
        </div>
      </div>
    );
  };

  const isRestaurant = (place?.category ?? '').toLowerCase().includes('nhà hàng') || (place?.category ?? '').toLowerCase().includes('restaurant');

  const renderServicesMenu = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '48px' }}>
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>Tiện ích miễn phí</h5>
          <Button variant="outline" onClick={() => openServiceEditor('free')} style={{ borderRadius: '10px', fontSize: '13px', gap: '8px', padding: '8px 16px' }}>
            <Plus size={16} /> Thêm tiện ích
          </Button>
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

            <div
              onClick={() => openServiceEditor('free')}
              style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '12px 24px', border: '1px solid #E2E8F0', borderStyle: 'dashed', color: '#94a3b8', borderRadius: '20px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', background: 'transparent' }}>
              <Plus size={16} /> <span>Thêm tiện ích</span>
            </div>
          </div>
        )}
      </div>

      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>Dịch vụ tính phí ({paidServices.length})</h5>
          <Button variant="outline" onClick={() => openServiceEditor('paid')} style={{ borderRadius: '10px', fontSize: '13px', gap: '8px', padding: '8px 16px' }}>
            <Plus size={16} /> Thêm dịch vụ
          </Button>
        </div>

        {renderServiceEditor('paid')}

        <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', overflow: 'hidden', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
          {servicesLoading ? (
            <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>Đang tải dịch vụ...</div>
          ) : paidServices.length > 0 ? (
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ textAlign: 'left', background: '#FCFCFD', borderBottom: '1px solid #F1F5F9' }}>
                  <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Tên dịch vụ</th>
                  <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: 'center' }}>Giá dịch vụ</th>
                  <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: 'center' }}>Trạng thái</th>
                  <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: 'center' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {paidServices.map((service, index) => (
                  <tr key={service.id} style={{ borderBottom: index < paidServices.length - 1 ? '1px solid #F8FAFC' : 'none' }}>
                    <td style={{ padding: '24px 32px', fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{service.name}</td>
                    <td style={{ padding: '24px 32px', fontSize: '15px', fontWeight: '800', color: '#3b82f6', textAlign: 'center', textDecoration: 'underline' }}>{formatPrice(service.price)}</td>
                    <td style={{ padding: '24px 32px', textAlign: 'center' }}>
                      <button
                        type="button"
                        onClick={() => togglePaidService(service.id)}
                        style={{ width: '44px', height: '24px', background: service.isActive ? '#3b82f6' : '#E2E8F0', borderRadius: '20px', position: 'relative', cursor: 'pointer', display: 'inline-block', verticalAlign: 'middle', border: 'none' }}>
                        <span style={{ position: 'absolute', right: service.isActive ? '4px' : 'auto', left: service.isActive ? 'auto' : '4px', top: '4px', width: '16px', height: '16px', background: 'white', borderRadius: '50%', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }} />
                      </button>
                    </td>
                    <td style={{ padding: '24px 32px', textAlign: 'center' }}>
                      <div style={{ display: 'flex', gap: '16px', color: '#94a3b8', justifyContent: 'center' }}>
                        <Edit2 size={18} style={{ cursor: 'pointer' }} onClick={() => openServiceEditor('paid', service)} />
                        <Trash2 size={18} style={{ cursor: 'pointer' }} onClick={() => deleteService('paid', service.id)} />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>Chưa có dịch vụ tính phí nào</div>
          )}
        </div>
      </div>

      {isRestaurant && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <h5 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>Quản lý thực đơn món ăn ({menuItems.length})</h5>
            <Button variant="outline" onClick={() => openServiceEditor('paid')} style={{ borderRadius: '10px', fontSize: '13px', gap: '8px', padding: '8px 16px' }}>
              <Plus size={16} /> Thêm món
            </Button>
          </div>

          <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', overflow: 'hidden', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
            {servicesLoading ? (
              <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>Đang tải thực đơn...</div>
            ) : menuItems.length > 0 ? (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ textAlign: 'left', background: '#FCFCFD', borderBottom: '1px solid #F1F5F9' }}>
                    <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Tên món</th>
                    <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Mô tả</th>
                    <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: 'center' }}>Giá</th>
                    <th style={{ padding: '20px 32px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: 'center' }}>Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  {menuItems.map((item, index) => (
                    <tr key={item.id} style={{ borderBottom: index < menuItems.length - 1 ? '1px solid #F8FAFC' : 'none' }}>
                      <td style={{ padding: '24px 32px', fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{item.name}</td>
                      <td style={{ padding: '24px 32px', fontSize: '14px', color: '#64748b' }}>{item.description || '-'}</td>
                      <td style={{ padding: '24px 32px', fontSize: '15px', fontWeight: '800', color: '#3b82f6', textAlign: 'center' }}>{formatPrice(item.price)}</td>
                      <td style={{ padding: '24px 32px', textAlign: 'center' }}>
                        <div style={{ display: 'flex', gap: '16px', color: '#94a3b8', justifyContent: 'center' }}>
                          <Edit2 size={18} style={{ cursor: 'pointer' }} onClick={() => openServiceEditor('paid', item)} />
                          <Trash2 size={18} style={{ cursor: 'pointer' }} onClick={() => setMenuItems((current) => current.filter((m) => m.id !== item.id))} />
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>Chưa có món ăn nào trong thực đơn</div>
            )}
          </div>
        </div>
      )}
    </div>
  );

  return (
    <>
      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>Đang tải dữ liệu địa điểm...</div>
      ) : error ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#ef4444' }}>{error}</div>
      ) : (
        <div style={{ padding: '0 20px' }}>
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

            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <span style={{ fontSize: '14px', fontWeight: 'bold', color: '#64748b' }}>
                Trạng thái: <span style={{ color: '#3b82f6' }}>{isActive ? 'Đang hoạt động' : 'Tạm ngưng'}</span>
              </span>
              <div
                onClick={() => setIsActive((current) => !current)}
                style={{ width: '44px', height: '22px', background: isActive ? '#3b82f6' : '#E2E8F0', borderRadius: '12px', position: 'relative', cursor: 'pointer', transition: '0.2s' }}>
                <div style={{ position: 'absolute', left: isActive ? '24px' : '4px', top: '3px', width: '16px', height: '16px', background: 'white', borderRadius: '50%', transition: '0.2s' }} />
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '32px', marginBottom: '32px', borderBottom: '1px solid #F1F5F9' }}>
            {(['Thông tin chung', 'Đánh giá', 'Dịch vụ'] as TabKey[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{
                  padding: '12px 0',
                  fontSize: '14px',
                  fontWeight: activeTab === tab ? '700' : '600',
                  color: activeTab === tab ? '#3b82f6' : '#64748b',
                  background: 'transparent',
                  border: 'none',
                  borderBottom: activeTab === tab ? '2px solid #3b82f6' : '2px solid transparent',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  marginBottom: '-1px',
                }}>
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

