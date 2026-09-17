export type LocationApprovalStatus = 'pending' | 'approved' | 'rejected';

const STORAGE_KEY = 'gp_location_approval_overrides';

const STATUS_LABELS: Record<LocationApprovalStatus, string> = {
  pending: 'Chờ duyệt',
  approved: 'Đã duyệt',
  rejected: 'Từ chối',
};

type OverrideRecord = Record<string, { status: LocationApprovalStatus; updatedAt: number }>;

const canUseStorage = (): boolean => typeof window !== 'undefined' && Boolean(window.localStorage);

const readOverrides = (): OverrideRecord => {
  if (!canUseStorage()) {
    return {};
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as OverrideRecord) : {};
  } catch {
    return {};
  }
};

const writeOverrides = (overrides: OverrideRecord): void => {
  if (!canUseStorage()) {
    return;
  }

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(overrides));
};

export const setLocationApprovalOverride = (id: string, status: LocationApprovalStatus): void => {
  if (!id) {
    return;
  }

  writeOverrides({
    ...readOverrides(),
    [id]: { status, updatedAt: Date.now() },
  });
};

export const markLocationPendingApproval = (id: string): void => {
  setLocationApprovalOverride(id, 'pending');
};

export const clearLocationApprovalOverride = (id: string): void => {
  if (!id) {
    return;
  }

  const overrides = readOverrides();
  if (!(id in overrides)) {
    return;
  }

  delete overrides[id];
  writeOverrides(overrides);
};

export const getLocationApprovalOverride = (id: string): LocationApprovalStatus | null => {
  if (!id) {
    return null;
  }

  return readOverrides()[id]?.status ?? null;
};

export const applyLocationApprovalOverride = <T extends { id: string; status?: string }>(location: T): T => {
  const overrideStatus = getLocationApprovalOverride(location.id);
  if (!overrideStatus) {
    return location;
  }

  return {
    ...location,
    status: STATUS_LABELS[overrideStatus],
  };
};
