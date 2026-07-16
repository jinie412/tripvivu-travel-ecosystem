import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { Star } from 'lucide-react';
import { reviewAPI } from '../../../services/reviewAPI';
import { ReviewDetailInfo } from '../../../types/review';
import { ReviewHeader } from './components/ReviewHeader';
import { ReviewContent } from './components/ReviewContent';
import { ReviewStatusBanner } from './components/ReviewStatusBanner';
import { ReviewActions } from './components/ReviewActions';
import './ReviewDetail.css';
import Swal from 'sweetalert2';

export const ReviewDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [review, setReview] = useState<ReviewDetailInfo | null>(null);
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

  // Map lý do tiếng Anh sang tiếng Việt và loại bỏ tiền tố
  const getTranslatedReason = (reason: string) => {
    let translated = reason.replace('Nội dung văn bản:', 'Nội dung vi phạm:');
    const map: Record<string, string> = {
      'Hate Speech': 'Ngôn từ thù hận',
      'Harassment': 'Quấy rối',
      'Self-Harm': 'Tự hại',
      'Sexual': 'Gợi dục',
      'Gore': 'Máu me',
      'Violence': 'Bạo lực'
    };
    Object.keys(map).forEach(key => {
      translated = translated.replace(new RegExp(key, 'gi'), map[key]);
    });
    return translated;
  };

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
      Swal.fire({ text: 'Không thể cập nhật phân loại đánh giá. Vui lòng thử lại.', icon: 'error' });
      throw error;
    }
  };

  /** Xử lý cập nhật trạng thái (Đã duyệt / Vi phạm) */
  const handleUpdateStatus = async (newStatus: ReviewDetailInfo['status']) => {
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
      await reviewAPI.updateReviewStatus(id, newStatus, reason);
      setReview({ ...review, status: newStatus, violation_reason: reason ?? review.violation_reason });
    } catch (error) {
      console.error('Failed to update review status', error);
      Swal.fire({ text: 'Không thể cập nhật trạng thái đánh giá. Vui lòng thử lại.', icon: 'error' });
    } finally {
      setUpdatingStatus(false);
    }
  };

  const hasContent = Boolean(
    review?.content && review.content.trim() !== '' && review.content !== '(Không có nội dung)',
  );
  const showClassification = Boolean(
    hasContent && review?.classification !== 'Chưa phân loại',
  );

  return (
    <div className="review-detail-page">
      <div className="rd-page-header">
        <div className="rd-breadcrumb">
          <span>Quản lý</span> / <Link to="/admin/reviews" style={{ color: 'var(--text-muted)', textDecoration: 'none' }}>Đánh giá</Link> / <span className="active-bread" style={{ color: 'var(--primary-blue)', fontWeight: 500 }}>Chi tiết</span>
        </div>
        
        <div className="rd-header-main">
          <h1 className="rd-page-title">Chi tiết đánh giá</h1>
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
              <ReviewHeader review={review} />

              {(review.status !== 'Đã ẩn' || showClassification) && (
                <div style={{ display: 'flex', gap: 20, alignItems: 'stretch', marginBottom: 20 }}>
                  {review.status !== 'Đã ẩn' && (
                    <div style={{ flex: 1 }}>
                      <ReviewStatusBanner
                        status={review.status}
                        violationReason={review.violation_reason}
                        getTranslatedReason={getTranslatedReason}
                        updating={updatingStatus}
                        onUpdateStatus={handleUpdateStatus}
                      />
                    </div>
                  )}
                  {showClassification && (
                    <div style={{ flex: 1 }}>
                      <ReviewActions
                        classification={review.classification}
                        onUpdateClassification={handleUpdateClassification}
                      />
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
                        <Star key={i} size={20} fill={i < review.rating ? '#facc15' : 'none'} color={i < review.rating ? '#facc15' : '#d1d5db'} style={{ marginRight: 4 }} />
                      ))}
                      <span style={{ marginLeft: 8, fontWeight: 600, color: '#eab308', fontSize: '16px' }}>{review.rating}/5</span>
                    </div>
                    <span className="rd-datetime" style={{ color: '#64748b', fontSize: '13px' }}>Đăng lúc {review.datetime}</span>
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
