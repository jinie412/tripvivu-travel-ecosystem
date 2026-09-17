import React, { useState } from 'react';
import { ShieldAlert, X } from 'lucide-react';

interface ReviewContentProps {
  content: string;
  images: string[];
  headerNode?: React.ReactNode;
  isMediaViolated?: boolean;
  mediaViolationReason?: string;
}

/** Hiển thị nội dung chi tiết đánh giá + hình ảnh đính kèm */
export const ReviewContent: React.FC<ReviewContentProps> = ({ content, images, headerNode, isMediaViolated, mediaViolationReason }) => {
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  return (
    <>
    <div className="rd-content-section">
      <div style={{ fontSize: '14px', fontWeight: 800, color: '#1e293b', marginBottom: '16px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
        Chi tiết đánh giá
      </div>
      {headerNode && (
        <div style={{ marginBottom: '20px' }}>
          {headerNode}
        </div>
      )}
      {/* Nội dung đánh giá */}
      <div className="rd-content-box" style={{ border: 'none', background: 'transparent', padding: 0, marginBottom: '24px' }}>
        <p className="rd-content-text">{content}</p>
      </div>

      {/* Hình ảnh/Video đính kèm */}
      {images.length > 0 && (
        <div className="rd-images-section">
          <div className="rd-images-label">
            <span className="rd-images-icon">📷</span>
            <span>HÌNH ẢNH / VIDEO ĐÍNH KÈM ({images.length})</span>
          </div>
          <div className="rd-images-grid">
            {images.map((mediaUrl, idx) => {
              const isVideo = mediaUrl && mediaUrl.match(/\.(mp4|mov|avi|webm|mkv)(\?.*)?$/i);
              return (
                <div key={idx} className="rd-image-item" style={{ position: 'relative' }}>
                  {isVideo ? (
                    <video src={mediaUrl} controls className="rd-image rd-video-element" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '14px' }} />
                  ) : (
                    <img 
                      src={mediaUrl} 
                      alt={`Ảnh đánh giá ${idx + 1}`} 
                      className="rd-image" 
                      style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '14px', cursor: 'pointer' }} 
                      onClick={() => setPreviewImage(mediaUrl)}
                    />
                  )}
                  {isMediaViolated && (
                    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'rgba(207, 19, 34, 0.9)', color: 'white', fontSize: '12px', fontWeight: '600', padding: '6px', borderBottomLeftRadius: '14px', borderBottomRightRadius: '14px', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px', zIndex: 10 }}>
                      <ShieldAlert size={14} />
                      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {mediaViolationReason ? `Vi phạm: ${mediaViolationReason}` : 'Vi phạm'}
                      </span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>

    {/* Lightbox Preview */}
    {previewImage && (
      <div 
        style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.85)', zIndex: 9999, display: 'flex', justifyContent: 'center', alignItems: 'center', cursor: 'zoom-out' }}
        onClick={() => setPreviewImage(null)}
      >
        <div style={{ position: 'absolute', top: 20, right: 20, color: 'white', cursor: 'pointer' }} onClick={() => setPreviewImage(null)}>
          <X size={32} />
        </div>
        <img src={previewImage} style={{ maxWidth: '90vw', maxHeight: '90vh', objectFit: 'contain' }} alt="Preview" />
      </div>
    )}
    </>
  );
};
