import React, { useRef } from 'react';
import { CalendarDays, Search } from 'lucide-react';

interface SelectOption {
  value: string;
  label: string;
}

interface ReviewFilterProps {
  search: string;
  classification: string;
  dateSent: string;
  dateExact: string;
  status: string;
  rating: string;
  classificationOptions: SelectOption[];
  dateSentOptions: SelectOption[];
  statusOptions: SelectOption[];
  ratingOptions: SelectOption[];
  showClassification?: boolean;
  searchPlaceholder?: string;
  onSearchChange: (value: string) => void;
  onClassificationChange: (value: string) => void;
  onDateSentChange: (value: string) => void;
  onDateExactChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onRatingChange: (value: string) => void;
}

export const ReviewFilter: React.FC<ReviewFilterProps> = ({
  search,
  classification,
  dateSent,
  dateExact,
  status,
  rating,
  classificationOptions,
  dateSentOptions,
  statusOptions,
  ratingOptions,
  showClassification = true,
  searchPlaceholder = 'Tìm kiếm địa điểm, người đánh giá...',
  onSearchChange,
  onClassificationChange,
  onDateSentChange,
  onDateExactChange,
  onStatusChange,
  onRatingChange,
}) => {
  const hiddenDateInputRef = useRef<HTMLInputElement>(null);

  const handleOpenDatePicker = () => {
    const input = hiddenDateInputRef.current;
    if (!input) {
      return;
    }

    if (typeof input.showPicker === 'function') {
      input.showPicker();
      return;
    }

    input.click();
  };

  return (
    <div className="location-filter-bar">
      <div className="filter-left">
        <div className="search-box">
          <Search size={18} className="search-icon" />
          <input
            type="text"
            placeholder={searchPlaceholder}
            className="search-input"
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
          />
        </div>
      </div>

      <div className="filter-right">
        <div className="dropdown">
          <select
            value={rating}
            onChange={(event) => onRatingChange(event.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', cursor: 'pointer' }}
          >
            {ratingOptions.map((option) => (
              <option key={option.value} value={option.value}>
                Rating ({option.label})
              </option>
            ))}
          </select>
        </div>
        <div className="dropdown review-date-dropdown">
          <select
            value={dateSent}
            onChange={(event) => onDateSentChange(event.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', cursor: 'pointer' }}
          >
            {dateSentOptions.map((option) => (
              <option key={option.value} value={option.value}>
                Ngày gửi ({option.label})
              </option>
            ))}
          </select>
          <button
            type="button"
            className={`review-date-trigger ${dateExact ? 'active' : ''}`}
            onClick={handleOpenDatePicker}
            title={dateExact ? `Ngày đã chọn: ${dateExact}` : 'Chọn ngày cụ thể'}
            aria-label="Chọn ngày gửi cụ thể"
          >
            <CalendarDays size={16} />
          </button>
          <input
            ref={hiddenDateInputRef}
            type="date"
            value={dateExact}
            onChange={(event) => onDateExactChange(event.target.value)}
            className="review-date-hidden-input"
            tabIndex={-1}
            aria-hidden="true"
          />
        </div>
        {showClassification && (
          <div className="dropdown">
            <select
              value={classification}
              onChange={(event) => onClassificationChange(event.target.value)}
              style={{ border: 'none', background: 'transparent', outline: 'none', cursor: 'pointer' }}
            >
              {classificationOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  Phân loại ({option.label})
                </option>
              ))}
            </select>
          </div>
        )}
        <div className="dropdown">
          <select
            value={status}
            onChange={(event) => onStatusChange(event.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', cursor: 'pointer' }}
          >
            {statusOptions.map((option) => (
              <option key={option.value} value={option.value}>
                Trạng thái ({option.label})
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
};
