import React from 'react';
import { Check, MapPin, X, ZoomIn, ZoomOut } from 'lucide-react';
import { LocationDetailInfo } from '../../../../types/location';

interface LocationMapProps {
  location: LocationDetailInfo;
  onCoordinatesSave: (latitude: number, longitude: number) => Promise<void>;
}

interface MapPreviewProps {
  lat: number;
  lng: number;
  locationName: string;
  zoom: number;
  width: number;
  height: number;
  className?: string;
}

const MAP_TILE_SIZE = 256;
const DEFAULT_MAP_ZOOM = 15;
const MIN_MAP_ZOOM = 12;
const MAX_MAP_ZOOM = 19;
const OSM_MAX_TILE_ZOOM = 19;

const clamp = (value: number, min: number, max: number) => Math.min(Math.max(value, min), max);

const latLngToWorldPixel = (lat: number, lng: number, zoom: number) => {
  const scale = MAP_TILE_SIZE * 2 ** zoom;
  const sinLat = Math.sin((clamp(lat, -85.05112878, 85.05112878) * Math.PI) / 180);

  return {
    x: ((lng + 180) / 360) * scale,
    y: (0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI)) * scale,
  };
};

const getMapTiles = (centerLat: number, centerLng: number, zoom: number, width: number, height: number) => {
  const tileZoom = Math.min(zoom, OSM_MAX_TILE_ZOOM);
  const overzoomScale = 2 ** (zoom - tileZoom);
  const center = latLngToWorldPixel(centerLat, centerLng, tileZoom);
  const startX = center.x - width / (2 * overzoomScale);
  const startY = center.y - height / (2 * overzoomScale);
  const firstTileX = Math.floor(startX / MAP_TILE_SIZE);
  const firstTileY = Math.floor(startY / MAP_TILE_SIZE);
  const lastTileX = Math.floor((startX + width / overzoomScale) / MAP_TILE_SIZE);
  const lastTileY = Math.floor((startY + height / overzoomScale) / MAP_TILE_SIZE);
  const maxTile = 2 ** tileZoom;
  const tiles: Array<{ key: string; src: string; left: number; top: number; size: number }> = [];

  for (let x = firstTileX; x <= lastTileX; x += 1) {
    for (let y = firstTileY; y <= lastTileY; y += 1) {
      if (y < 0 || y >= maxTile) continue;
      const wrappedX = ((x % maxTile) + maxTile) % maxTile;
      tiles.push({
        key: `${zoom}-${wrappedX}-${y}`,
        src: `https://${'abcd'[(wrappedX + y) % 4]}.basemaps.cartocdn.com/rastertiles/voyager/${tileZoom}/${wrappedX}/${y}.png`,
        left: (x * MAP_TILE_SIZE - startX) * overzoomScale,
        top: (y * MAP_TILE_SIZE - startY) * overzoomScale,
        size: MAP_TILE_SIZE * overzoomScale,
      });
    }
  }

  return tiles;
};

const getGoongStaticMapUrl = (lat: number, lng: number, zoom: number, width: number, height: number): string => {
  const apiKey = import.meta.env.VITE_GOONG_MAPTILES_KEY || import.meta.env.VITE_GOONG_API_KEY;

  if (!apiKey) {
    return '';
  }

  const params = new URLSearchParams({
    center: `${lat},${lng}`,
    zoom: String(zoom),
    size: `${width}x${height}`,
    markers: `${lat},${lng}`,
    api_key: apiKey,
  });

  return `https://rsapi.goong.io/staticmap?${params.toString()}`;
};

const MapPreview: React.FC<MapPreviewProps> = ({ lat, lng, locationName, zoom, width, height, className = '' }) => {
  const goongStaticMapUrl = getGoongStaticMapUrl(lat, lng, zoom, width, height);
  const mapTiles = React.useMemo(() => getMapTiles(lat, lng, zoom, width, height), [height, lat, lng, width, zoom]);
  const [useGoongMap, setUseGoongMap] = React.useState(Boolean(goongStaticMapUrl));

  React.useEffect(() => {
    setUseGoongMap(Boolean(goongStaticMapUrl));
  }, [goongStaticMapUrl]);

  return (
    <div className={`ld-map-surface ${className}`}>
      {useGoongMap && goongStaticMapUrl ? (
        <img
          className="ld-goong-map-img"
          src={goongStaticMapUrl}
          alt={`Bản đồ ${locationName}`}
          loading="lazy"
          decoding="async"
          onError={() => setUseGoongMap(false)}
        />
      ) : (
        <div className="ld-tile-map" aria-hidden="true">
          {mapTiles.map((tile) => (
            <img
              key={tile.key}
              src={tile.src}
              alt=""
              loading="lazy"
              decoding="async"
              style={{ left: tile.left, top: tile.top, width: tile.size, height: tile.size }}
            />
          ))}
        </div>
      )}
      <div className="ld-map-pin">
        <MapPin size={34} fill="#ef444433" color="#ef4444" />
      </div>
      <div className="ld-map-chip">
        <MapPin size={16} color="var(--primary-blue)" />
        <span>{lat.toFixed(6)}, {lng.toFixed(6)}</span>
      </div>
    </div>
  );
};

export const LocationMap: React.FC<LocationMapProps> = ({ location, onCoordinatesSave }) => {
  const lat = Number(location.lat);
  const lng = Number(location.lng);
  const hasCoords = Number.isFinite(lat) && Number.isFinite(lng) && !(lat === 0 && lng === 0);
  const [isMapOpen, setIsMapOpen] = React.useState(false);
  const [zoom, setZoom] = React.useState(MAX_MAP_ZOOM);
  const [draftLat, setDraftLat] = React.useState('');
  const [draftLng, setDraftLng] = React.useState('');
  const [isSavingCoordinates, setIsSavingCoordinates] = React.useState(false);
  const [coordinateError, setCoordinateError] = React.useState('');

  React.useEffect(() => {
    setDraftLat(Number.isFinite(lat) ? String(lat) : '');
    setDraftLng(Number.isFinite(lng) ? String(lng) : '');
    setCoordinateError('');
  }, [lat, lng]);

  React.useEffect(() => {
    if (!isMapOpen) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsMapOpen(false);
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isMapOpen]);

  const parsedDraftLat = Number(draftLat);
  const parsedDraftLng = Number(draftLng);
  const hasCoordinateChanges = Number.isFinite(parsedDraftLat)
    && Number.isFinite(parsedDraftLng)
    && (parsedDraftLat !== lat || parsedDraftLng !== lng);

  const changeZoom = (step: number) => {
    setZoom((current) => clamp(current + step, MIN_MAP_ZOOM, MAX_MAP_ZOOM));
  };

  const resetCoordinateDraft = () => {
    setDraftLat(Number.isFinite(lat) ? String(lat) : '');
    setDraftLng(Number.isFinite(lng) ? String(lng) : '');
    setCoordinateError('');
  };

  const saveCoordinates = async () => {
    const nextLat = Number(draftLat);
    const nextLng = Number(draftLng);

    if (!Number.isFinite(nextLat) || nextLat < -90 || nextLat > 90) {
      setCoordinateError('Vĩ độ phải là số trong khoảng -90 đến 90.');
      return;
    }

    if (!Number.isFinite(nextLng) || nextLng < -180 || nextLng > 180) {
      setCoordinateError('Kinh độ phải là số trong khoảng -180 đến 180.');
      return;
    }

    try {
      setIsSavingCoordinates(true);
      setCoordinateError('');
      await onCoordinatesSave(nextLat, nextLng);
    } catch (error) {
      console.error('Failed to update place coordinates', error);
      setCoordinateError('Không thể cập nhật tọa độ. Vui lòng thử lại.');
    } finally {
      setIsSavingCoordinates(false);
    }
  };

  return (
    <div className="ld-card">
      <div className="ld-card-header">
        <div className="ld-card-title-group">
          <MapPin size={18} className="ld-icon-danger" color="#ef4444" />
          <h3 className="ld-card-title">Vị trí & Bản đồ</h3>
        </div>
      </div>

      <div className="ld-form-grid">
        <div className="ld-form-group full-width">
          <label className="ld-label">Địa chỉ chi tiết</label>
          <input type="text" className="ld-input" value={location.address} readOnly />
        </div>

        <div className="ld-form-group">
          <label className="ld-label">Vĩ độ (lat)</label>
          <input
            type="number"
            className="ld-input"
            value={draftLat}
            min={-90}
            max={90}
            step="0.000001"
            onChange={(event) => setDraftLat(event.target.value)}
          />
        </div>

        <div className="ld-form-group">
          <label className="ld-label">Kinh độ (long)</label>
          <input
            type="number"
            className="ld-input"
            value={draftLng}
            min={-180}
            max={180}
            step="0.000001"
            onChange={(event) => setDraftLng(event.target.value)}
          />
        </div>  

        <div className="ld-form-group full-width">
          {hasCoords ? (
            <button
              type="button"
              className="ld-map-view"
              aria-label={`Mở bản đồ lớn cho ${location.name}`}
              onClick={() => setIsMapOpen(true)}>
              <MapPreview
                lat={lat}
                lng={lng}
                locationName={location.name}
                zoom={DEFAULT_MAP_ZOOM}
                width={840}
                height={300}
              />
              <span className="ld-map-open-hint">Bấm để phóng to</span>
            </button>
          ) : (
            <div className="ld-map-placeholder">
              <div className="ld-map-stripes"></div>
              <div className="ld-map-marker-box">
                <MapPin size={24} color="var(--primary-blue)" />
                <div className="ld-map-label">Chưa có tọa độ bản đồ</div>
              </div>
            </div>
          )}
        </div>

        <div className="ld-form-group full-width">
          <div className="ld-coordinate-actions">
            <div className="ld-coordinate-buttons">
              {hasCoordinateChanges && (
                <button type="button" className="ld-coordinate-cancel" onClick={resetCoordinateDraft} disabled={isSavingCoordinates}>
                  Hủy
                </button>
              )}
              <button
                type="button"
                className="ld-coordinate-save"
                onClick={() => void saveCoordinates()}
                disabled={!hasCoordinateChanges || isSavingCoordinates}>
                <Check size={15} />
                <span>{isSavingCoordinates ? 'Đang lưu...' : 'Lưu tọa độ'}</span>
              </button>
            </div>
          </div>
          {coordinateError && <div className="ld-coordinate-error">{coordinateError}</div>}
        </div>
      </div>

      {isMapOpen && hasCoords && (
        <div className="ld-map-modal" role="dialog" aria-modal="true" aria-label={`Bản đồ ${location.name}`}>
          <div className="ld-map-modal-panel">
            <div className="ld-map-modal-header">
              <div>
                <h4>{location.name}</h4>
                <p>{location.address}</p>
              </div>
              <button type="button" className="ld-map-modal-close" aria-label="Đóng bản đồ" onClick={() => setIsMapOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <div className="ld-map-modal-body">
              <MapPreview
                lat={lat}
                lng={lng}
                locationName={location.name}
                zoom={zoom}
                width={1100}
                height={620}
                className="ld-map-modal-surface"
              />
              <div className="ld-map-zoom-controls">
                <button type="button" aria-label="Phóng to bản đồ" onClick={() => changeZoom(1)} disabled={zoom >= MAX_MAP_ZOOM}>
                  <ZoomIn size={18} />
                </button>
                <span>{zoom}</span>
                <button type="button" aria-label="Thu nhỏ bản đồ" onClick={() => changeZoom(-1)} disabled={zoom <= MIN_MAP_ZOOM}>
                  <ZoomOut size={18} />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
