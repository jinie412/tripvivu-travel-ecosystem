import React, { useEffect, useMemo, useState } from 'react';
import { ChevronLeft, ChevronRight, Expand, X } from 'lucide-react';
import defaultLocationImage from '../../../../assets/images/location-default.svg';

interface PhotoGalleryProps {
  photos: string[];
}

export const PhotoGallery: React.FC<PhotoGalleryProps> = ({ photos }) => {
  const THUMBNAIL_LIMIT = 4;
  const hasPhotos = Array.isArray(photos) && photos.length > 0;
  const displayPhotos = useMemo(
    () => (hasPhotos ? photos.filter((photo) => typeof photo === 'string' && photo.trim().length > 0) : [defaultLocationImage]),
    [hasPhotos, photos],
  );
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [thumbStartIndex, setThumbStartIndex] = useState(0);
  const [isZoomOpen, setIsZoomOpen] = useState(false);

  const totalPhotos = displayPhotos.length;
  const maxThumbStart = Math.max(0, totalPhotos - THUMBNAIL_LIMIT);
  const thumbEndIndex = Math.min(totalPhotos, thumbStartIndex + THUMBNAIL_LIMIT);
  const visibleThumbnails = displayPhotos.slice(thumbStartIndex, thumbEndIndex);
  const hasPrevThumb = thumbStartIndex > 0;
  const hasNextThumb = thumbEndIndex < totalPhotos;

  useEffect(() => {
    setSelectedIndex(0);
    setThumbStartIndex(0);
  }, [displayPhotos]);

  useEffect(() => {
    if (selectedIndex < thumbStartIndex) {
      setThumbStartIndex(selectedIndex);
      return;
    }
    if (selectedIndex >= thumbStartIndex + THUMBNAIL_LIMIT) {
      setThumbStartIndex(Math.min(selectedIndex - THUMBNAIL_LIMIT + 1, maxThumbStart));
    }
  }, [selectedIndex, thumbStartIndex, maxThumbStart]);

  const mainPhoto = displayPhotos[selectedIndex] || defaultLocationImage;

  const openZoom = () => setIsZoomOpen(true);
  const closeZoom = () => setIsZoomOpen(false);
  const goToPreviousPhoto = () => {
    setSelectedIndex((prev) => (prev === 0 ? totalPhotos - 1 : prev - 1));
  };
  const goToNextPhoto = () => {
    setSelectedIndex((prev) => (prev === totalPhotos - 1 ? 0 : prev + 1));
  };
  const showPreviousThumbs = () => {
    setThumbStartIndex((prev) => Math.max(0, prev - 1));
  };
  const showNextThumbs = () => {
    setThumbStartIndex((prev) => Math.min(maxThumbStart, prev + 1));
  };
  const openMoreThumbnails = () => {
    if (!hasNextThumb) {
      return;
    }
    const nextStart = Math.min(maxThumbStart, thumbStartIndex + THUMBNAIL_LIMIT);
    setThumbStartIndex(nextStart);
    setSelectedIndex(nextStart);
  };

  return (
    <>
      <div className="ld-card mb-24">
        <div className="ld-card-header">
          <h3 className="ld-card-title">Thư viện ảnh</h3>
          <span className="ld-photo-count">{hasPhotos ? displayPhotos.length : 0} ảnh</span>
        </div>

        <div className="ld-gallery">
          <div className="ld-main-photo">
            <img
              src={mainPhoto}
              alt="Main view"
              className="ld-img"
              onError={(event) => {
                event.currentTarget.onerror = null;
                event.currentTarget.src = defaultLocationImage;
              }}
            />
            <button className="ld-expand-btn" onClick={openZoom} type="button" aria-label="Phóng to ảnh">
              <Expand size={20} />
            </button>
          </div>

          <div className="ld-thumb-nav">
            <button
              type="button"
              className="ld-thumb-nav-btn"
              onClick={showPreviousThumbs}
              disabled={!hasPrevThumb}
              aria-label="Xem ảnh trước"
            >
              <ChevronLeft size={16} />
            </button>

            <div className="ld-thumb-row" role="list" aria-label="Danh sách ảnh thu nhỏ">
              {visibleThumbnails.map((photo, index) => {
                const actualIndex = thumbStartIndex + index;
                const remaining = totalPhotos - thumbEndIndex;
                const showMoreOverlay = index === visibleThumbnails.length - 1 && hasNextThumb && remaining > 0;

                return (
                  <button
                    key={`${photo}-${actualIndex}`}
                    type="button"
                    className={`ld-thumb-item ${selectedIndex === actualIndex ? 'active' : ''}`}
                    onClick={() => setSelectedIndex(actualIndex)}
                    aria-label={`Ảnh ${actualIndex + 1}`}
                    aria-pressed={selectedIndex === actualIndex}
                  >
                    <img
                      src={photo}
                      alt={`Thumbnail ${actualIndex + 1}`}
                      className="ld-img"
                      onError={(event) => {
                        event.currentTarget.onerror = null;
                        event.currentTarget.src = defaultLocationImage;
                      }}
                    />
                    {showMoreOverlay && (
                      <span
                        className="ld-thumb-more"
                        onClick={(event) => {
                          event.stopPropagation();
                          openMoreThumbnails();
                        }}
                      >
                        +{remaining}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>

            <button
              type="button"
              className="ld-thumb-nav-btn"
              onClick={showNextThumbs}
              disabled={!hasNextThumb}
              aria-label="Xem ảnh tiếp theo"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      </div>

      {isZoomOpen && (
        <div className="ld-lightbox" onClick={closeZoom} role="dialog" aria-modal="true" aria-label="Ảnh phóng to">
          <button
            type="button"
            className="ld-lightbox-close"
            onClick={closeZoom}
            aria-label="Đóng ảnh phóng to"
          >
            <X size={18} />
          </button>

          {totalPhotos > 1 && (
            <button
              type="button"
              className="ld-lightbox-nav ld-lightbox-nav-left"
              onClick={(event) => {
                event.stopPropagation();
                goToPreviousPhoto();
              }}
              aria-label="Ảnh trước"
            >
              <ChevronLeft size={24} />
            </button>
          )}

          {totalPhotos > 1 && (
            <button
              type="button"
              className="ld-lightbox-nav ld-lightbox-nav-right"
              onClick={(event) => {
                event.stopPropagation();
                goToNextPhoto();
              }}
              aria-label="Ảnh tiếp theo"
            >
              <ChevronRight size={24} />
            </button>
          )}

          <div className="ld-lightbox-content" onClick={(event) => event.stopPropagation()}>
            <img
              src={mainPhoto}
              alt="Zoomed view"
              className="ld-lightbox-image"
              onError={(event) => {
                event.currentTarget.onerror = null;
                event.currentTarget.src = defaultLocationImage;
              }}
            />
          </div>
        </div>
      )}
    </>
  );
};
