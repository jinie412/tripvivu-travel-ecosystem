import React, { useState } from 'react';
import { Bell, Info } from 'lucide-react';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import { AccordionCard, AlgoGroup, Tip } from './components/AlgorithmSettingsPrimitives';
import { TwoTowerSettingsCard } from './components/TwoTowerSettingsCard';
import './AlgorithmSettings.css';

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
  { name: 'Không khí', window: 30, minCount: 10, similarity: 0.6 },
];

const hoursToLabel = (hours: number): string => {
  if (hours <= 0) return '-';
  const days = hours / 24;
  if (days < 1) return `${hours}h`;
  if (days === 1) return '1 ngày';
  return `${days} ngày`;
};

const outOfRange = (v: number, min: number, max: number) => v < min || v > max || Number.isNaN(v);

type CardKey = 'general' | 'weights' | 'classification' | 'conflict' | 'time' | 'twoTower';
type ConflictMode = 'all' | 'limit_k';
type UpgradeMode = 'representative' | 'all_clusters';

export const AlgorithmSettings: React.FC = () => {
  const [open, setOpen] = useState<Record<CardKey, boolean>>({
    general: true,
    weights: false,
    classification: false,
    conflict: false,
    time: false,
    twoTower: false,
  });
  const toggle = (k: CardKey) => setOpen((p) => ({ ...p, [k]: !p[k] }));

  const [banner, setBanner] = useState<string | null>(null);
  const showBanner = (ctx: string) => setBanner(`Thay đổi này sẽ ảnh hưởng đến ${ctx} đang được xử lý.`);

  const [maxDistance, setMaxDistance] = useState(50);
  const [locationPriority, setLocationPriority] = useState('Cao');
  const [distanceWeight, setDistanceWeight] = useState(0.4);
  const [topicThreshold, setTopicThreshold] = useState(0.18);
  const [minConfidence, setMinConfidence] = useState(0.55);
  const [labelMargin, setLabelMargin] = useState(0.1);
  const [topicsC3, setTopicsC3] = useState(() => DEFAULT_TOPICS_C3.map((t) => ({ ...t })));
  const [conflictThreshold, setConflictThreshold] = useState(0.65);
  const [windowFactor, setWindowFactor] = useState(6);
  const [conflictMode, setConflictMode] = useState<ConflictMode>('all');
  const [maxK, setMaxK] = useState(5);
  const [upgradeMode, setUpgradeMode] = useState<UpgradeMode>('representative');
  const [topicsC5, setTopicsC5] = useState(() => DEFAULT_TOPICS_C5.map((t) => ({ ...t })));

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
          <button className="icon-btn" type="button">
            <Bell size={20} />
          </button>
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

        <AccordionCard
          title="Tham số thuật toán chung"
          open={open.general}
          onToggle={() => toggle('general')}
          onSave={() => {}}
          onReset={() => {
            setMaxDistance(50);
            setLocationPriority('Cao');
          }}>
          <div className="as-row as-row--2col">
            <div className="as-field">
              <label className="as-label">Khoảng cách tối đa tìm địa điểm (km)</label>
              <input
                type="number"
                className={`as-input${outOfRange(maxDistance, 1, 500) ? ' as-input--err' : ''}`}
                value={maxDistance}
                min={1}
                max={500}
                onChange={(e) => setMaxDistance(Number(e.target.value))}
              />
            </div>
            <div className="as-field">
              <label className="as-label">Ưu tiên địa điểm mới</label>
              <select className="as-select" value={locationPriority} onChange={(e) => setLocationPriority(e.target.value)}>
                <option>Thấp</option>
                <option>Trung bình</option>
                <option>Cao</option>
              </select>
            </div>
          </div>
        </AccordionCard>

        <AlgoGroup title="Thuật toán gợi ý">
          <AccordionCard
            title="Trọng số mô hình"
            open={open.weights}
            onToggle={() => toggle('weights')}
            onSave={() => {}}
            onReset={() => setDistanceWeight(0.4)}>
            <div className="as-field">
              <label className="as-label">
                Trọng số khoảng cách
                <Tip text="Mức độ ảnh hưởng của khoảng cách địa lý lên điểm gợi ý (0.0 - 1.0)" />
              </label>
              <input
                type="number"
                step="0.01"
                min={0}
                max={1}
                className={`as-input${outOfRange(distanceWeight, 0, 1) ? ' as-input--err' : ''}`}
                value={distanceWeight}
                onChange={(e) => setDistanceWeight(Number(e.target.value))}
              />
              <span className="as-hint">Khuyến nghị: 0.20 - 0.60</span>
            </div>
          </AccordionCard>
        </AlgoGroup>

        <AlgoGroup title="Thuật toán lọc - phân loại đánh giá">
          <AccordionCard
            title="Phân loại đánh giá"
            open={open.classification}
            onToggle={() => toggle('classification')}
            onSave={() => {}}
            onReset={() => {
              setTopicThreshold(0.18);
              setMinConfidence(0.55);
              setLabelMargin(0.1);
              setTopicsC3(DEFAULT_TOPICS_C3.map((t) => ({ ...t })));
            }}>
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
                  onChange={(e) => {
                    setTopicThreshold(Number(e.target.value));
                    showBanner('các đánh giá đang chờ phân loại');
                  }}
                />
                <span className="as-hint">Khuyến nghị: 0.10 - 0.30</span>
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
                  onChange={(e) => {
                    setMinConfidence(Number(e.target.value));
                    showBanner('các đánh giá đang chờ phân loại');
                  }}
                />
                <span className="as-hint">Khuyến nghị: 0.40 - 0.70</span>
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
                  onChange={(e) => setLabelMargin(Number(e.target.value))}
                />
                <span className="as-hint">Khuyến nghị: 0.05 - 0.20</span>
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
                          onChange={(e) => setTopicsC3((p) => p.map((t, i) => (i === idx ? { ...t, hours: Number(e.target.value) } : t)))}
                        />
                      </td>
                      <td className="as-muted">{hoursToLabel(row.hours)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </AccordionCard>

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
            }}>
            <div className="as-stack">
              <div className="as-field">
                <label className="as-label">
                  Ngưỡng điểm xung đột
                  <Tip text="Điểm cosine similarity tối thiểu để phát hiện xung đột giữa hai đánh giá (0.50 - 0.90)" />
                </label>
                <input
                  type="number"
                  step="0.01"
                  min={0.5}
                  max={0.9}
                  className={`as-input as-input--sm${outOfRange(conflictThreshold, 0.5, 0.9) ? ' as-input--err' : ''}`}
                  value={conflictThreshold}
                  onChange={(e) => {
                    setConflictThreshold(Number(e.target.value));
                    showBanner('các cặp đánh giá');
                  }}
                />
              </div>

              <div className="as-field">
                <label className="as-label">
                  Hệ số cửa sổ tra cứu
                  <Tip text="Nhân với khoảng thời gian phân loại để tính cửa sổ nhìn lại (1 - 20)" />
                </label>
                <input
                  type="number"
                  min={1}
                  max={20}
                  className={`as-input as-input--sm${outOfRange(windowFactor, 1, 20) ? ' as-input--err' : ''}`}
                  value={windowFactor}
                  onChange={(e) => setWindowFactor(Number(e.target.value))}
                />
                <span className="as-hint">
                  Ví dụ: Đồ ăn (7 ngày x {windowFactor} = {7 * windowFactor} ngày nhìn lại)
                </span>
              </div>

              <div className="as-field">
                <label className="as-label">Chế độ lựa chọn đánh giá so sánh</label>
                <div className="as-radio-group">
                  <label className="as-radio">
                    <input type="radio" name="conflictMode" checked={conflictMode === 'all'} onChange={() => setConflictMode('all')} />
                    So sánh tất cả
                  </label>
                  <label className="as-radio">
                    <input
                      type="radio"
                      name="conflictMode"
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
                      onChange={(e) => setMaxK(Number(e.target.value))}
                    />
                  </div>
                )}
              </div>
            </div>
          </AccordionCard>

          <AccordionCard
            title="Quản lý thời gian"
            open={open.time}
            onToggle={() => toggle('time')}
            onSave={() => {}}
            onReset={() => {
              setUpgradeMode('representative');
              setTopicsC5(DEFAULT_TOPICS_C5.map((t) => ({ ...t })));
            }}>
            <div className="as-field as-field--mb">
              <label className="as-label">Chế độ nâng cấp đánh giá</label>
              <div className="as-radio-group">
                <label className="as-radio">
                  <input
                    type="radio"
                    name="upgradeMode"
                    checked={upgradeMode === 'representative'}
                    onChange={() => setUpgradeMode('representative')}
                  />
                  Chỉ nâng cấp đánh giá đại diện
                </label>
                <label className="as-radio">
                  <input
                    type="radio"
                    name="upgradeMode"
                    checked={upgradeMode === 'all_clusters'}
                    onChange={() => setUpgradeMode('all_clusters')}
                  />
                  Nâng cấp toàn bộ cụm
                </label>
              </div>
              <span className="as-hint">
                {upgradeMode === 'representative'
                  ? 'Chỉ cập nhật đánh giá đại diện nhất trong mỗi cụm.'
                  : 'Cập nhật toàn bộ đánh giá trong tất cả các cụm, tiêu tốn nhiều tài nguyên hơn.'}
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
                          onChange={(e) => setTopicsC5((p) => p.map((t, i) => (i === idx ? { ...t, window: Number(e.target.value) } : t)))}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          className="as-input as-input--inline"
                          value={row.minCount}
                          min={1}
                          onChange={(e) =>
                            setTopicsC5((p) => p.map((t, i) => (i === idx ? { ...t, minCount: Number(e.target.value) } : t)))
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
                          onChange={(e) =>
                            setTopicsC5((p) => p.map((t, i) => (i === idx ? { ...t, similarity: Number(e.target.value) } : t)))
                          }
                        />
                      </td>
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
