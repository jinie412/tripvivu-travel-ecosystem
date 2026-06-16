import React, { useState } from 'react';
import { Bell, Loader2 } from 'lucide-react';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import {
  algorithmPipelineAPI,
  formatPipelineDateTime,
} from '../../../services/algorithmPipelineAPI';
import './AlgorithmRunner.css';

// ── Toggle ───────────────────────────────────────────────────────────────────

const Toggle: React.FC<{ checked: boolean; onChange: (v: boolean) => void }> = ({
  checked, onChange,
}) => (
  <button
    role="switch"
    aria-checked={checked}
    className={`ar-toggle${checked ? ' ar-toggle--on' : ''}`}
    onClick={() => onChange(!checked)}
  >
    <span className="ar-toggle__thumb" />
  </button>
);

// ── AlgoDropdown ──────────────────────────────────────────────────────────────

interface AlgoDropdownProps {
  title: string;
  description: string;
  available: boolean;
  autoEnabled: boolean;
  onAutoChange: (v: boolean) => void;
  frequency: string;
  onFrequencyChange: (v: string) => void;
  runDay: string;
  onRunDayChange: (v: string) => void;
  runTime: string;
  onRunTimeChange: (v: string) => void;
  isRunning: boolean;
  lastRun?: string;
  onRunNow: () => void;
}

const AlgoDropdown: React.FC<AlgoDropdownProps> = ({
  title, description, available,
  autoEnabled, onAutoChange,
  frequency, onFrequencyChange,
  runDay, onRunDayChange,
  runTime, onRunTimeChange,
  isRunning, lastRun, onRunNow,
}) => (
  <div className="ar-dropdown">
    <div className="ar-dropdown__header">
      <span className="ar-dropdown__title">{title}</span>
      <div className="ar-dropdown__toggle-wrap">
        <span className="ar-dropdown__auto-label">Tự động</span>
        <Toggle checked={autoEnabled} onChange={onAutoChange} />
      </div>
    </div>

    <div className="ar-dropdown__body">
          <p className="ar-dropdown__desc">{description}</p>

          <div className="ar-dropdown__schedule">
            <div className="ar-dropdown__field">
              <label className="ar-dropdown__field-label">ĐỊNH KỲ</label>
              <select
                className="ar-select"
                value={frequency}
                onChange={e => onFrequencyChange(e.target.value)}
              >
                <option value="daily">Hàng ngày</option>
                <option value="weekly">Hàng tuần</option>
                <option value="monthly">Hàng tháng</option>
              </select>
            </div>
            <div className="ar-dropdown__field">
              <label className="ar-dropdown__field-label">GIỜ CHẠY</label>
              <input
                type="time"
                className="ar-input"
                value={runTime}
                onChange={e => onRunTimeChange(e.target.value)}
              />
            </div>
            {frequency === 'weekly' && (
              <div className="ar-dropdown__field">
                <label className="ar-dropdown__field-label">NGÀY CHẠY</label>
                <select
                  className="ar-select"
                  value={runDay}
                  onChange={e => onRunDayChange(e.target.value)}
                >
                  <option value="1">Thứ Hai</option>
                  <option value="2">Thứ Ba</option>
                  <option value="3">Thứ Tư</option>
                  <option value="4">Thứ Năm</option>
                  <option value="5">Thứ Sáu</option>
                  <option value="6">Thứ Bảy</option>
                  <option value="0">Chủ Nhật</option>
                </select>
              </div>
            )}
            {frequency === 'monthly' && (
              <div className="ar-dropdown__field">
                <label className="ar-dropdown__field-label">NGÀY TRONG THÁNG</label>
                <select
                  className="ar-select"
                  value={runDay}
                  onChange={e => onRunDayChange(e.target.value)}
                >
                  {Array.from({ length: 28 }, (_, i) => i + 1).map(d => (
                    <option key={d} value={String(d)}>Ngày {d}</option>
                  ))}
                </select>
              </div>
            )}
          </div>

          <div className="ar-dropdown__footer">
            <div className="ar-dropdown__last-run">
              <span className="ar-dropdown__last-run-label">Chạy thủ công</span>
              {lastRun && (
                <span className="ar-dropdown__last-run-time">Lần cuối: {lastRun}</span>
              )}
            </div>
            <button
              className={`ar-btn-primary${(autoEnabled || !available || isRunning) ? ' ar-btn-primary--disabled' : ''}`}
              onClick={onRunNow}
              disabled={autoEnabled || !available || isRunning}
              title={autoEnabled ? 'Tắt lịch tự động để chạy thủ công' : !available ? 'Tính năng chưa được triển khai' : undefined}
            >
              {isRunning ? (
                <>
                  <Loader2 size={14} className="ar-spin" />
                  Đang chạy...
                </>
              ) : (
                'Chạy ngay'
              )}
            </button>
        </div>
    </div>
  </div>
);

// ── Page ─────────────────────────────────────────────────────────────────────

export const AlgorithmRunner: React.FC = () => {
  // ── Review pipeline ──
  const [reviewAutoEnabled, setReviewAutoEnabled] = useState(false);
  const [reviewFrequency, setReviewFrequency] = useState('daily');
  const [reviewRunDay, setReviewRunDay] = useState('1');
  const [reviewRunTime, setReviewRunTime] = useState('02:00');
  const [reviewRunning, setReviewRunning] = useState(false);
  const [reviewLastRun, setReviewLastRun] = useState<string | undefined>(undefined);

  // ── Recommend pipeline ──
  const [recommendAutoEnabled, setRecommendAutoEnabled] = useState(false);
  const [recommendFrequency, setRecommendFrequency] = useState('daily');
  const [recommendRunDay, setRecommendRunDay] = useState('1');
  const [recommendRunTime, setRecommendRunTime] = useState('03:00');

  // ── Schedule pipeline ──
  const [scheduleAutoEnabled, setScheduleAutoEnabled] = useState(false);
  const [scheduleFrequency, setScheduleFrequency] = useState('weekly');
  const [scheduleRunDay, setScheduleRunDay] = useState('1');
  const [scheduleRunTime, setScheduleRunTime] = useState('04:00');

  const [runResult, setRunResult] = useState<string | null>(null);

  const handleRunReviewPipeline = async () => {
    setReviewRunning(true);
    setRunResult(null);
    try {
      const result = await algorithmPipelineAPI.runPipeline({ dry_run: false });
      setReviewLastRun(formatPipelineDateTime(result.completed_at));
      setRunResult(
        `Hoàn thành: xử lý ${result.total_reviews} đánh giá, ` +
        `${result.conflicts_detected} xung đột, ` +
        `${result.long_term_summaries} tóm tắt dài hạn.`
      );
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Lỗi không xác định';
      setRunResult(`Lỗi: ${message}`);
    } finally {
      setReviewRunning(false);
    }
  };

  return (
    <div className="page-container ar-page">
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Lịch chạy thuật toán</h1>
          <div className="breadcrumb">
            <span className="text-muted">Cài đặt</span>
            {' / '}
            <span className="active-bread">Lịch chạy thuật toán</span>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn"><Bell size={20} /></button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="ar-content">
        {runResult && (
          <div
            className={`ar-banner${runResult.startsWith('Lỗi') ? ' ar-banner--error' : ' ar-banner--success'}`}
            role="alert"
          >
            <span>{runResult}</span>
            <button className="ar-banner__close" onClick={() => setRunResult(null)}>×</button>
          </div>
        )}

        <div className="ar-accordion">
          <AlgoDropdown
            title="Thuật toán gợi ý"
            description="Tạo gợi ý địa điểm cá nhân hoá dựa trên lịch sử tương tác và sở thích của người dùng (Two Tower model)."
            available={false}
            autoEnabled={recommendAutoEnabled}
            onAutoChange={setRecommendAutoEnabled}
            frequency={recommendFrequency}
            onFrequencyChange={setRecommendFrequency}
            runDay={recommendRunDay}
            onRunDayChange={setRecommendRunDay}
            runTime={recommendRunTime}
            onRunTimeChange={setRecommendRunTime}
            isRunning={false}
            onRunNow={() => {}}
          />
          <AlgoDropdown
            title="Lọc – Phân loại đánh giá"
            description="Phân loại đánh giá theo chủ đề, phát hiện xung đột và quản lý vòng đời đánh giá theo thời gian."
            available={true}
            autoEnabled={reviewAutoEnabled}
            onAutoChange={setReviewAutoEnabled}
            frequency={reviewFrequency}
            onFrequencyChange={setReviewFrequency}
            runDay={reviewRunDay}
            onRunDayChange={setReviewRunDay}
            runTime={reviewRunTime}
            onRunTimeChange={setReviewRunTime}
            isRunning={reviewRunning}
            lastRun={reviewLastRun}
            onRunNow={handleRunReviewPipeline}
          />
          <AlgoDropdown
            title="Lập lịch"
            description="Tối ưu hoá lịch trình tham quan dựa trên vị trí địa lý, thời gian mở cửa và sở thích của người dùng."
            available={false}
            autoEnabled={scheduleAutoEnabled}
            onAutoChange={setScheduleAutoEnabled}
            frequency={scheduleFrequency}
            onFrequencyChange={setScheduleFrequency}
            runDay={scheduleRunDay}
            onRunDayChange={setScheduleRunDay}
            runTime={scheduleRunTime}
            onRunTimeChange={setScheduleRunTime}
            isRunning={false}
            onRunNow={() => {}}
          />
        </div>
      </div>
    </div>
  );
};
