import React, { useEffect, useState, useMemo } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import {
  Bell,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  ArrowUpDown,
} from 'lucide-react';
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
  planning: number;
  confirmed: number;
  rejected: number;
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
  const [stats, setStats] = useState<DashStats>({
    totalUsers: 0, newUsersMonth: 0,
    totalLocations: 0,
    totalReviews: 0, pendingApproval: 0,
    pendingReviews: 0, violationReviews: 0,
  });
  const [topLocations, setTopLocations] = useState<TopLocation[]>([]);
  const [activityData, setActivityData] = useState<ActivityPoint[]>([]);
  const [interaction, setInteraction] = useState<DashInteraction>({
    noInteraction: 0,
    createdTrip: 0,
    completedTrip: 0,
  });
  const [activityPeriod, setActivityPeriod] = useState<'week' | 'month'>('week');
  const [locSortDesc, setLocSortDesc] = useState<boolean>(true);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);

      const [rUser, rLocAll, rLocPending, rReviews, rTopLocs] = await Promise.allSettled([
        apiClient.get('/admin/users/stats'),
        apiClient.get('/admin/places', { params: { status: 'all', page: 1, limit: 1 } }),
        apiClient.get('/admin/places', { params: { status: 'pending', page: 1, limit: 1 } }),
        apiClient.get('/admin/reviews', { params: { page: 1, limit: 1, sort: 'newest' } }),
        apiClient.get('/admin/places', { params: { status: 'approved', page: 1, limit: 100 } }),
      ]);

      // ── User stats
      let totalUsers = 0, newUsersMonth = 0;
      if (rUser.status === 'fulfilled') {
        const raw = rUser.value.data;
        const d = raw?.data ?? raw;
        totalUsers = Number(d?.totalUsers ?? 0);
        newUsersMonth = Number(d?.newThisMonth ?? 0);

        // Dữ liệu hoạt động theo ngày — khi API trả về activityByDay thì tự cập nhật
        if (Array.isArray(d?.activityByDay)) {
          setActivityData(d.activityByDay);
        }

        // Dữ liệu tương tác — khi API trả về interaction thì tự cập nhật
        if (d?.interaction) {
          setInteraction({
            noInteraction: Number(d.interaction.noInteraction ?? 0),
            createdTrip: Number(d.interaction.createdTrip ?? 0),
            completedTrip: Number(d.interaction.completedTrip ?? 0),
          });
        }
      }

      // ── Location counts
      let totalLocations = 0, pendingApproval = 0;
      if (rLocAll.status === 'fulfilled')
        totalLocations = Number(rLocAll.value.data?.pagination?.total ?? 0);
      if (rLocPending.status === 'fulfilled')
        pendingApproval = Number(rLocPending.value.data?.pagination?.total ?? 0);

      // ── Review stats
      let totalReviews = 0, pendingReviews = 0, violationReviews = 0;
      if (rReviews.status === 'fulfilled') {
        const s = rReviews.value.data?.summary;
        totalReviews = Number(s?.total_reviews ?? 0);
        pendingReviews = Number(s?.pending_count ?? 0);
        violationReviews = Number(s?.violation_count ?? 0);
      }

      setStats({
        totalUsers, newUsersMonth,
        totalLocations,
        totalReviews, pendingApproval, pendingReviews, violationReviews,
      });

      // ── Top locations
      if (rTopLocs.status === 'fulfilled') {
        const raw: Record<string, unknown>[] = rTopLocs.value.data?.data ?? [];
        const processed: TopLocation[] = raw
          .filter((loc) => loc.review_count !== undefined && loc.review_count !== null)
          .map((loc) => ({
            id: String(loc.id),
            name: String(loc.name ?? ''),
            visitCount: Number(loc.review_count),
            // Khi API trả về các trường trạng thái thì tự cập nhật, mặc định 0
            planning: Number(loc.planning ?? 0),
            confirmed: Number(loc.confirmed ?? 0),
            rejected: Number(loc.rejected ?? 0),
          }));
        processed.sort((a, b) => b.visitCount - a.visitCount);
        setTopLocations(processed);
      }

      [rUser, rLocAll, rLocPending, rReviews, rTopLocs].forEach((r, i) => {
        if (r.status === 'rejected')
          console.error(`[Dashboard] API ${i + 1} lỗi:`, r.reason);
      });

      setLoading(false);
    };

    load();
  }, []);

  const userChangePct = calcChangePct(stats.totalUsers, stats.newUsersMonth);

  const sortedLocations = useMemo(
    () => [...topLocations].sort((a, b) => locSortDesc ? b.visitCount - a.visitCount : a.visitCount - b.visitCount),
    [topLocations, locSortDesc],
  );
  const maxVisits = sortedLocations[0]?.visitCount || 1;

  const hasStatusData = sortedLocations.some(
    (loc) => loc.planning > 0 || loc.confirmed > 0 || loc.rejected > 0,
  );

  return (
    <div className="page-container">
      {/* ── Header ── */}
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Dashboard</h1>
        </div>
        <div className="header-actions">
          <button className="icon-btn"><Bell size={20} /></button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content">

        {/* ══ Row 1: Stats Cards ══ */}
        <div className="dash-stats-grid">
          <StatCard
            label="Tổng người dùng"
            value={loading ? '—' : stats.totalUsers.toLocaleString('vi-VN')}
            changePct={userChangePct}
            loading={loading}
          />
          <StatCard
            label="Tổng địa điểm"
            value={loading ? '—' : stats.totalLocations.toLocaleString('vi-VN')}
            changePct={0}
            loading={loading}
          />
          <StatCard
            label="Tổng đánh giá"
            value={loading ? '—' : stats.totalReviews.toLocaleString('vi-VN')}
            changePct={0}
            loading={loading}
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
              <Link to="/admin/locations" className="dash-status-link">Xem danh sách</Link>
            </div>
            <div className="dash-status-value">
              {loading ? '—' : String(stats.pendingApproval).padStart(2, '0')}
            </div>
          </div>

          <div className="dash-status-card dash-status-blue">
            <div className="dash-status-top">
              <span className="dash-status-label">Đánh giá chờ duyệt</span>
              <Link to="/admin/reviews" className="dash-status-link">Xem danh sách</Link>
            </div>
            <div className="dash-status-value">
              {loading ? '—' : String(stats.pendingReviews).padStart(2, '0')}
            </div>
          </div>

          <div className="dash-status-card dash-status-red">
            <div className="dash-status-top">
              <span className="dash-status-label">Đánh giá vi phạm</span>
              <AlertTriangle size={16} style={{ color: 'var(--danger-red)' }} />
            </div>
            <div className="dash-status-value dash-status-value-red">
              {loading ? '—' : String(stats.violationReviews).padStart(2, '0')}
            </div>
          </div>
        </div>

        {/* ══ Row 3: Activity Chart + Interaction Bars ══ */}
        <div className="dash-mid-grid">

          {/* Area Chart */}
          <div className="card dash-chart-main">
            <div className="dash-card-header">
              <h3 className="dash-card-title">Người dùng hoạt động theo thời gian</h3>
              <div className="dash-period-toggle">
                <button
                  className={`dash-toggle-btn ${activityPeriod === 'week' ? 'active' : ''}`}
                  onClick={() => setActivityPeriod('week')}
                >Tuần</button>
                <button
                  className={`dash-toggle-btn ${activityPeriod === 'month' ? 'active' : ''}`}
                  onClick={() => setActivityPeriod('month')}
                >Tháng</button>
              </div>
            </div>

            {activityData.length === 0 ? (
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
                    interval={activityPeriod === 'month' ? 4 : 0}
                  />
                  <YAxis hide />
                  <Tooltip
                    contentStyle={{
                      borderRadius: 8,
                      border: '1px solid #e5e7eb',
                      fontSize: 12,
                      boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                    }}
                    formatter={(v) => [
                      `${Number(v ?? 0).toLocaleString('vi-VN')} người`,
                      'Đang hoạt động',
                    ]}
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

            <div className="interaction-list">
              <InteractionBar label="Chưa tương tác"        pct={interaction.noInteraction} color="#ef4444" />
              <InteractionBar label="Đã tạo lịch trình"     pct={interaction.createdTrip}   color="#f59e0b" />
              <InteractionBar label="Đã đi theo lịch trình" pct={interaction.completedTrip} color="#3b82f6" />
            </div>

            {interaction.noInteraction === 0 && interaction.createdTrip === 0 && interaction.completedTrip === 0 && (
              <p className="interaction-note">Chưa có dữ liệu tương tác.</p>
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
                onClick={() => setLocSortDesc(prev => !prev)}
                title={locSortDesc ? 'Đang sắp xếp: Nhiều → Ít. Nhấn để đảo ngược' : 'Đang sắp xếp: Ít → Nhiều. Nhấn để đảo ngược'}
              >
                <ArrowUpDown size={13} />
              </button>
            </div>

            <div className="top-loc-list top-loc-list--scrollable">
              {loading ? (
                <div className="dash-empty-msg">Đang tải...</div>
              ) : sortedLocations.length === 0 ? (
                <div className="dash-empty-msg">Chưa có dữ liệu lượt đánh giá</div>
              ) : (
                sortedLocations.map((loc, idx) => (
                  <div key={loc.id} className="top-loc-row">
                    <span className="top-loc-rank">{String(idx + 1).padStart(2, '0')}</span>
                    <Link to={`/admin/locations/${loc.id}`} className="top-loc-name">
                      {loc.name}
                    </Link>
                    <div className="top-loc-bar-track">
                      <div
                        className="top-loc-bar-fill"
                        style={{ width: `${Math.round((loc.visitCount / maxVisits) * 100)}%` }}
                      />
                    </div>
                    <span className="top-loc-count">
                      {loc.visitCount.toLocaleString('vi-VN')} đánh giá
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Stacked Status Bars */}
          <div className="card">
            <div className="dash-card-header">
              <h3 className="dash-card-title">Trạng thái tại các điểm đến phổ biến</h3>
            </div>
            <p className="trip-status-subtitle">
              Thống kê trạng thái thực tế theo từng địa điểm
            </p>

            <div className="trip-legend">
              <span className="legend-item"><span className="legend-dot dot-planning" />Đang lên lịch</span>
              <span className="legend-item"><span className="legend-dot dot-confirmed" />Xác nhận</span>
              <span className="legend-item"><span className="legend-dot dot-rejected" />Hoàn thành</span>
            </div>

            <div className="trip-status-list">
              {loading ? (
                <div className="dash-empty-msg">Đang tải...</div>
              ) : !hasStatusData ? (
                <div className="dash-empty-msg">Chưa có dữ liệu trạng thái</div>
              ) : (
                sortedLocations.slice(0, 5).map((loc) => (
                  <div key={loc.id} className="trip-row">
                    <span className="trip-row-name">{loc.name}</span>
                    <div className="trip-bar">
                      <div className="trip-seg seg-planning" style={{ width: `${loc.planning}%` }}>
                        {loc.planning > 0 ? `${loc.planning}%` : ''}
                      </div>
                      <div className="trip-seg seg-confirmed" style={{ width: `${loc.confirmed}%` }}>
                        {loc.confirmed > 0 ? `${loc.confirmed}%` : ''}
                      </div>
                      <div className="trip-seg seg-rejected" style={{ width: `${loc.rejected}%` }}>
                        {loc.rejected > 0 ? `${loc.rejected}%` : ''}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>

            <p className="trip-status-note">
              ⓘ Cập nhật dựa trên dữ liệu thực tế trong hệ thống.
            </p>
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
            {isPos ? '+' : '-'}{abs}%
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
      <span className="interaction-pct" style={{ color }}>{pct}%</span>
    </div>
    <div className="interaction-track">
      <div className="interaction-fill" style={{ width: `${pct}%`, backgroundColor: color }} />
    </div>
  </div>
);
