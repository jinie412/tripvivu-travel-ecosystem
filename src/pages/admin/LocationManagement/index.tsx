import React, { useEffect, useState } from 'react';
import { Location, LocationStatsInfo } from '../../../types/location';
import { locationAPI } from '../../../services/locationAPI';
import { LocationStats } from './components/LocationStats';
import { LocationFilter } from './components/LocationFilter';
import { LocationTable } from './components/LocationTable';
import { Bell, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './LocationManagement.css';

export const LocationManagement: React.FC = () => {
  const [locations, setLocations] = useState<Location[]>([]);
  const [stats, setStats] = useState<LocationStatsInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedRows, setSelectedRows] = useState<string[]>([]);

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

  useEffect(() => {
    const fetchLocationPageData = async () => {
      setLoading(true);
      try {
        const [statsData, locationsData] = await Promise.all([
          locationAPI.getLocationStats(),
          locationAPI.getLocations(currentPage, itemsPerPage)
        ]);
        setStats(statsData);
        setLocations(locationsData.data);
        setTotalItems(locationsData.total);
      } catch (error) {
        console.error('Failed to load location data', error);
      } finally {
        setLoading(false);
      }
    };
    fetchLocationPageData();
  }, [currentPage]);

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
          />
        </div>
      </div>
    </div>
  );
};
