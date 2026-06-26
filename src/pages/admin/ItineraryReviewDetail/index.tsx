import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import { itineraryReviewAPI } from '../../../services/reviewAPI';
import { ItineraryReviewDetailInfo } from '../../../types/review';
import { ItineraryReviewHeader } from './components/ItineraryReviewHeader';
import { ItineraryReviewActions } from './components/ItineraryReviewActions';
import { ReviewContent } from '../ReviewDetail/components/ReviewContent';
import { ReportSection } from '../ReviewDetail/components/ReportSection';
import '../ReviewDetail/ReviewDetail.css';
import './ItineraryReviewDetail.css';

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

  const handleClose = () => {
    navigate('/admin/reviews?tab=itinerary');
  };

  const handleUpdateStatus = async (newStatus: 'Đã duyệt' | 'Vi phạm' | 'Chờ duyệt') => {
    if (!review || !id) return;
    if (newStatus === 'Chờ duyệt') {
      window.alert('Không thể chuyển trạng thái về Chờ duyệt.');
      return;
    }

    const reason =
      newStatus === 'Vi phạm'
        ? window.prompt('Nhập lý do đánh dấu vi phạm:') || undefined
        : undefined;

    try {
      await itineraryReviewAPI.updateItineraryReviewStatus(id, newStatus, reason);
      setReview({ ...review, status: newStatus });
    } catch (error) {
      console.error('Failed to update itinerary review status', error);
      window.alert('Không thể cập nhật trạng thái đánh giá. Vui lòng thử lại.');
    }
  };

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
          <button className="btn-outline-secondary" onClick={handleClose}>
            <ArrowLeft size={16} />
            <span>Quay lại</span>
          </button>
        </div>
      </div>

      <div className="rd-page-content">
        {loading ? (
          <div className="rd-loading">Đang tải chi tiết đánh giá...</div>
        ) : !review ? (
          <div className="rd-loading">Không tìm thấy đánh giá.</div>
        ) : (
          <div className="rd-grid">
            <div className="rd-col-main">
              <ItineraryReviewHeader review={review} />
              {review.status === 'Vi phạm' && review.violation_reason && (
                <div style={{ background: '#fff1f0', border: '1px solid #ffa39e', borderRadius: 6, padding: '10px 14px', marginBottom: 16, color: '#a8071a' }}>
                  <strong>Lý do vi phạm (AI):</strong> {review.violation_reason}
                </div>
              )}
              <ReviewContent content={review.content} images={review.images} />
            </div>

            <div className="rd-col-side">
              <ReportSection
                reportCount={review.reportCount}
                reportReasons={review.reportReasons}
                adminNote={review.adminNote}
              />
              <ItineraryReviewActions
                status={review.status || 'Đã duyệt'}
                onUpdateStatus={(status) => {
                  void handleUpdateStatus(status);
                }}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
