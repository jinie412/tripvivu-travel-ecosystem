import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ShieldAlert, Star, CheckCircle, Clock } from 'lucide-react';
import { itineraryReviewAPI } from '../../../services/reviewAPI';
import { ItineraryReviewDetailInfo } from '../../../types/review';
import { ItineraryReviewHeader } from './components/ItineraryReviewHeader';
import { ReviewContent } from '../ReviewDetail/components/ReviewContent';

import '../ReviewDetail/ReviewDetail.css';
import './ItineraryReviewDetail.css';
import Swal from 'sweetalert2';

const getTranslatedReason = (reason: string) => {
  let translated = reason.replace('Nội dung văn bản:', '').replace('Nội dung vi phạm:', '').trim();
  if (translated.startsWith(':')) translated = translated.substring(1).trim();
  const map: Record<string, string> = {
    'sexual/minors': 'Nội dung khiêu dâm liên quan trẻ em',
    'sexual': 'Nội dung khiêu dâm',
    'harassment/threatening': 'Quấy rối kèm đe dọa',
    'harassment': 'Quấy rối',
    'hate/threatening': 'Thù ghét kèm đe dọa',
    'hate': 'Thù ghét / phân biệt',
    'illicit/violent': 'Nội dung phi pháp kèm bạo lực',
    'illicit': 'Nội dung phi pháp',
    'self-harm/intent': 'Ý định tự gây hại',
    'self-harm/instructions': 'Hướng dẫn tự gây hại',
    'self-harm': 'Tự gây hại',
    'violence/graphic': 'Bạo lực, hình ảnh phản cảm',
    'violence': 'Bạo lực',
  };
  Object.keys(map).forEach(k => {
    translated = translated.replace(new RegExp(`\\b${k.replace(/\//g, '\\/')}\\b`, 'g'), map[k]);
  });
  return translated;
};

export const ItineraryReviewDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [review, setReview] = useState<ItineraryReviewDetailInfo | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDetail = async () => {
      if (!id) return;
      setLoading(true);
      try {
        const data = await itineraryReviewAPI.getItineraryReviewById(id);
        setReview(data);
      } catch (error) {
        console.error('Failed to load itinerary review detail', error);
      } finally {
        setLoading(false);
      }
    };
    fetchDetail();
  }, [id]);

  return (
    <div className="review-detail-page itinerary-review-detail-page">
      <div className="rd-page-header">
        <div className="rd-breadcrumb">
          <span>Quản lý</span> /{' '}
          <Link
            to="/admin/reviews?tab=itinerary"
            style={{ color: 'var(--text-muted)', textDecoration: 'none' }}
          >
            Đánh giá lịch trình
          </Link>{' '}
          /{' '}
          <span className="active-bread" style={{ color: 'var(--primary-blue)', fontWeight: 500 }}>
            Chi tiết
          </span>
        </div>

        <div className="rd-header-main">
          <h1 className="rd-page-title">Chi tiết đánh giá lịch trình</h1>
        </div>
      </div>

      <div className="rd-page-content">
        {loading ? (
          <div className="rd-loading">Đang tải chi tiết đánh giá...</div>
        ) : !review ? (
          <div className="rd-loading">Không tìm thấy đánh giá.</div>
        ) : (
          <div style={{ display: 'flex', justifyContent: 'center', maxWidth: '900px', margin: '0 auto' }}>
            <div className="rd-col-main" style={{ width: '100%' }}>
              <ItineraryReviewHeader review={review} />

              {review.status === 'Đã duyệt' && (
                <div style={{ background: '#f6ffed', border: '1px solid #b7eb8f', borderRadius: 8, padding: '16px', marginBottom: 20 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#389e0d' }}>
                    <CheckCircle size={20} />
                    <strong style={{ fontSize: '15px' }}>Đánh giá này hợp lệ và đã được duyệt</strong>
                  </div>
                </div>
              )}

              {review.status === 'Chờ duyệt' && (
                <div style={{ background: '#fffbe6', border: '1px solid #ffe58f', borderRadius: 8, padding: '16px', marginBottom: 20 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#d48806' }}>
                    <Clock size={20} />
                    <strong style={{ fontSize: '15px' }}>Đánh giá này đang chờ kiểm duyệt</strong>
                  </div>
                </div>
              )}

              {review.status === 'Vi phạm' && (
                <div style={{ 
                  display: 'flex', 
                  flexDirection: 'column',
                  gap: '12px',
                  background: '#fff1f0', 
                  border: '1px solid #ffa39e', 
                  borderRadius: '8px', 
                  padding: '16px', 
                  marginBottom: '24px', 
                  color: '#cf1322' 
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <ShieldAlert size={20} color="#cf1322" />
                    <strong style={{ fontSize: '16px' }}>Đánh giá này vi phạm tiêu chuẩn cộng đồng</strong>
                  </div>
                  {review.violation_reason && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', paddingLeft: '28px' }}>
                      <span style={{ fontSize: '14px', color: '#a8071a', fontWeight: 500 }}>Lý do phát hiện:</span>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                        {getTranslatedReason(review.violation_reason).split(',').map((reason, idx) => (
                          <span key={idx} style={{ 
                            background: '#cf1322', 
                            color: '#fff', 
                            padding: '4px 10px', 
                            borderRadius: '6px', 
                            fontSize: '13px', 
                            fontWeight: '600' 
                          }}>
                            {reason.trim()}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
              <ReviewContent 
                content={review.content} 
                images={review.images} 
                isMediaViolated={review.status === 'Vi phạm'}
                mediaViolationReason={review.violation_reason ? getTranslatedReason(review.violation_reason) : undefined}
                headerNode={
                  <div className="rd-rating-row" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: 'none', marginTop: 0, paddingTop: 0 }}>
                    <div className="rd-stars" style={{ display: 'flex', alignItems: 'center' }}>
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star
                          key={i}
                          size={24}
                          fill={i < review.rating ? '#facc15' : 'none'}
                          color={i < review.rating ? '#facc15' : '#d1d5db'}
                        />
                      ))}
                      <span style={{ marginLeft: 8, fontSize: '18px', fontWeight: 600, color: '#facc15' }}>
                        {review.rating}/5
                      </span>
                    </div>
                    <span className="rd-datetime" style={{ color: '#64748b', fontSize: '14px' }}>Đăng lúc {review.datetime}</span>
                  </div>
                }
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
