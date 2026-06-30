import React, { useEffect, useState } from 'react';
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
  scheduleSaving?: boolean;
  scheduleDirty?: boolean;
  lastRun?: string;
  onSaveSchedule?: () => void;
  onRunNow: () => void;
}

const AlgoDropdown: React.FC<AlgoDropdownProps> = ({
  title, available,
  autoEnabled, onAutoChange,
  frequency, onFrequencyChange,
  runDay, onRunDayChange,
  runTime, onRunTimeChange,
  isRunning, scheduleSaving = false, scheduleDirty = false, lastRun, onSaveSchedule, onRunNow,
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
          {lastRun && (
            <div className="ar-dropdown__last-run ar-dropdown__last-run--top">
              <span className="ar-dropdown__last-run-label">Lần chạy cuối</span>
              <span className="ar-dropdown__last-run-time">{lastRun}</span>
            </div>
          )}
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

          {onSaveSchedule && (
            <div className="ar-dropdown__schedule-actions">
              <button
                className={`ar-btn-primary${(!available || scheduleSaving || !scheduleDirty) ? ' ar-btn-primary--disabled' : ''}`}
                type="button"
                onClick={onSaveSchedule}
                disabled={!available || scheduleSaving || !scheduleDirty}
              >
                {scheduleSaving ? (
                  <>
                    <Loader2 size={14} className="ar-spin" />
                    Đang lưu...
                  </>
                ) : (
                  'Lưu thay đổi'
                )}
              </button>
            </div>
          )}

          <div className="ar-dropdown__footer">
            <div className="ar-dropdown__last-run">
              <span className="ar-dropdown__last-run-label">Chạy thủ công</span>
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
  const [reviewScheduleSaving, setReviewScheduleSaving] = useState(false);
  const [reviewScheduleDirty, setReviewScheduleDirty] = useState(false);
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

  useEffect(() => {
    let alive = true;

    async function loadReviewSchedule() {
      try {
        const schedule = await algorithmPipelineAPI.getReviewFilterSchedule();
        if (!alive) return;
        setReviewAutoEnabled(schedule.autoEnabled);
        setReviewFrequency(schedule.frequency);
        setReviewRunDay(schedule.runDay);
        setReviewRunTime(schedule.runTime);
        setReviewScheduleDirty(false);
        if (schedule.lastRunAt) {
          setReviewLastRun(formatPipelineDateTime(schedule.lastRunAt));
        }
      } catch (err: unknown) {
        if (!alive) return;
        const message = err instanceof Error ? err.message : 'Không thể tải lịch chạy tự động';
        setRunResult(`Lỗi: ${message}`);
      }
    }

    void loadReviewSchedule();
    return () => {
      alive = false;
    };
  }, []);

  const saveReviewSchedule = async () => {
    setReviewScheduleSaving(true);
    try {
      const schedule = await algorithmPipelineAPI.updateReviewFilterSchedule({
        autoEnabled: reviewAutoEnabled,
        frequency: reviewFrequency as 'daily' | 'weekly' | 'monthly',
        runTime: reviewRunTime,
        runDay: Number(reviewRunDay),
      });
      setReviewAutoEnabled(schedule.autoEnabled);
      setReviewFrequency(schedule.frequency);
      setReviewRunDay(schedule.runDay);
      setReviewRunTime(schedule.runTime);
      setReviewScheduleDirty(false);
      if (schedule.lastRunAt) {
        setReviewLastRun(formatPipelineDateTime(schedule.lastRunAt));
      }
      setRunResult('Đã lưu lịch chạy tự động thuật toán lọc đánh giá.');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Không thể lưu lịch chạy tự động';
      setRunResult(`Lỗi: ${message}`);
    } finally {
      setReviewScheduleSaving(false);
    }
  };

  const handleReviewAutoChange = (next: boolean) => {
    setReviewAutoEnabled(next);
    setReviewScheduleDirty(true);
  };

  const handleReviewFrequencyChange = (next: string) => {
    const frequency = next as 'daily' | 'weekly' | 'monthly';
    const nextDay =
      frequency === 'weekly'
        ? ['0', '1', '2', '3', '4', '5', '6'].includes(reviewRunDay)
          ? reviewRunDay
          : '1'
        : frequency === 'monthly'
          ? String(Math.min(Math.max(Number(reviewRunDay) || 1, 1), 28))
          : reviewRunDay;
    setReviewFrequency(frequency);
    setReviewRunDay(nextDay);
    setReviewScheduleDirty(true);
  };

  const handleReviewRunTimeChange = (next: string) => {
    setReviewRunTime(next);
    setReviewScheduleDirty(true);
  };

  const handleReviewRunDayChange = (next: string) => {
    setReviewRunDay(next);
    setReviewScheduleDirty(true);
  };

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
            title="Lọc đánh giá"
            available={true}
            autoEnabled={reviewAutoEnabled}
            onAutoChange={handleReviewAutoChange}
            frequency={reviewFrequency}
            onFrequencyChange={handleReviewFrequencyChange}
            runDay={reviewRunDay}
            onRunDayChange={handleReviewRunDayChange}
            runTime={reviewRunTime}
            onRunTimeChange={handleReviewRunTimeChange}
            isRunning={reviewRunning}
            scheduleSaving={reviewScheduleSaving}
            scheduleDirty={reviewScheduleDirty}
            lastRun={reviewLastRun}
            onSaveSchedule={saveReviewSchedule}
            onRunNow={handleRunReviewPipeline}
          />
          <AlgoDropdown
            title="Lập lịch"
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
