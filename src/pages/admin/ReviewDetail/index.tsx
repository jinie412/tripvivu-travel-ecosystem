import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, ShieldAlert, Star, CheckCircle, Clock } from 'lucide-react';
import { reviewAPI } from '../../../services/reviewAPI';
import { ReviewDetailInfo } from '../../../types/review';
import { ReviewHeader } from './components/ReviewHeader';
import { ReviewContent } from './components/ReviewContent';
import { ReportSection } from './components/ReportSection';
import { ReviewActions } from './components/ReviewActions';
import './ReviewDetail.css';
import Swal from 'sweetalert2';

export const ReviewDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [review, setReview] = useState<ReviewDetailInfo | null>(null);
  const [loading, setLoading] = useState(true);

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

  const renderClassification = (review: ReviewDetailInfo) => {
    if (!review.content || review.content.trim() === '' || review.content === '(Không có nội dung)') {
      return null;
    }

    const cls = review.classification;
    if (cls === 'Ngắn hạn') {
      return (
        <span style={{ background: '#dbeafe', color: '#2563eb', padding: '4px 10px', borderRadius: '6px', fontSize: '13px', fontWeight: 600 }}>
          Ngắn hạn
        </span>
      );
    }
    if (cls === 'Dài hạn') {
      return (
        <span style={{ background: '#dcfce7', color: '#16a34a', padding: '4px 10px', borderRadius: '6px', fontSize: '13px', fontWeight: 600 }}>
          Dài hạn
        </span>
      );
    }
    return (
      <span style={{ background: '#f1f5f9', color: '#475569', padding: '4px 10px', borderRadius: '6px', fontSize: '13px', fontWeight: 600 }}>
        Chưa phân loại
      </span>
    );
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
    if (!newStatus || newStatus === 'Chờ duyệt' || newStatus === 'Đã ẩn') {
      Swal.fire({ text: 'Không thể chuyển trạng thái về Chờ duyệt.', icon: 'error' });
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
      Swal.fire({ text: 'Không thể cập nhật trạng thái đánh giá. Vui lòng thử lại.', icon: 'error' });
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
                <div style={{ background: '#fff1f0', border: '1px solid #ffa39e', borderRadius: 8, padding: '16px', marginBottom: 20 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#cf1322', marginBottom: review.violation_reason ? '12px' : 0 }}>
                    <ShieldAlert size={20} />
                    <strong style={{ fontSize: '15px' }}>Đánh giá này vi phạm tiêu chuẩn cộng đồng</strong>
                  </div>
                  
                  {review.violation_reason && (
                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
                      <span style={{ color: '#a8071a', fontSize: '14px' }}>Lý do phát hiện:</span>
                      {getTranslatedReason(review.violation_reason).split(',').map((reasonPart, idx) => {
                        const cleanReason = reasonPart.trim().replace('Nội dung vi phạm: ', '');
                        if (!cleanReason) return null;
                        return (
                          <span key={idx} style={{ background: '#cf1322', color: 'white', padding: '4px 10px', borderRadius: '6px', fontSize: '13px', fontWeight: 600 }}>
                            {cleanReason}
                          </span>
                        );
                      })}
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
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      {renderClassification(review)}
                      <span className="rd-datetime" style={{ color: '#64748b', fontSize: '13px' }}>Đăng lúc {review.datetime}</span>
                    </div>
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
