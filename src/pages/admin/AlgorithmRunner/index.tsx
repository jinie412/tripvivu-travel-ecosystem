import React, { useEffect, useRef, useState } from 'react';
import { Activity, Bell, CalendarClock, CheckCircle2, CircleHelp, Clock3, Loader2, Play, Save, XCircle } from 'lucide-react';
import Swal from 'sweetalert2';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import { NotificationBell } from '../../../components/NotificationBell';
import { algorithmPipelineAPI, formatPipelineDateTime } from '../../../services/algorithmPipelineAPI';
import { sessionCfTrainingAPI } from '../../../services/sessionCfTrainingAPI';
import { algorithmTrainingAPI } from '../../../services/algorithmTrainingAPI';
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
  checked,
  disabled = false,
  onChange,
}) => (
  <button
    type="button"
    role="switch"
    aria-checked={checked}
    className={`ar-toggle${checked ? ' ar-toggle--on' : ''}${disabled ? ' ar-toggle--disabled' : ''}`}
    disabled={disabled}
    onClick={() => onChange(!checked)}>
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
  autoSaving?: boolean;
  scheduleSaving?: boolean;
  scheduleDirty?: boolean;
  lastRun?: string;
  statusDetail?: string;
  statusType?: 'progress' | 'running' | 'success' | 'failed' | 'unknown';
  onSaveSchedule?: () => void;
  onRunNow: () => void;
  runLabel?: string;
}

const AlgoDropdown: React.FC<AlgoDropdownProps> = ({
  title,
  available,
  autoEnabled,
  onAutoChange,
  frequency,
  onFrequencyChange,
  runDay,
  onRunDayChange,
  runTime,
  onRunTimeChange,
  isRunning,
  autoSaving = false,
  scheduleSaving = false,
  scheduleDirty = false,
  lastRun,
  statusDetail,
  statusType = 'progress',
  onSaveSchedule,
  onRunNow,
  runLabel = 'Chạy ngay',
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
        <Toggle checked={autoEnabled} disabled={!available || autoSaving} onChange={onAutoChange} />
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
          <div className={`ar-dropdown__meta ar-dropdown__meta--status-${statusType}`}>
            {statusType === 'success' ? (
              <CheckCircle2 size={17} />
            ) : statusType === 'failed' ? (
              <XCircle size={17} />
            ) : statusType === 'running' ? (
              <Activity size={17} />
            ) : statusType === 'unknown' ? (
              <CircleHelp size={17} />
            ) : (
              <Loader2 size={16} className={isRunning ? 'ar-spin' : ''} />
            )}
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
            <select className="ar-select" value={frequency} onChange={(e) => onFrequencyChange(e.target.value)}>
              <option value="daily">Hàng ngày</option>
              <option value="weekly">Hàng tuần</option>
              <option value="monthly">Hàng tháng</option>
            </select>
          </div>
          <div className="ar-dropdown__field">
            <label className="ar-dropdown__field-label">GIỜ CHẠY</label>
            <input type="time" className="ar-input" value={runTime} onChange={(e) => onRunTimeChange(e.target.value)} />
          </div>
          {frequency === 'weekly' && (
            <div className="ar-dropdown__field">
              <label className="ar-dropdown__field-label">NGÀY CHẠY</label>
              <select className="ar-select" value={runDay} onChange={(e) => onRunDayChange(e.target.value)}>
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
              <select className="ar-select" value={runDay} onChange={(e) => onRunDayChange(e.target.value)}>
                {Array.from({ length: 28 }, (_, i) => i + 1).map((d) => (
                  <option key={d} value={String(d)}>
                    Ngày {d}
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>

        {onSaveSchedule && (
          <div className="ar-dropdown__schedule-actions">
            <button
              className={`ar-btn-primary${!available || scheduleSaving || !scheduleDirty ? ' ar-btn-primary--disabled' : ''}`}
              type="button"
              onClick={onSaveSchedule}
              disabled={!available || scheduleSaving || !scheduleDirty}>
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
          className={`ar-btn-primary${autoEnabled || !available || isRunning ? ' ar-btn-primary--disabled' : ''}`}
          onClick={onRunNow}
          disabled={autoEnabled || !available || isRunning}
          title={autoEnabled ? 'Tắt lịch tự động để chạy thủ công' : !available ? 'Tính năng chưa được triển khai' : undefined}>
          {isRunning ? (
            <>
              <Loader2 size={14} className="ar-spin" />
              Đang chạy...
            </>
          ) : (
            <>
              <Play size={14} />
              {runLabel}
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
  const [reviewAutoSaving, setReviewAutoSaving] = useState(false);
  const [reviewStatusDetail, setReviewStatusDetail] = useState('Chưa ghi nhận');

  // ── Recommend pipeline (retrain hybrid recommender) ──
  const [recommendAutoEnabled, setRecommendAutoEnabled] = useState(false);
  const [recommendFrequency, setRecommendFrequency] = useState('daily');
  const [recommendRunDay, setRecommendRunDay] = useState('1');
  const [recommendRunTime, setRecommendRunTime] = useState('03:00');
  const [recommendRunning, setRecommendRunning] = useState(false);
  const [recommendScheduleSaving, setRecommendScheduleSaving] = useState(false);
  const [recommendScheduleDirty, setRecommendScheduleDirty] = useState(false);
  const [recommendAutoSaving, setRecommendAutoSaving] = useState(false);
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

  // ── Session-CF training (Funk-SVD historical CF, docs/create-data) ──
  const [sessionCfAutoEnabled, setSessionCfAutoEnabled] = useState(false);
  const [sessionCfFrequency, setSessionCfFrequency] = useState('daily');
  const [sessionCfRunDay, setSessionCfRunDay] = useState('1');
  const [sessionCfRunTime, setSessionCfRunTime] = useState('02:00');
  const [sessionCfRunning, setSessionCfRunning] = useState(false);
  const [sessionCfScheduleSaving, setSessionCfScheduleSaving] = useState(false);
  const [sessionCfScheduleDirty, setSessionCfScheduleDirty] = useState(false);
  const [sessionCfAutoSaving, setSessionCfAutoSaving] = useState(false);
  const [sessionCfLastRun, setSessionCfLastRun] = useState<string | undefined>(undefined);

  // ── Two-Tower training (docs/trigger — Phase 0/1 + Modal) ──
  const [twoTowerAutoEnabled, setTwoTowerAutoEnabled] = useState(false);
  const [twoTowerFrequency, setTwoTowerFrequency] = useState('daily');
  const [twoTowerRunDay, setTwoTowerRunDay] = useState('1');
  const [twoTowerRunTime, setTwoTowerRunTime] = useState('01:00');
  const [twoTowerRunning, setTwoTowerRunning] = useState(false);
  const [twoTowerScheduleSaving, setTwoTowerScheduleSaving] = useState(false);
  const [twoTowerScheduleDirty, setTwoTowerScheduleDirty] = useState(false);
  const [twoTowerAutoSaving, setTwoTowerAutoSaving] = useState(false);
  const [twoTowerLastRun, setTwoTowerLastRun] = useState<string | undefined>(undefined);
  const twoTowerObservedRunId = useRef<string | null>(null);
  const twoTowerNotifiedRunIds = useRef(new Set<string>());

  const [runResult, setRunResult] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;

    async function loadSchedules() {
      try {
        const [schedule, recommendSchedule, retrainStatus, reviewHistory] = await Promise.all([
          algorithmPipelineAPI.getReviewFilterSchedule(),
          algorithmPipelineAPI.getRecommenderRetrainSchedule(),
          algorithmPipelineAPI.getRecommenderRetrainStatus(),
          algorithmPipelineAPI.getHistory({ algorithm: 'review_filter', pageSize: 20 }),
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
        const latestReviewRun = reviewHistory.history.find(
          (item) => item.details?.requestedAction === 'run_pipeline',
        );
        if (latestReviewRun) {
          setReviewStatusDetail(latestReviewRun.success && latestReviewRun.status !== 'failed' ? 'Hoàn thành' : 'Thất bại');
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

    async function loadSessionCfSchedule() {
      try {
        const schedule = await sessionCfTrainingAPI.getSchedule();
        if (!alive) return;
        setSessionCfAutoEnabled(schedule.autoEnabled);
        setSessionCfFrequency(schedule.frequency);
        setSessionCfRunDay(schedule.runDay);
        setSessionCfRunTime(schedule.runTime);
        setSessionCfScheduleDirty(false);
        if (schedule.lastRunAt) {
          setSessionCfLastRun(formatPipelineDateTime(schedule.lastRunAt));
        }
      } catch (err: unknown) {
        if (!alive) return;
        const message = err instanceof Error ? err.message : 'Không thể tải lịch chạy tự động';
        setRunResult(`Lỗi: ${message}`);
      }
    }

    async function loadTwoTowerSchedule() {
      try {
        const schedule = await algorithmTrainingAPI.getSchedule('two-tower');
        if (!alive) return;
        setTwoTowerAutoEnabled(schedule.autoEnabled);
        setTwoTowerFrequency(schedule.frequency);
        setTwoTowerRunDay(schedule.runDay);
        setTwoTowerRunTime(schedule.runTime);
        setTwoTowerScheduleDirty(false);
        if (schedule.lastRunAt) {
          setTwoTowerLastRun(formatPipelineDateTime(schedule.lastRunAt));
        }
      } catch (err: unknown) {
        if (!alive) return;
        const message = err instanceof Error ? err.message : 'Không thể tải lịch chạy tự động';
        setRunResult(`Lỗi: ${message}`);
      }
    }

    void loadSchedules();
    void loadSessionCfSchedule();
    void loadTwoTowerSchedule();
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
              notify(
                'success',
                `Retrain hoàn thành${baseline != null && hybrid != null ? ` — RMSE rating ${baseline.toFixed(4)}, hybrid ${hybrid.toFixed(4)}` : ''}.`,
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

  useEffect(() => {
    // Train Two-Tower chay tren GPU (Modal) mat ~30 phut, khong the doi tai cho -- job duoc gui
    // bat dong bo (spawn) roi bao ve qua webhook. Poll training_runs de biet khi nao xong thay vi
    // gia dinh xong ngay sau khi goi API run-full-training.
    const syncTwoTowerStatus = async () => {
      try {
        const runs = await algorithmTrainingAPI.getRuns('two-tower', 5);
        const run = runs.find((r) => r.runType === 'training');
        if (!run) return;

        const isActive = run.status === 'pending' || run.status === 'running';
        setTwoTowerRunning(isActive);

        if (isActive) {
          twoTowerObservedRunId.current = run.id;
          return;
        }

        if (run.completedAt) {
          setTwoTowerLastRun(formatPipelineDateTime(run.completedAt));
        }
        if (twoTowerObservedRunId.current === run.id && !twoTowerNotifiedRunIds.current.has(run.id)) {
          twoTowerNotifiedRunIds.current.add(run.id);
          if (run.status === 'completed') {
            notify('success', 'Two-Tower train xong.');
          } else if (run.status === 'failed') {
            notify('error', run.errorMessage ?? 'Two-Tower train thất bại');
          }
        }
      } catch {
        // Giu polling; loi tam thoi khong nen lam mat trang thai dang chay tren UI.
      }
    };
    void syncTwoTowerStatus();
    const timer = window.setInterval(() => void syncTwoTowerStatus(), 5000);
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

  const handleRecommendAutoChange = async (next: boolean) => {
    const previous = recommendAutoEnabled;
    setRecommendAutoEnabled(next);
    setRecommendAutoSaving(true);
    try {
      const schedule = await algorithmPipelineAPI.updateRecommenderRetrainSchedule({ autoEnabled: next });
      setRecommendAutoEnabled(schedule.autoEnabled);
      notify('success', `Đã ${schedule.autoEnabled ? 'bật' : 'tắt'} lịch tự động thuật toán gợi ý.`);
    } catch (err: unknown) {
      setRecommendAutoEnabled(previous);
      notify('error', err instanceof Error ? err.message : 'Không thể cập nhật trạng thái tự động');
    } finally {
      setRecommendAutoSaving(false);
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

  const handleReviewAutoChange = async (next: boolean) => {
    const previous = reviewAutoEnabled;
    setReviewAutoEnabled(next);
    setReviewAutoSaving(true);
    try {
      const schedule = await algorithmPipelineAPI.updateReviewFilterSchedule({ autoEnabled: next });
      setReviewAutoEnabled(schedule.autoEnabled);
      notify('success', `Đã ${schedule.autoEnabled ? 'bật' : 'tắt'} lịch tự động lọc đánh giá.`);
    } catch (err: unknown) {
      setReviewAutoEnabled(previous);
      notify('error', err instanceof Error ? err.message : 'Không thể cập nhật trạng thái tự động');
    } finally {
      setReviewAutoSaving(false);
    }
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
    setReviewStatusDetail('Đang chạy');
    try {
      const result = await algorithmPipelineAPI.runPipeline({ dry_run: false });
      setReviewLastRun(formatPipelineDateTime(result.completed_at));
      setReviewStatusDetail('Hoàn thành');
      notify(
        'success',
        `Hoàn thành: xử lý ${result.total_reviews} đánh giá, ` +
          `${result.conflicts_detected} xung đột, ` +
          `${result.long_term_summaries} tóm tắt dài hạn.`,
      );
    } catch (err: unknown) {
      setReviewStatusDetail('Thất bại');
      const message = err instanceof Error ? err.message : 'Lỗi không xác định';
      notify('error', message);
    } finally {
      setReviewRunning(false);
    }
  };

  const saveSessionCfSchedule = async () => {
    setSessionCfScheduleSaving(true);
    try {
      const schedule = await sessionCfTrainingAPI.updateSchedule({
        autoEnabled: sessionCfAutoEnabled,
        frequency: sessionCfFrequency as 'daily' | 'weekly' | 'monthly',
        runTime: sessionCfRunTime,
        runDay: Number(sessionCfRunDay),
      });
      setSessionCfAutoEnabled(schedule.autoEnabled);
      setSessionCfFrequency(schedule.frequency);
      setSessionCfRunDay(schedule.runDay);
      setSessionCfRunTime(schedule.runTime);
      setSessionCfScheduleDirty(false);
      if (schedule.lastRunAt) {
        setSessionCfLastRun(formatPipelineDateTime(schedule.lastRunAt));
      }
      setRunResult('Đã lưu lịch chạy tự động huấn luyện Session-CF.');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Không thể lưu lịch chạy tự động';
      setRunResult(`Lỗi: ${message}`);
    } finally {
      setSessionCfScheduleSaving(false);
    }
  };

  const handleSessionCfAutoChange = async (next: boolean) => {
    const previous = sessionCfAutoEnabled;
    setSessionCfAutoEnabled(next);
    setSessionCfAutoSaving(true);
    try {
      const schedule = await sessionCfTrainingAPI.updateSchedule({ autoEnabled: next });
      setSessionCfAutoEnabled(schedule.autoEnabled);
      notify('success', `Đã ${schedule.autoEnabled ? 'bật' : 'tắt'} lịch tự động cập nhật mô hình tương tác.`);
    } catch (err: unknown) {
      setSessionCfAutoEnabled(previous);
      notify('error', err instanceof Error ? err.message : 'Không thể cập nhật trạng thái tự động');
    } finally {
      setSessionCfAutoSaving(false);
    }
  };

  const handleSessionCfFrequencyChange = (next: string) => {
    const frequency = next as 'daily' | 'weekly' | 'monthly';
    const nextDay =
      frequency === 'weekly'
        ? ['0', '1', '2', '3', '4', '5', '6'].includes(sessionCfRunDay)
          ? sessionCfRunDay
          : '1'
        : frequency === 'monthly'
          ? String(Math.min(Math.max(Number(sessionCfRunDay) || 1, 1), 28))
          : sessionCfRunDay;
    setSessionCfFrequency(frequency);
    setSessionCfRunDay(nextDay);
    setSessionCfScheduleDirty(true);
  };

  const handleSessionCfRunTimeChange = (next: string) => {
    setSessionCfRunTime(next);
    setSessionCfScheduleDirty(true);
  };

  const handleSessionCfRunDayChange = (next: string) => {
    setSessionCfRunDay(next);
    setSessionCfScheduleDirty(true);
  };

  const handleRunSessionCfTraining = async () => {
    setSessionCfRunning(true);
    setRunResult(null);
    try {
      const result = await sessionCfTrainingAPI.runTraining({ dry_run: false, upload_r2: true });
      setSessionCfLastRun(formatPipelineDateTime(result.completed_at));
      const metricsText = Object.entries(result.metrics)
        .map(([k, v]) => `${k}=${v.toFixed(4)}`)
        .join(', ');
      setRunResult(
        `Hoàn thành: train lại với ${result.n_users} user, ${result.n_items} place ` +
          `(model=${result.model_type}${metricsText ? `, ${metricsText}` : ''}). ` +
          `${result.uploaded_r2 ? 'Đã upload R2 và nạp lại model đang chạy.' : 'Chưa upload R2.'}`,
      );
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Lỗi không xác định';
      setRunResult(`Lỗi: ${message}`);
    } finally {
      setSessionCfRunning(false);
    }
  };

  const saveTwoTowerSchedule = async () => {
    setTwoTowerScheduleSaving(true);
    try {
      const schedule = await algorithmTrainingAPI.updateSchedule('two-tower', {
        autoEnabled: twoTowerAutoEnabled,
        frequency: twoTowerFrequency as 'daily' | 'weekly' | 'monthly',
        runTime: twoTowerRunTime,
        runDay: Number(twoTowerRunDay),
      });
      setTwoTowerAutoEnabled(schedule.autoEnabled);
      setTwoTowerFrequency(schedule.frequency);
      setTwoTowerRunDay(schedule.runDay);
      setTwoTowerRunTime(schedule.runTime);
      setTwoTowerScheduleDirty(false);
      if (schedule.lastRunAt) {
        setTwoTowerLastRun(formatPipelineDateTime(schedule.lastRunAt));
      }
      setRunResult(
        'Đã lưu lịch tự động cho Two-Tower — hệ thống sẽ tự chuẩn bị dữ liệu theo lịch, ' +
          'và chỉ tự train khi có dữ liệu mới thật sự (đồng thời đã đủ thời gian tối thiểu kể từ lần train gần nhất).',
      );
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Không thể lưu lịch chạy tự động';
      setRunResult(`Lỗi: ${message}`);
    } finally {
      setTwoTowerScheduleSaving(false);
    }
  };

  const handleTwoTowerAutoChange = async (next: boolean) => {
    const previous = twoTowerAutoEnabled;
    setTwoTowerAutoEnabled(next);
    setTwoTowerAutoSaving(true);
    try {
      const schedule = await algorithmTrainingAPI.updateSchedule('two-tower', { autoEnabled: next });
      setTwoTowerAutoEnabled(schedule.autoEnabled);
      notify('success', `Đã ${schedule.autoEnabled ? 'bật' : 'tắt'} lịch tự động Two-Tower.`);
    } catch (err: unknown) {
      setTwoTowerAutoEnabled(previous);
      notify('error', err instanceof Error ? err.message : 'Không thể cập nhật trạng thái tự động');
    } finally {
      setTwoTowerAutoSaving(false);
    }
  };

  const handleTwoTowerFrequencyChange = (next: string) => {
    const frequency = next as 'daily' | 'weekly' | 'monthly';
    const nextDay =
      frequency === 'weekly'
        ? ['0', '1', '2', '3', '4', '5', '6'].includes(twoTowerRunDay)
          ? twoTowerRunDay
          : '1'
        : frequency === 'monthly'
          ? String(Math.min(Math.max(Number(twoTowerRunDay) || 1, 1), 28))
          : twoTowerRunDay;
    setTwoTowerFrequency(frequency);
    setTwoTowerRunDay(nextDay);
    setTwoTowerScheduleDirty(true);
  };

  const handleTwoTowerRunTimeChange = (next: string) => {
    setTwoTowerRunTime(next);
    setTwoTowerScheduleDirty(true);
  };

  const handleTwoTowerRunDayChange = (next: string) => {
    setTwoTowerRunDay(next);
    setTwoTowerScheduleDirty(true);
  };

  const handleRunTwoTowerTraining = async () => {
    setTwoTowerRunning(true);
    setRunResult(null);
    try {
      const dataset = await algorithmTrainingAPI.prepareDataset('two-tower');
      const training = await algorithmTrainingAPI.runFullTraining('two-tower', {
        trainingDatasetId: dataset.trainingDatasetId,
      });
      const datasetNote = dataset.skipped
        ? `Không có dữ liệu mới nên dùng lại dataset đã chuẩn bị trước đó ` +
          `(${dataset.rowCounts.interactions ?? 0} tương tác, ${dataset.rowCounts.users ?? 0} user).`
        : `Đã chuẩn bị dữ liệu (${dataset.rowCounts.interactions ?? 0} tương tác, ` + `${dataset.rowCounts.users ?? 0} user).`;
      setRunResult(
        `${datasetNote} Đã gửi job train lên Modal ` +
          `(trạng thái: ${training.status}). Train chạy trên GPU khoảng 30 phút — bạn có thể rời trang, ` +
          `hệ thống sẽ tự thông báo khi xong.`,
      );
      // Khong flip running=false o day -- job vua submit van dang chay tren Modal (~30 phut).
      // Effect syncTwoTowerStatus() se polling va tu cap nhat running/thong bao khi run thuc su xong.
    } catch (err: unknown) {
      setTwoTowerRunning(false);
      const message = err instanceof Error ? err.message : 'Lỗi không xác định';
      setRunResult(`Lỗi: ${message}`);
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
          <NotificationBell />
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="ar-content">
        {runResult && (
          <div className={`ar-banner${runResult.startsWith('Lỗi') ? ' ar-banner--error' : ' ar-banner--success'}`} role="alert">
            <span>{runResult}</span>
            <button className="ar-banner__close" onClick={() => setRunResult(null)}>
              ×
            </button>
          </div>
        )}

        <div className="ar-accordion">
          <AlgoDropdown
            title="Thuật toán gợi ý"
            available={true}
            autoEnabled={recommendAutoEnabled}
            onAutoChange={handleRecommendAutoChange}
            frequency={recommendFrequency}
            onFrequencyChange={(value) => {
              setRecommendFrequency(value);
              setRecommendScheduleDirty(true);
            }}
            runDay={recommendRunDay}
            onRunDayChange={(value) => {
              setRecommendRunDay(value);
              setRecommendScheduleDirty(true);
            }}
            runTime={recommendRunTime}
            onRunTimeChange={(value) => {
              setRecommendRunTime(value);
              setRecommendScheduleDirty(true);
            }}
            isRunning={recommendRunning}
            autoSaving={recommendAutoSaving}
            scheduleSaving={recommendScheduleSaving}
            scheduleDirty={recommendScheduleDirty}
            lastRun={recommendLastRun}
            statusDetail={`${recommendStep}${recommendRunning ? ` ${recommendProgress}%` : ''}`}
            onSaveSchedule={saveRecommendSchedule}
            onRunNow={handleRunRecommendPipeline}
          />
          <AlgoDropdown
            title="Thuật toán lọc đánh giá"
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
            autoSaving={reviewAutoSaving}
            scheduleSaving={reviewScheduleSaving}
            scheduleDirty={reviewScheduleDirty}
            lastRun={reviewLastRun}
            statusDetail={reviewStatusDetail}
            statusType={
              reviewStatusDetail === 'Hoàn thành'
                ? 'success'
                : reviewStatusDetail === 'Thất bại'
                  ? 'failed'
                  : reviewStatusDetail === 'Đang chạy'
                    ? 'running'
                    : 'unknown'
            }
            onSaveSchedule={saveReviewSchedule}
            onRunNow={handleRunReviewPipeline}
          />
          <AlgoDropdown
            title="Cập nhật mô hình tương tác người dùng"
            available={true}
            autoEnabled={sessionCfAutoEnabled}
            onAutoChange={handleSessionCfAutoChange}
            frequency={sessionCfFrequency}
            onFrequencyChange={handleSessionCfFrequencyChange}
            runDay={sessionCfRunDay}
            onRunDayChange={handleSessionCfRunDayChange}
            runTime={sessionCfRunTime}
            onRunTimeChange={handleSessionCfRunTimeChange}
            isRunning={sessionCfRunning}
            autoSaving={sessionCfAutoSaving}
            scheduleSaving={sessionCfScheduleSaving}
            scheduleDirty={sessionCfScheduleDirty}
            lastRun={sessionCfLastRun}
            onSaveSchedule={saveSessionCfSchedule}
            onRunNow={handleRunSessionCfTraining}
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
          <AlgoDropdown
            title="Thuật toán truy hồi (Two-Tower)"
            available={true}
            autoEnabled={twoTowerAutoEnabled}
            onAutoChange={handleTwoTowerAutoChange}
            frequency={twoTowerFrequency}
            onFrequencyChange={handleTwoTowerFrequencyChange}
            runDay={twoTowerRunDay}
            onRunDayChange={handleTwoTowerRunDayChange}
            runTime={twoTowerRunTime}
            onRunTimeChange={handleTwoTowerRunTimeChange}
            isRunning={twoTowerRunning}
            autoSaving={twoTowerAutoSaving}
            scheduleSaving={twoTowerScheduleSaving}
            scheduleDirty={twoTowerScheduleDirty}
            lastRun={twoTowerLastRun}
            statusDetail={twoTowerRunning ? 'Đang train trên GPU (khoảng 30 phút)...' : undefined}
            onSaveSchedule={saveTwoTowerSchedule}
            onRunNow={handleRunTwoTowerTraining}
            runLabel="Train lại"
          />
        </div>
      </div>
    </div>
  );
};
