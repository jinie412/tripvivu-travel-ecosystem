import React, { useEffect, useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Bell, TrendingUp, TrendingDown, AlertTriangle, ArrowUpDown, ChevronDown } from 'lucide-react';
import { Link } from 'react-router-dom';
import apiClient from '../../../utils/apiClient';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './Dashboard.css';

// ─────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────
interface DashStats {
  totalUsers: number;
  newUsersMonth: number;
  totalLocations: number;
  totalReviews: number;
  pendingApproval: number;
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

// ─────────────────────────────────────────────────────────
// Dashboard Component
// ─────────────────────────────────────────────────────────
export const AdminDashboard: React.FC = () => {
  const [loadingStats, setLoadingStats] = useState(true);

  const [stats, setStats] = useState<DashStats>({
    totalUsers: 0,
    newUsersMonth: 0,
    totalLocations: 0,
    totalReviews: 0,
    pendingApproval: 0,
    pendingReviews: 0,
    violationReviews: 0,
  });
  const [selectedMonth, setSelectedMonth] = useState<number>(new Date().getMonth() + 1);
  const [selectedWeek, setSelectedWeek] = useState<number | ''>('');
  const [locSortDesc, setLocSortDesc] = useState<boolean>(true);
  const [showAllLocs, setShowAllLocs] = useState<boolean>(false);
  const [monthDropdownOpen, setMonthDropdownOpen] = useState<boolean>(false);
  const [weekDropdownOpen, setWeekDropdownOpen] = useState<boolean>(false);

  // ---------------------------------------------------------
  // LUỒNG 1: Tải các con số thống kê tổng
  // ---------------------------------------------------------
  useEffect(() => {
    const loadStats = async () => {
      setLoadingStats(true);
      try {
        const [rUser, rLocAll, rLocPending, rReviews] = await Promise.allSettled([
          apiClient.get('/admin/users/stats'),
          apiClient.get('/admin/places', { params: { status: 'all', page: 1, limit: 1 } }),
          apiClient.get('/admin/places', { params: { status: 'pending', page: 1, limit: 1 } }),
          apiClient.get('/admin/reviews', { params: { page: 1, limit: 1, sort: 'newest' } }),
        ]);

        const newStats: DashStats = {
          totalUsers: 0,
          newUsersMonth: 0,
          totalLocations: 0,
          totalReviews: 0,
          pendingApproval: 0,
          pendingReviews: 0,
          violationReviews: 0,
        };

        if (rUser.status === 'fulfilled') {
          const d = rUser.value.data?.data ?? rUser.value.data;
          newStats.totalUsers = Number(d?.totalUsers ?? 0);
          newStats.newUsersMonth = Number(d?.newThisMonth ?? 0);
        }

        if (rLocAll.status === 'fulfilled') newStats.totalLocations = Number(rLocAll.value.data?.pagination?.total ?? 0);
        if (rLocPending.status === 'fulfilled') newStats.pendingApproval = Number(rLocPending.value.data?.pagination?.total ?? 0);

        if (rReviews.status === 'fulfilled') {
          const s = rReviews.value.data?.summary;
          newStats.totalReviews = Number(s?.total_reviews ?? 0);
          newStats.pendingReviews = Number(s?.pending_count ?? 0);
          newStats.violationReviews = Number(s?.violation_count ?? 0);
        }

        setStats(newStats);
      } finally {
        setLoadingStats(false);
      }
    };
    loadStats();
  }, []);

  // ---------------------------------------------------------
  // LUỒNG 2: Tải chart user hoạt động (Fix 1+5: useQuery với signal tự động cancel)
  // ---------------------------------------------------------
  const { data: activityData = [], isLoading: loadingChart } = useQuery({
    queryKey: ['dashboard-chart', selectedMonth, selectedWeek],
    queryFn: async ({ signal }) => {
      const params: Record<string, number> = { month: selectedMonth };
      if (selectedWeek !== '') params.week = selectedWeek as number;
      const res = await apiClient.get('/admin/dashboard/chart', { params, signal });
      return (res.data?.data ?? []) as ActivityPoint[];
    },
    staleTime: 30 * 60 * 1000,
  });

  // ---------------------------------------------------------
  // LUỒNG 3: Tải chart danh sách địa điểm và trạng thái (Fix 2+5: useQuery + limit param)
  // ---------------------------------------------------------
  const { data: topLocations = [], isLoading: loadingLocs } = useQuery({
    queryKey: ['dashboard-popular-places'],
    queryFn: async () => {
      const response = await apiClient.get('/admin/dashboard/popular-places', { params: { limit: 10 } });
      const rawData = response.data?.data || [];
      return rawData.map((loc: any) => ({
        id: String(loc.id),
        name: String(loc.name ?? 'Không rõ'),
        visitCount: Number(loc.visitCount ?? 0),
        pending: Number(loc.pendingPct ?? loc.planningPct ?? 0),
        ongoing: Number(loc.ongoingPct ?? loc.confirmedPct ?? 0),
        completed: Number(loc.completedPct ?? 0),
        uncompleted: Number(loc.uncompletedPct ?? 0),
      })) as TopLocation[];
    },
    staleTime: 60 * 60 * 1000,
  });

  // ---------------------------------------------------------
  // LUỒNG 4: Tải dữ liệu tương tác người dùng
  // ---------------------------------------------------------
  const { data: interaction = { noInteraction: 0, createdTrip: 0, completedTrip: 0 }, isLoading: loadingInteraction } =
    useQuery<DashInteraction>({
      queryKey: ['dashboard-interactions'],
      queryFn: async () => {
        const res = await apiClient.get('/admin/dashboard/interactions');
        return res.data?.data ?? { noInteraction: 0, createdTrip: 0, completedTrip: 0 };
      },
      staleTime: 5 * 60 * 1000,
    });

  const userChangePct = calcChangePct(stats.totalUsers, stats.newUsersMonth);

  // Fix 3: Gộp sortedLocations, maxVisits, hasStatusData vào 1 useMemo
  const { sortedLocations, maxVisits, hasStatusData } = useMemo(() => {
    const sorted = [...topLocations].sort((a, b) =>
      locSortDesc ? b.visitCount - a.visitCount : a.visitCount - b.visitCount,
    );
    return {
      sortedLocations: sorted,
      maxVisits: sorted[0]?.visitCount || 1,
      hasStatusData: sorted.some((l) => l.pending > 0 || l.ongoing > 0 || l.completed > 0 || l.uncompleted > 0),
    };
  }, [topLocations, locSortDesc]);

  return (
    <div className="page-container">
      {/* ── Header ── */}
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Dashboard</h1>
        </div>
        <div className="header-actions">
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
            value={loadingStats ? '—' : stats.totalLocations.toLocaleString('vi-VN')}
            changePct={0}
            loading={loadingStats}
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
              <Link to="/admin/locations" className="dash-status-link">
                Xem danh sách
              </Link>
            </div>
            <div className="dash-status-value">{loadingStats ? '—' : String(stats.pendingApproval).padStart(2, '0')}</div>
          </div>

          <div className="dash-status-card dash-status-blue">
            <div className="dash-status-top">
              <span className="dash-status-label">Đánh giá chờ duyệt</span>
              <Link to="/admin/reviews" className="dash-status-link">
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
                      {[1, 2, 3, 4].map((w) => (
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
              <h3 className="dash-card-title">Địa điểm phổ biến</h3>
              <button
                className="top-loc-sort-btn"
                onClick={() => setLocSortDesc((prev) => !prev)}
                title={locSortDesc ? 'Đang sắp xếp: Nhiều → Ít. Nhấn để đảo ngược' : 'Đang sắp xếp: Ít → Nhiều. Nhấn để đảo ngược'}>
                <ArrowUpDown size={13} />
              </button>
            </div>

              <div className="top-loc-list top-loc-list--scrollable">
                {loadingLocs ? (
                  <div className="dash-empty-msg">Đang tải danh sách địa điểm...</div>
                ) : sortedLocations.length === 0 ? (
                  <div className="dash-empty-msg">Chưa có dữ liệu lượt đánh giá</div>
                ) : (
                  <>
                    {sortedLocations.slice(0, showAllLocs ? 10 : 5).map((loc, idx) => (
                      <div key={loc.id} className="top-loc-row">
                        <span className="top-loc-rank">{String(idx + 1).padStart(2, '0')}</span>
                        {/* Sử dụng thẻ span thay vì Link do id bây giờ là chuỗi tên thành phố thay vì UUID */}
                        <span className="top-loc-name">{loc.name}</span>
                        <div className="top-loc-bar-track">
                          {/* Biểu đồ số 1: Hiển thị độ dài dựa trên số visitCount so với mốc max */}
                          <div
                            className="top-loc-bar-fill"
                            style={{ width: `${Math.round((loc.visitCount / maxVisits) * 100)}%` }}
                          />
                        </div>
                        <span className="top-loc-count">{loc.visitCount.toLocaleString('vi-VN')} lượt</span>
                      </div>
                    ))}
                    {sortedLocations.length > 5 && (
                      <button className="top-loc-view-all" onClick={() => setShowAllLocs(!showAllLocs)}>
                        {showAllLocs ? 'Thu gọn' : `Xem thêm (${sortedLocations.length - 5} địa điểm)`}
                      </button>
                    )}
                  </>
                )}
              </div>
          </div>

          {/* Stacked Status Bars */}
          <div className="card">
            <div className="dash-card-header">
              <h3 className="dash-card-title">Trạng thái hành trình tại các điểm đến phổ biến</h3>
            </div>
            <p className="trip-status-subtitle">Thống kê trạng thái thực tế theo từng địa điểm</p>

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
