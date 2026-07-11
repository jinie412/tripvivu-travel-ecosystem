import React, { useEffect, useRef, useState } from 'react';
import { Bell, CalendarClock, Clock3, Loader2, Play, Save } from 'lucide-react';
import Swal from 'sweetalert2';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import {
  algorithmPipelineAPI,
  formatPipelineDateTime,
} from '../../../services/algorithmPipelineAPI';
import './AlgorithmRunner.css';

const notify = (icon: 'success' | 'error' | 'info', title: string) => {
  void Swal.fire({
    toast: true,
    position: 'top-end',
    icon,
    title,
    showConfirmButton: false,
    timer: 5000,
    timerProgressBar: true,
  });
};

// ── Toggle ───────────────────────────────────────────────────────────────────

const Toggle: React.FC<{ checked: boolean; disabled?: boolean; onChange: (v: boolean) => void }> = ({
  checked, disabled = false, onChange,
}) => (
  <button
    type="button"
    role="switch"
    aria-checked={checked}
    className={`ar-toggle${checked ? ' ar-toggle--on' : ''}${disabled ? ' ar-toggle--disabled' : ''}`}
    disabled={disabled}
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
  statusDetail?: string;
  onSaveSchedule?: () => void;
  onRunNow: () => void;
}

const AlgoDropdown: React.FC<AlgoDropdownProps> = ({
  title, available,
  autoEnabled, onAutoChange,
  frequency, onFrequencyChange,
  runDay, onRunDayChange,
  runTime, onRunTimeChange,
  isRunning, scheduleSaving = false, scheduleDirty = false, lastRun, statusDetail, onSaveSchedule, onRunNow,
}) => (
  <div className={`ar-dropdown${!available ? ' ar-dropdown--muted' : ''}`}>
    <div className="ar-dropdown__header">
      <div className="ar-dropdown__title-wrap">
        <div className="ar-dropdown__title-row">
          <span className="ar-dropdown__title">{title}</span>
          {/* <span className={`ar-badge ${available ? (autoEnabled ? 'ar-badge--active' : 'ar-badge--inactive') : 'ar-badge--disabled'}`}>
            {!available ? 'Chưa khả dụng' : autoEnabled ? 'Tự động bật' : 'Tự động tắt'}
          </span> */}
        </div>
      </div>
      <div className="ar-dropdown__toggle-wrap">
        <span className="ar-dropdown__auto-label">Tự động</span>
        <Toggle checked={autoEnabled} disabled={!available} onChange={onAutoChange} />
      </div>
    </div>

    <div className="ar-dropdown__body">
          <div className="ar-dropdown__meta-row">
            <div className="ar-dropdown__meta">
              <Clock3 size={16} />
              <div>
                <span className="ar-dropdown__meta-label">Lần chạy cuối</span>
                <span className="ar-dropdown__meta-value">{lastRun ?? 'Chưa ghi nhận'}</span>
              </div>
            </div>
            {statusDetail && (
              <div className="ar-dropdown__meta">
                <Loader2 size={16} className={isRunning ? 'ar-spin' : ''} />
                <div>
                  <span className="ar-dropdown__meta-label">Trạng thái</span>
                  <span className="ar-dropdown__meta-value">{statusDetail}</span>
                </div>
              </div>
            )}
          </div>

          <section className="ar-section ar-section--schedule">
            <div className="ar-section__header">
              <CalendarClock size={18} />
              <div>
                <h2>Lịch tự động</h2>
                <p>{autoEnabled ? 'Đang chạy theo lịch đã thiết lập' : 'Đã tắt lịch tự động cho thuật toán này'}</p>
              </div>
            </div>
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
                  <>
                    <Save size={14} />
                    Lưu thay đổi
                  </>
                )}
              </button>
            </div>
          )}
          </section>

          <section className="ar-section ar-section--manual">
            <div className="ar-section__header">
              <Play size={18} />
              <div>
                <h2>Chạy thủ công</h2>
                <p>{autoEnabled ? 'Tắt tự động để chạy ngay thủ công' : 'Kích hoạt thuật toán một lần theo nhu cầu'}</p>
              </div>
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
                <>
                  <Play size={14} />
                  Chạy ngay
                </>
              )}
            </button>
          </section>
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
  const [recommendRunning, setRecommendRunning] = useState(false);
  const [recommendScheduleSaving, setRecommendScheduleSaving] = useState(false);
  const [recommendScheduleDirty, setRecommendScheduleDirty] = useState(false);
  const [recommendLastRun, setRecommendLastRun] = useState<string | undefined>();
  const [recommendProgress, setRecommendProgress] = useState(0);
  const [recommendStep, setRecommendStep] = useState('Sẵn sàng');
  const observedRunId = useRef<string | null>(null);
  const notifiedRunIds = useRef(new Set<string>());

  // ── Schedule pipeline ──
  const [scheduleAutoEnabled, setScheduleAutoEnabled] = useState(false);
  const [scheduleFrequency, setScheduleFrequency] = useState('weekly');
  const [scheduleRunDay, setScheduleRunDay] = useState('1');
  const [scheduleRunTime, setScheduleRunTime] = useState('04:00');

  useEffect(() => {
    let alive = true;

    async function loadSchedules() {
      try {
        const [schedule, recommendSchedule, retrainStatus] = await Promise.all([
          algorithmPipelineAPI.getReviewFilterSchedule(),
          algorithmPipelineAPI.getRecommenderRetrainSchedule(),
          algorithmPipelineAPI.getRecommenderRetrainStatus(),
        ]);
        if (!alive) return;
        setReviewAutoEnabled(schedule.autoEnabled);
        setReviewFrequency(schedule.frequency);
        setReviewRunDay(schedule.runDay);
        setReviewRunTime(schedule.runTime);
        setReviewScheduleDirty(false);
        if (schedule.lastRunAt) {
          setReviewLastRun(formatPipelineDateTime(schedule.lastRunAt));
        }
        setRecommendAutoEnabled(recommendSchedule.autoEnabled);
        setRecommendFrequency(recommendSchedule.frequency);
        setRecommendRunDay(recommendSchedule.runDay);
        setRecommendRunTime(recommendSchedule.runTime);
        setRecommendScheduleDirty(false);
        if (recommendSchedule.lastRunAt) {
          setRecommendLastRun(formatPipelineDateTime(recommendSchedule.lastRunAt));
        }
        if (retrainStatus.currentRun) {
          observedRunId.current = retrainStatus.currentRun.id;
          setRecommendRunning(true);
          setRecommendProgress(retrainStatus.currentRun.metrics?.progress ?? 0);
          setRecommendStep(retrainStatus.currentRun.metrics?.current_step ?? retrainStatus.currentRun.status);
        } else if (retrainStatus.latestRun) {
          const latest = retrainStatus.latestRun;
          observedRunId.current = latest.id;
          setRecommendStep(latest.status === 'completed' ? 'Hoàn thành' : latest.status);
          setRecommendProgress(latest.metrics?.progress ?? 0);
          if (latest.completedAt) setRecommendLastRun(formatPipelineDateTime(latest.completedAt));
        }
      } catch (err: unknown) {
        if (!alive) return;
        const message = err instanceof Error ? err.message : 'Không thể tải lịch chạy tự động';
        notify('error', message);
      }
    }

    void loadSchedules();
    return () => {
      alive = false;
    };
  }, []);

  useEffect(() => {
    const syncRetrainStatus = async () => {
      try {
        const status = await algorithmPipelineAPI.getRecommenderRetrainStatus();
        const run = status.currentRun ?? status.latestRun;
        if (!run) return;

        // Scheduler có thể tạo run mà trang không biết trước. Poll chung sẽ phát hiện
        // run mới và hiển thị tiến trình ngay trên card.
        if (status.currentRun) {
          observedRunId.current = run.id;
          setRecommendRunning(true);
        }
        setRecommendProgress(run.metrics?.progress ?? 0);
        setRecommendStep(run.metrics?.current_step ?? run.status);
        if (run.startedAt || run.createdAt) {
          setRecommendLastRun(formatPipelineDateTime(run.startedAt ?? run.createdAt));
        }
        if (run.status === 'completed' || run.status === 'failed') {
          setRecommendRunning(false);
          if (run.completedAt) setRecommendLastRun(formatPipelineDateTime(run.completedAt));
          if (!notifiedRunIds.current.has(run.id) && observedRunId.current === run.id) {
            notifiedRunIds.current.add(run.id);
            if (run.status === 'completed') {
            const baseline = run.metrics?.rating_only_test_rmse;
            const hybrid = run.metrics?.test_rmse;
              notify('success',
              `Retrain hoàn thành${baseline != null && hybrid != null ? ` — RMSE rating ${baseline.toFixed(4)}, hybrid ${hybrid.toFixed(4)}` : ''}.`
              );
            } else {
              notify('error', run.errorMessage ?? 'Retrain thất bại');
            }
          }
        }
      } catch {
        // Keep polling; transient API errors should not lose the running job UI.
      }
    };
    const timer = window.setInterval(() => void syncRetrainStatus(), 3000);
    return () => window.clearInterval(timer);
  }, []);

  const saveRecommendSchedule = async () => {
    setRecommendScheduleSaving(true);
    try {
      const schedule = await algorithmPipelineAPI.updateRecommenderRetrainSchedule({
        autoEnabled: recommendAutoEnabled,
        frequency: recommendFrequency as 'daily' | 'weekly' | 'monthly',
        runTime: recommendRunTime,
        runDay: Number(recommendRunDay),
      });
      setRecommendAutoEnabled(schedule.autoEnabled);
      setRecommendFrequency(schedule.frequency);
      setRecommendRunDay(schedule.runDay);
      setRecommendRunTime(schedule.runTime);
      setRecommendScheduleDirty(false);
      notify('success', 'Đã lưu lịch retrain thuật toán gợi ý.');
    } catch (err: unknown) {
      notify('error', err instanceof Error ? err.message : 'Không thể lưu lịch retrain');
    } finally {
      setRecommendScheduleSaving(false);
    }
  };

  const handleRunRecommendPipeline = async () => {
    setRecommendRunning(true);
    setRecommendProgress(0);
    setRecommendStep('Đang tạo job');
    try {
      const status = await algorithmPipelineAPI.runRecommenderRetrain();
      if (status.currentRun) {
        observedRunId.current = status.currentRun.id;
        setRecommendStep(status.currentRun.metrics?.current_step ?? 'queued');
      }
    } catch (err: unknown) {
      setRecommendRunning(false);
      notify('error', err instanceof Error ? err.message : 'Không thể chạy retrain');
    }
  };

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
      notify('success', 'Đã lưu lịch chạy tự động thuật toán lọc đánh giá.');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Không thể lưu lịch chạy tự động';
      notify('error', message);
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
    try {
      const result = await algorithmPipelineAPI.runPipeline({ dry_run: false });
      setReviewLastRun(formatPipelineDateTime(result.completed_at));
      notify('success',
        `Hoàn thành: xử lý ${result.total_reviews} đánh giá, ` +
        `${result.conflicts_detected} xung đột, ` +
        `${result.long_term_summaries} tóm tắt dài hạn.`
      );
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Lỗi không xác định';
      notify('error', message);
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
        <div className="ar-accordion">
          <AlgoDropdown
            title="Thuật toán gợi ý"
            available={true}
            autoEnabled={recommendAutoEnabled}
            onAutoChange={(value) => { setRecommendAutoEnabled(value); setRecommendScheduleDirty(true); }}
            frequency={recommendFrequency}
            onFrequencyChange={(value) => { setRecommendFrequency(value); setRecommendScheduleDirty(true); }}
            runDay={recommendRunDay}
            onRunDayChange={(value) => { setRecommendRunDay(value); setRecommendScheduleDirty(true); }}
            runTime={recommendRunTime}
            onRunTimeChange={(value) => { setRecommendRunTime(value); setRecommendScheduleDirty(true); }}
            isRunning={recommendRunning}
            scheduleSaving={recommendScheduleSaving}
            scheduleDirty={recommendScheduleDirty}
            lastRun={recommendLastRun}
            statusDetail={`${recommendStep}${recommendRunning ? ` ${recommendProgress}%` : ''}`}
            onSaveSchedule={saveRecommendSchedule}
            onRunNow={handleRunRecommendPipeline}
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
