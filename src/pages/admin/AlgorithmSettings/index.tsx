import React, { useEffect, useMemo, useState } from 'react';
import { Bell, Info } from 'lucide-react';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import { NotificationBell } from '../../../components/NotificationBell';
import { AccordionCard, AlgoGroup, Tip } from './components/AlgorithmSettingsPrimitives';
import { TwoTowerSettingsCard } from './components/TwoTowerSettingsCard';
import { hybridConfigAPI } from '../../../services/hybridConfigAPI';
import {
  algorithmSettingsAPI,
  ReviewFilterSettingsResponse,
  } from '../../../services/algorithmSettingsAPI';
import './AlgorithmSettings.css';

type CardKey = 'weights' | 'classification' | 'conflict' | 'time' | 'twoTower';

const outOfRange = (value: number, min: number, max: number) =>
  Number.isNaN(value) || value < min || value > max;

const hoursToLabel = (hours: number): string => {
  if (hours <= 0) return '-';
  const days = hours / 24;
  if (days < 1) return `${hours}h`;
  if (days === 1) return '1 ngày';
  return `${days} ngày`;
};

const formatRange = (min: number, max: number) => `Khuyến nghị: ${min} - ${max}`;

export const AlgorithmSettings: React.FC = () => {
  const [open, setOpen] = useState<Record<CardKey, boolean>>({
    weights: false,
    classification: false,
    conflict: false,
    time: false,
    twoTower: false,
  });
  const toggle = (key: CardKey) => setOpen((prev) => ({ ...prev, [key]: !prev[key] }));

  const [banner, setBanner] = useState<string | null>(null);
  const [distanceWeight, setDistanceWeight] = useState(0.4);
  const [candidateCount, setCandidateCount] = useState(10);
  const [recommendationActive, setRecommendationActive] = useState<boolean | null>(null);
  const [recommendationLoading, setRecommendationLoading] = useState(false);
  const [recommendationSaving, setRecommendationSaving] = useState(false);

  const [reviewFilterSettings, setReviewFilterSettings] = useState<ReviewFilterSettingsResponse | null>(null);
  const [reviewFilterDraft, setReviewFilterDraft] = useState<Record<string, number>>({});
  const [reviewFilterActive, setReviewFilterActive] = useState<boolean | null>(null);
  const [reviewFilterLoading, setReviewFilterLoading] = useState(false);
  const [reviewFilterSaving, setReviewFilterSaving] = useState(false);
  const [twoTowerActive, setTwoTowerActive] = useState<boolean | null>(null);

  const reviewFilterTopics = useMemo(
    () => reviewFilterSettings?.topics ?? [],
    [reviewFilterSettings],
  );

  const applyReviewFilterSettings = (data: ReviewFilterSettingsResponse) => {
    setReviewFilterSettings(data);
    setReviewFilterActive(Boolean(data.algorithm.isActive));
    setReviewFilterDraft(
      Object.fromEntries(
        Object.entries(data.parameters).map(([name, meta]) => [name, Number(meta.currentValue)]),
      ),
    );
  };

  useEffect(() => {
    let alive = true;

    async function loadAlgorithmStatuses() {
      try {
        const data = await algorithmSettingsAPI.getAlgorithmStatuses();
        if (!alive) return;
        if (typeof data.hybrid_recommender === 'boolean') {
          setRecommendationActive(data.hybrid_recommender);
        }
        if (typeof data.review_filter === 'boolean') {
          setReviewFilterActive(data.review_filter);
        }
        if (typeof data.two_tower_retrieval === 'boolean') {
          setTwoTowerActive(data.two_tower_retrieval);
        }
      } catch {
        // Status badges are refreshed again by the detailed setting requests.
      }
    }

    async function loadRecommendationSettings() {
      setRecommendationLoading(true);
      try {
        const data = await hybridConfigAPI.getWeights();
        if (!alive) return;
        setDistanceWeight(Number(data.distance_weight ?? 0.4));
        setCandidateCount(Number(data.candidate_count ?? 10));
        setRecommendationActive(Boolean(data.is_active));
      } catch {
        if (alive) setBanner('Không thể tải cấu hình thuật toán gợi ý.');
      } finally {
        if (alive) setRecommendationLoading(false);
      }
    }

    async function loadReviewFilterSettings() {
      setReviewFilterLoading(true);
      try {
        const data = await algorithmSettingsAPI.getReviewFilterSettings();
        if (alive) applyReviewFilterSettings(data);
      } catch {
        if (alive) setBanner('Không thể tải cấu hình thuật toán lọc đánh giá.');
      } finally {
        if (alive) setReviewFilterLoading(false);
      }
    }

    loadAlgorithmStatuses();
    loadRecommendationSettings();
    loadReviewFilterSettings();
    return () => {
      alive = false;
    };
  }, []);

  const saveRecommendationSettings = async () => {
    if (outOfRange(distanceWeight, 0, 1)) {
      setBanner('Trọng số khoảng cách phải nằm trong khoảng 0 - 1.');
      return;
    }
    if (outOfRange(candidateCount, 1, 50) || !Number.isInteger(candidateCount)) {
      setBanner('Số địa điểm ứng viên phải là số nguyên trong khoảng 1 - 50.');
      return;
    }

    setRecommendationSaving(true);
    try {
      const data = await hybridConfigAPI.updateWeights({
        distance_weight: distanceWeight,
        candidate_count: candidateCount,
      });
      setDistanceWeight(Number(data.distance_weight ?? distanceWeight));
      setCandidateCount(Number(data.candidate_count ?? candidateCount));
      setRecommendationActive(Boolean(data.is_active));
      setBanner('Đã lưu cấu hình thuật toán gợi ý.');
    } catch {
      setBanner('Không thể lưu cấu hình thuật toán gợi ý. Vui lòng thử lại.');
    } finally {
      setRecommendationSaving(false);
    }
  };

  const param = (name: string) => reviewFilterSettings?.parameters[name];
  const value = (name: string) => Number(reviewFilterDraft[name] ?? param(name)?.currentValue ?? 0);
  const setParam = (name: string, nextValue: number) => {
    setReviewFilterDraft((prev) => ({ ...prev, [name]: nextValue }));
  };
  const inputClass = (name: string, extra = '') => {
    const meta = param(name);
    const nextValue = value(name);
    const unlimitedCandidates = name === 'max_candidates_per_review' && nextValue === 0;
    const invalid = meta && !unlimitedCandidates
      ? outOfRange(nextValue, meta.minValue, meta.maxValue)
      : false;
    return `as-input${extra}${invalid ? ' as-input--err' : ''}`;
  };
  const integerParam = (name: string) =>
    name === 'max_candidates_per_review' ||
    name.startsWith('ttl_hours.') ||
    name.startsWith('lookback_multiplier.') ||
    name.startsWith('window_days.') ||
    name.startsWith('threshold.');

  const validateReviewFilter = (names: string[]) => {
    for (const name of names) {
      const meta = param(name);
      const nextValue = value(name);
      if (!meta) continue;
      const unlimitedCandidates = name === 'max_candidates_per_review' && nextValue === 0;
      if (!unlimitedCandidates && outOfRange(nextValue, meta.minValue, meta.maxValue)) {
        setBanner(`${meta.description || name} phải nằm trong khoảng ${meta.minValue} - ${meta.maxValue}.`);
        return false;
      }
      if (integerParam(name) && !Number.isInteger(nextValue)) {
        setBanner(`${meta.description || name} phải là số nguyên.`);
        return false;
      }
    }
    return true;
  };

  const saveReviewFilter = async (names: string[]) => {
    if (!validateReviewFilter(names)) return;
    setReviewFilterSaving(true);
    try {
      const data = await algorithmSettingsAPI.updateReviewFilterSettings({
        parameters: Object.fromEntries(names.map((name) => [name, value(name)])),
      });
      applyReviewFilterSettings(data);
      setBanner('Đã lưu tham số thuật toán lọc đánh giá.');
    } catch {
      setBanner('Không thể lưu tham số thuật toán lọc đánh giá.');
    } finally {
      setReviewFilterSaving(false);
    }
  };

  const resetReviewFilter = async () => {
    setReviewFilterSaving(true);
    try {
      const data = await algorithmSettingsAPI.resetReviewFilterSettings();
      applyReviewFilterSettings(data);
      setBanner('Đã khôi phục mặc định tham số thuật toán lọc đánh giá.');
    } catch {
      setBanner('Không thể khôi phục mặc định tham số thuật toán lọc đánh giá.');
    } finally {
      setReviewFilterSaving(false);
    }
  };

  const allTopicNames = (prefix: string) => reviewFilterTopics.map((topic) => `${prefix}.${topic.key}`);
  const classificationNames = [
    'topic_other_threshold',
    'classifier_confidence_threshold',
    'classifier_ambiguity_margin',
    ...allTopicNames('ttl_hours'),
  ];
  const conflictNames = [
    'conflict_score_threshold',
    'max_candidates_per_review',
    ...allTopicNames('lookback_multiplier'),
  ];
  const timeNames = [
    'promotion_mode',
    ...allTopicNames('window_days'),
    ...allTopicNames('threshold'),
    ...allTopicNames('sim_threshold'),
  ];

  const renderNumberInput = (name: string, extra = '', step = 1) => {
    const meta = param(name);
    return (
      <input
        type="number"
        step={step}
        min={meta?.minValue}
        max={meta?.maxValue}
        className={inputClass(name, extra)}
        value={value(name)}
        onChange={(event) => setParam(name, Number(event.target.value))}
      />
    );
  };

  const renderHint = (name: string) => {
    const meta = param(name);
    return meta ? <span className="as-hint">{formatRange(meta.minValue, meta.maxValue)}</span> : null;
  };

  const statusBadge = (isActive: boolean | null | undefined) => {
    if (isActive === null || isActive === undefined) return undefined;
    return isActive ? 'Đang hoạt động' : 'Tạm tắt';
  };

  return (
    <div className="page-container as-page">
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Bảng điều khiển thiết lập thuật toán</h1>
          <div className="breadcrumb">
            <span className="text-muted">Thiết lập</span>
            {' / '}
            <span className="active-bread">Thiết lập thuật toán</span>
          </div>
        </div>
        <div className="header-actions">
          <NotificationBell />
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content as-content">
        {banner && (
          <div className="as-banner" role="alert">
            <Info size={14} />
            <span>{banner}</span>
            <button className="as-banner__close" type="button" onClick={() => setBanner(null)} aria-label="Đóng">
              x
            </button>
          </div>
        )}

        <AlgoGroup title="Thuật toán gợi ý" badge={statusBadge(recommendationActive)}>
          <AccordionCard
            title="Cấu hình gợi ý"
            open={open.weights}
            onToggle={() => toggle('weights')}
            onSave={saveRecommendationSettings}
            onReset={() => {
              setDistanceWeight(0.4);
              setCandidateCount(10);
            }}
            saveDisabled={recommendationLoading || recommendationSaving}
            saveLabel={recommendationSaving ? 'Đang lưu...' : 'Lưu thay đổi'}>
            {recommendationLoading && <div className="as-muted as-loading-line">Đang tải cấu hình thuật toán gợi ý...</div>}
            <div className="as-row as-row--2col">
              <div className="as-field">
                <label className="as-label">
                  Trọng số khoảng cách
                  <Tip text="Hệ số khoảng cách trong Hybrid Recommender. model_weight luôn bằng 1 - distance_weight." />
                </label>
                <input
                  type="number"
                  step="0.01"
                  min={0}
                  max={1}
                  className={"as-input" + (outOfRange(distanceWeight, 0, 1) ? " as-input--err" : "")}
                  value={distanceWeight}
                  onChange={(e) => setDistanceWeight(Number(e.target.value))}
                />
                <span className="as-hint">Giá trị hợp lệ: 0 - 1</span>
              </div>

              <div className="as-field">
                <label className="as-label">
                  Số địa điểm ứng viên
                  <Tip text="Số kết quả mặc định truyền vào tham số k của Hybrid Recommender khi request không truyền k." />
                </label>
                <input
                  type="number"
                  min={1}
                  max={50}
                  className={"as-input" + (outOfRange(candidateCount, 1, 50) || !Number.isInteger(candidateCount) ? " as-input--err" : "")}
                  value={candidateCount}
                  onChange={(e) => setCandidateCount(Number(e.target.value))}
                />
                <span className="as-hint">Mặc định hiện tại của model: 10</span>
              </div>
            </div>
          </AccordionCard>
        </AlgoGroup>

        <AlgoGroup title="Thuật toán lọc đánh giá" badge={statusBadge(reviewFilterActive ?? reviewFilterSettings?.algorithm.isActive)}>
          {reviewFilterLoading && <div className="as-muted as-loading-line">Đang tải tham số thuật toán lọc - phân loại đánh giá...</div>}

          <AccordionCard
            title="Phân loại đánh giá"
            open={open.classification}
            onToggle={() => toggle('classification')}
            onSave={() => saveReviewFilter(classificationNames)}
            onReset={resetReviewFilter}
            saveDisabled={reviewFilterLoading || reviewFilterSaving || !reviewFilterSettings}
            resetDisabled={reviewFilterLoading || reviewFilterSaving || !reviewFilterSettings}
            saveLabel={reviewFilterSaving ? 'Đang lưu...' : 'Lưu thay đổi'}>
            <div className="as-row as-row--3col">
              <div className="as-field">
                <label className="as-label">Ngưỡng nhận dạng chủ đề <Tip text="Điểm tối thiểu để xác định chủ đề; thấp hơn ngưỡng sẽ xếp vào Khác." /></label>
                {renderNumberInput('topic_other_threshold', '', 0.01)}
                {renderHint('topic_other_threshold')}
              </div>
              <div className="as-field">
                <label className="as-label">Độ tin cậy tối thiểu của mô hình <Tip text="PhoBERT phải đạt mức này mới phán quyết ngắn hạn/dài hạn." /></label>
                {renderNumberInput('classifier_confidence_threshold', '', 0.01)}
                {renderHint('classifier_confidence_threshold')}
              </div>
              <div className="as-field">
                <label className="as-label">Biên độ phân biệt nhãn <Tip text="Khoảng cách tối thiểu giữa hai nhãn để tránh mô hình do dự." /></label>
                {renderNumberInput('classifier_ambiguity_margin', '', 0.01)}
                {renderHint('classifier_ambiguity_margin')}
              </div>
            </div>

            <div className="as-table-wrap">
              <table className="as-table">
                <thead>
                  <tr>
                    <th>Chủ đề</th>
                    <th>Thời hạn (giờ) <Tip text="Số giờ đánh giá ngắn hạn còn hiệu lực theo từng chủ đề trước khi bị ẩn." /></th>
                    <th>Khuyến nghị <Tip text="Khoảng giá trị tối thiểu - tối đa của thời hạn." /></th>
                    <th>Tương đương <Tip text="Quy đổi thời hạn giờ sang ngày để dễ đối chiếu." /></th>
                  </tr>
                </thead>
                <tbody>
                  {reviewFilterTopics.map((topic) => {
                    const name = `ttl_hours.${topic.key}`;
                    const meta = param(name);
                    return (
                      <tr key={topic.key}>
                        <td>{topic.label}</td>
                        <td>{renderNumberInput(name, ' as-input--inline')}</td>
                        <td className="as-muted">{meta ? `${meta.minValue} - ${meta.maxValue}` : '-'}</td>
                        <td className="as-muted">{hoursToLabel(value(name))}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </AccordionCard>

          <AccordionCard
            title="Phát hiện xung đột"
            open={open.conflict}
            onToggle={() => toggle('conflict')}
            onSave={() => saveReviewFilter(conflictNames)}
            onReset={resetReviewFilter}
            saveDisabled={reviewFilterLoading || reviewFilterSaving || !reviewFilterSettings}
            resetDisabled={reviewFilterLoading || reviewFilterSaving || !reviewFilterSettings}
            saveLabel={reviewFilterSaving ? 'Đang lưu...' : 'Lưu thay đổi'}>
            <div className="as-stack">
              <div className="as-field">
                <label className="as-label">
                  Giới hạn đánh giá so sánh
                  <Tip text="Số đánh giá dài hạn tối đa so sánh với mỗi đánh giá ngắn hạn. Nhập 0 để không giới hạn hoặc từ 1 đến 1000 để bật giới hạn." />
                </label>
                {renderNumberInput('max_candidates_per_review', ' as-input--sm')}
                {renderHint('max_candidates_per_review')}
              </div>

              <div className="as-field">
                <label className="as-label">Ngưỡng điểm xung đột <Tip text="Điểm tối thiểu để xác nhận hai đánh giá mâu thuẫn nhau." /></label>
                {renderNumberInput('conflict_score_threshold', ' as-input--sm', 0.01)}
                {renderHint('conflict_score_threshold')}
              </div>              

              <div className="as-table-wrap">
                <table className="as-table">
                  <thead>
                    <tr>
                      <th>Chủ đề</th>
                      <th>Hệ số cửa sổ tra cứu <Tip text="Cửa sổ tìm đánh giá = thời hạn hiệu lực của chủ đề nhân với hệ số này." /></th>
                      <th>Khuyến nghị <Tip text="Khoảng giá trị tối thiểu - tối đa của hệ số cửa sổ tra cứu." /></th>
                    </tr>
                  </thead>
                  <tbody>
                    {reviewFilterTopics.map((topic) => {
                      const name = `lookback_multiplier.${topic.key}`;
                      const meta = param(name);
                      return (
                        <tr key={topic.key}>
                          <td>{topic.label}</td>
                          <td>{renderNumberInput(name, ' as-input--inline')}</td>
                          <td className="as-muted">{meta ? `${meta.minValue} - ${meta.maxValue}` : '-'}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </AccordionCard>

          <AccordionCard
            title="Quản lý thời gian và tổng hợp đánh giá dài hạn"
            open={open.time}
            onToggle={() => toggle('time')}
            onSave={() => saveReviewFilter(timeNames)}
            onReset={resetReviewFilter}
            saveDisabled={reviewFilterLoading || reviewFilterSaving || !reviewFilterSettings}
            resetDisabled={reviewFilterLoading || reviewFilterSaving || !reviewFilterSettings}
            saveLabel={reviewFilterSaving ? 'Đang lưu...' : 'Lưu thay đổi'}>
            <div className="as-field as-field--mb">
              <label className="as-label">Chế độ nâng cấp đánh giá <Tip text="Chọn cách chuyển đánh giá ngắn hạn trong cụm đủ điều kiện thành dài hạn." /></label>
              <div className="as-radio-group">
                <label className="as-radio">
                  <input type="radio" name="promotionMode" checked={value('promotion_mode') === 0} onChange={() => setParam('promotion_mode', 0)} />
                  Chỉ nâng cấp đánh giá đại diện
                  <Tip text="Chỉ đánh giá đại diện của cụm được nâng cấp lên dài hạn." />
                </label>
                <label className="as-radio">
                  <input type="radio" name="promotionMode" checked={value('promotion_mode') === 1} onChange={() => setParam('promotion_mode', 1)} />
                  Nâng cấp toàn bộ cụm
                  <Tip text="Tất cả đánh giá trong cụm đủ điều kiện được nâng cấp lên dài hạn." />
                </label>
              </div>
            </div>

            <div className="as-table-wrap">
              <table className="as-table">
                <thead>
                  <tr>
                    <th>Chủ đề</th>
                    <th>Cửa sổ (ngày) <Tip text="Số ngày gần nhất dùng để gom các đánh giá cùng chủ đề thành cụm." /></th>
                    <th>Số tối thiểu <Tip text="Số đánh giá tối thiểu trong cụm để đủ điều kiện tạo nhận xét dài hạn." /></th>
                    <th>Ngưỡng tương đồng <Tip text="Điểm giống nhau tối thiểu để hai đánh giá được gom vào cùng một cụm." /></th>
                  </tr>
                </thead>
                <tbody>
                  {reviewFilterTopics.map((topic) => (
                    <tr key={topic.key}>
                      <td>{topic.label}</td>
                      <td>{renderNumberInput(`window_days.${topic.key}`, ' as-input--inline')}</td>
                      <td>{renderNumberInput(`threshold.${topic.key}`, ' as-input--inline')}</td>
                      <td>{renderNumberInput(`sim_threshold.${topic.key}`, ' as-input--inline', 0.01)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </AccordionCard>
        </AlgoGroup>

        <AlgoGroup title="Thuật toán lập lịch">
          <TwoTowerSettingsCard open={open.twoTower} onToggle={() => toggle('twoTower')} setBanner={setBanner} />
        </AlgoGroup>
      </div>
    </div>
  );
};
