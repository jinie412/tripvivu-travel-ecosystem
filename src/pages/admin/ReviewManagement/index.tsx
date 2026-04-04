import React, { useEffect, useState } from 'react';
import { Review, ReviewStatsInfo } from '../../../types/review';
import { reviewAPI } from '../../../services/reviewAPI';
import { ReviewStats } from './components/ReviewStats';
import { ReviewFilter } from './components/ReviewFilter';
import { ReviewTable } from './components/ReviewTable';
import { Bell } from 'lucide-react';
import { Link } from 'react-router-dom';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './ReviewManagement.css';

export const ReviewManagement: React.FC = () => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [stats, setStats] = useState<ReviewStatsInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  // Pagination state
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalItems, setTotalItems] = useState<number>(0);
  const itemsPerPage = 10;

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const [statsData, reviewsData] = await Promise.all([
          reviewAPI.getReviewStats(),
          reviewAPI.getReviews(currentPage, itemsPerPage)
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
  }, [currentPage]);

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
          <ReviewFilter />

          <ReviewTable
            reviews={reviews}
            loading={loading}
            currentPage={currentPage}
            totalItems={totalItems}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
          />
        </div>
      </div>
    </div>
  );
};
