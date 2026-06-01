import React, { useEffect, useState } from 'react';
import { Location, LocationStatsInfo } from '../../../types/location';
import { locationAPI, LocationCategoryOptions, LocationFilterParams } from '../../../services/locationAPI';
import { LocationStats } from './components/LocationStats';
import { LocationFilter } from './components/LocationFilter';
import { LocationTable } from './components/LocationTable';
import { Bell, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './LocationManagement.css';

const STATUS_OPTIONS = [
  { value: 'all', label: 'Tất cả' },
  { value: 'pending', label: 'Chờ duyệt' },
  { value: 'approved', label: 'Đã duyệt' },
  { value: 'rejected', label: 'Từ chối' },
];

export const LocationManagement: React.FC = () => {
  const [locations, setLocations] = useState<Location[]>([]);
  const [stats, setStats] = useState<LocationStatsInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedRows, setSelectedRows] = useState<string[]>([]);
  const [categoryOptions, setCategoryOptions] = useState<LocationCategoryOptions>({
    categories: [],
  });

  const [searchInput, setSearchInput] = useState<string>('');
  const [search, setSearch] = useState<string>('');
  const [status, setStatus] = useState<string>('all');
  const [categoryName, setCategoryName] = useState<string>('');

  // Pagination state
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalItems, setTotalItems] = useState<number>(0);
  const itemsPerPage = 10;

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedRows(locations.map(l => l.id));
    } else {
      setSelectedRows([]);
    }
  };

  const handleSelectRow = (id: string, checked: boolean) => {
    if (checked) {
      setSelectedRows(prev => [...prev, id]);
    } else {
      setSelectedRows(prev => prev.filter(r => r !== id));
    }
  };

  // Debounce search input 400ms trước khi gửi API
  useEffect(() => {
    const timer = setTimeout(() => {
      setCurrentPage(1);
      setSearch(searchInput);
    }, 400);
    return () => clearTimeout(timer);
  }, [searchInput]);

  // Fetch stats 1 lần khi mount, không phụ thuộc filter
  useEffect(() => {
    locationAPI.getLocationStats()
      .then(setStats)
      .catch((err) => {
        console.error('Failed to load location stats', err);
      });
  }, []);

  useEffect(() => {
    const fetchLocationPageData = async () => {
      setLoading(true);
      try {
        const filters: LocationFilterParams = {
          search,
          status: status as 'all' | 'pending' | 'approved' | 'rejected',
          categoryName,
        };

        const locationsData = await locationAPI.getLocations(
          currentPage,
          itemsPerPage,
          filters,
        );
        setLocations(locationsData.data);
        setTotalItems(locationsData.total);
      } catch (error) {
        console.error('Failed to load location data', error);
      } finally {
        setLoading(false);
      }
    };
    fetchLocationPageData();
  }, [currentPage, search, status, categoryName]);

  useEffect(() => {
    const fetchCategoryOptions = async () => {
      try {
        const data = await locationAPI.getLocationCategories();
        setCategoryOptions(data);
      } catch (error) {
        console.error('Failed to load location categories', error);
      }
    };

    void fetchCategoryOptions();
  }, []);

  const refreshCurrentPage = async () => {
    const filters: LocationFilterParams = {
      search,
      status: status as 'all' | 'pending' | 'approved' | 'rejected',
      categoryName,
    };

    const [locationsData, statsData] = await Promise.all([
      locationAPI.getLocations(currentPage, itemsPerPage, filters),
      locationAPI.getLocationStats(),
    ]);

    setLocations(locationsData.data);
    setTotalItems(locationsData.total);
    setStats(statsData);
  };

  const handleApprove = async (locationId: string) => {
    try {
      await locationAPI.approveLocation(locationId);
      await refreshCurrentPage();
    } catch (error) {
      console.error('Failed to approve location', error);
      window.alert('Không thể duyệt địa điểm. Vui lòng thử lại.');
    }
  };

  const handleReject = async (locationId: string, reason?: string) => {
    try {
      await locationAPI.rejectLocation(locationId, reason);
      await refreshCurrentPage();
    } catch (error) {
      console.error('Failed to reject location', error);
      window.alert('Không thể từ chối địa điểm. Vui lòng thử lại.');
    }
  };

  return (
    <div className="page-container">
      {/* Top Header */}
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Quản lý địa điểm</h1>
          <div className="breadcrumb">
            <span className="text-muted">Quản lý</span> / <Link to="/admin/locations" className="active-bread">Địa điểm</Link>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn">
            <Bell size={20} />
          </button>
          <AdminHeaderProfile />
          <Link to="/admin/locations/add" className="btn-primary">
            <Plus size={18} />
            <span>Thêm địa điểm</span>
          </Link>
        </div>
      </header>

      <div className="page-content">
        <LocationStats stats={stats} loading={loading} />

        <div className="card tab-container">
          <LocationFilter
            selectedCount={selectedRows.length}
            search={searchInput}
            status={status}
            categoryName={categoryName}
            statusOptions={STATUS_OPTIONS}
            categoryOptions={categoryOptions.categories}
            onSearchChange={(value) => setSearchInput(value)}
            onStatusChange={(value) => {
              setCurrentPage(1);
              setStatus(value);
            }}
            onCategoryChange={(value) => {
              setCurrentPage(1);
              setCategoryName(value);
            }}
          />

          <LocationTable
            locations={locations}
            loading={loading}
            selectedRows={selectedRows}
            onSelectRow={handleSelectRow}
            onSelectAll={handleSelectAll}
            currentPage={currentPage}
            totalItems={totalItems}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
            onApprove={handleApprove}
            onReject={handleReject}
          />
        </div>
      </div>
    </div>
  );
};
