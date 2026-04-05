import React, { useEffect, useState } from 'react';
import { Review, ReviewStatsInfo } from '../../../types/review';
import { reviewAPI, ReviewFilterParams } from '../../../services/reviewAPI';
import { ReviewStats } from './components/ReviewStats';
import { ReviewFilter } from './components/ReviewFilter';
import { ReviewTable } from './components/ReviewTable';
import { Bell } from 'lucide-react';
import { Link } from 'react-router-dom';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './ReviewManagement.css';

export const ReviewManagement: React.FC = () => {
  const classificationOptions = [
    { value: 'all', label: 'Tất cả' },
    { value: 'long-term', label: 'Dài hạn' },
    { value: 'short-term', label: 'Ngắn hạn' },
    { value: 'need-action', label: 'Cần xử lý' },
    { value: 'unclassified', label: 'Chưa phân loại' },
  ];

  const dateSentOptions = [
    { value: 'all', label: 'Tất cả' },
    { value: 'today', label: 'Hôm nay' },
    { value: 'yesterday', label: 'Hôm qua' },
    { value: 'last_7_days', label: '7 ngày qua' },
    { value: 'last_30_days', label: '30 ngày qua' },
  ];

  const statusOptions = [
    { value: 'all', label: 'Tất cả' },
    { value: 'pending', label: 'Chờ duyệt' },
    { value: 'approved', label: 'Đã duyệt' },
    { value: 'violation', label: 'Vi phạm' },
  ];

  const ratingOptions = [
    { value: 'all', label: 'Tất cả' },
    { value: '1', label: '1 sao' },
    { value: '2', label: '2 sao' },
    { value: '3', label: '3 sao' },
    { value: '4', label: '4 sao' },
    { value: '5', label: '5 sao' },
  ];

  const [reviews, setReviews] = useState<Review[]>([]);
  const [stats, setStats] = useState<ReviewStatsInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const [search, setSearch] = useState('');
  const [classification, setClassification] = useState('all');
  const [dateSent, setDateSent] = useState('all');
  const [dateExact, setDateExact] = useState('');
  const [status, setStatus] = useState('all');
  const [rating, setRating] = useState('all');

  // Pagination state
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalItems, setTotalItems] = useState<number>(0);
  const itemsPerPage = 10;

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const filters: ReviewFilterParams = {
          search,
          classification: classification as ReviewFilterParams['classification'],
          dateSent: dateSent as ReviewFilterParams['dateSent'],
          dateExact: dateExact || undefined,
          status: status as ReviewFilterParams['status'],
          rating: rating === 'all' ? undefined : Number(rating),
        };

        const [statsData, reviewsData] = await Promise.all([
          reviewAPI.getReviewStats(),
          reviewAPI.getReviews(currentPage, itemsPerPage, filters),
        ]);
        setStats(statsData);
        setReviews(reviewsData.data);
        setTotalItems(reviewsData.total);
      } catch (error) {
        console.error('Failed to load review data', error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [currentPage, search, classification, dateSent, dateExact, status, rating]);

  const handleUpdateStatus = async (
    reviewId: string,
    newStatus: Review['status'],
  ) => {
    if (newStatus === 'Chờ duyệt') {
      window.alert('Trạng thái Chờ duyệt không hỗ trợ cập nhật thủ công.');
      throw new Error('Unsupported status transition');
    }

    const reason =
      newStatus === 'Vi phạm'
        ? window.prompt('Nhập lý do đánh dấu vi phạm:') || undefined
        : undefined;

    await reviewAPI.updateReviewStatus(reviewId, newStatus, reason);
    const latestStats = await reviewAPI.getReviewStats();
    setStats(latestStats);
  };

  return (
    <div className="page-container">
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Quản lý đánh giá</h1>
          <div className="breadcrumb">
            <span className="text-muted">Quản lý</span> / <Link to="/admin/reviews" className="active-bread">Đánh giá</Link>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn">
            <Bell size={20} />
          </button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content">
        <ReviewStats stats={stats} loading={loading} />

        <div className="card tab-container">
          <ReviewFilter
            search={search}
            classification={classification}
            dateSent={dateSent}
            dateExact={dateExact}
            status={status}
            rating={rating}
            classificationOptions={classificationOptions}
            dateSentOptions={dateSentOptions}
            statusOptions={statusOptions}
            ratingOptions={ratingOptions}
            onSearchChange={(value) => {
              setCurrentPage(1);
              setSearch(value);
            }}
            onClassificationChange={(value) => {
              setCurrentPage(1);
              setClassification(value);
            }}
            onDateSentChange={(value) => {
              setCurrentPage(1);
              setDateExact('');
              setDateSent(value);
            }}
            onDateExactChange={(value) => {
              setCurrentPage(1);
              setDateSent('all');
              setDateExact(value);
            }}
            onStatusChange={(value) => {
              setCurrentPage(1);
              setStatus(value);
            }}
            onRatingChange={(value) => {
              setCurrentPage(1);
              setRating(value);
            }}
          />

          <ReviewTable
            reviews={reviews}
            loading={loading}
            currentPage={currentPage}
            totalItems={totalItems}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
            onStatusChange={handleUpdateStatus}
          />
        </div>
      </div>
    </div>
  );
};
