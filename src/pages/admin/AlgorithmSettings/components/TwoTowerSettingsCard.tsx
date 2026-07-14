import React, { useEffect, useMemo, useState } from 'react';
import {
  algorithmSettingsAPI,
  type IntentKey,
  type SlotKey,
  type TwoTowerSettingsResponse,
  type UpdateTwoTowerSettingsRequest,
} from '../../../../services/algorithmSettingsAPI';
import { AccordionCard, Tip } from './AlgorithmSettingsPrimitives';

const INTENT_ROWS: Array<{ key: IntentKey; label: string }> = [
  { key: 'general', label: 'Khám phá tổng hợp' },
  { key: 'food', label: 'Ẩm thực & Bản địa' },
  { key: 'urban', label: 'Đô thị & Vui chơi' },
  { key: 'nature', label: 'Khám phá & Sinh thái' },
  { key: 'beach', label: 'Nghỉ dưỡng & Biển' },
  { key: 'culture', label: 'Văn hóa & Lịch sử' },
];

const SLOT_COLUMNS: Array<{ key: SlotKey; label: string }> = [
  { key: 'attraction', label: 'Tham quan' },
  { key: 'restaurant', label: 'Ăn uống' },
  { key: 'cafe', label: 'Cafe' },
  { key: 'entertainment', label: 'Giải trí' },
  { key: 'accommodation', label: 'Lưu trú' },
];

type TwoTowerFormState = {
  isActive: boolean;
  defaultTopK: number;
  maxTopK: number;
  maxIntents: number;
  fetchBufferMultiplier: number;
  enableAttractionTravelTypeFilter: boolean;
  enableDiversityBudget: boolean;
  quotas: Record<IntentKey, Record<SlotKey, number>>;
};

const DEFAULT_TWO_TOWER_FORM: TwoTowerFormState = {
  isActive: true,
  defaultTopK: 100,
  maxTopK: 200,
  maxIntents: 3,
  fetchBufferMultiplier: 2,
  enableAttractionTravelTypeFilter: true,
  enableDiversityBudget: true,
  quotas: {
    general: { attraction: 4, restaurant: 2, cafe: 1, entertainment: 1, accommodation: 1 },
    food: { attraction: 1, restaurant: 4, cafe: 2, entertainment: 0, accommodation: 1 },
    urban: { attraction: 2, restaurant: 2, cafe: 1, entertainment: 3, accommodation: 1 },
    nature: { attraction: 5, restaurant: 2, cafe: 0, entertainment: 0, accommodation: 1 },
    beach: { attraction: 3, restaurant: 2, cafe: 1, entertainment: 1, accommodation: 1 },
    culture: { attraction: 5, restaurant: 2, cafe: 1, entertainment: 2, accommodation: 1 },
  },
};

const cloneTwoTowerForm = (form: TwoTowerFormState): TwoTowerFormState => ({
  ...form,
  quotas: Object.fromEntries(INTENT_ROWS.map(({ key }) => [key, { ...form.quotas[key] }])) as Record<IntentKey, Record<SlotKey, number>>,
});

const outOfRange = (v: number, min: number, max: number) => v < min || v > max || Number.isNaN(v);

const paramValue = (data: TwoTowerSettingsResponse, key: keyof TwoTowerSettingsResponse['core'], fallback: number) => {
  const raw = data.core[key]?.currentValue;
  return typeof raw === 'number' ? raw : fallback;
};

// Backend trả currentValue của param boolean dưới dạng true/false thật (không phải 1/0),
// nên phải so cả 2 dạng — so sánh "=== 1" sẽ luôn false với boolean và làm toggle hiển thị sai.
const paramBool = (data: TwoTowerSettingsResponse, key: keyof TwoTowerSettingsResponse['core'], fallback: boolean) => {
  const raw = data.core[key]?.currentValue;
  if (raw === undefined || raw === null) return fallback;
  return raw === true || raw === 1;
};

const mapResponseToForm = (data: TwoTowerSettingsResponse): TwoTowerFormState => {
  const fallback = DEFAULT_TWO_TOWER_FORM;
  const quotas = cloneTwoTowerForm(fallback).quotas;

  INTENT_ROWS.forEach(({ key: intent }) => {
    SLOT_COLUMNS.forEach(({ key: slot }) => {
      const raw = data.quotas?.[intent]?.[slot]?.currentValue;
      quotas[intent][slot] = typeof raw === 'number' ? raw : fallback.quotas[intent][slot];
    });
  });

  return {
    isActive: Boolean(data.algorithm?.isActive),
    defaultTopK: paramValue(data, 'defaultTopK', fallback.defaultTopK),
    maxTopK: paramValue(data, 'maxTopK', fallback.maxTopK),
    maxIntents: paramValue(data, 'maxIntents', fallback.maxIntents),
    fetchBufferMultiplier: paramValue(data, 'fetchBufferMultiplier', fallback.fetchBufferMultiplier),
    enableAttractionTravelTypeFilter: paramBool(
      data,
      'enableAttractionTravelTypeFilter',
      fallback.enableAttractionTravelTypeFilter,
    ),
    enableDiversityBudget: paramBool(data, 'enableDiversityBudget', fallback.enableDiversityBudget),
    quotas,
  };
};

const mapFormToPayload = (form: TwoTowerFormState): UpdateTwoTowerSettingsRequest => ({
  isActive: form.isActive,
  defaultTopK: form.defaultTopK,
  maxTopK: form.maxTopK,
  maxIntents: form.maxIntents,
  fetchBufferMultiplier: form.fetchBufferMultiplier,
  enableAttractionTravelTypeFilter: form.enableAttractionTravelTypeFilter,
  enableDiversityBudget: form.enableDiversityBudget,
  quotas: form.quotas,
});

const validateTwoTower = (form: TwoTowerFormState): string[] => {
  const errors: string[] = [];

  if (outOfRange(form.defaultTopK, 10, 200)) errors.push('Số địa điểm ứng viên mặc định phải nằm trong khoảng 10 - 200.');
  if (outOfRange(form.maxTopK, 50, 300)) errors.push('Giới hạn địa điểm ứng viên tối đa phải nằm trong khoảng 50 - 300.');
  if (form.defaultTopK > form.maxTopK) errors.push('Số địa điểm ứng viên mặc định không được lớn hơn giới hạn tối đa.');
  if (outOfRange(form.maxIntents, 1, 6)) errors.push('Số loại hình du lịch tối đa phải nằm trong khoảng 1 - 6.');
  if (outOfRange(form.fetchBufferMultiplier, 1, 5)) errors.push('Hệ số mở rộng tập lấy trước phải nằm trong khoảng 1 - 5.');

  INTENT_ROWS.forEach(({ key: intent, label }) => {
    SLOT_COLUMNS.forEach(({ key: slot }) => {
      const value = form.quotas[intent][slot];
      if (outOfRange(value, 0, 10)) {
        errors.push(`Hạn mức "${label}" phải nằm trong khoảng 0 - 10.`);
      }
    });
  });

  return errors;
};

interface TwoTowerSettingsCardProps {
  open: boolean;
  onToggle: () => void;
  setBanner: (message: string) => void;
}

export const TwoTowerSettingsCard: React.FC<TwoTowerSettingsCardProps> = ({ open, onToggle, setBanner }) => {
  const [twoTower, setTwoTower] = useState<TwoTowerFormState>(() => cloneTwoTowerForm(DEFAULT_TWO_TOWER_FORM));
  const [twoTowerOriginal, setTwoTowerOriginal] = useState<TwoTowerFormState | null>(null);
  const [twoTowerLoading, setTwoTowerLoading] = useState(false);
  const [twoTowerSaving, setTwoTowerSaving] = useState(false);
  const [twoTowerError, setTwoTowerError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;

    async function loadTwoTowerSettings() {
      setTwoTowerLoading(true);
      setTwoTowerError(null);
      try {
        const data = await algorithmSettingsAPI.getTwoTowerSettings();
        const form = mapResponseToForm(data);
        if (!alive) return;
        setTwoTower(form);
        setTwoTowerOriginal(cloneTwoTowerForm(form));
      } catch {
        if (!alive) return;
        setTwoTowerError('Không thể tải cấu hình mô hình truy xuất địa điểm. Đang hiển thị giá trị mặc định.');
      } finally {
        if (alive) setTwoTowerLoading(false);
      }
    }

    loadTwoTowerSettings();
    return () => {
      alive = false;
    };
  }, []);

  const twoTowerErrors = useMemo(() => validateTwoTower(twoTower), [twoTower]);
  const canSaveTwoTower = twoTowerErrors.length === 0 && !twoTowerSaving && !twoTowerLoading;

  const updateTwoTowerField = <K extends keyof TwoTowerFormState>(key: K, value: TwoTowerFormState[K]) => {
    setTwoTower((prev) => ({ ...prev, [key]: value }));
  };

  const updateQuota = (intent: IntentKey, slot: SlotKey, value: number) => {
    setTwoTower((prev) => ({
      ...prev,
      quotas: {
        ...prev.quotas,
        [intent]: {
          ...prev.quotas[intent],
          [slot]: value,
        },
      },
    }));
  };

  const handleSaveTwoTower = async () => {
    const errors = validateTwoTower(twoTower);
    if (errors.length) {
      setBanner(errors[0]);
      return;
    }

    setTwoTowerSaving(true);
    try {
      const updated = await algorithmSettingsAPI.updateTwoTowerSettings(mapFormToPayload(twoTower));
      const next = mapResponseToForm(updated);
      setTwoTower(next);
      setTwoTowerOriginal(cloneTwoTowerForm(next));
      setBanner('Đã lưu cấu hình mô hình truy xuất địa điểm.');
    } catch {
      setBanner('Không thể lưu cấu hình mô hình truy xuất địa điểm. Vui lòng thử lại.');
    } finally {
      setTwoTowerSaving(false);
    }
  };

  const handleResetTwoTower = async () => {
    setTwoTowerSaving(true);
    try {
      const reset = await algorithmSettingsAPI.resetTwoTowerSettings();
      const next = mapResponseToForm(reset);
      setTwoTower(next);
      setTwoTowerOriginal(cloneTwoTowerForm(next));
      setBanner('Đã khôi phục cấu hình mô hình truy xuất địa điểm mặc định.');
    } catch {
      setBanner('Không thể khôi phục cấu hình mô hình truy xuất địa điểm.');
      if (twoTowerOriginal) setTwoTower(cloneTwoTowerForm(twoTowerOriginal));
    } finally {
      setTwoTowerSaving(false);
    }
  };

  return (
    <AccordionCard
      title="Mô hình truy xuất địa điểm"
      badge={twoTower.isActive ? 'Đang hoạt động' : 'Tạm tắt'}
      open={open}
      onToggle={onToggle}
      onSave={handleSaveTwoTower}
      onReset={handleResetTwoTower}
      saveDisabled={!canSaveTwoTower}
      resetDisabled={twoTowerSaving || twoTowerLoading}
      saveLabel={twoTowerSaving ? 'Đang lưu...' : 'Lưu thay đổi'}>
      <p className="as-hint as-hint--block">Áp dụng cho bước lấy địa điểm ứng viên.</p>

      {twoTowerLoading && <div className="as-muted as-loading-line">Đang tải cấu hình mô hình truy xuất địa điểm...</div>}
      {twoTowerError && <div className="as-banner as-banner--error as-inline-banner">{twoTowerError}</div>}
      {twoTowerErrors.length > 0 && <div className="as-err-text as-validation-line">{twoTowerErrors[0]}</div>}

      <div className="as-section-title">Trạng thái</div>
      <div className="as-inline-status">
        <div>
          <div className="as-status-title">Đang sử dụng mô hình truy xuất địa điểm</div>
          <span className="as-hint">Khi tắt, backend có thể vẫn dùng phương án dự phòng an toàn tùy cấu hình runtime.</span>
        </div>
        <button
          type="button"
          className={`as-toggle${twoTower.isActive ? ' as-toggle--on' : ''}`}
          onClick={() => updateTwoTowerField('isActive', !twoTower.isActive)}
          aria-label="Bật hoặc tắt mô hình truy xuất địa điểm">
          <span className="as-toggle__thumb" />
        </button>
      </div>

      <div className="as-section-title">Tham số lấy địa điểm ứng viên</div>
      <div className="as-row as-row--2col">
        <div className="as-field">
          <label className="as-label">
            Số địa điểm ứng viên mặc định
            <Tip text="Số địa điểm tối đa trả về khi request không truyền top_k." />
          </label>
          <input
            type="number"
            min={10}
            max={200}
            className={`as-input${outOfRange(twoTower.defaultTopK, 10, 200) ? ' as-input--err' : ''}`}
            value={twoTower.defaultTopK}
            onChange={(e) => updateTwoTowerField('defaultTopK', Number(e.target.value))}
          />
        </div>
        <div className="as-field">
          <label className="as-label">
            Giới hạn địa điểm ứng viên tối đa
            <Tip text="Giới hạn số địa điểm ứng viên tối đa mà mỗi request được phép lấy." />
          </label>
          <input
            type="number"
            min={50}
            max={300}
            className={`as-input${outOfRange(twoTower.maxTopK, 50, 300) || twoTower.defaultTopK > twoTower.maxTopK ? ' as-input--err' : ''}`}
            value={twoTower.maxTopK}
            onChange={(e) => updateTwoTowerField('maxTopK', Number(e.target.value))}
          />
        </div>
        <div className="as-field">
          <label className="as-label">
            Số loại hình du lịch tối đa
            <Tip text="Số loại hình du lịch tối đa dùng khi người dùng chọn nhiều loại hình." />
          </label>
          <input
            type="number"
            min={1}
            max={6}
            className={`as-input${outOfRange(twoTower.maxIntents, 1, 6) ? ' as-input--err' : ''}`}
            value={twoTower.maxIntents}
            onChange={(e) => updateTwoTowerField('maxIntents', Number(e.target.value))}
          />
        </div>
        <div className="as-field">
          <label className="as-label">
            Hệ số mở rộng tập lấy trước
            <Tip text="Mỗi nhóm địa điểm sẽ lấy hạn mức x số ngày x hệ số này trước khi lọc đa dạng." />
          </label>
          <input
            type="number"
            min={1}
            max={5}
            className={`as-input${outOfRange(twoTower.fetchBufferMultiplier, 1, 5) ? ' as-input--err' : ''}`}
            value={twoTower.fetchBufferMultiplier}
            onChange={(e) => updateTwoTowerField('fetchBufferMultiplier', Number(e.target.value))}
          />
        </div>
      </div>

      <div className="as-toggle-list">
        <div className="as-inline-status as-inline-status--compact">
          <span className="as-status-title">Lọc điểm tham quan theo loại hình du lịch</span>
          <button
            type="button"
            className={`as-toggle${twoTower.enableAttractionTravelTypeFilter ? ' as-toggle--on' : ''}`}
            onClick={() => updateTwoTowerField('enableAttractionTravelTypeFilter', !twoTower.enableAttractionTravelTypeFilter)}
            aria-label="Lọc điểm tham quan theo loại hình du lịch">
            <span className="as-toggle__thumb" />
          </button>
        </div>
        <div className="as-inline-status as-inline-status--compact">
          <span className="as-status-title">Bật phân bổ đa dạng theo hạn mức</span>
          <button
            type="button"
            className={`as-toggle${twoTower.enableDiversityBudget ? ' as-toggle--on' : ''}`}
            onClick={() => updateTwoTowerField('enableDiversityBudget', !twoTower.enableDiversityBudget)}
            aria-label="Bật phân bổ đa dạng theo hạn mức">
            <span className="as-toggle__thumb" />
          </button>
        </div>
      </div>

      <div className="as-section-title">Hạn mức theo loại hình du lịch</div>
      <div className="as-table-wrap">
        <table className="as-table as-quota-table">
          <thead>
            <tr>
              <th>Loại hình du lịch</th>
              {SLOT_COLUMNS.map((slot) => (
                <th key={slot.key}>{slot.label}</th>
              ))}
              <th>Tổng/ngày</th>
            </tr>
          </thead>
          <tbody>
            {INTENT_ROWS.map((intent) => {
              const rowTotal = SLOT_COLUMNS.reduce((sum, slot) => sum + twoTower.quotas[intent.key][slot.key], 0);
              return (
                <tr key={intent.key}>
                  <td className="as-fw500">{intent.label}</td>
                  {SLOT_COLUMNS.map((slot) => {
                    const value = twoTower.quotas[intent.key][slot.key];
                    return (
                      <td key={slot.key}>
                        <input
                          type="number"
                          min={0}
                          max={10}
                          className={`as-input as-input--inline${outOfRange(value, 0, 10) ? ' as-input--err' : ''}`}
                          value={value}
                          onChange={(e) => updateQuota(intent.key, slot.key, Number(e.target.value))}
                        />
                      </td>
                    );
                  })}
                  <td className={rowTotal > 15 ? 'as-quota-total--warn' : 'as-muted'}>{rowTotal}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      {INTENT_ROWS.some((intent) => SLOT_COLUMNS.reduce((sum, slot) => sum + twoTower.quotas[intent.key][slot.key], 0) > 15) && (
        <span className="as-hint as-hint--block as-quota-warning">Tổng hạn mức/ngày cao có thể làm bước truy xuất nặng hơn.</span>
      )}
    </AccordionCard>
  );
};
