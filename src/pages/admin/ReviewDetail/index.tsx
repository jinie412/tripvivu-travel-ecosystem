import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import { reviewAPI } from '../../../services/reviewAPI';
import { ReviewDetailInfo } from '../../../types/review';
import { ReviewHeader } from './components/ReviewHeader';
import { ReviewContent } from './components/ReviewContent';
import { ReportSection } from './components/ReportSection';
import { ReviewActions } from './components/ReviewActions';
import './ReviewDetail.css';

export const ReviewDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [review, setReview] = useState<ReviewDetailInfo | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDetail = async () => {
      if (!id) return;
      setLoading(true);
      try {
        const data = await reviewAPI.getReviewById(id);
        setReview(data);
      } catch (error) {
        console.error('Failed to load review detail', error);
      } finally {
        setLoading(false);
      }
    };
    fetchDetail();
  }, [id]);

  /** Đóng và quay lại trang quản lý */
  const handleClose = () => {
    navigate('/admin/reviews');
  };

  /** Xử lý cập nhật phân loại (ngắn hạn / dài hạn) */
  const handleUpdateClassification = async (newType: 'Ngắn hạn' | 'Dài hạn') => {
    if (!review) return;
    if (!id) return;

    try {
      const result = await reviewAPI.updateReviewTimeLabel(id, newType);
      setReview({
        ...review,
        classification: newType,
        status: result.status ?? review.status,
      });
    } catch (error) {
      console.error('Failed to update review classification', error);
      window.alert('Không thể cập nhật phân loại đánh giá. Vui lòng thử lại.');
      throw error;
    }
  };

  /** Xử lý cập nhật trạng thái (Đã duyệt / Vi phạm) */
  const handleUpdateStatus = async (newStatus: ReviewDetailInfo['status']) => {
    if (!review) return;
    if (!id) return;
    if (!newStatus || newStatus === 'Chờ duyệt' || newStatus === 'Đã ẩn') {
      window.alert('Không thể chuyển trạng thái về Chờ duyệt.');
      return;
    }

    const reason =
      newStatus === 'Vi phạm'
        ? window.prompt('Nhập lý do đánh dấu vi phạm:') || undefined
        : undefined;

    try {
      await reviewAPI.updateReviewStatus(id, newStatus, reason);
      setReview({ ...review, status: newStatus });
    } catch (error) {
      console.error('Failed to update review status', error);
      window.alert('Không thể cập nhật trạng thái đánh giá. Vui lòng thử lại.');
    }
  };

  return (
    <div className="review-detail-page">
      <div className="rd-page-header">
        <div className="rd-breadcrumb">
          <span>Quản lý</span> / <Link to="/admin/reviews" style={{ color: 'var(--text-muted)', textDecoration: 'none' }}>Đánh giá</Link> / <span className="active-bread" style={{ color: 'var(--primary-blue)', fontWeight: 500 }}>Chi tiết</span>
        </div>
        
        <div className="rd-header-main">
          <h1 className="rd-page-title">Chi tiết đánh giá</h1>
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
              <ReviewHeader review={review} />
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
              <ReviewActions 
                status={review.status || 'Đã duyệt'}
                classification={review.classification}
                hasContent={review.reviewType === 'with_content'}
                onUpdateClassification={handleUpdateClassification}
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
