import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { Star } from 'lucide-react';
import { itineraryReviewAPI } from '../../../services/reviewAPI';
import { ItineraryReviewDetailInfo } from '../../../types/review';
import { ItineraryReviewHeader } from './components/ItineraryReviewHeader';
import { ReviewContent } from '../ReviewDetail/components/ReviewContent';
import { ReviewStatusBanner } from '../ReviewDetail/components/ReviewStatusBanner';

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
  const [updatingStatus, setUpdatingStatus] = useState(false);

  const promptViolationReason = async (): Promise<string | undefined> => {
    const { value, isConfirmed } = await Swal.fire({
      title: 'Đánh dấu vi phạm',
      input: 'text',
      inputLabel: 'Nhập lý do đánh dấu vi phạm',
      inputPlaceholder: 'Lý do vi phạm...',
      showCancelButton: true,
      confirmButtonText: 'Xác nhận',
      cancelButtonText: 'Hủy',
      confirmButtonColor: '#3b82f6',
      cancelButtonColor: '#94a3b8',
    });
    if (!isConfirmed) {
      throw new Error('REASON_INPUT_CANCELLED');
    }
    return typeof value === 'string' && value.trim() ? value.trim() : undefined;
  };

  /** Xử lý cập nhật trạng thái (Đã duyệt / Vi phạm) */
  const handleUpdateStatus = async (newStatus: ItineraryReviewDetailInfo['status']) => {
    if (!review) return;
    if (!id) return;
    if (!newStatus || newStatus === 'Chờ duyệt' || newStatus === 'Đã ẩn' || newStatus === review.status) {
      return;
    }

    let reason: string | undefined;
    if (newStatus === 'Vi phạm') {
      try {
        reason = await promptViolationReason();
      } catch {
        return;
      }
    }

    setUpdatingStatus(true);
    try {
      await itineraryReviewAPI.updateItineraryReviewStatus(id, newStatus, reason);
      setReview({ ...review, status: newStatus, violation_reason: reason ?? review.violation_reason });
    } catch (error) {
      console.error('Failed to update itinerary review status', error);
      Swal.fire({ text: 'Không thể cập nhật trạng thái đánh giá. Vui lòng thử lại.', icon: 'error' });
    } finally {
      setUpdatingStatus(false);
    }
  };

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

              <div style={{ marginBottom: 20 }}>
                <ReviewStatusBanner
                  status={review.status}
                  violationReason={review.violation_reason}
                  getTranslatedReason={getTranslatedReason}
                  updating={updatingStatus}
                  onUpdateStatus={handleUpdateStatus}
                />
              </div>

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
