import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Bell, ChevronDown, Info, Loader2, RotateCcw } from 'lucide-react';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import {
  PipelineHistoryItem,
  algorithmPipelineAPI,
  formatPipelineDateTime,
  formatPipelineDuration,
} from '../../../services/algorithmPipelineAPI';
import './AlgorithmSettings.css';

// ── Static default data ──────────────────────────────────────────────────────

const DEFAULT_TOPICS_C3 = [
  { name: 'Giao thông', hours: 24 },
  { name: 'Thời tiết', hours: 24 },
  { name: 'Đông đúc', hours: 48 },
  { name: 'Dịch vụ', hours: 72 },
  { name: 'Giá cả', hours: 72 },
  { name: 'Cơ sở hạ tầng', hours: 168 },
  { name: 'Đồ ăn & uống', hours: 168 },
  { name: 'Hoạt động', hours: 168 },
  { name: 'Không khí', hours: 720 },
];

const DEFAULT_TOPICS_C5 = [
  { name: 'Giao thông', window: 1, minCount: 3, similarity: 0.75 },
  { name: 'Thời tiết', window: 1, minCount: 3, similarity: 0.75 },
  { name: 'Đông đúc', window: 2, minCount: 3, similarity: 0.70 },
  { name: 'Dịch vụ', window: 3, minCount: 5, similarity: 0.70 },
  { name: 'Giá cả', window: 3, minCount: 5, similarity: 0.70 },
  { name: 'Cơ sở hạ tầng', window: 7, minCount: 5, similarity: 0.65 },
  { name: 'Đồ ăn & uống', window: 7, minCount: 5, similarity: 0.65 },
  { name: 'Hoạt động', window: 7, minCount: 5, similarity: 0.65 },
  { name: 'Không khí', window: 30, minCount: 10, similarity: 0.60 },
];

// ── Helpers ──────────────────────────────────────────────────────────────────

const hoursToLabel = (hours: number): string => {
  if (hours <= 0) return '—';
  const days = hours / 24;
  if (days < 1) return `${hours}h`;
  if (days === 1) return '1 ngày';
  return `${days} ngày`;
};

const outOfRange = (v: number, min: number, max: number) => v < min || v > max;

// ── Tooltip icon ─────────────────────────────────────────────────────────────

const Tip: React.FC<{ text: string }> = ({ text }) => (
  <span className="as-tooltip">
    <Info size={13} className="as-tooltip__icon" />
    <span className="as-tooltip__bubble">{text}</span>
  </span>
);

// ── Toggle switch ─────────────────────────────────────────────────────────────

const Toggle: React.FC<{ checked: boolean; onChange: (v: boolean) => void }> = ({
  checked,
  onChange,
}) => (
  <button
    role="switch"
    aria-checked={checked}
    className={`as-toggle${checked ? ' as-toggle--on' : ''}`}
    onClick={() => onChange(!checked)}
  >
    <span className="as-toggle__thumb" />
  </button>
);

// ── Accordion card ────────────────────────────────────────────────────────────

interface CardProps {
  title: string;
  badge?: string;
  open: boolean;
  onToggle: () => void;
  onSave: () => void;
  onReset: () => void;
  children: React.ReactNode;
}

const AccordionCard: React.FC<CardProps> = ({
  title, badge, open, onToggle, onSave, onReset, children,
}) => (
  <div className={`as-card${open ? ' as-card--open' : ''}`}>
    <button className="as-card__header" onClick={onToggle}>
      <span className="as-card__title">
        {title}
        {badge && <span className="as-card__badge">{badge}</span>}
      </span>
      <ChevronDown size={16} className={`as-card__chevron${open ? ' as-card__chevron--open' : ''}`} />
    </button>
    {open && (
      <div className="as-card__body">
        {children}
        <div className="as-card__footer">
          <button className="as-btn-ghost" onClick={onReset}>
            <RotateCcw size={13} />
            Khôi phục mặc định
          </button>
          <button className="as-btn-primary" onClick={onSave}>
            Lưu thay đổi
          </button>
        </div>
      </div>
    )}
  </div>
);

// ── Pipeline run panel ────────────────────────────────────────────────────────

interface PipelinePanelProps {
  title: string;
  icon: React.ReactNode;
  autoEnabled: boolean;
  onAutoChange: (v: boolean) => void;
  frequency: string;
  onFrequencyChange: (v: string) => void;
  runTime: string;
  onRunTimeChange: (v: string) => void;
  onRunNow: () => void;
  isRunning: boolean;
  lastRun?: string;
  available?: boolean;
}

const PipelinePanel: React.FC<PipelinePanelProps> = ({
  title,
  icon,
  autoEnabled,
  onAutoChange,
  frequency,
  onFrequencyChange,
  runTime,
  onRunTimeChange,
  onRunNow,
  isRunning,
  lastRun,
  available = true,
}) => (
  <div className="as-pipeline-panel">
    <div className="as-pipeline-panel__header">
      <div className="as-pipeline-panel__title">
        <span className="as-pipeline-panel__icon">{icon}</span>
        {title}
      </div>
      <div className="as-pipeline-panel__auto">
        <span className="as-pipeline-panel__auto-label">Tự động</span>
        <Toggle checked={autoEnabled} onChange={onAutoChange} />
      </div>
    </div>

    <div className="as-pipeline-panel__schedule">
      <div className="as-pipeline-panel__field">
        <label className="as-pipeline-panel__field-label">ĐỊNH KỲ</label>
        <select
          className="as-select as-select--sm"
          value={frequency}
          onChange={e => onFrequencyChange(e.target.value)}
          disabled={!autoEnabled}
        >
          <option value="daily">Hàng ngày</option>
          <option value="weekly">Hàng tuần</option>
          <option value="monthly">Hàng tháng</option>
        </select>
      </div>
      <div className="as-pipeline-panel__field">
        <label className="as-pipeline-panel__field-label">GIỜ CHẠY</label>
        <input
          type="time"
          className="as-input as-input--sm"
          value={runTime}
          onChange={e => onRunTimeChange(e.target.value)}
          disabled={!autoEnabled}
        />
      </div>
    </div>

    <div className="as-pipeline-panel__footer">
      <div className="as-pipeline-panel__last-run">
        <span className="as-pipeline-panel__last-run-label">Chạy thủ công</span>
        {lastRun && (
          <span className="as-pipeline-panel__last-run-time">Lần cuối: {lastRun}</span>
        )}
      </div>
      <button
        className={`as-btn-primary${(!available || isRunning) ? ' as-btn-primary--disabled' : ''}`}
        onClick={onRunNow}
        disabled={!available || isRunning}
        title={!available ? 'Tính năng chưa được triển khai' : undefined}
      >
        {isRunning ? (
          <>
            <Loader2 size={14} className="as-spin" />
            Đang chạy...
          </>
        ) : (
          'Chạy ngay'
        )}
      </button>
    </div>
  </div>
);

// ── Page ──────────────────────────────────────────────────────────────────────

type CardKey = 'general' | 'weights' | 'classification' | 'conflict' | 'time' | 'twoTower';
type ConflictMode = 'all' | 'limit_k';
type UpgradeMode = 'representative' | 'all_clusters';

export const AlgorithmSettings: React.FC = () => {
  // ── Accordion state ──
  const [open, setOpen] = useState<Record<CardKey, boolean>>({
    general: true,
    weights: false,
    classification: false,
    conflict: false,
    time: false,
    twoTower: false,
  });
  const toggle = (k: CardKey) => setOpen(p => ({ ...p, [k]: !p[k] }));

  // ── Change banner ──
  const [banner, setBanner] = useState<string | null>(null);
  const showBanner = (ctx: string) =>
    setBanner(`Thay đổi này sẽ ảnh hưởng đến ${ctx} đang được xử lý.`);

  // ── Card 1: Tham số thuật toán chung ──
  const [maxDistance, setMaxDistance] = useState(50);
  const [locationPriority, setLocationPriority] = useState('Cao');

  // ── Card 2: Trọng số mô hình ──
  const [distanceWeight, setDistanceWeight] = useState(0.4);

  // ── Card 3: Phân loại đánh giá ──
  const [topicThreshold, setTopicThreshold] = useState(0.18);
  const [minConfidence, setMinConfidence] = useState(0.55);
  const [labelMargin, setLabelMargin] = useState(0.10);
  const [topicsC3, setTopicsC3] = useState(() => DEFAULT_TOPICS_C3.map(t => ({ ...t })));

  // ── Card 4: Phát hiện xung đột ──
  const [conflictThreshold, setConflictThreshold] = useState(0.65);
  const [windowFactor, setWindowFactor] = useState(6);
  const [conflictMode, setConflictMode] = useState<ConflictMode>('all');
  const [maxK, setMaxK] = useState(5);

  // ── Card 5: Quản lý thời gian ──
  const [upgradeMode, setUpgradeMode] = useState<UpgradeMode>('representative');
  const [topicsC5, setTopicsC5] = useState(() => DEFAULT_TOPICS_C5.map(t => ({ ...t })));

  // ── Card 6: Two Tower ──
  const [temperature, setTemperature] = useState(1.0);
  const [maxHistory, setMaxHistory] = useState(50);

  // ── Pipeline: Phân loại đánh giá ──
  const [reviewAutoEnabled, setReviewAutoEnabled] = useState(false);
  const [reviewFrequency, setReviewFrequency] = useState('daily');
  const [reviewRunTime, setReviewRunTime] = useState('02:00');
  const [reviewRunning, setReviewRunning] = useState(false);
  const [reviewLastRun, setReviewLastRun] = useState<string | undefined>(undefined);

  // ── History ──
  const [historyRows, setHistoryRows] = useState<PipelineHistoryItem[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [runResult, setRunResult] = useState<string | null>(null);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const loadHistory = useCallback(async () => {
    try {
      setHistoryLoading(true);
      const data = await algorithmPipelineAPI.getHistory(20);
      setHistoryRows(data.history);
    } catch {
      // lịch sử không tải được — giữ dữ liệu cũ
    } finally {
      setHistoryLoading(false);
    }
  }, []);

  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  const handleRunReviewPipeline = async () => {
    setReviewRunning(true);
    setRunResult(null);
    try {
      const result = await algorithmPipelineAPI.runPipeline({
        no_pretrained: false,
        topic_other_threshold: topicThreshold,
        candidate_mode: conflictMode === 'all' ? 'all' : 'topk',
        promotion_mode: upgradeMode === 'representative' ? 'representative' : 'all',
        dry_run: false,
      });
      setReviewLastRun(formatPipelineDateTime(result.completed_at));
      setRunResult(
        `Hoàn thành: xử lý ${result.total_reviews} đánh giá, ` +
        `${result.conflicts_detected} xung đột, ` +
        `${result.long_term_summaries} tóm tắt dài hạn.`
      );
      await loadHistory();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Lỗi không xác định';
      setRunResult(`Lỗi: ${message}`);
    } finally {
      setReviewRunning(false);
    }
  };

  // Dọn polling khi unmount
  useEffect(() => {
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, []);

  return (
    <div className="page-container as-page">
      {/* ── Page header ── */}
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Bảng điều khiển Thiết lập Thuật toán</h1>
          <div className="breadcrumb">
            <span className="text-muted">Thiết lập</span>
            {' / '}
            <span className="active-bread">Thiết lập thuật toán</span>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn"><Bell size={20} /></button>
          <AdminHeaderProfile />
        </div>
      </header>

      {/* ── Main content ── */}
      <div className="page-content as-content">

        {/* Change banner */}
        {banner && (
          <div className="as-banner" role="alert">
            <Info size={14} />
            <span>{banner}</span>
            <button className="as-banner__close" onClick={() => setBanner(null)} aria-label="Đóng">×</button>
          </div>
        )}

        {/* Run result banner */}
        {runResult && (
          <div
            className={`as-banner${runResult.startsWith('Lỗi') ? ' as-banner--error' : ' as-banner--success'}`}
            role="alert"
          >
            <Info size={14} />
            <span>{runResult}</span>
            <button className="as-banner__close" onClick={() => setRunResult(null)} aria-label="Đóng">×</button>
          </div>
        )}

        {/* ━━ Pipeline control panels ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <div className="as-pipeline-row">
          <PipelinePanel
            title="Phân loại đánh giá"
            icon={<span className="as-pipeline-panel__icon-emoji">📋</span>}
            autoEnabled={reviewAutoEnabled}
            onAutoChange={setReviewAutoEnabled}
            frequency={reviewFrequency}
            onFrequencyChange={setReviewFrequency}
            runTime={reviewRunTime}
            onRunTimeChange={setReviewRunTime}
            onRunNow={handleRunReviewPipeline}
            isRunning={reviewRunning}
            lastRun={reviewLastRun}
            available={true}
          />
        </div>

        {/* ━━ Card 1: Tham số thuật toán chung ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <AccordionCard
          title="Tham số thuật toán chung"
          open={open.general}
          onToggle={() => toggle('general')}
          onSave={() => {}}
          onReset={() => { setMaxDistance(50); setLocationPriority('Cao'); }}
        >
          <div className="as-row as-row--2col">
            <div className="as-field">
              <label className="as-label">Khoảng cách tối đa tìm địa điểm (km)</label>
              <input
                type="number"
                className={`as-input${outOfRange(maxDistance, 1, 500) ? ' as-input--err' : ''}`}
                value={maxDistance}
                min={1}
                max={500}
                onChange={e => setMaxDistance(Number(e.target.value))}
              />
            </div>
            <div className="as-field">
              <label className="as-label">Ưu tiên địa điểm mới</label>
              <select
                className="as-select"
                value={locationPriority}
                onChange={e => setLocationPriority(e.target.value)}
              >
                <option>Thấp</option>
                <option>Trung bình</option>
                <option>Cao</option>
              </select>
            </div>
          </div>
        </AccordionCard>

        {/* ━━ Card 2: Trọng số mô hình ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <AccordionCard
          title="Trọng số mô hình"
          open={open.weights}
          onToggle={() => toggle('weights')}
          onSave={() => {}}
          onReset={() => setDistanceWeight(0.4)}
        >
          <div className="as-field">
            <label className="as-label">
              Trọng số khoảng cách
              <Tip text="Mức độ ảnh hưởng của khoảng cách địa lý lên điểm gợi ý (0.0 – 1.0)" />
            </label>
            <input
              type="number"
              step="0.01"
              min={0}
              max={1}
              className={`as-input${outOfRange(distanceWeight, 0, 1) ? ' as-input--err' : ''}`}
              value={distanceWeight}
              onChange={e => setDistanceWeight(Number(e.target.value))}
            />
            <span className="as-hint">Khuyến nghị: 0.20 – 0.60</span>
          </div>
        </AccordionCard>

        {/* ━━ Card 3: Phân loại đánh giá ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <AccordionCard
          title="Phân loại đánh giá"
          open={open.classification}
          onToggle={() => toggle('classification')}
          onSave={() => {}}
          onReset={() => {
            setTopicThreshold(0.18);
            setMinConfidence(0.55);
            setLabelMargin(0.10);
            setTopicsC3(DEFAULT_TOPICS_C3.map(t => ({ ...t })));
          }}
        >
          <div className="as-row as-row--3col">
            <div className="as-field">
              <label className="as-label">
                Ngưỡng nhận dạng chủ đề
                <Tip text="Điểm tối thiểu để gán chủ đề cho đánh giá" />
              </label>
              <input
                type="number"
                step="0.01"
                min={0}
                max={1}
                className={`as-input${outOfRange(topicThreshold, 0, 1) ? ' as-input--err' : ''}`}
                value={topicThreshold}
                onChange={e => {
                  setTopicThreshold(Number(e.target.value));
                  showBanner('các đánh giá đang chờ phân loại');
                }}
              />
              <span className="as-hint">Khuyến nghị: 0.10 – 0.30</span>
            </div>
            <div className="as-field">
              <label className="as-label">
                Độ tin cậy tối thiểu của mô hình
                <Tip text="Ngưỡng tin cậy để chấp nhận kết quả phân loại" />
              </label>
              <input
                type="number"
                step="0.01"
                min={0}
                max={1}
                className={`as-input${outOfRange(minConfidence, 0, 1) ? ' as-input--err' : ''}`}
                value={minConfidence}
                onChange={e => {
                  setMinConfidence(Number(e.target.value));
                  showBanner('các đánh giá đang chờ phân loại');
                }}
              />
              <span className="as-hint">Khuyến nghị: 0.40 – 0.70</span>
            </div>
            <div className="as-field">
              <label className="as-label">
                Biên độ phân biệt nhãn
                <Tip text="Khoảng cách tối thiểu giữa các nhãn để tránh xung đột phân loại" />
              </label>
              <input
                type="number"
                step="0.01"
                min={0}
                max={1}
                className={`as-input${outOfRange(labelMargin, 0, 1) ? ' as-input--err' : ''}`}
                value={labelMargin}
                onChange={e => setLabelMargin(Number(e.target.value))}
              />
              <span className="as-hint">Khuyến nghị: 0.05 – 0.20</span>
            </div>
          </div>

          <div className="as-table-wrap">
            <table className="as-table">
              <thead>
                <tr>
                  <th>Chủ đề</th>
                  <th>Thời hạn (giờ)</th>
                  <th>Tương đương</th>
                </tr>
              </thead>
              <tbody>
                {topicsC3.map((row, idx) => (
                  <tr key={row.name}>
                    <td>{row.name}</td>
                    <td>
                      <input
                        type="number"
                        className="as-input as-input--inline"
                        value={row.hours}
                        min={1}
                        onChange={e =>
                          setTopicsC3(p =>
                            p.map((t, i) => i === idx ? { ...t, hours: Number(e.target.value) } : t)
                          )
                        }
                      />
                    </td>
                    <td className="as-muted">{hoursToLabel(row.hours)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </AccordionCard>

        {/* ━━ Card 4: Phát hiện xung đột ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <AccordionCard
          title="Phát hiện xung đột"
          open={open.conflict}
          onToggle={() => toggle('conflict')}
          onSave={() => {}}
          onReset={() => {
            setConflictThreshold(0.65);
            setWindowFactor(6);
            setConflictMode('all');
            setMaxK(5);
          }}
        >
          <div className="as-stack">
            <div className="as-field">
              <label className="as-label">
                Ngưỡng điểm xung đột
                <Tip text="Điểm cosine similarity tối thiểu để phát hiện xung đột giữa hai đánh giá (0.50 – 0.90)" />
              </label>
              <input
                type="number"
                step="0.01"
                min={0.50}
                max={0.90}
                className={`as-input as-input--sm${outOfRange(conflictThreshold, 0.50, 0.90) ? ' as-input--err' : ''}`}
                value={conflictThreshold}
                onChange={e => {
                  setConflictThreshold(Number(e.target.value));
                  showBanner('các cặp đánh giá đang được xử lý');
                }}
              />
            </div>

            <div className="as-field">
              <label className="as-label">
                Hệ số cửa sổ tra cứu
                <Tip text="Nhân với khoảng thời gian phân loại để tính cửa sổ nhìn lại (1 – 20)" />
              </label>
              <input
                type="number"
                min={1}
                max={20}
                className={`as-input as-input--sm${outOfRange(windowFactor, 1, 20) ? ' as-input--err' : ''}`}
                value={windowFactor}
                onChange={e => setWindowFactor(Number(e.target.value))}
              />
              <span className="as-hint">
                Ví dụ: Đồ ăn (7 ngày × {windowFactor} = {7 * windowFactor} ngày nhìn lại)
              </span>
            </div>

            <div className="as-field">
              <label className="as-label">Chế độ lựa chọn đánh giá so sánh</label>
              <div className="as-radio-group">
                <label className="as-radio">
                  <input
                    type="radio"
                    name="conflictMode"
                    value="all"
                    checked={conflictMode === 'all'}
                    onChange={() => setConflictMode('all')}
                  />
                  So sánh tất cả
                </label>
                <label className="as-radio">
                  <input
                    type="radio"
                    name="conflictMode"
                    value="limit_k"
                    checked={conflictMode === 'limit_k'}
                    onChange={() => setConflictMode('limit_k')}
                  />
                  Giới hạn K đánh giá
                </label>
              </div>

              {conflictMode === 'limit_k' && (
                <div className="as-indented">
                  <label className="as-label">Số đánh giá tối đa để so sánh</label>
                  <input
                    type="number"
                    min={3}
                    max={50}
                    className={`as-input as-input--sm${outOfRange(maxK, 3, 50) ? ' as-input--err' : ''}`}
                    value={maxK}
                    onChange={e => setMaxK(Number(e.target.value))}
                  />
                </div>
              )}
            </div>
          </div>
        </AccordionCard>

        {/* ━━ Card 5: Quản lý thời gian ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <AccordionCard
          title="Quản lý thời gian"
          open={open.time}
          onToggle={() => toggle('time')}
          onSave={() => {}}
          onReset={() => {
            setUpgradeMode('representative');
            setTopicsC5(DEFAULT_TOPICS_C5.map(t => ({ ...t })));
          }}
        >
          <div className="as-field as-field--mb">
            <label className="as-label">Chế độ nâng cấp đánh giá</label>
            <div className="as-radio-group">
              <label className="as-radio">
                <input
                  type="radio"
                  name="upgradeMode"
                  value="representative"
                  checked={upgradeMode === 'representative'}
                  onChange={() => setUpgradeMode('representative')}
                />
                Chỉ nâng cấp đánh giá đại diện
              </label>
              <label className="as-radio">
                <input
                  type="radio"
                  name="upgradeMode"
                  value="all_clusters"
                  checked={upgradeMode === 'all_clusters'}
                  onChange={() => setUpgradeMode('all_clusters')}
                />
                Nâng cấp toàn bộ cụm
              </label>
            </div>
            <span className="as-hint">
              {upgradeMode === 'representative'
                ? 'Chỉ cập nhật đánh giá đại diện nhất trong mỗi cụm.'
                : 'Cập nhật toàn bộ đánh giá trong tất cả các cụm (tiêu tốn nhiều tài nguyên hơn).'}
            </span>
          </div>

          <div className="as-table-wrap">
            <table className="as-table">
              <thead>
                <tr>
                  <th>Chủ đề</th>
                  <th>Cửa sổ (ngày)</th>
                  <th>Số tối thiểu</th>
                  <th>Ngưỡng tương đồng</th>
                </tr>
              </thead>
              <tbody>
                {topicsC5.map((row, idx) => (
                  <tr key={row.name}>
                    <td>{row.name}</td>
                    <td>
                      <input
                        type="number"
                        className="as-input as-input--inline"
                        value={row.window}
                        min={1}
                        onChange={e =>
                          setTopicsC5(p =>
                            p.map((t, i) => i === idx ? { ...t, window: Number(e.target.value) } : t)
                          )
                        }
                      />
                    </td>
                    <td>
                      <input
                        type="number"
                        className="as-input as-input--inline"
                        value={row.minCount}
                        min={1}
                        onChange={e =>
                          setTopicsC5(p =>
                            p.map((t, i) => i === idx ? { ...t, minCount: Number(e.target.value) } : t)
                          )
                        }
                      />
                    </td>
                    <td>
                      <input
                        type="number"
                        step="0.01"
                        min={0}
                        max={1}
                        className="as-input as-input--inline"
                        value={row.similarity}
                        onChange={e =>
                          setTopicsC5(p =>
                            p.map((t, i) => i === idx ? { ...t, similarity: Number(e.target.value) } : t)
                          )
                        }
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </AccordionCard>

        {/* ━━ Card 6: Two Tower ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <AccordionCard
          title="Two Tower"
          open={open.twoTower}
          onToggle={() => toggle('twoTower')}
          onSave={() => {}}
          onReset={() => { setTemperature(1.0); setMaxHistory(50); }}
        >
          <div className="as-row as-row--2col">
            <div className="as-field">
              <label className="as-label">
                Temperature
                <Tip text="Điều chỉnh mức độ ngẫu nhiên trong kết quả gợi ý (0.1 – 5.0)" />
              </label>
              <input
                type="number"
                step="0.1"
                min={0.1}
                max={5.0}
                className={`as-input${outOfRange(temperature, 0.1, 5.0) ? ' as-input--err' : ''}`}
                value={temperature}
                onChange={e => setTemperature(Number(e.target.value))}
              />
              <span className="as-hint">Khuyến nghị: 0.5 – 2.0</span>
            </div>
            <div className="as-field">
              <label className="as-label">
                Max History
                <Tip text="Số lượng lịch sử tương tác tối đa dùng để tính embedding người dùng (1 – 500)" />
              </label>
              <input
                type="number"
                min={1}
                max={500}
                className={`as-input${outOfRange(maxHistory, 1, 500) ? ' as-input--err' : ''}`}
                value={maxHistory}
                onChange={e => setMaxHistory(Number(e.target.value))}
              />
              <span className="as-hint">Khuyến nghị: 20 – 100</span>
            </div>
          </div>
        </AccordionCard>

        {/* ━━ Lịch sử chạy thuật toán ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */}
        <div className="as-history">
          <div className="as-history__header">
            <span className="as-history__title">
              <span className="as-history__dot" />
              Lịch sử chạy thuật toán
            </span>
            <button className="as-btn-ghost as-btn-ghost--sm" onClick={loadHistory} disabled={historyLoading}>
              {historyLoading ? <Loader2 size={12} className="as-spin" /> : <RotateCcw size={12} />}
              Làm mới
            </button>
          </div>
          <div className="as-table-wrap">
            <table className="as-table">
              <thead>
                <tr>
                  <th>Thuật toán</th>
                  <th>Ngày chạy</th>
                  <th>Thời gian xử lý</th>
                  <th>Trạng thái</th>
                  <th>Kết quả tóm tắt</th>
                </tr>
              </thead>
              <tbody>
                {historyRows.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="as-muted" style={{ textAlign: 'center', padding: '20px' }}>
                      {historyLoading ? 'Đang tải...' : 'Chưa có lịch sử chạy trong phiên này.'}
                    </td>
                  </tr>
                ) : (
                  historyRows.map((row, idx) => (
                    <tr key={`${row.run_id}-${idx}`}>
                      <td className="as-fw500">Phân loại đánh giá</td>
                      <td className="as-muted">{formatPipelineDateTime(row.started_at)}</td>
                      <td className="as-muted">{formatPipelineDuration(row.duration_seconds)}</td>
                      <td>
                        <span className={`as-badge as-badge--${row.success ? 'done' : 'error'}`}>
                          <span className="as-badge__dot" />
                          {row.success ? 'Thành công' : 'Thất bại'}
                        </span>
                      </td>
                      <td className={row.success ? 'as-muted' : 'as-err-text'}>
                        {row.success
                          ? `Xử lý ${row.total_reviews} đánh giá — ${row.conflicts_detected} xung đột — ${row.long_term_summaries} tóm tắt dài hạn`
                          : row.error || 'Lỗi không xác định'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </div>
  );
};
