import React, { useState, useMemo } from 'react';
import { useQuery, useQueryClient, keepPreviousData } from '@tanstack/react-query';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Bell, TrendingUp, TrendingDown, AlertTriangle, ChevronDown, RefreshCw } from 'lucide-react';
import { Link } from 'react-router-dom';
import apiClient from '../../../utils/apiClient';
import { locationAPI } from '../../../services/locationAPI';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './Dashboard.css';

// ─────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────
interface DashStats {
  totalUsers: number;
  newUsersMonth: number;
  totalReviews: number;
  pendingReviews: number;
  violationReviews: number;
}

interface TopLocation {
  id: string;
  name: string;
  visitCount: number;
  pending: number; // Đang lên lịch
  ongoing: number; // Đang diễn ra
  completed: number; // Hoàn thành
  uncompleted: number; // Chưa hoàn thành
}

interface ActivityPoint {
  date: string;
  users: number;
}

interface DashInteraction {
  noInteraction: number;
  createdTrip: number;
  completedTrip: number;
}

// ─────────────────────────────────────────────────────────
// Logic helpers
// ─────────────────────────────────────────────────────────

function calcChangePct(total: number, newThisMonth: number): number {
  const prev = total - newThisMonth;
  if (!prev || !newThisMonth) return 0;
  return Math.round((newThisMonth / prev) * 1000) / 10;
}

function getWeeksInMonth(month: number, year: number): number {
  const firstDayOfWeek = new Date(year, month - 1, 1).getDay();
  const daysInMonth = new Date(year, month, 0).getDate();
  return Math.ceil((firstDayOfWeek + daysInMonth) / 7);
}

const EMPTY_STATS: DashStats = {
  totalUsers: 0,
  newUsersMonth: 0,
  totalReviews: 0,
  pendingReviews: 0,
  violationReviews: 0,
};

// ─────────────────────────────────────────────────────────
// Dashboard Component
// ─────────────────────────────────────────────────────────
export const AdminDashboard: React.FC = () => {
  const [selectedMonth, setSelectedMonth] = useState<number>(new Date().getMonth() + 1);
  const [selectedWeek, setSelectedWeek] = useState<number | ''>('');
  const [popularMode, setPopularMode] = useState<'top' | 'flop'>('top');
  const [popularCategory, setPopularCategory] = useState<string>('');
  const [showAllLocs, setShowAllLocs] = useState<boolean>(false);
  const [monthDropdownOpen, setMonthDropdownOpen] = useState<boolean>(false);
  const [weekDropdownOpen, setWeekDropdownOpen] = useState<boolean>(false);
  const [refreshNonce, setRefreshNonce] = useState<number>(0);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const queryClient = useQueryClient();

  // ---------------------------------------------------------
  // Làm mới toàn bộ dữ liệu dashboard ngay lập tức: xóa cache phía backend
  // (RAM, TTL tới 1 giờ) rồi đổi refreshNonce để bust luôn cache HTTP của
  // trình duyệt (query param mới → URL mới) và ép các useQuery gọi lại.
  // ---------------------------------------------------------
  const handleRefreshData = async () => {
    setIsRefreshing(true);
    try {
      await apiClient.post('/admin/dashboard/refresh-cache');
    } catch {
      // Vẫn tiếp tục bust cache phía client kể cả khi lời gọi này lỗi
    } finally {
      setRefreshNonce((n) => n + 1);
      await queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      await queryClient.invalidateQueries({ queryKey: ['dashboard-chart'] });
      await queryClient.invalidateQueries({ queryKey: ['dashboard-popular-places'] });
      await queryClient.invalidateQueries({ queryKey: ['dashboard-interactions'] });
      setIsRefreshing(false);
    }
  };

  // ---------------------------------------------------------
  // Fix 1+2: Stats dùng useQuery — cache 5 phút, giữ data 30 phút sau unmount
  // ---------------------------------------------------------
  const { data: stats = EMPTY_STATS, isLoading: loadingStats } = useQuery<DashStats>({
    queryKey: ['dashboard-stats', refreshNonce],
    queryFn: async () => {
      const res = await apiClient.get('/admin/dashboard/stats', { params: { _r: refreshNonce || undefined } });
      return res.data?.data ?? EMPTY_STATS;
    },
    staleTime: 0,
    gcTime: 0,
  });

  // ---------------------------------------------------------
  // Fix 2+3: Chart — giữ data cũ khi đổi tháng/tuần (keepPreviousData), gcTime dài
  // ---------------------------------------------------------
  const { data: activityData = [], isLoading: loadingChart } = useQuery({
    queryKey: ['dashboard-chart', selectedMonth, selectedWeek, refreshNonce],
    queryFn: async ({ signal }) => {
      const params: Record<string, number> = { month: selectedMonth };
      if (selectedWeek !== '') params.week = selectedWeek as number;
      if (refreshNonce) params._r = refreshNonce;
      const res = await apiClient.get('/admin/dashboard/chart', { params, signal });
      return (res.data?.data ?? []) as ActivityPoint[];
    },
    staleTime: 0,
    gcTime: 0,
    placeholderData: keepPreviousData,
  });

  // ---------------------------------------------------------
  // Location stats — gọi cùng API với trang quản lý địa điểm
  // ---------------------------------------------------------
  const { data: locationStats } = useQuery({
    queryKey: ['location-stats'],
    queryFn: () => locationAPI.getLocationStats(),
    staleTime: 0,
    gcTime: 0,
  });

  // ---------------------------------------------------------
  // Danh mục địa điểm — dùng chung API với trang quản lý địa điểm
  // ---------------------------------------------------------
  const { data: categoryOptions = [] } = useQuery({
    queryKey: ['location-categories'],
    queryFn: async () => {
      const res = await locationAPI.getLocationCategories();
      return res.categories;
    },
    staleTime: 5 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
  });

  // ---------------------------------------------------------
  // Fix 2: Popular places — tăng gcTime lên 2 giờ
  // ---------------------------------------------------------
  const { data: topLocations = [], isLoading: loadingLocs } = useQuery({
    queryKey: ['dashboard-popular-places', popularMode, popularCategory, refreshNonce],
    queryFn: async () => {
      const response = await apiClient.get('/admin/dashboard/popular-places', {
        params: {
          limit: 20,
          mode: popularMode,
          categoryName: popularCategory || undefined,
          _r: refreshNonce || undefined,
        },
      });
      const rawData = response.data?.data || [];
      return rawData.map((loc: any) => ({
        id: String(loc.id),
        name: String(loc.name ?? 'Không rõ'),
        visitCount: Number(loc.visitCount ?? 0),
        pending: Number(loc.pendingPct ?? 0),
        ongoing: Number(loc.ongoingPct ?? 0),
        completed: Number(loc.completedPct ?? 0),
        uncompleted: Number(loc.uncompletedPct ?? 0),
      })) as TopLocation[];
    },
    staleTime: 0,
    gcTime: 0,
  });

  // ---------------------------------------------------------
  // Fix 2: Interactions — tăng gcTime lên 30 phút
  // ---------------------------------------------------------
  const { data: interaction = { noInteraction: 0, createdTrip: 0, completedTrip: 0 }, isLoading: loadingInteraction } =
    useQuery<DashInteraction>({
      queryKey: ['dashboard-interactions', refreshNonce],
      queryFn: async () => {
        const res = await apiClient.get('/admin/dashboard/interactions', { params: { _r: refreshNonce || undefined } });
        return res.data?.data ?? { noInteraction: 0, createdTrip: 0, completedTrip: 0 };
      },
      staleTime: 0,
      gcTime: 0,
    });

  const userChangePct = calcChangePct(stats.totalUsers, stats.newUsersMonth);

  const weeksInSelectedMonth = useMemo(() => getWeeksInMonth(selectedMonth, new Date().getFullYear()), [selectedMonth]);

  const { sortedLocations, maxVisits, hasStatusData } = useMemo(() => {
    return {
      sortedLocations: topLocations,
      maxVisits: topLocations[0]?.visitCount || 1,
      hasStatusData: topLocations.some((l) => l.pending > 0 || l.ongoing > 0 || l.completed > 0 || l.uncompleted > 0),
    };
  }, [topLocations]);

  return (
    <div className="page-container">
      {/* ── Header ── */}
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Dashboard</h1>
        </div>
        <div className="header-actions">
          <button
            className="icon-btn"
            onClick={handleRefreshData}
            disabled={isRefreshing}
            title="Làm mới toàn bộ dữ liệu dashboard (xóa cache, lấy dữ liệu mới nhất)">
            <RefreshCw size={18} className={isRefreshing ? 'dash-refresh-spin' : ''} />
          </button>
          <button className="icon-btn">
            <Bell size={20} />
          </button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content">
        {/* ══ Row 1: Stats Cards ══ */}
        <div className="dash-stats-grid">
          <StatCard
            label="Tổng người dùng"
            value={loadingStats ? '—' : stats.totalUsers.toLocaleString('vi-VN')}
            changePct={userChangePct}
            loading={loadingStats}
          />
          <StatCard
            label="Tổng địa điểm"
            value={locationStats ? locationStats.totalLocations.toLocaleString('vi-VN') : '—'}
            changePct={0}
            loading={!locationStats}
          />
          <StatCard
            label="Tổng đánh giá"
            value={loadingStats ? '—' : stats.totalReviews.toLocaleString('vi-VN')}
            changePct={0}
            loading={loadingStats}
          />
        </div>

        {/* ══ Row 2: Status Cards ══ */}
        <div className="dash-section-heading">
          <span>Hiện trạng</span>
        </div>

        <div className="dash-status-grid">
          <div className="dash-status-card dash-status-orange">
            <div className="dash-status-top">
              <span className="dash-status-label">Địa điểm chờ duyệt</span>
              <Link to="/admin/locations?status=pending" className="dash-status-link">
                Xem danh sách
              </Link>
            </div>
            <div className="dash-status-value">{locationStats ? String(locationStats.pendingApproval).padStart(2, '0') : '—'}</div>
          </div>

          <div className="dash-status-card dash-status-blue">
            <div className="dash-status-top">
              <span className="dash-status-label">Đánh giá chờ duyệt</span>
              <Link to="/admin/reviews?status=pending" className="dash-status-link">
                Xem danh sách
              </Link>
            </div>
            <div className="dash-status-value">{loadingStats ? '—' : String(stats.pendingReviews).padStart(2, '0')}</div>
          </div>

          <div className="dash-status-card dash-status-red">
            <div className="dash-status-top">
              <span className="dash-status-label">Đánh giá vi phạm</span>
              <AlertTriangle size={16} style={{ color: 'var(--danger-red)' }} />
            </div>
            <div className="dash-status-value dash-status-value-red">
              {loadingStats ? '—' : String(stats.violationReviews).padStart(2, '0')}
            </div>
          </div>
        </div>

        {/* ══ Row 3: Activity Chart + Interaction Bars ══ */}
        <div className="dash-mid-grid">
          {/* Area Chart */}
          <div className="card dash-chart-main">
            <div className="dash-card-header">
              <h3 className="dash-card-title">Người dùng hoạt động theo thời gian</h3>
              <div className="dash-period-toggle" style={{ display: 'flex', gap: '8px' }}>
                <div className="dash-month-dropdown-wrapper" style={{ position: 'relative' }}>
                  <button
                    className={`dash-toggle-btn ${monthDropdownOpen ? 'active' : ''}`}
                    onClick={() => {
                      setMonthDropdownOpen(!monthDropdownOpen);
                      setWeekDropdownOpen(false);
                    }}>
                    <span>Tháng {selectedMonth}</span>
                    <ChevronDown size={14} style={{ opacity: 0.6 }} />
                  </button>

                  {monthDropdownOpen && (
                    <div className="dash-month-selector popover">
                      {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                        <button
                          key={m}
                          className={`month-pill ${selectedMonth === m ? 'active' : ''}`}
                          onClick={() => {
                            setSelectedMonth(m);
                            setSelectedWeek('');
                            setMonthDropdownOpen(false);
                          }}>
                          Tháng {m}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <div className="dash-week-dropdown-wrapper" style={{ position: 'relative' }}>
                  <button
                    className={`dash-toggle-btn ${weekDropdownOpen ? 'active' : ''}`}
                    onClick={() => {
                      setWeekDropdownOpen(!weekDropdownOpen);
                      setMonthDropdownOpen(false);
                    }}>
                    <span>{selectedWeek === '' ? 'Cả tháng' : `Tuần ${selectedWeek}`}</span>
                    <ChevronDown size={14} style={{ opacity: 0.6 }} />
                  </button>

                  {weekDropdownOpen && (
                    <div className="dash-month-selector popover" style={{ minWidth: '130px' }}>
                      <button
                        className={`month-pill ${selectedWeek === '' ? 'active' : ''}`}
                        onClick={() => {
                          setSelectedWeek('');
                          setWeekDropdownOpen(false);
                        }}>
                        Cả tháng
                      </button>
                      {Array.from({ length: weeksInSelectedMonth }, (_, i) => i + 1).map((w) => (
                        <button
                          key={w}
                          className={`month-pill ${selectedWeek === w ? 'active' : ''}`}
                          onClick={() => {
                            setSelectedWeek(w);
                            setWeekDropdownOpen(false);
                          }}>
                          Tuần {w}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {loadingChart ? (
              <div className="dash-empty-chart">Đang tải dữ liệu biểu đồ...</div>
            ) : activityData.length === 0 ? (
              <div className="dash-empty-chart">Chưa có dữ liệu hoạt động</div>
            ) : (
              <ResponsiveContainer width="100%" height={210}>
                <AreaChart data={activityData} margin={{ top: 8, right: 8, left: -30, bottom: 0 }}>
                  <defs>
                    <linearGradient id="usersGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.18} />
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid vertical={false} stroke="#f3f4f6" strokeDasharray="0" />
                  <XAxis
                    dataKey="date"
                    tick={{ fontSize: 11, fill: '#9ca3af' }}
                    axisLine={false}
                    tickLine={false}
                    interval={selectedWeek === '' ? 4 : 0}
                  />
                  <YAxis hide />
                  <Tooltip
                    contentStyle={{
                      borderRadius: 8,
                      border: '1px solid #e5e7eb',
                      fontSize: 12,
                      boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                    }}
                    formatter={(v) => [`${Number(v ?? 0).toLocaleString('vi-VN')} người`, 'Đang hoạt động']}
                    labelStyle={{ fontWeight: 600, marginBottom: 4 }}
                  />
                  <Area
                    type="monotone"
                    dataKey="users"
                    stroke="#3b82f6"
                    strokeWidth={2.5}
                    fill="url(#usersGrad)"
                    dot={false}
                    activeDot={{ r: 5, fill: '#3b82f6', strokeWidth: 0 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>

          {/* Interaction Progress Bars */}
          <div className="card dash-interaction-card">
            <div className="dash-card-header">
              <h3 className="dash-card-title">Mức độ tương tác của người dùng</h3>
            </div>

            {loadingInteraction ? (
              <div className="dash-empty-msg" style={{ marginTop: '20px' }}>
                Đang tải dữ liệu...
              </div>
            ) : (
              <>
                <div className="interaction-list">
                  <InteractionBar label="Chưa tương tác" pct={interaction.noInteraction} color="#ef4444" />
                  <InteractionBar label="Đã tạo lịch trình" pct={interaction.createdTrip} color="#f59e0b" />
                  <InteractionBar label="Đã đi theo lịch trình" pct={interaction.completedTrip} color="#3b82f6" />
                </div>

                {interaction.noInteraction === 0 && interaction.createdTrip === 0 && interaction.completedTrip === 0 && (
                  <p className="interaction-note">Chưa có dữ liệu tương tác.</p>
                )}
              </>
            )}
          </div>
        </div>

        {/* ══ Row 4: Top Locations + Status Bars ══ */}
        <div className="dash-bottom-grid">
          {/* Top Locations horizontal bars */}
          <div className="card">
            <div className="dash-card-header">
              <h3 className="dash-card-title">
                {popularMode === 'top' ? 'Top 20 địa điểm được ghé thăm nhiều nhất' : '20 địa điểm ít khách ghé thăm nhất'}
              </h3>
              <div className="dash-mode-toggle">
                <select
                  className="dash-category-select"
                  value={popularCategory}
                  onChange={(e) => setPopularCategory(e.target.value)}
                  title="Lọc theo danh mục địa điểm">
                  <option value="">Tất cả danh mục</option>
                  {categoryOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
                <button
                  className={`dash-toggle-btn ${popularMode === 'top' ? 'active' : ''}`}
                  onClick={() => {
                    setPopularMode('top');
                    setShowAllLocs(false);
                  }}
                  title="Top 20 địa điểm có nhiều du khách thực sự ghé thăm nhất (GPS check-in)">
                  🔥 Nổi bật
                </button>
                <button
                  className={`dash-toggle-btn ${popularMode === 'flop' ? 'active' : ''}`}
                  onClick={() => {
                    setPopularMode('flop');
                    setShowAllLocs(false);
                  }}
                  title="20 địa điểm có ít du khách thực sự ghé thăm nhất (GPS check-in)">
                  ❄️ Ít khách
                </button>
              </div>
            </div>

            <div className="top-loc-list top-loc-list--scrollable">
              {loadingLocs ? (
                <div className="dash-empty-msg">Đang tải danh sách địa điểm...</div>
              ) : sortedLocations.length === 0 ? (
                <div className="dash-empty-msg">Chưa có dữ liệu</div>
              ) : (
                <>
                  {sortedLocations.slice(0, showAllLocs ? 20 : 10).map((loc, idx) => (
                    <Link key={loc.id} to={`/admin/locations/${loc.id}`} className="top-loc-row top-loc-row--link" title={loc.name}>
                      <span className="top-loc-rank">{String(idx + 1).padStart(2, '0')}</span>
                      <span className="top-loc-name">{loc.name}</span>
                      <div className="top-loc-bar-track">
                        <div className="top-loc-bar-fill" style={{ width: `${Math.round((loc.visitCount / maxVisits) * 100)}%` }} />
                      </div>
                      <span className="top-loc-count">{loc.visitCount.toLocaleString('vi-VN')} khách</span>
                    </Link>
                  ))}
                  {sortedLocations.length > 10 && (
                    <button className="top-loc-view-all" onClick={() => setShowAllLocs(!showAllLocs)}>
                      {showAllLocs ? 'Thu gọn' : `Xem thêm (${sortedLocations.length - 10} địa điểm)`}
                    </button>
                  )}
                </>
              )}
            </div>
          </div>

          {/* Stacked Status Bars */}
          <div className="card">
            <div className="dash-card-header">
              <h3 className="dash-card-title">Trạng thái hành trình tại các địa điểm phổ biến</h3>
            </div>
            <p className="trip-status-subtitle">Phân bố trạng thái lịch trình tại thời điểm du khách check-in thực tế</p>

            <div className="trip-legend">
              <span className="legend-item">
                <span className="legend-dot dot-pending" />
                Đang lên lịch
              </span>
              <span className="legend-item">
                <span className="legend-dot dot-ongoing" />
                Đang diễn ra
              </span>
              <span className="legend-item">
                <span className="legend-dot dot-completed" />
                Hoàn thành
              </span>
              <span className="legend-item">
                <span className="legend-dot dot-uncompleted" />
                Chưa hoàn thành
              </span>
            </div>

            <div className="trip-status-list">
              {loadingLocs ? (
                <div className="dash-empty-msg">Đang tải trạng thái...</div>
              ) : !hasStatusData ? (
                <div className="dash-empty-msg">Chưa có dữ liệu trạng thái</div>
              ) : (
                sortedLocations.slice(0, 5).map((loc) => (
                  <div key={loc.id} className="trip-row">
                    <span className="trip-row-name">{loc.name}</span>
                    <div className="trip-bar">
                      {/* Biểu đồ số 2: Stacked Bar chia tỉ lệ phần trăm cho 4 trạng thái */}
                      <div className="trip-seg seg-pending" style={{ width: `${loc.pending}%` }}>
                        {loc.pending > 0 ? `${loc.pending}%` : ''}
                      </div>
                      <div className="trip-seg seg-ongoing" style={{ width: `${loc.ongoing}%` }}>
                        {loc.ongoing > 0 ? `${loc.ongoing}%` : ''}
                      </div>
                      <div className="trip-seg seg-completed" style={{ width: `${loc.completed}%` }}>
                        {loc.completed > 0 ? `${loc.completed}%` : ''}
                      </div>
                      <div className="trip-seg seg-uncompleted" style={{ width: `${loc.uncompleted}%` }}>
                        {loc.uncompleted > 0 ? `${loc.uncompleted}%` : ''}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
            <p className="trip-status-note">ⓘ Cập nhật dựa trên dữ liệu thực tế trong hệ thống.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────

interface StatCardProps {
  label: string;
  value: string;
  changePct: number;
  loading: boolean;
}

const StatCard: React.FC<StatCardProps> = ({ label, value, changePct, loading }) => {
  const isPos = changePct > 0;
  const abs = Math.abs(changePct);
  return (
    <div className="dash-stat-card">
      <div className="stat-card-top">
        <span className="stat-label">{label}</span>
        {!loading && changePct !== 0 && (
          <span className={`stat-badge ${isPos ? 'badge-up' : 'badge-down'}`}>
            {isPos ? <TrendingUp size={11} /> : <TrendingDown size={11} />}
            {isPos ? '+' : '-'}
            {abs}%
          </span>
        )}
      </div>
      <span className="stat-value">{value}</span>
    </div>
  );
};

interface InteractionBarProps {
  label: string;
  pct: number;
  color: string;
}

const InteractionBar: React.FC<InteractionBarProps> = ({ label, pct, color }) => (
  <div className="interaction-item">
    <div className="interaction-row">
      <span className="interaction-label">{label}</span>
      <span className="interaction-pct" style={{ color }}>
        {pct}%
      </span>
    </div>
    <div className="interaction-track">
      <div className="interaction-fill" style={{ width: `${pct}%`, backgroundColor: color }} />
    </div>
  </div>
);
