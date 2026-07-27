import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  AlertCircle,
  ArrowUpDown,
  ChevronDown,
  ChevronUp,
  MapPin,
  PackageCheck,
  ShoppingBag,
} from 'lucide-react';
import { businessLocationAPI } from '@/services/businessLocationAPI';
import { getDashboardStats, getFoodPerformance, getOrdersByPlace, getPlaceServicesByType, isPendingOrder, normalizeOrderStatus } from '@/services/order.service';
import { getCurrentUser } from '@/utils/auth';
import type { Location } from '@/types/location';

interface DashboardStats {
  totalPlaces: number;
  pendingOrders: number;
  activeItems: number;
  averageRating: number;
}

interface PerformanceItem {
  id: string;
  name: string;
  locationName: string;
  category: string;
  price: number;
  orderCount: number;
  revenue: number;
  rating: number;
  rawDate?: string;
  imageUrl?: string;
}

interface DashboardFallbackData {
  stats: DashboardStats;
  performance: PerformanceItem[];
}

interface ProviderUser {
  businessId?: string;
  business_id?: string;
  vendorId?: string;
  vendor_id?: string;
  id?: string;
}

interface StatCardProps {
  label: string;
  value: string | number;
  icon: React.ReactNode;
  loading?: boolean;
  onClick: () => void;
}

type SortKey = 'name' | 'location' | 'price' | 'orders' | 'revenue';
type SortDirection = 'asc' | 'desc';

interface DashboardPeriod {
  month?: number;
  year?: number;
}

const numberFrom = (...values: unknown[]): number => {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
    if (typeof value === 'string' && value.trim()) {
      const parsed = Number(value.replace(/[^\d.-]/g, ''));
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }
  return 0;
};

const textFrom = (...values: unknown[]): string => {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) {
      return value.trim();
    }
  }
  return '';
};

const getVendorId = (user: ProviderUser | null): string => {
  return (
    [
      user?.businessId,
      user?.business_id,
      user?.vendorId,
      user?.vendor_id,
      user?.id,
    ].find((value): value is string => typeof value === 'string' && value.trim().length > 0) || ''
  );
};

const normalizeStats = (payload: unknown): DashboardStats => {
  const data = payload && typeof payload === 'object' ? (payload as Record<string, unknown>) : {};

  return {
    totalPlaces: numberFrom(
      data.total_places,
      data.totalPlaces,
      data.total_locations,
      data.totalLocations,
      data.places_count,
    ),
    pendingOrders: numberFrom(
      data.pending_orders,
      data.pendingOrders,
      data.new_orders,
      data.newOrders,
      data.total_pending_orders,
    ),
    activeItems: numberFrom(
      data.total_food_items,
      data.totalFoodItems,
      data.active_items,
      data.activeItems,
      data.active_products,
      data.total_services,
    ),
    averageRating: numberFrom(data.average_rating, data.averageRating, data.avg_rating, data.rating),
  };
};

const normalizePerformanceItem = (item: unknown, index: number): PerformanceItem => {
  const data = item && typeof item === 'object' ? (item as Record<string, unknown>) : {};
  const orderCount = numberFrom(
    data.order_count,
    data.orderCount,
    data.orders,
    data.booking_count,
    data.bookingCount,
    data.quantity,
  );
  const price = numberFrom(data.price, data.food_price, data.service_price, data.amount);
  const revenue = price * orderCount;

  return {
    id: textFrom(data.food_id, data.service_id, data.product_id, data.id) || `performance-${index}`,
    name: textFrom(data.food_name, data.service_name, data.product_name, data.name, data.title) || 'Chưa đặt tên',
    locationName: textFrom(data.place_name, data.location_name, data.restaurant_name, data.placeName) || 'Chưa rõ địa điểm',
    category: textFrom(
      data.place_category,
      data.location_category,
      data.travel_type,
      data.type_name,
      data.place_type_name,
      data.place_type,
      data.p_type_name,
      data.category_name,
      data.category,
      data.type,
      data.product_type,
      data.service_type,
    ) || 'Địa điểm',
    price,
    orderCount,
    revenue,
    rating: numberFrom(data.rating, data.average_rating, data.avg_rating),
    rawDate: textFrom(data.ordered_time, data.created_at, data.date, data.month),
    imageUrl: textFrom(data.image_url, data.imageUrl, data.photo, data.thumbnail) || undefined,
  };
};

const isActiveService = (value: unknown): boolean => {
  if (value === undefined || value === null) {
    return true;
  }
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value === 1;
  }
  if (typeof value === 'string') {
    return ['true', '1', 'active', 'approved'].includes(value.toLowerCase());
  }
  return true;
};

const buildServicePerformance = (
  locations: Location[],
  servicesByPlace: Array<{ placeId: string; services: unknown[] }>,
): PerformanceItem[] => {
  const locationMap = new Map(locations.map((location) => [location.id, location]));

  return servicesByPlace.flatMap(({ placeId, services }) =>
    services.map((service, index) => {
      const data = service && typeof service === 'object' ? (service as Record<string, unknown>) : {};
      const location = locationMap.get(placeId);
      const price = numberFrom(data.price, data.service_price, data.amount);

      return {
        id: textFrom(data.id, data.service_id, data.serviceId) || `${placeId}-service-${index}`,
        name: textFrom(data.name, data.service_name, data.title) || 'Chưa đặt tên',
        locationName: location?.name || 'Chưa rõ địa điểm',
        category: location?.category || 'Địa điểm',
        price,
        orderCount: 0,
        revenue: 0,
        rating: location?.rating || 0,
        imageUrl: textFrom(data.image_url, data.imageUrl, data.photo, data.food_image, data.thumbnail, data.menu_image, data.item_image, data.photo_url) || undefined,
      };
    }),
  );
};

const getOrderLocationName = (order: Record<string, unknown>): string =>
  textFrom(order.place_name, order.location_name, order.restaurant_name, order.placeName);

const isOrderInSelectedPeriod = (order: unknown, month?: number, year?: number): boolean => {
  if (!month || !year) {
    return true;
  }

  const data = order && typeof order === 'object' ? (order as Record<string, unknown>) : {};
  const rawDate = textFrom(data.ordered_time, data.created_at, data.createdAt, data.order_date, data.date);
  if (!rawDate) {
    return true;
  }

  const date = new Date(rawDate);
  if (Number.isNaN(date.getTime())) {
    return true;
  }

  return date.getMonth() + 1 === month && date.getFullYear() === year;
};

const isCompletedOrder = (order: unknown): boolean => normalizeOrderStatus(order) === 'completed';

const parseOrderItems = (order: Record<string, unknown>): Array<{ name: string; quantity: number; price: number }> => {
  const rawItems = Array.isArray(order.items)
    ? order.items
    : Array.isArray(order.foods)
      ? order.foods
      : Array.isArray(order.services)
        ? order.services
        : [];

  if (rawItems.length > 0) {
    return rawItems
      .map((item) => {
        const data = item && typeof item === 'object' ? (item as Record<string, unknown>) : {};
        return {
          name: textFrom(data.name, data.food_name, data.service_name, data.product_name, data.title),
          quantity: numberFrom(data.quantity, data.qty, data.count) || 1,
          price: numberFrom(data.price, data.food_price, data.service_price, data.amount),
        };
      })
      .filter((item) => item.name);
  }

  const foodsText = textFrom(order.foods, order.food_names, order.service_names);
  if (!foodsText) {
    return [];
  }

  return foodsText
    .split(/[,;\n]+/)
    .map((name) => name.trim())
    .filter(Boolean)
    .map((name) => ({ name, quantity: 1, price: 0 }));
};

const findBaselinePerformanceItem = (
  baseline: PerformanceItem[],
  locationName: string,
  serviceName: string,
): PerformanceItem | undefined => {
  const normalizedLocation = normalizeDedupeText(locationName);
  const normalizedService = normalizeDedupeText(serviceName);

  return baseline.find(
    (item) =>
      normalizeDedupeText(item.locationName) === normalizedLocation &&
      normalizeDedupeText(item.name) === normalizedService,
  );
};

const aggregateOrderPerformanceItems = (items: PerformanceItem[]): PerformanceItem[] => {
  const itemMap = new Map<string, PerformanceItem>();

  items.forEach((item) => {
    const key = getPerformanceDedupeKey(item);
    const current = itemMap.get(key);

    if (!current) {
      itemMap.set(key, item);
      return;
    }

    const orderCount = current.orderCount + item.orderCount;
    itemMap.set(key, {
      ...current,
      orderCount,
      revenue: current.revenue + item.revenue,
      rating: Math.max(current.rating, item.rating),
      rawDate: current.rawDate || item.rawDate,
    });
  });

  return Array.from(itemMap.values());
};

const buildOrderPerformance = (
  orders: unknown[],
  baseline: PerformanceItem[],
  locations: Location[],
): PerformanceItem[] => {
  const locationById = new Map(locations.map((location) => [location.id, location]));
  const locationByName = new Map(locations.map((location) => [normalizeDedupeText(location.name), location]));

  const items = orders.flatMap((order, orderIndex) => {
    const data = order && typeof order === 'object' ? (order as Record<string, unknown>) : {};
    const completedOrder = isCompletedOrder(data);
    const locationName = getOrderLocationName(data);
    const location =
      locationById.get(textFrom(data.placeId, data.place_id, data.location_id)) ||
      locationByName.get(normalizeDedupeText(locationName));

    return parseOrderItems(data).map((orderItem, itemIndex) => {
      const baselineItem = findBaselinePerformanceItem(baseline, locationName || location?.name || '', orderItem.name);
      const price = orderItem.price || baselineItem?.price || 0;
      const requestedCount = orderItem.quantity || 1;
      const orderCount = completedOrder ? requestedCount : 0;
      const revenue = price * orderCount;

      return {
        id: baselineItem?.id || `order-performance-${orderIndex}-${itemIndex}`,
        name: baselineItem?.name || orderItem.name,
        locationName: baselineItem?.locationName || location?.name || locationName || 'Chưa rõ địa điểm',
        category: baselineItem?.category || location?.category || 'Địa điểm',
        price,
        orderCount,
        revenue,
        rating: baselineItem?.rating || location?.rating || 0,
        rawDate: textFrom(data.ordered_time, data.created_at, data.createdAt, data.order_date, data.date),
        imageUrl: baselineItem?.imageUrl,
      };
    });
  });

  return aggregateOrderPerformanceItems(items.filter(isPaidPerformanceItem));
};

const getFallbackDashboardData = async (
  vendorId: string,
  period?: DashboardPeriod,
  includeBaselineWhenEmpty = true,
): Promise<DashboardFallbackData> => {
  const [locationsResult, ordersResult] = await Promise.allSettled([
    businessLocationAPI.getLocations(
      {
        vendorId,
        status: 'all',
        sort: 'newest',
      },
      { page: 1, limit: 500 },
    ),
    getOrdersByPlace(vendorId),
  ]);

  const locations = locationsResult.status === 'fulfilled' ? locationsResult.value.locations : [];
  const orders = ordersResult.status === 'fulfilled' ? ordersResult.value : [];
  const ordersInPeriod = orders.filter((order) => isOrderInSelectedPeriod(order, period?.month, period?.year));

  const servicesByPlace = await Promise.all(
    locations.slice(0, 50).map(async (location) => {
      try {
        const payload = await getPlaceServicesByType(location.id);
        const paidServices = Array.isArray(payload?.paidServices) ? payload.paidServices : [];
        const nestedPaidServices = Array.isArray(payload?.data?.paidServices) ? payload.data.paidServices : [];
        const menuItems = Array.isArray(payload?.menuItems) ? payload.menuItems : [];
        const nestedMenuItems = Array.isArray(payload?.data?.menuItems) ? payload.data.menuItems : [];
        const services = [...paidServices, ...nestedPaidServices, ...menuItems, ...nestedMenuItems].filter((service) => {
          const data = service && typeof service === 'object' ? (service as Record<string, unknown>) : {};
          return isActiveService(data.is_active ?? data.active ?? data.status);
        });

        return { placeId: location.id, services };
      } catch {
        return { placeId: location.id, services: [] };
      }
    }),
  );

  const baselinePerformance = dedupePerformanceItems(buildServicePerformance(locations, servicesByPlace).filter(isPaidPerformanceItem));
  const orderPerformance = buildOrderPerformance(
    ordersInPeriod,
    baselinePerformance,
    locations,
  );
  const performance = includeBaselineWhenEmpty
    ? mergePerformanceItems(baselinePerformance, orderPerformance)
    : orderPerformance;
  const activeItems = performance.length;
  const ratedLocations = locations.filter((location) => typeof location.rating === 'number' && location.rating > 0);
  const averageRating =
    ratedLocations.length > 0
      ? ratedLocations.reduce((total, location) => total + (location.rating || 0), 0) / ratedLocations.length
      : 0;
  const pendingOrders = orders.filter(isPendingOrder).length;

  return {
    stats: {
      totalPlaces: locations.length,
      pendingOrders,
      activeItems,
      averageRating,
    },
    performance,
  };
};

const formatCurrency = (value: number): string => {
  return `${Math.max(0, value).toLocaleString('vi-VN')}đ`;
};

const isInSelectedPeriod = (item: PerformanceItem, month: number, year: number): boolean => {
  if (!item.rawDate) {
    return true;
  }

  const date = new Date(item.rawDate);
  if (Number.isNaN(date.getTime())) {
    return true;
  }

  return date.getMonth() + 1 === month && date.getFullYear() === year;
};

const isPaidPerformanceItem = (item: PerformanceItem): boolean => item.price > 0;

const normalizeDedupeText = (value: string): string =>
  value
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ');

const getPerformanceDedupeKey = (item: PerformanceItem): string =>
  [
    normalizeDedupeText(item.locationName),
    normalizeDedupeText(item.name),
    item.price,
  ].join('|');

const dedupePerformanceItems = (items: PerformanceItem[]): PerformanceItem[] => {
  const itemMap = new Map<string, PerformanceItem>();

  items.forEach((item) => {
    const key = getPerformanceDedupeKey(item);
    const current = itemMap.get(key);

    if (!current) {
      itemMap.set(key, item);
      return;
    }

    itemMap.set(key, {
      ...current,
      id: current.id || item.id,
      orderCount: item.orderCount,
      revenue: Math.max(current.revenue, item.revenue),
      rating: Math.max(current.rating, item.rating),
      rawDate: current.rawDate || item.rawDate,
      imageUrl: current.imageUrl || item.imageUrl,
    });
  });

  return Array.from(itemMap.values());
};

const mergePerformanceItems = (...groups: PerformanceItem[][]): PerformanceItem[] => {
  const itemMap = new Map<string, PerformanceItem>();

  groups.flat().forEach((item) => {
    const key = getPerformanceDedupeKey(item);
    const current = itemMap.get(key);

    if (!current) {
      itemMap.set(key, item);
      return;
    }

    itemMap.set(key, {
      ...current,
      ...item,
      id: current.id || item.id,
      category: current.category !== 'Địa điểm' ? current.category : item.category,
      orderCount: item.orderCount,
      revenue: item.revenue,
      rating: Math.max(current.rating, item.rating),
      rawDate: item.rawDate || current.rawDate,
      imageUrl: current.imageUrl || item.imageUrl,
    });
  });

  return Array.from(itemMap.values());
};

const StatCard: React.FC<StatCardProps> = ({ label, value, icon, loading, onClick }) => (
  <button
    type="button"
    onClick={onClick}
    style={{
      flex: 1,
      minWidth: '220px',
      background: 'var(--bg-surface)',
      padding: '20px 22px',
      borderRadius: '16px',
      display: 'flex',
      gap: '16px',
      alignItems: 'flex-start',
      border: '1px solid var(--border-color)',
      cursor: 'pointer',
      textAlign: 'left',
      transition: 'transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease',
    }}
    onMouseEnter={(event) => {
      event.currentTarget.style.transform = 'translateY(-2px)';
      event.currentTarget.style.boxShadow = '0 12px 24px rgba(15, 23, 42, 0.08)';
      event.currentTarget.style.borderColor = '#bfdbfe';
    }}
    onMouseLeave={(event) => {
      event.currentTarget.style.transform = 'translateY(0)';
      event.currentTarget.style.boxShadow = 'none';
      event.currentTarget.style.borderColor = 'var(--border-color)';
    }}>
    <span
      style={{
        width: '44px',
        height: '44px',
        borderRadius: '12px',
        background: '#eff6ff',
        color: '#2563eb',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}>
      {icon}
    </span>
      <span style={{ display: 'flex', flexDirection: 'column', gap: '8px', minWidth: 0 }}>
      <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
        <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: 600 }}>{label}</span>
      </span>
      <span
        style={{
          fontSize: '1.875rem',
          fontWeight: 800,
          color: 'var(--text-primary)',
          lineHeight: 1,
          minHeight: '30px',
        }}>
        {loading ? '...' : value}
      </span>
    </span>
  </button>
);

const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const currentDate = useMemo(() => new Date(), []);
  const [selectedMonth, setSelectedMonth] = useState(currentDate.getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(currentDate.getFullYear());
  const [sortConfig, setSortConfig] = useState<{ key: SortKey; direction: SortDirection }>({
    key: 'revenue',
    direction: 'desc',
  });
  const [stats, setStats] = useState<DashboardStats>({
    totalPlaces: 0,
    pendingOrders: 0,
    activeItems: 0,
    averageRating: 0,
  });
  const [foodPerformance, setFoodPerformance] = useState<PerformanceItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [locationFilter, setLocationFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);

  const vendorId = useMemo(() => getVendorId(getCurrentUser<ProviderUser>()), []);
  const isPeriodFilterActive = selectedMonth !== currentDate.getMonth() + 1 || selectedYear !== currentDate.getFullYear();

  const fetchDashboard = useCallback(async () => {
    if (!vendorId) {
      setStats({ totalPlaces: 0, pendingOrders: 0, activeItems: 0, averageRating: 0 });
      setFoodPerformance([]);
      setError('Không tìm thấy thông tin đối tác. Vui lòng đăng nhập lại.');
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const period = { month: selectedMonth, year: selectedYear };
      const [statsResult, performanceResult] = await Promise.allSettled([
        getDashboardStats(vendorId, period),
        getFoodPerformance(vendorId, period),
      ]);

      // This fallback scans orders and locations and can fan out into many catalog
      // requests. Keep the normal dashboard path fast by using it only on failure.
      const needsFallback = statsResult.status === 'rejected' || performanceResult.status === 'rejected';
      const fallbackResult = needsFallback
        ? await getFallbackDashboardData(vendorId, period, !isPeriodFilterActive)
          .then((value) => ({ status: 'fulfilled' as const, value }))
          .catch((reason) => ({ status: 'rejected' as const, reason }))
        : null;

      let nextStats =
        statsResult.status === 'fulfilled'
          ? normalizeStats(statsResult.value)
          : { totalPlaces: 0, pendingOrders: 0, activeItems: 0, averageRating: 0 };
      let normalizedPerformance =
        performanceResult.status === 'fulfilled'
          ? dedupePerformanceItems(
            performanceResult.value
              .map(normalizePerformanceItem)
              .filter((item) => isInSelectedPeriod(item, selectedMonth, selectedYear))
              .filter(isPaidPerformanceItem),
          )
          : [];
      const fallbackPerformance = fallbackResult?.status === 'fulfilled' ? fallbackResult.value.performance : [];
      const fallbackStats = fallbackResult?.status === 'fulfilled' ? fallbackResult.value.stats : null;
      if (performanceResult.status === 'rejected') normalizedPerformance = fallbackPerformance;

      if (statsResult.status === 'rejected' && fallbackResult?.status === 'fulfilled') {
        nextStats = fallbackResult.value.stats;
      }

      if (performanceResult.status === 'rejected' && fallbackResult?.status === 'rejected') {
        setError('Không thể tải đầy đủ dữ liệu hiệu suất. Vui lòng thử lại.');
      }

      nextStats = {
        ...nextStats,
        totalPlaces: nextStats.totalPlaces || fallbackStats?.totalPlaces || 0,
        pendingOrders: fallbackStats?.pendingOrders ?? nextStats.pendingOrders,
        averageRating: nextStats.averageRating || fallbackStats?.averageRating || 0,
        activeItems: normalizedPerformance.length,
      };

      setStats(nextStats);
      setFoodPerformance(normalizedPerformance);
    } catch (fetchError) {
      console.error('Error fetching dashboard:', fetchError);
      setError('Không thể tải dữ liệu dashboard. Vui lòng thử lại.');
      setStats({ totalPlaces: 0, pendingOrders: 0, activeItems: 0, averageRating: 0 });
      setFoodPerformance([]);
    } finally {
      setLoading(false);
    }
  }, [currentDate, isPeriodFilterActive, selectedMonth, selectedYear, vendorId]);

  useEffect(() => {
    void fetchDashboard();
  }, [fetchDashboard]);

  const filterLocations = useMemo(
    () => Array.from(new Set(foodPerformance.map((i) => i.locationName).filter(Boolean))).sort(),
    [foodPerformance],
  );

  const filterCategories = useMemo(
    () => Array.from(new Set(foodPerformance.map((i) => i.category).filter(Boolean))).sort(),
    [foodPerformance],
  );

  const sortedData = useMemo(() => {
    let sortableData = [...foodPerformance];
    if (locationFilter !== 'all') sortableData = sortableData.filter((i) => i.locationName === locationFilter);
    if (categoryFilter !== 'all') sortableData = sortableData.filter((i) => i.category === categoryFilter);
    sortableData.sort((a, b) => {
      const aValue =
        sortConfig.key === 'price'
          ? a.price
          : sortConfig.key === 'orders'
            ? a.orderCount
            : sortConfig.key === 'revenue'
              ? a.revenue
              : sortConfig.key === 'location'
                ? a.locationName
                : a.name;
      const bValue =
        sortConfig.key === 'price'
          ? b.price
          : sortConfig.key === 'orders'
            ? b.orderCount
            : sortConfig.key === 'revenue'
              ? b.revenue
              : sortConfig.key === 'location'
                ? b.locationName
                : b.name;

      if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
    return sortableData;
  }, [sortConfig, foodPerformance, locationFilter, categoryFilter]);

  const ITEMS_PER_PAGE = 10;

  useEffect(() => {
    setCurrentPage(1);
  }, [locationFilter, categoryFilter, selectedMonth, selectedYear, sortConfig]);

  const totalPages = Math.ceil(sortedData.length / ITEMS_PER_PAGE);
  const paginatedData = sortedData.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

  const requestSort = (key: SortKey) => {
    setSortConfig((current) => ({
      key,
      direction: current.key === key ? (current.direction === 'asc' ? 'desc' : 'asc') : 'desc',
    }));
  };

  const renderSortIndicator = (key: SortKey) => {
    if (sortConfig.key !== key) return <ArrowUpDown size={14} style={{ marginLeft: '8px', opacity: 0.35 }} />;
    return sortConfig.direction === 'asc' ? (
      <ChevronUp size={14} style={{ marginLeft: '8px', color: '#2563eb' }} />
    ) : (
      <ChevronDown size={14} style={{ marginLeft: '8px', color: '#2563eb' }} />
    );
  };

  const emptyMessage = useMemo(() => {
    if (stats.totalPlaces === 0) {
      return 'Bạn chưa có địa điểm nào. Hãy thêm địa điểm đầu tiên để bắt đầu kinh doanh.';
    }
    if (stats.activeItems === 0) {
      return 'Không có kết quả hiển thị.';
    }
    return `Chưa có lượt đặt trong Tháng ${String(selectedMonth).padStart(2, '0')}/${selectedYear}.`;
  }, [selectedMonth, selectedYear, stats.activeItems, stats.totalPlaces]);

  return (
    <div style={{ padding: '0 20px' }}>
      <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', marginBottom: '34px' }}>
        <StatCard
          label="Địa điểm đã đăng ký"
          value={stats.totalPlaces}
          icon={<MapPin size={22} />}
          loading={loading}
          onClick={() => navigate('/locations')}
        />
        <StatCard
          label="Đơn mới"
          value={stats.pendingOrders}
          icon={<ShoppingBag size={22} />}
          loading={loading}
          onClick={() => navigate('/orders?status=pending')}
        />
        <StatCard
          label="Sản phẩm"
          value={stats.activeItems}
          icon={<PackageCheck size={22} />}
          loading={loading}
          onClick={() => navigate('/locations')}
        />
      </div>

      {error && (
        <div
          style={{
            marginBottom: '20px',
            padding: '14px 16px',
            borderRadius: '12px',
            background: '#fef2f2',
            color: '#991b1b',
            border: '1px solid #fecaca',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '16px',
            fontSize: '14px',
            fontWeight: 600,
          }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <AlertCircle size={18} />
            {error}
          </span>
          <button
            type="button"
            onClick={() => void fetchDashboard()}
            style={{
              border: '1px solid #fecaca',
              background: 'white',
              color: '#991b1b',
              borderRadius: '10px',
              padding: '8px 12px',
              fontWeight: 700,
              cursor: 'pointer',
            }}>
            Thử lại
          </button>
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', gap: '20px', flexWrap: 'wrap' }}>
        <h3
          style={{
            fontSize: '1.5rem',
            fontWeight: 800,
            color: 'var(--text-primary)',
          }}>
          Hiệu suất dịch vụ kinh doanh
        </h3>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap', marginLeft: 'auto' }}>
          <select
            value={locationFilter}
            onChange={(e) => setLocationFilter(e.target.value)}
            style={{ padding: '10px 16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: 'white', fontSize: '14px', fontWeight: 700, outline: 'none', color: '#1e293b', cursor: 'pointer', minHeight: '44px' }}>
            <option value="all">Tất cả địa điểm</option>
            {filterLocations.map((loc) => <option key={loc} value={loc}>{loc}</option>)}
          </select>
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            style={{ padding: '10px 16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: 'white', fontSize: '14px', fontWeight: 700, outline: 'none', color: '#1e293b', cursor: 'pointer', minHeight: '44px' }}>
            <option value="all">Tất cả phân loại</option>
            {filterCategories.map((cat) => <option key={cat} value={cat}>{cat}</option>)}
          </select>
          <select
            value={selectedMonth}
            onChange={(event) => setSelectedMonth(Number(event.target.value))}
            style={{
              padding: '10px 16px',
              borderRadius: '12px',
              border: '1px solid #e2e8f0',
              background: 'white',
              fontSize: '14px',
              fontWeight: 700,
              outline: 'none',
              color: '#1e293b',
              cursor: 'pointer',
              minHeight: '44px',
            }}>
            {Array.from({ length: 12 }, (_, i) => (
              <option key={i + 1} value={i + 1}>
                Tháng {(i + 1).toString().padStart(2, '0')}
              </option>
            ))}
          </select>
          <select
            value={selectedYear}
            onChange={(event) => setSelectedYear(Number(event.target.value))}
            style={{
              padding: '10px 16px',
              borderRadius: '12px',
              border: '1px solid #e2e8f0',
              background: 'white',
              fontSize: '14px',
              fontWeight: 700,
              outline: 'none',
              color: '#1e293b',
              cursor: 'pointer',
              minHeight: '44px',
            }}>
            {Array.from({ length: 8 }, (_, i) => currentDate.getFullYear() - 4 + i).map((year) => (
              <option key={year} value={year}>
                Năm {year}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div
        style={{
          background: 'white',
          borderRadius: '18px',
          padding: '8px 0',
          boxShadow: '0 10px 18px rgba(15, 23, 42, 0.06)',
          border: '1px solid #f1f5f9',
          overflowX: 'auto',
        }}>
        <table style={{ width: '100%', minWidth: '860px', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #f1f5f9' }}>
              <th style={tableHeadStyle('left', false)}>
                <div style={{ display: 'flex', alignItems: 'center' }}>Dịch vụ / tiện ích</div>
              </th>
              <th style={tableHeadStyle('left', false)}>
                <div style={{ display: 'flex', alignItems: 'center' }}>Địa điểm</div>
              </th>
              <th style={tableHeadStyle('left', false)}>Phân loại</th>
              <th onClick={() => requestSort('price')} style={tableHeadStyle('center', true)}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>Phí dịch vụ {renderSortIndicator('price')}</div>
              </th>
              <th onClick={() => requestSort('orders')} style={tableHeadStyle('center', true)}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>Lượt đặt/yêu cầu {renderSortIndicator('orders')}</div>
              </th>
              <th onClick={() => requestSort('revenue')} style={tableHeadStyle('center', true)}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>Doanh thu {renderSortIndicator('revenue')}</div>
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              Array.from({ length: 4 }, (_, index) => (
                <tr key={index} style={{ borderBottom: index === 3 ? 'none' : '1px solid #f8fafc' }}>
                  <td colSpan={6} style={{ padding: '16px 24px' }}>
                    <div style={{ height: '44px', borderRadius: '12px', background: 'linear-gradient(90deg, #f8fafc, #eef2f7, #f8fafc)' }} />
                  </td>
                </tr>
              ))
            ) : sortedData.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: '56px 24px', textAlign: 'center', color: '#94a3b8', fontSize: '15px' }}>
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              paginatedData.map((item, index) => (
                <tr
                  key={item.id}
                  style={{
                    borderBottom: index === paginatedData.length - 1 ? 'none' : '1px solid #f8fafc',
                    transition: 'background 0.18s ease',
                  }}
                  onMouseEnter={(event) => (event.currentTarget.style.background = '#f8fafc')}
                  onMouseLeave={(event) => (event.currentTarget.style.background = 'transparent')}>
                  <td style={{ padding: '16px 24px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                      <div style={{ position: 'relative', width: '52px', height: '52px', flexShrink: 0 }}>
                        {item.imageUrl ? (
                          <img
                            src={item.imageUrl}
                            alt={item.name}
                            style={{ width: '52px', height: '52px', borderRadius: '14px', objectFit: 'cover', display: 'block' }}
                            onError={(e) => {
                              const target = e.currentTarget;
                              target.style.display = 'none';
                              const fallback = target.nextElementSibling as HTMLElement | null;
                              if (fallback) fallback.style.display = 'flex';
                            }}
                          />
                        ) : null}
                        <div
                          style={{
                            width: '52px', height: '52px', background: '#f1f5f9', borderRadius: '14px',
                            display: item.imageUrl ? 'none' : 'flex', alignItems: 'center', justifyContent: 'center',
                          }}>
                          <PackageCheck size={24} color="#64748b" />
                        </div>
                        {(currentPage - 1) * ITEMS_PER_PAGE + index < 3 && (
                          <span
                            style={{
                              position: 'absolute', top: '-8px', left: '-8px',
                              background: (currentPage - 1) * ITEMS_PER_PAGE + index === 0 ? '#f59e0b' : (currentPage - 1) * ITEMS_PER_PAGE + index === 1 ? '#64748b' : '#b45309',
                              color: 'white', width: '22px', height: '22px', borderRadius: '50%',
                              display: 'flex', alignItems: 'center', justifyContent: 'center',
                              fontSize: '11px', fontWeight: 800, border: '2px solid white',
                              boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                            }}>
                            {(currentPage - 1) * ITEMS_PER_PAGE + index + 1}
                          </span>
                        )}
                      </div>
                      <span style={{ fontWeight: 700, color: 'var(--text-primary)', fontSize: '0.875rem' }}>{item.name}</span>
                    </div>
                  </td>
                  <td style={{ padding: '16px 24px' }}>
                    <span style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-secondary)' }}>{item.locationName}</span>
                  </td>
                  <td style={{ padding: '16px 24px' }}>
                    <span
                      style={{
                        padding: '6px 12px',
                        borderRadius: '8px',
                        fontSize: '11px',
                        fontWeight: 800,
                        background: '#dbeafe',
                        color: '#2563eb',
                        textTransform: 'uppercase',
                      }}>
                      {item.category}
                    </span>
                  </td>
                  <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                    <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--text-primary)' }}>{formatCurrency(item.price)}</span>
                  </td>
                  <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                    <span style={{ fontSize: '0.875rem', fontWeight: 800, color: '#059669' }}>{item.orderCount}</span>
                  </td>
                  <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                    <span style={{ fontSize: '0.875rem', fontWeight: 800, color: '#0f172a' }}>{formatCurrency(item.revenue)}</span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px', marginTop: '20px', flexWrap: 'wrap' }}>
          <button
            type="button"
            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            style={{
              padding: '8px 16px', borderRadius: '10px', border: '1px solid #e2e8f0',
              background: currentPage === 1 ? '#f8fafc' : 'white', color: currentPage === 1 ? '#94a3b8' : '#1e293b',
              fontWeight: 700, fontSize: '14px', cursor: currentPage === 1 ? 'default' : 'pointer',
            }}>
            ‹
          </button>
          {Array.from({ length: totalPages }, (_, i) => i + 1)
            .filter((page) => page === 1 || page === totalPages || Math.abs(page - currentPage) <= 1)
            .reduce<Array<number | '...'>>((acc, page, i, arr) => {
              if (i > 0 && typeof arr[i - 1] === 'number' && (page as number) - (arr[i - 1] as number) > 1) {
                acc.push('...');
              }
              acc.push(page);
              return acc;
            }, [])
            .map((page, i) =>
              page === '...' ? (
                <span key={`ellipsis-${i}`} style={{ padding: '8px 4px', color: '#94a3b8', fontSize: '14px' }}>…</span>
              ) : (
                <button
                  key={page}
                  type="button"
                  onClick={() => setCurrentPage(page as number)}
                  style={{
                    padding: '8px 14px', borderRadius: '10px',
                    border: currentPage === page ? '1px solid #2563eb' : '1px solid #e2e8f0',
                    background: currentPage === page ? '#2563eb' : 'white',
                    color: currentPage === page ? 'white' : '#1e293b',
                    fontWeight: 700, fontSize: '14px', cursor: 'pointer',
                  }}>
                  {page}
                </button>
              )
            )}
          <button
            type="button"
            onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
            style={{
              padding: '8px 16px', borderRadius: '10px', border: '1px solid #e2e8f0',
              background: currentPage === totalPages ? '#f8fafc' : 'white', color: currentPage === totalPages ? '#94a3b8' : '#1e293b',
              fontWeight: 700, fontSize: '14px', cursor: currentPage === totalPages ? 'default' : 'pointer',
            }}>
            ›
          </button>
          <span style={{ fontSize: '13px', color: '#64748b', marginLeft: '8px' }}>
            {(currentPage - 1) * ITEMS_PER_PAGE + 1}–{Math.min(currentPage * ITEMS_PER_PAGE, sortedData.length)} / {sortedData.length}
          </span>
        </div>
      )}
    </div>
  );
};

const tableHeadStyle = (textAlign: 'left' | 'center', sortable: boolean): React.CSSProperties => ({
  textAlign,
  padding: '20px 24px',
  fontSize: '0.75rem',
  color: 'var(--text-secondary)',
  fontWeight: 800,
  textTransform: 'uppercase',
  cursor: sortable ? 'pointer' : 'default',
  userSelect: 'none',
  whiteSpace: 'nowrap',
});

export default DashboardPage;
