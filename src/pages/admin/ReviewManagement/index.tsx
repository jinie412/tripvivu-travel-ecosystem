import React, { useEffect, useState } from 'react';
import { Review, ReviewStatsInfo, ItineraryReview, ItineraryReviewStatsInfo } from '../../../types/review';
import {
  reviewAPI,
  ReviewFilterParams,
  itineraryReviewAPI,
  ItineraryReviewFilterParams,
} from '../../../services/reviewAPI';
import { ReviewStats } from './components/ReviewStats';
import { ReviewFilter } from './components/ReviewFilter';
import { ReviewTable } from './components/ReviewTable';
import { Bell } from 'lucide-react';
import { Link, useSearchParams } from 'react-router-dom';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './ReviewManagement.css';

type ActiveTab = 'location' | 'itinerary';

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

/** Chuyển ItineraryReview sang Review để dùng chung ReviewTable */
const toReviewRow = (r: ItineraryReview): Review => ({
  id: r.id,
  userAvatar: r.userAvatar,
  userName: r.userName,
  locationName: r.itineraryName,
  content: r.content,
  rating: r.rating,
  date: r.date,
  status: r.status,
});

export const ReviewManagement: React.FC = () => {
  const [searchParams] = useSearchParams();
  const [activeTab, setActiveTab] = useState<ActiveTab>(
    searchParams.get('tab') === 'itinerary' ? 'itinerary' : 'location',
  );

  // ── Shared filter state (reset khi đổi tab)
  const [search, setSearch] = useState('');
  const [classification, setClassification] = useState('all');
  const [dateSent, setDateSent] = useState('all');
  const [dateExact, setDateExact] = useState('');
  const [status, setStatus] = useState('all');
  const [rating, setRating] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);

  // ── Location reviews state
  const [locationReviews, setLocationReviews] = useState<Review[]>([]);
  const [locationStats, setLocationStats] = useState<ReviewStatsInfo | null>(null);
  const [locationTotal, setLocationTotal] = useState(0);

  // ── Itinerary reviews state
  const [itineraryReviews, setItineraryReviews] = useState<Review[]>([]);
  const [itineraryStats, setItineraryStats] = useState<ItineraryReviewStatsInfo | null>(null);
  const [itineraryTotal, setItineraryTotal] = useState(0);

  const [loading, setLoading] = useState(true);
  const itemsPerPage = 10;

  // Đồng bộ tab khi URL query param thay đổi (click sidebar)
  useEffect(() => {
    const tabFromUrl = searchParams.get('tab') === 'itinerary' ? 'itinerary' : 'location';
    setActiveTab(tabFromUrl);
    setSearch('');
    setClassification('all');
    setDateSent('all');
    setDateExact('');
    setStatus('all');
    setRating('all');
    setCurrentPage(1);
  }, [searchParams]);


  // ── Fetch location reviews
  useEffect(() => {
    if (activeTab !== 'location') return;
    const fetch = async () => {
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
        setLocationStats(statsData);
        setLocationReviews(reviewsData.data);
        setLocationTotal(reviewsData.total);
      } catch (error) {
        console.error('Failed to load location reviews', error);
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [activeTab, currentPage, search, classification, dateSent, dateExact, status, rating]);

  // ── Fetch itinerary reviews
  useEffect(() => {
    if (activeTab !== 'itinerary') return;
    const fetch = async () => {
      setLoading(true);
      try {
        const filters: ItineraryReviewFilterParams = {
          search,
          dateSent: dateSent as ItineraryReviewFilterParams['dateSent'],
          dateExact: dateExact || undefined,
          status: status as ItineraryReviewFilterParams['status'],
          rating: rating === 'all' ? undefined : Number(rating),
        };
        const [statsData, reviewsData] = await Promise.all([
          itineraryReviewAPI.getItineraryReviewStats(),
          itineraryReviewAPI.getItineraryReviews(currentPage, itemsPerPage, filters),
        ]);
        setItineraryStats(statsData);
        setItineraryReviews(reviewsData.data.map(toReviewRow));
        setItineraryTotal(reviewsData.total);
      } catch (error) {
        console.error('Failed to load itinerary reviews', error);
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [activeTab, currentPage, search, dateSent, dateExact, status, rating]);

  const handleUpdateLocationStatus = async (reviewId: string, newStatus: Review['status']) => {
    if (newStatus === 'Chờ duyệt') {
      window.alert('Trạng thái Chờ duyệt không hỗ trợ cập nhật thủ công.');
      throw new Error('Unsupported status transition');
    }
    const reason = newStatus === 'Vi phạm'
      ? window.prompt('Nhập lý do đánh dấu vi phạm:') || undefined
      : undefined;
    await reviewAPI.updateReviewStatus(reviewId, newStatus, reason);
    const latestStats = await reviewAPI.getReviewStats();
    setLocationStats(latestStats);
  };

  const handleUpdateItineraryStatus = async (reviewId: string, newStatus: Review['status']) => {
    if (newStatus === 'Chờ duyệt') {
      window.alert('Trạng thái Chờ duyệt không hỗ trợ cập nhật thủ công.');
      throw new Error('Unsupported status transition');
    }
    const reason = newStatus === 'Vi phạm'
      ? window.prompt('Nhập lý do đánh dấu vi phạm:') || undefined
      : undefined;
    await itineraryReviewAPI.updateItineraryReviewStatus(reviewId, newStatus, reason);
    const latestStats = await itineraryReviewAPI.getItineraryReviewStats();
    setItineraryStats(latestStats);
  };

  const activeStats = activeTab === 'location' ? locationStats : itineraryStats;
  const activeReviews = activeTab === 'location' ? locationReviews : itineraryReviews;
  const activeTotal = activeTab === 'location' ? locationTotal : itineraryTotal;
  const handleStatusChange = activeTab === 'location' ? handleUpdateLocationStatus : handleUpdateItineraryStatus;

  return (
    <div className="page-container">
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Quản lý đánh giá</h1>
          <div className="breadcrumb">
            <span className="text-muted">Quản lý</span>
            {' / '}
            <span className="text-muted">Đánh giá</span>
            {' / '}
            <Link
              to={activeTab === 'location' ? '/admin/reviews' : '/admin/reviews?tab=itinerary'}
              className="active-bread"
            >
              {activeTab === 'location' ? 'Đánh giá địa điểm' : 'Đánh giá lịch trình'}
            </Link>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn"><Bell size={20} /></button>
          <AdminHeaderProfile />
        </div>
      </header>

      <div className="page-content">
        <ReviewStats stats={activeStats} loading={loading} />

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
            showClassification={activeTab === 'location'}
            searchPlaceholder={
              activeTab === 'location'
                ? 'Tìm kiếm địa điểm, người đánh giá...'
                : 'Tìm kiếm lịch trình, người đánh giá...'
            }
            onSearchChange={(value) => { setCurrentPage(1); setSearch(value); }}
            onClassificationChange={(value) => { setCurrentPage(1); setClassification(value); }}
            onDateSentChange={(value) => { setCurrentPage(1); setDateExact(''); setDateSent(value); }}
            onDateExactChange={(value) => { setCurrentPage(1); setDateSent('all'); setDateExact(value); }}
            onStatusChange={(value) => { setCurrentPage(1); setStatus(value); }}
            onRatingChange={(value) => { setCurrentPage(1); setRating(value); }}
          />

          <ReviewTable
            reviews={activeReviews}
            loading={loading}
            currentPage={currentPage}
            totalItems={activeTotal}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
            onStatusChange={handleStatusChange}
            showClassification={activeTab === 'location'}
            targetColumnLabel={activeTab === 'location' ? 'ĐỊA ĐIỂM' : 'LỊCH TRÌNH'}
            rowNavigatePath={activeTab === 'itinerary' ? '/admin/itinerary-reviews' : '/admin/reviews'}
          />
        </div>
      </div>
    </div>
  );
};
